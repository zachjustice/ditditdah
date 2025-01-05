class MessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message)
    cutoff_time = Time.current - (MessageConstants::MESSAGE_DISTANCE_METERS / MessageConstants::MESSAGE_SPEED_MPS)
    users = UserLocation.containing_point(message.id, cutoff_time).all
    logger.info("Broadcasting message to #{users.size} user#{"s" if users.size > 1}")
    users.each do |u|
      MessagesChannel.broadcast_to u.user_id, render(message)
    end
  end

  private
  def render(message)
    {
      id: message.id,
      start: {
        lat: message.start.latitude,
        long: message.start.longitude },
      true_heading: message.true_heading,
      created_at: message.created_at
    }
  end
end
