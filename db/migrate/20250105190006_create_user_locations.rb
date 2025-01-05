class CreateUserLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :user_locations, id: :uuid do |t|
      t.st_point :location, null: false
      t.integer :status, null: false
      t.references :user, null: false, type: :uuid, foreign_key: true

      t.timestamps

      t.index :location, using: :gist
    end
  end
end
