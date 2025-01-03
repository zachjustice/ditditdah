class Message < ApplicationRecord
  belongs_to :user

  validates :contents, presence: true
  validates :start, presence: true
  validates :end, presence: true
  validates :bbox, presence: true
  validates :true_heading, numericality: true
end
