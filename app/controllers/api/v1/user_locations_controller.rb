module Api::V1
  class UserLocationsController < ApplicationController
    before_action :authenticate_user!

    # PATCH/PUT /users/location
    def update
      location_params = params.require(:location).permit(coords: [ :lat, :long ])
      long = location_params[:coords][:long]
      lat = location_params[:coords][:lat]

      location = UserLocation.find_or_initialize_by(user_id: current_user.id)
      new_location = Geo.point(long, lat)

      if new_location.distance(location.location) > 10 || location.inactive?
        location.location = new_location
        location.active!
      end

      if location.save
        # TODO Schedule job to set user to inactive
        render json: {
          status: { code: 200, message: "Success" }
        }, status: :ok
      else
        render json: { errors: location.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /user/location
    def delete
      location = UserLocation.find_or_initialize_by(user_id: current_user.id)
      location.inactive! if location

      if location && location.save
        render json: {
          status: { code: 200, message: "Success" }
        }, status: :ok
      else
        render json: { errors: location.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
