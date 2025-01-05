class UserLocation < ApplicationRecord
  self.implicit_order_column = "created_at"
  belongs_to :user

  enum :status, [ :inactive, :active ]

  validates :location, presence: true
  validates :status, presence: true
end
