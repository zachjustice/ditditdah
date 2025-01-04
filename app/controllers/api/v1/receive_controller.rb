module Api::V1
  class ReceiveController < ApplicationController
    include ActionController::Live
    # before_action :authenticate_user!

    def index
      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Last-Modified"] = Time.now.httpdate

      lat = params[:lat]
      long = params[:long]

      sse = SSE.new(response.stream, event: "receive-messages", retry: 300)
      sse.write("STREAM OPEN")

      stream_endtime = 90.minutes.from_now
      messages = get_upcoming_messages(lat, long)
      sent_messages = Set.new
      puts(messages)
      next_message_time = messages.keys.min
      next_message_id = messages[next_message_time].id
      while Time.current < stream_endtime do
        puts "Next message in #{(next_message_time - Time.current)/60} minutes at #{next_message_time}"
        # Make sure the next message hasn't been sent yet
        while sent_messages.include?(next_message_id)
          messages.delete(next_message_time)
          next_message_time = messages.keys.min
          next_message_id = messages[next_message_time].id
        end

        if (Time.current - next_message_time).abs < 1.minutes.to_s
          # The message is close, go ahead and send it to the client
          m = messages[next_message_time]
          sse.write("#{m.id} #{m.start.latitude} #{m.start.longitude} #{next_message_time}")
          sent_messages.add(m.id)

          # Get the next message
          next_message_time = messages.keys.min
          next_message_id = messages[next_message_time].id

          if (Time.current - next_message_time).abs > 30
            sleep 30
          end
        end
      end
    ensure
      sse.write("CLOSING STREAM")
      sse.close
    end

    private

    def get_upcoming_messages(user_lat, user_long)
      cutoff_time = Time.current - (MessageConstants::MESSAGE_DISTANCE_METERS / MessageConstants::MESSAGE_SPEED_MPS)
      puts("Cutoff_time for #{(MessageConstants::MESSAGE_DISTANCE_METERS / MessageConstants::MESSAGE_SPEED_MPS)} -> #{cutoff_time}")
      messages = Message.containing_point(user_lat, user_long, cutoff_time).all
      message_arrival_times = {}
      messages.each do |m|
        nearest_point = GeoCalculations.nearest_point_on_line(m.start.latitude, m.start.longitude, m.end.latitude, m.end.longitude, user_lat, user_long)
        distance = m.start.distance(nearest_point)
        travel_time_seconds = distance / MessageConstants::MESSAGE_SPEED_MPS
        start_time = Time.parse(m.created_at.to_s)
        arrival_time = start_time + travel_time_seconds
        if Time.current.before?(arrival_time)
          puts("new #{distance}m; #{start_time} -> #{arrival_time} (now #{Time.current})")
          message_arrival_times[arrival_time] = m
        else
          puts("old #{distance}m; #{start_time} -> #{arrival_time} (now #{Time.current})")
        end
      end
      message_arrival_times
      # messages.filter do |m|
      #   current_position = GeoCalculations.calculate_current_position(m.created_at, Geokit::LatLng.new(m.start.latitude, m.start.longitude), m.true_heading, MessageConstants::MESSAGE_SPEED_MPS, MessageConstants::MESSAGE_DISTANCE_METERS)
      #   current_position.distance_to(user_position) <= MessageConstants::MESSAGE_RADIUS_METERS
      # end
    end
  end
end
