require 'resque'

# don't know why this works without this in dev but not prod
Resque.redis = REDIS