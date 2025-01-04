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

      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      message = current_user.messages.new(
        true_heading: true_heading,
        start: factory.point(long, lat), # rgeo factory point takes x,y which is long, lat NOT lat, long
        end: factory.point(end_point.longitude, end_point.latitude), # rgeo factory point takes x,y which is long, lat NOT lat, long
        bbox: bounding_box,
        contents: message_params[:contents],
      )

      if message.save
        geohash = GeoHash.encode(lat, long, 6)
        logger.debug("Sending message to geohash #{geohash}")
        MessagesChannel.broadcast_to(
          geohash,
          {
            id: message.id,
            start: {
              lat: message.start.latitude,
              long: message.start.longitude },
            true_heading: message.true_heading,
            created_at: message.created_at
          }
        )

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

    private

    def calculate_message_bounds(start_point, end_point, message_radius)
      # TODO add distance before and after endpoint to bounding box
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
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
          factory.point(start_left.lng, start_left.lat), # Start Left
          factory.point(end_left.lng, end_left.lat),     # End Left
          factory.point(end_right.lng, end_right.lat),   # End Right
          factory.point(start_right.lng, start_right.lat), # Start Right
          factory.point(start_left.lng, start_left.lat)  # Close the polygon
        ])
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
