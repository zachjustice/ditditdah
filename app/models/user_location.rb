class UserLocation < ApplicationRecord
  self.implicit_order_column = "created_at"
  belongs_to :user

  enum :status, [ :inactive, :active ]

  validates :location, presence: true
  validates :status, presence: true

  scope :containing_point, ->(message_id, cutoff_time) {
    where(
      "created_at >= :cutoff_time AND ST_Covers((SELECT bbox FROM messages WHERE id = :message_id), location)",
      { message_id: message_id, cutoff_time: cutoff_time }
    )
  }
end
