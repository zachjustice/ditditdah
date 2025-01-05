class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  self.implicit_order_column = "created_at"
  has_many :messages, dependent: :destroy
  has_many :user_locations, dependent: :destroy

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self
end
