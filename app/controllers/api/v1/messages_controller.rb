module Api::V1
  class MessagesController < ApplicationController
    before_action :authenticate_user!

    def update
      # TODO add idempotency. hash the message, start, heading and created_at milliseconds UTC. save as unique value on table.
      message_params = params.require(:message).permit(:true_heading, :contents, coords: [ :lat, :long ])

      # Compute geohash
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      message = current_user.messages.new(
        true_heading: message_params[:true_heading],
        start: factory.point(message_params[:coords][:lat], message_params[:coords][:long]),
          # TODO compute the endpoint
        end: factory.point(message_params[:coords][:lat], message_params[:coords][:long]),
        # TODO compute the bounding box of the signal
        bbox: "POLYGON ((30 10, 40 40, 20 40, 10 20, 30 10))",
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

      # TODO calculate current position of the signal
      if message
        render json: {
          status: { code: 200, message: "Success." },
          data: MessageSerializer.new(message).serializable_hash[:data][:attributes].merge({
            current_position: {
              lat: message.start.latitude,
              long: message.start.longitude,
              timestamp: Time.now.utc.iso8601
            }
          })
        }
      else
        render json: {
          status: { code: 404, message: "Not found." }
        }, status: :not_found
      end
    end
  end
end
