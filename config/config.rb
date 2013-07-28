configure :production do
  set :api_key, ENV['API_KEY']
  set :mongoid, 'config/mongoid.yml'
end

configure :development do
  set :api_key, 123
  set :mongoid, 'config/mongoid_test.yml'
end
