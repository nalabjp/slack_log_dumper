#! /usr/bin/env ruby
require 'slack-ruby-client'

Slack.configure do |config|
  config.token = ENV['SLACK_TOKEN']
end

SLACK_WORKSPACE = ENV['SLACK_WORKSPACE']
