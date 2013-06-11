# Load the rails application
require File.expand_path('../application', __FILE__)

APP_SETTINGS = YAML.load_file("#{Rails.root.to_s}/config/settings.yml")[Rails.env]
# Initialize the rails application
DaBobfather::Application.initialize!
