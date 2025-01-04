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
      stream_endtime = 1.minutes.from_now
      # messages = get_upcoming_messages(lat, long)
      while Time.current < stream_endtime do
        sleep 1
        # sse.write("HIT    #{ndx}. #{m.id} #{m.start.latitude} #{m.start.longitude}")
      end
    ensure
      sse.close
    end

    private

    def get_upcoming_messages(user_lat, user_long)
      # cutoff_time = Time.current - (MessageConstants::MESSAGE_DISTANCE_METERS / MessageConstants::MESSAGE_SPEED_MPS)
      # messages = Message.containing_point(user_lat, user_long, cutoff_time).all
      # messages.each do |m|
      #   nearest_point = GeoCalculations.nearest_point_on_line(m.start.latitude, m.start.longitude, m.end.latitude, m.end.longitude, user_lat, user_long)
      #   distance = m.start.distance(nearest_point)
      #   travel_time = distance / MessageConstants::MESSAGE_SPEED_MPS
      # end
      # messages.filter do |m|
      #   current_position = GeoCalculations.calculate_current_position(m.created_at, Geokit::LatLng.new(m.start.latitude, m.start.longitude), m.true_heading, MessageConstants::MESSAGE_SPEED_MPS, MessageConstants::MESSAGE_DISTANCE_METERS)
      #   current_position.distance_to(user_position) <= MessageConstants::MESSAGE_RADIUS_METERS
      # end
    end
  end
end
