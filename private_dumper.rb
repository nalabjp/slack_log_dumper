#! /usr/bin/env ruby
require_relative 'config'
require_relative 'private_channel'
require_relative 'user'
require_relative 'dumper'

class PrivateDumper
  def initialize(channel_name)
    @client = Slack::Web::Client.new
    @user = User.new(@client)
    @private_channel = PrivateChannel.new(@client, channel_name)
  end

  def dump
    Dumper.new(@private_channel.logs, @user).dump
  end
end

PrivateDumper.new(ARGV[0]).dump
