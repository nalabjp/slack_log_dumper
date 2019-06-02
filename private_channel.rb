#! /usr/bin/env ruby

class PrivateChannel
  def initialize(client, channel_name)
    @client = client
    @channel_name = channel_name
    @logs = []
    @latest = Time.current.to_i
  end

  def logs
    return @logs unless @logs.empty?

    channel = fetch_channel(@channel_name)
    read_all_logs(channel)
    @logs
  end

  private

  def fetch_channel(channel_name)
    @client.groups_list['groups'].find { |c| c['name'] == channel_name }
  end

  def fetch_group_history(channel_id, latest)
    @client.groups_history(channel: channel_id, count: 1000, latest: latest)
  end

  def read_all_logs(channel)
    latest = Time.current.to_i
    loop do
      chunk = fetch_group_history(channel.id, latest)
      raise 'Something happened...' unless chunk.ok?

      @logs.push(*chunk.messages)

      break unless chunk.has_more?

      latest = chunk.messages.last.ts
    end
  end
end
