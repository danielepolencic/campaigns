require 'rubygems'
require 'sinatra'
require 'dm-timestamps'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'json'
require 'mail'

SIGNATURE_LENGTH = 5

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class JSONable
  def to_json
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var
    end
    hash.to_json
  end
  def from_json! string
    JSON.load(string).each do |var, val|
      self.instance_variable_set var, val
    end
  end
end

class Person < JSONable
  include DataMapper::Resource

  property :id          , Serial
  property :name        , String
  property :email       , String, :required => true
  property :url_hash    , String
  property :created_at  , DateTime
  property :updated_at  , DateTime

  has n, :friendships_followed_people , 'Friendship', :child_key => [ :source_id ]
  has n, :friendships_followers       , 'Friendship', :child_key => [ :target_id ]
  has n, :followed_people             , self, :through => :friendships_followed_people  , :via => :target
  has n, :followers                   , self, :through => :friendships_followers        , :via => :source

end

class Friendship
  include DataMapper::Resource

  belongs_to :source, 'Person', :key => true
  belongs_to :target, 'Person', :key => true
end

helpers do
  def utm_tracking(label, *args)
    "?utm_campaign=#{args.first[:campaign]}&utm_medium=#{args.first[:source]}&utm_source=#{args.first[:source]}&utm_content=#{label}"
  end
end

if test?
  DataMapper.finalize.auto_migrate!
else
  DataMapper.finalize.auto_upgrade!
end

def random_string
  random = ''
  until random =~ /^([a-zA-Z]|[0-9]){#{SIGNATURE_LENGTH}}$/ do
    random = rand(36**SIGNATURE_LENGTH).to_s(36)
  end
  return random
end

def valid_email( value )
  begin
   return false if value == ''
   parsed = Mail::Address.new( value )
   return parsed.address == value && parsed.local != parsed.address
  rescue Mail::Field::ParseError
    return false
  end
end

get '/' do
  erb :home
end

get '/list' do
  @users = Person.all
  erb :list
end

get '/invite' do
  @current_campaign = "invite"
  erb :invite
end

post '/invite' do
  content_type :json
  params[:addresses].inspect
  response = {
                  "status" => "successful",
                  "addresses" => params[:addresses]
               }
  response.to_json
end

post '/register' do
  unless valid_email(params[:email])
    # status 404
    response = {
                  "status" => "error",
                  "email" => params[:email],
                  "name" => params[:name],
               }
  else
    response = {
                  "status" => "successful",
                  "email" => params[:email],
                  "name" => params[:name],
               }
    if user = Person.first( :email => params[:email] )
      response['url_hash'] = user.url_hash
      response['followers'] = user.followers.length
    else
      random_url_hash = random_string()
      new_user = Person.new :email => params[:email], :name => params[:name], :url_hash => random_url_hash
      new_user.save
      response['url_hash'] = random_url_hash
    end
    if params[:url_hash] and params[:url_hash] =~ /^([a-zA-Z]|[0-9]){5}$/
      leader = Person.first(:url_hash => params[:url_hash])
      leader.followers << new_user
      leader.save
    end
  end
  if test?
    content_type :json
    response.to_json
  else
    content_type :json
    response.to_json
  end
end

get %r{/c/(([a-zA-Z]|[0-9]){#{SIGNATURE_LENGTH}})$} do
  @user = Person.first :url_hash => params[:captures].first
  erb :profile
end

get %r{/(([a-zA-Z]|[0-9]){#{SIGNATURE_LENGTH}})$} do
  user = Person.first(:url_hash => params[:captures].first)
  if user
    username = if user.name then user.name else "no one" end
    response = {
      "status" => "successful",
      "message" => "Hello friend of #{username}",
      "followers" => user.followers.length
     }
  else
    redirect '/'
  end
  if test?
    content_type :json
    response.to_json
  else
    @url_hash = params[:captures].first
    erb :home
  end
end

post '/email' do
  if valid_email(params[:email])
    response = {
      "status" => "successful"
    }
  else
    status 400
    response = {
      "status" => "error",
      "error" => "The email doesn't match. Please double check."
    }
  end
  response.to_json
end

not_found do
  status 404
  redirect to('/')
end
