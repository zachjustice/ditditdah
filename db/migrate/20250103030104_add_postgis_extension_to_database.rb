class AddPostgisExtensionToDatabase < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'postgis' unless extension_enabled?('postgis')
  end
end
