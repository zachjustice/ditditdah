class MessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message)
    geohash = GeoHash.encode(message.start.latitude, message.start.longitude, 6)
    logger.debug("Sending message to geohash #{geohash} for #{message.id}")
    MessagesChannel.broadcast_to geohash, render(message)
    # TODO schedule updates for geohash in the path
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
