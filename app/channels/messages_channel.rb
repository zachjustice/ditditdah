require "pr_geohash"

class MessagesChannel < ApplicationCable::Channel
  def subscribed
    user_id = params[:user_id]
    stream_for user_id
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
