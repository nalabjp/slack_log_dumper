#! /usr/bin/env ruby
require 'cgi'

class Dumper
  def initialize(logs, user)
    @logs = logs
    @user = user
  end

  def dump
    puts format_logs.join("\n")
  end

  private

  def format_logs
    reorder_logs.map do |message|
      timestamp = formatted_timestamp(message.ts)
      user = fetch_user(message.user)

      offset = child_thread?(message) ? 1 : 0

      text = message.text

      # Enclose the mention with backticks
      text = mention_with_backtick(text)
      # Convert all newlines once into newline tags
      text = lf_to_br(text)
      # Convert tabs to 4 spaces in soft tab
      text = hardtab_to_softtab(text)
      # Convert conversion in code block back
      text = codeblock_formatting(text, offset)
      # Convert strikethrough for markdown
      text = markdown_strikethrough(text)
      # Convert quotation
      text = markdown_quotation(text, offset)
      # Convert slack channel link
      text = slack_channel_link(text)

      # files
      text.concat(attached_files(message))

      # attachements
      text.concat(attached_attachments(message))

      # reactions
      text.concat(attached_reactions(message))

      "#{indent(offset)}- **[#{timestamp}] #{user}**<br />#{text}"
    end
  end

  # Sort child threads to line up with parent thread
  def reorder_logs
    @logs.reverse.each_with_object({}) { |message, hash|
      if parent_thread?(message)
        hash[message.ts] = [message, []]
      elsif child_thread?(message)
        hash[message.thread_ts][1].push(message)
      else
        hash[message.ts] = [message]
      end
    }.values.flatten
  end

  def child_thread?(message)
    message.key?('thread_ts') && ( message.ts != message.thread_ts )
  end

  def parent_thread?(message)
    message.key?('thread_ts') && ( message.ts == message.thread_ts )
  end

  def formatted_timestamp(timestamp)
    Time.at(timestamp.to_i).strftime('%F %T (%a)')
  end

  def fetch_user(user)
    @user.info(user)
  end

  def indent(offset)
    "\t" * offset
  end

  def mention_with_backtick(text)
    text.gsub(/\<@([[:alnum:]]+)\>/) { u = fetch_user($1); "`@#{u}`" }
  end

  def lf_to_br(text)
    text.gsub("\n", '<br />')
  end

  def hardtab_to_softtab(text)
    text.gsub("\t", "&nbsp;"*4)
  end

  def codeblock_formatting(text, offset)
    text = codeblock_unescape(text)
    text = codeblock_whitespace(text)
    text = codeblock_linefeed_with_indent(text, offset)
    text = codeblock_after_linefeed_with_indent(text, offset)
  end

  # Return line feed tag in code block to line feed code
  # Indent the code block at the same time
  def codeblock_linefeed_with_indent(text, offset)
    text.gsub(/```(.+)```/) { "\n\n#{indent(offset+1)}```#{$1.gsub('<br />', "\n#{indent(offset+1)}")}```" }
  end

  # Convert a newline immediately after a code block from a newline tag to a newline code
  # Indent sentences following the code block
  def codeblock_after_linefeed_with_indent(text, offset)
    text.gsub(/```\<br \/\>/) { "```\n#{indent(offset+1)}" }
  end

  def codeblock_unescape(text)
    text.gsub(/```(.+)```/) { "```#{CGI.unescapeHTML($1)}```" }
  end

  def codeblock_whitespace(text)
    text.gsub(/```(.+)```/) { "```#{$1.gsub('&nbsp;', "\s")}```" }
  end

  def markdown_strikethrough(text)
    text.gsub('~', '~~')
  end

  def markdown_quotation(text, offset)
    # TODO: Unfinished implementation (<br /> => \n)
    # text
    #   .gsub(/\A((&gt;)+)\s/) { "\n#{indent(offset+1)}#{$1}\s" }
    #   .gsub(/\<br \/\>((&gt;)+)\s/) { "\n#{indent(offset+1)}#{$1}\s" }
    #   .gsub(/&gt;/, '>')
    text
  end

  def slack_channel_link(text)
    SLACK_WORKSPACE ? text.gsub(/\<#(.+)\|(.+)\>/) { "[##{$2}](https://#{SLACK_WORKSPACE}.slack.com/archives/#{$1})" } : text

  end

  def attached_files(message)
    return '' unless message.key?('files')

    # TODO: Get image and upload?
    message.files.map { |file|
      "[image](#{file.url_private})"
    }.join('<br />').insert(0, '<br />')
  end

  def attached_reactions(message)
    return '' unless message.key?('reactions')

    # TODO: Get emoji and upload?
    message.reactions.map { |reaction|
      users = reaction.users.map {|u| "`@#{fetch_user(u)}`" }.join(' ')
      "<:#{reaction.name}:x#{reaction['count']} / #{users}>"
    }.join(' ').insert(0, '<br />')
  end

  def attached_attachments(message)
    # TODO: Will implements?
    ''
  end
end
