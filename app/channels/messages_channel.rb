require "pr_geohash"

class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel
    lat = params[:lat]
    long = params[:long]
    geohash = GeoHash.encode(lat, long, MessageConstants::GEOHASH_LENGTH)
    puts("Starting stream for #{geohash} - #{lat} #{long}")
    stream_for geohash
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
