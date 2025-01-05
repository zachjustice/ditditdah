require "pr_geohash"

class MessagesChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel
    lat = params[:lat]
    long = params[:long]
    geohash = GeoHash.encode(lat, long, 6)
    puts("Starting stream for #{geohash} - #{lat} #{long}")
    stream_for geohash
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
