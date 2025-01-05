module Api::V1
  class MessagesController < ApplicationController
    before_action :authenticate_user!

    def update
      # TODO add idempotency. hash the message, start, heading and created_at milliseconds UTC. save as unique value on table.
      message_params = params.require(:message).permit(:true_heading, :contents, coords: [ :lat, :long ])

      long = message_params[:coords][:long]
      lat = message_params[:coords][:lat]
      true_heading = message_params[:true_heading]

      start_point = Geokit::LatLng.new(lat, long)
      end_point = start_point.endpoint(true_heading, MessageConstants::MESSAGE_DISTANCE_METERS)
      bounding_box = self.calculate_message_bounds(start_point, end_point, MessageConstants::MESSAGE_RADIUS_METERS)

      message = current_user.messages.new(
        true_heading: true_heading,
        start: Geo.point(long, lat), # rgeo factory point takes x,y which is long, lat NOT lat, long
        end: Geo.point(end_point.longitude, end_point.latitude), # rgeo factory point takes x,y which is long, lat NOT lat, long
        bbox: bounding_box,
        contents: message_params[:contents],
      )

      if message.save
        render json: {
          status: { code: 200, message: "Success" },
          data: { id: message.id }
        }, status: :ok
      else
        render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      message = current_user.messages.find_by(id: params[:id])
      start_point = Geokit::LatLng.new(message.start.latitude, message.start.longitude)
      current_position = GeoCalculations.calculate_current_position(message.created_at, start_point, message.true_heading, MessageConstants::MESSAGE_SPEED_MPS, MessageConstants::MESSAGE_DISTANCE_METERS) || message.end

      if message
        render json: {
          status: { code: 200, message: "Success." },
          data: MessageSerializer.new(message).serializable_hash[:data][:attributes].merge({
            start: {
              lat: message.start.latitude,
              long: message.start.longitude
            },
            current_position: {
              lat: current_position.latitude,
              long: current_position.longitude,
              timestamp: Time.current.iso8601
            },
            end: {
              lat: message.end.latitude,
              long: message.end.longitude
            }
          })
        }
      else
        render json: {
          status: { code: 404, message: "Not found." }
        }, status: :not_found
      end
    end

    def index
      lat, long = params[:lat], params[:long]
      upcoming = self.get_upcoming_messages(lat, long)
      render json: {
        status: { code: 200, message: "Success" },
        data: { upcoming: upcoming }
      }, status: :ok
    end

    private

    def get_upcoming_messages(user_lat, user_long)
      cutoff_time = Time.current - (MessageConstants::MESSAGE_DISTANCE_METERS / MessageConstants::MESSAGE_SPEED_MPS)
      messages = Message.containing_point(user_lat, user_long, cutoff_time).all

      upcoming = messages.map do |m|
        nearest_point = GeoCalculations.nearest_point_on_line(m.start.latitude, m.start.longitude, m.end.latitude, m.end.longitude, user_lat, user_long)

        distance = m.start.distance(nearest_point)
        travel_time_seconds = distance / MessageConstants::MESSAGE_SPEED_MPS
        start_time = Time.parse(m.created_at.to_s)
        arrival_time = start_time + travel_time_seconds

        if Time.current.before?(arrival_time)
          {
            id: m.id,
            start: {
              lat: m.start.latitude,
              long: m.start.longitude
            },
            speed_mps: MessageConstants::MESSAGE_SPEED_MPS,
            true_heading: m.true_heading,
            created_at: m.created_at,
            arrive_at: arrival_time
          }
        else
          nil
        end
      end

      upcoming.compact
    end

    def calculate_message_bounds(start_point, end_point, message_radius)
      # TODO add distance before and after endpoint to bounding box
      factory = Geo.factory
      bearing = start_point.heading_to(end_point)
      bearing_left = (bearing - 90) % 360
      bearing_right = (bearing + 90) % 360

      # Calculate Offset Points
      start_left = start_point.endpoint(bearing_left, message_radius)
      start_right = start_point.endpoint(bearing_right, message_radius)

      end_left = end_point.endpoint(bearing_left, message_radius)
      end_right = end_point.endpoint(bearing_right, message_radius)

      factory.polygon(
        factory.linear_ring([
          Geo.point(start_left.lng, start_left.lat), # Start Left
          Geo.point(end_left.lng, end_left.lat),     # End Left
          Geo.point(end_right.lng, end_right.lat),   # End Right
          Geo.point(start_right.lng, start_right.lat), # Start Right
          Geo.point(start_left.lng, start_left.lat)  # Close the polygon
        ])
      )
    end
  end
end
