require "rufus-scheduler"

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

      messages = get_upcoming_messages(lat, long)
      stream_endtime = 90.minutes.from_now
      sent_messages = Set.new
      puts(messages.keys.inspect)

      unsubscribe = Rails.configuration.event_store.subscribe(to: [ MessageSent ]) { |event|
        puts("### RECEIVED EVENT: #{event.inspect}")
      }

      scheduler = Rufus::Scheduler.new
      messages.each do |arrival_time, message|
        scheduled_time = Time.at(arrival_time)
        logger.debug("### scheduling #{message.id} #{scheduled_time}")
        scheduler.at scheduled_time.to_s do
          logger.debug("### sending #{message.id}")
          sse.write("#{message.id} #{message.start.latitude} #{message.start.longitude}")
          sent_messages.add(message.id)
        end
      end

      scheduler.at stream_endtime.to_s do
        puts("### ending stream")
        if scheduler
          scheduler.shutdown
        end
        if sse
          sse.write("CLOSING STREAM")
          sse.close
        end

        if unsubscribe
          unsubscribe.call
        end
      end

      # TODO use a scheduler / threads or something
      # next_message_time = messages.keys.min
      # next_message_id = messages[next_message_time]&.id
      # while Time.current < stream_endtime do
      #   puts "Next message in #{(next_message_time - Time.current.to_i)/60} minutes at #{Time.at(next_message_time)}"
      #   # Make sure the next message hasn't been sent yet
      #   while sent_messages.include?(next_message_id)
      #     messages.delete(next_message_time)
      #     next_message_time = messages.keys.min
      #     next_message_id = messages[next_message_time]&.id
      #   end

      #   if messages.size > 0 && (next_message_time - Time.current.to_i).abs < 1.minutes.to_i
      #     # The message is close, go ahead and send it to the client
      #     m = messages[next_message_time]
      #     sse.write("#{m.id} #{m.start.latitude} #{m.start.longitude} #{next_message_time}")
      #     sent_messages.add(m.id)
      #     messages.delete(next_message_id)

      #     # Get the next message
      #     next_message_time = messages.keys.min
      #     next_message_id = messages[next_message_time]&.id
      #   end

      #   if messages.size == 0 || (next_message_time - Time.current.to_i).abs > 30
      #     sleep 30
      #   end
      # end
    ensure
      if scheduler
        scheduler.shutdown
      end
      if sse
        sse.write("CLOSING STREAM")
        sse.close
      end

      if unsubscribe
        unsubscribe.call
      end
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
          message_arrival_times[arrival_time.to_i] = m
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
