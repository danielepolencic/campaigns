require "rack/test"
require "./app.rb"
require "digest"
require "json"

set :environment, :test

def app
  Sinatra::Application
end

describe 'General' do
  it "should validate email" do
    valid_email("daniele.polencic@gmail.com").should be_true
  end

  it "should not validate the email" do
    valid_email("HelloWorld").should be_false
  end
end

describe 'Database' do

  before :all do
    @email = "daniele@uasabi.com"
    @name = "daniele"
    @follower = "follower@email.com"
    @followed_person = "followed_person@email.com"
  end

  before :each do
    # reset the db
    DataMapper.auto_migrate!
  end

  it "should create a user" do
    random_url_hash = random_string()
    user = Person.new :email => @email, :name => @name, :url_hash => random_url_hash
    user.save

    old_user = Person.get(1)
    old_user.email.should == @email
    old_user.name.should == @name
    old_user.url_hash.should == random_url_hash
  end

  it "should create a follower" do
    user = Person.new :email => @email, :name => @name, :url_hash => random_string()
    follower = Person.new :email => @follower, :name => 'Miriam', :url_hash => random_string()
    user.followers << follower
    user.save

    Person.all.should have(2).entries
    old_user = Person.first(:email => @email)
    old_user.followers.should have(1).entries
    old_user.followers.first.email.should == @follower
  end

  it "should be followed" do
    user = Person.new :email => @email, :name => @name, :url_hash => random_string()
    leader= Person.new :email => @followed_person, :name => 'Miriam', :url_hash => random_string()
    user.followed_people << leader
    user.save

    Person.all.should have(2).persons
    old_user = Person.get(1)
    old_user.followed_people.should have(1).entries
    old_user.followed_people.first.email.should == @followed_person
  end

  it "should pass mass following" do
    user = Person.new :email => @email, :name => @name, :url_hash => random_string()

    ["Miriam", "Paride", "Apollo"].each do |username|
      leader = Person.new :email => "#{username}@email.com", :name => username, :url_hash => random_string()
      user.followed_people << leader
    end
    user.save

    Person.all.should have(4).persons
    old_user = Person.first :email => @email
    old_user.followed_people.should have(3).entries
  end

  it "should pass mass followers" do
    user = Person.new :email => @email, :name => @name, :url_hash => random_string()

    ["Miriam", "Paride", "Apollo"].each do |username|
      follower = Person.new :email => "#{username}@email.com", :name => username, :url_hash => random_string()
      user.followers << follower
    end
    user.save

    (2..4).each do |user_id|
      followed_person = Person.get(user_id)
      followed_person.followed_people.should have(1).entries
      followed_person.followed_people.first.email.should == @email
    end
  end

end

describe 'Web Service' do
  include Rack::Test::Methods

  before :all do
    @email = "daniele@uasabi.com"
    @name = "daniele"
    @follower = "follower@email.com"
    @followed_person = "followed_person@email.com"
  end

  before :each do
    # reset the db
    DataMapper.auto_migrate!
  end

  it "loads the home page" do
    get '/'
    last_response.should be_ok
  end

  it "creates the user" do
    post '/register', params = { :email => @email, :name => @name }
    last_response.headers["Content-type"].should match(/application\/json/)
    response = JSON.parse(last_response.body)
    response["status"].should == "successful"
    response["email"].should == @email
    response["name"].should == @name
    response["url_hash"].should_not be_empty
    new_user = Person.get(1)
    new_user.email.should == @email
    new_user.name.should == @name
    new_user.url_hash.should_not be_empty
  end

  it "doesn't create the user" do
    post '/register', params = { :email => @name, :name => @name }
    last_response.should_not be_ok
    Person.all.should have(0).entries
  end

  it "creates the follower" do
    post '/register', params = { :email => @email, :name => @name }
    JSON.parse(last_response.body)["url_hash"].should_not be_empty
    post "/register", params = { :email => @follower, :url_hash => JSON.parse(last_response.body)["url_hash"] }
    last_response.headers["Content-type"].should match(/application\/json/)
    response = JSON.parse(last_response.body)
    response["status"].should == "successful"
    response["email"].should == @follower

    new_user = Person.get(1)
    new_user.email.should == @email
    new_user.name.should == @name
    new_user.followers.should have(1).entries
    new_user.followers.first.email.should == @follower

    follower = Person.first :email => @follower
    follower.followed_people.should have(1).entries
    follower.followed_people.first.email.should == @email
  end

  it "doesn't create the follower" do
    post '/register', params = { :email => @email, :name => @name }
    JSON.parse(last_response.body)["url_hash"].should_not be_empty
    post "/register", params = { :email => @name, :url_hash => JSON.parse(last_response.body)["url_hash"] }
    last_response.should_not be_ok
    Person.all.should have(1).entries
  end

  it "greets followers" do
    post '/register', params = { :email => @email, :name => @name }
    get "/#{JSON.parse(last_response.body)["url_hash"]}"
    last_response.body.should_not be_empty
    response = JSON.parse(last_response.body)
    response["status"].should == "successful"
    response["message"].should == "Hello friend of #{@name}"
  end

  it "doesn't validate the email" do
    post "/email", params = { :email => "HelloWorld@" }
    last_response.should_not be_ok
    response = JSON.parse(last_response.body)
    response["status"].should == "error"
  end

  it "validates the email" do
    post "/email", params = { :email => @email }
    last_response.should be_ok
    response = JSON.parse(last_response.body)
    response["status"].should == "successful"
  end

  it "shows the profile" do
    post '/register', params = { :email => @email, :name => @name }
    get "/c/#{JSON.parse(last_response.body)["url_hash"]}"
    last_response.should be_ok
  end
end
