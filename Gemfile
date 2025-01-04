source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"

# devise is a gem that handles users and authentication. It takes care of all the controllers necessary for user creation (users_controller) and user sessions (users_sessions_controller).
gem "devise"

# devise-jwt, a gem, is an extension to devise which handles the use of JWT tokens for user authentication
gem "devise-jwt"

# jsonapi-serializer is a gem that will serialize ruby objects in JSON format
gem "jsonapi-serializer"

# Core component to support geospatial objects, handle geometry, parse additional datatypes (WKT, WKB, Multipolygons).
gem "rgeo"

# Enables PostGIS database features to work within ActiveRecord — provides additional migrations, allows spatial data in queries etc.
gem "activerecord-postgis-adapter", git: "https://github.com/rgeo/activerecord-postgis-adapter.git", ref: "147fd43191ef703e2a1b3654f31d9139201a87e8"

# Provides additional extensions and helpers for ActiveRecord.
# https://github.com/rgeo/rgeo-activerecord/wiki/Spatial-Factory-Store
# gem 'rgeo-activerecord'

# Useful for getting the end position given a start position, heading, and distance
gem "geokit"

# Objects created by this factory, rgeo's ffi factory, give access to low-level geos objects that can be manipulated using ffi-geos's api.
# (which itself is basically thin wrappers around the libgeos C api calls).
# This is all used to get the nearest point on a line given some other point somewhere else.
gem "ffi-geos"

gem "rufus-scheduler"

gem "pr_geohash"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end
gem "rails_event_store", "~> 2.15.0"
