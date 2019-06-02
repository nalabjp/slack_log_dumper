#! /usr/bin/env ruby

class User
  def initialize(client)
    @users = {}
    @client = client
  end

  def info(user)
    @users[user] ||= @client.users_info(user: user).user.profile.display_name
  end
end
