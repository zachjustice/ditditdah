class Message < ApplicationRecord
  belongs_to :user

  validates :contents, presence: true
  validates :start, presence: true
  validates :end, presence: true
  validates :bbox, presence: true
  validates :true_heading, numericality: true

  def self.near(point, distance)
    where(
      "ST_DWithin(start, :point, :distance)",
      { point: Geo.to_wkt(point), distance: distance * 1000 } # wants meters not kms
    )
  end

  scope :containing_point, ->(latitude, longitude, cutoff_time) {
    where(
      "created_at >= :cutoff AND ST_Covers(bbox, ST_SetSRID(ST_Point(:long, :lat), #{Geo::SRID}))",
      { long: longitude, lat: latitude, cutoff: cutoff_time }
    )
  }
end
