require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'rack/contrib/jsonp'
require 'mongoid'
require 'json'
require 'multi_json'
require 'mail'
require_relative 'model/campaign'
require_relative 'model/person'
require_relative 'config/config'

use Rack::JSONP

set :json_encoder, :to_json

Mongoid.load!(settings.mongoid.to_s)

get '/' do
  erb :usage
end

before '/register' do
  if params[:email].blank? || ! validEmail?( params[:email] )
    halt 403, {'Content-Type' => 'application/json'}, { ok: false, message: 'Email is not valid.' }.to_json
  end

  if params[:campaign].blank?
    halt 403, {'Content-Type' => 'application/json'}, { ok: false, message: 'Campaign identifier is missing.' }.to_json
  end

  unless params[:api_key] && ( params[:api_key].to_i == settings.api_key.to_i )
    halt 403, {'Content-Type' => 'application/json'}, {:ok => false, :message => 'API KEY not valid.'}.to_json
  end
end

get '/register' do
  user = Person.where( :email => params[:email] ).first
  campaign = Campaign.where( :name => params[:campaign] ).first_or_create

  if user.nil?
    args = params.reject{ |key, value| key == 'campaign' }
    args[:signature] = signature(5)
    user = Person.new args
    user.save

    campaign.people << user
    campaign.save

    leader = Person.where( :signature => params[:signature] ).first
    unless params[:signature].nil? || leader.nil?
      leader.followers.push user
      leader.save
    end

    return json user
  end

  unless campaign.people.where( user[:id] )
    campaign.people.push user
    campaign.save
  end

  json user
end

def signature( length )
  return Array.new(length){[*'0'..'9', *'a'..'z', *'A'..'Z'].sample}.join
end

def validEmail?( email )
  begin
   return false if email == ''
   parsed = Mail::Address.new( email )
   return parsed.address == email && parsed.local != parsed.address
  rescue Mail::Field::ParseError
    return false
  end
end
