if ENV["REDISTOGO_URL"]
  #for heroku
  redis_url =  ENV["REDISTOGO_URL"]
  # overlap
  #redis_url =  ENV["REDIS_URL"]
  uri = URI.parse(redis_url)
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  REDIS = $redis
else
 $redis = Redis.connect(:user => APP_SETTINGS['redis_user'],
   :password => APP_SETTINGS['redis_password'],
   :host => APP_SETTINGS['redis_server'], :port => APP_SETTINGS['redis_port'])
   REDIS = $redis
end
