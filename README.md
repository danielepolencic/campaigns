# Campaigns
Simple service for registering users to campaigns. Supports followers/leaders
paradigm.

## Features
- JSONP compatible
- Heroku compatible
- Uses free tier on MongoHQ
- HTTP API

## Install
Download this repository

    ~$ git clone git@github.com:danielepolencic/campaigns

From within the newly created folder

    ~$ bundle install
    ~$ ruby app.rb

Visit the following page: [http://localhost:4567](http://localhost:4567)

## Tests
Run

    ~$ rspec spec
