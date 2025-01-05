class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages, id: :uuid do |t|
      t.string :contents, null: false
      t.decimal :true_heading, null: false
      t.st_point :start, geographic: true, null: false
      t.st_point :end, geographic: true, null: false
      t.st_polygon :bbox, geographic: true, null: false
      t.references :user, null: false, type: :uuid, foreign_key: true

      t.timestamps

      t.index :start, using: :gist
      t.index :end, using: :gist
      t.index :bbox, using: :gist
    end
  end
end
