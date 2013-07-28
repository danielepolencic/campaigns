require 'rack/test'
require 'digest'
require 'json'
require_relative '../app'

set :environment, :test

def app
  Sinatra::Application
end

describe 'Campaign' do
  include Rack::Test::Methods

  before :all do
    @campaign = 'Awesome Strategy'
    @email = 'leader@test.com'
    @name = 'Daniele'
    @follower = 'follower@test.com'
    @api_key = settings.api_key.to_i
  end

  before :each do
    Mongoid.purge!
    Mongoid::IdentityMap.clear
    session = Mongoid::Sessions.default
    session.use('campaigns_test')
    session.collections.each do |collection|
      collection.drop
    end
  end

  it 'should register a new user' do
    get '/register', params = {
      email: @email,
      name: @name,
      campaign: @campaign,
      api_key: @api_key
    }
    last_response.should be_ok
    user = Person.first
    user.email.should == @email
    user[:name].should == @name
    user[:signature].should_not be_empty
  end

  it 'should fail to register the new user if the email is not valid' do
    get '/register', params = {
      email: @name,
      name: @name,
      campaign: @campaign,
      api_key: @api_key
    }
    last_response.should_not be_ok
    Person.all.should have(0).entries
  end

  it 'should fail to register the new user if there is no campaign' do
    get '/register', params = { email: @name, name: @name, api_key: @api_key }
    last_response.should_not be_ok
    Person.all.should have(0).entries
  end

  it 'should create a new follower' do
    get '/register', params = {
      email: @email,
      name: @name,
      campaign: @campaign,
      api_key: @api_key
    }
    get '/register', params = {
      email: @follower,
      signature: JSON.parse(last_response.body)['signature'],
      campaign: @campaign,
      api_key: @api_key
    }
    last_response.should be_ok

    leader = Person.first
    leader.followers.should have(1).entries
    leader.followers.first.email.should == @follower

    follower = Person.where( :email => @follower ).first
    follower.leaders.should have(1).entries
    follower.leaders.first.email.should == @email
  end

  it 'should not create a new follower if the signature is new' do
    get '/register', params = {
      email: @email,
      name: @name,
      campaign: @campaign,
      api_key: @api_key
    }
    get '/register', params = {
      email: @follower,
      signature: 'abc12',
      campaign: @campaign,
      api_key: @api_key
    }
    last_response.should be_ok
    leader = Person.where( :email => @email ).first
    leader.followers.should have(0).entries
  end

end
