# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "nokogiri"
require "redcarpet"

module TextHelper
  def force_zone(time)
    (time.in_time_zone(@time_zone || Time.zone) rescue nil) || time
  end

  def self.date_string(start_date, *args)
    return nil unless start_date

    start_date = start_date.in_time_zone.beginning_of_day
    style = args.last.is_a?(Symbol) ? args.pop : :normal
    end_date = args.pop
    end_date = end_date.in_time_zone.beginning_of_day if end_date
    start_date_display = Utils::DatePresenter.new(start_date).as_string(style)
    if end_date.nil? || start_date == end_date
      start_date_display
    else
      I18n.t("time.ranges.different_days",
             "%{start_date_and_time} to %{end_date_and_time}",
             start_date_and_time: start_date_display,
             end_date_and_time: Utils::DatePresenter.new(end_date).as_string(style))
    end
  end

  def date_string(*args)
    TextHelper.date_string(*args)
  end

  def time_string(start_time, end_time = nil, zone = nil)
    presenter = Utils::TimePresenter.new(start_time, zone)
    presenter.as_string(display_as_range: end_time)
  end

  def datetime_span(*args)
    string = datetime_string(*args)
    if string.present? && args[0]
      "<span class='zone_cached_datetime' title='#{args[0].iso8601 rescue ""}'>#{string}</span>"
    else
      nil
    end
  end

  def datetime_string(start_datetime, datetime_type = :event, end_datetime = nil, shorten_midnight = false, zone = nil, with_weekday: false)
    zone ||= ::Time.zone
    presenter = Utils::DatetimeRangePresenter.new(start_datetime, end_datetime, datetime_type, zone, with_weekday:)
    presenter.as_string(shorten_midnight:)
  end

  def time_ago_in_words_with_ago(time)
    I18n.t("#time.with_ago", "%{time} ago", time: (time_ago_in_words time rescue ""))
  end

  # more precise than distance_of_time_in_words, and takes a number of seconds,
  # rather than two times. also assumes durations on the scale of hours or
  # less, so doesn't bother with days, months, or years
  def readable_duration(total_seconds)
    hours, remainder = total_seconds.divmod(3600)
    minutes = remainder.div(60)

    if hours >= 1 && minutes.zero?
      I18n.t(
        { one: "1 hour", other: "%{count} hours" },
        count: hours
      )
    elsif hours > 1
      I18n.t(
        { one: "%{hours} hours and 1 minute", other: "%{hours} hours and %{count} minutes" },
        hours:,
        count: minutes
      )
    elsif hours == 1
      I18n.t(
        { one: "1 hour and 1 minute", other: "1 hour and %{count} minutes" },
        count: minutes
      )
    elsif minutes >= 1
      I18n.t(
        { one: "1 minute", other: "%{count} minutes" },
        count: minutes
      )
    else
      I18n.t("less than a minute")
    end
  end

  # By Henrik Nyh <http://henrik.nyh.se> 2008-01-30.
  # Free to modify and redistribute with credit.

  # modified by Dave Nolan <http://textgoeshere.org.uk> 2008-02-06
  # Ellipsis appended to text of last HTML node
  # Ellipsis inserted after final word break

  # modified by Mark Dickson <mark@sitesteaders.com> 2008-12-18
  # Option to truncate to last full word
  # Option to include a 'more' link
  # Check for nil last child

  # Copied from http://pastie.textmate.org/342485,
  # based on http://henrik.nyh.se/2008/01/rails-truncate-html-helper
  def truncate_html(input, options = {})
    doc = Nokogiri::HTML(input)
    options[:max_length] ||= 250
    num_words = options[:num_words] || (options[:max_length] / 5) || 30
    truncate_string = options[:ellipsis] || I18n.t("lib.text_helper.ellipsis", "...")
    truncate_string += options[:link] if options[:link]
    truncate_elem = Nokogiri::HTML("<span>" + truncate_string + "</span>").at("span")

    current = doc.children.first
    count = 0

    while true
      # we found a text node
      if current.is_a?(Nokogiri::XML::Text)
        count += current.text.split.length
        # we reached our limit, let's get outta here!
        break if count > num_words

        previous = current
      end

      if !current.children.empty?
        # this node has children, can't be a text node,
        # lets descend and look for text nodes
        current = current.children.first
      elsif !current.next.nil?
        # this has no children, but has a sibling, let's check it out
        current = current.next
      else
        # we are the last child, we need to ascend until we are
        # either done or find a sibling to continue on to
        n = current
        while !n.is_a?(Nokogiri::HTML::Document) && n.parent.next.nil?
          n = n.parent
        end

        # we've reached the top and found no more text nodes, break
        if n.is_a?(Nokogiri::HTML::Document)
          break
        else
          current = n.parent.next
        end
      end
    end

    if count >= num_words
      unless count == num_words
        new_content = current.text.split

        # If we're here, the last text node we counted eclipsed the number of words
        # that we want, so we need to cut down on words.  The easiest way to think about
        # this is that without this node we'd have fewer words than the limit, so all
        # the previous words plus a limited number of words from this node are needed.
        # We simply need to figure out how many words are needed and grab that many.
        # Then we need to -subtract- an index, because the first word would be index zero.

        # For example, given:
        # <p>Testing this HTML truncater.</p><p>To see if its working.</p>
        # Let's say I want 6 words.  The correct returned string would be:
        # <p>Testing this HTML truncater.</p><p>To see...</p>
        # All the words in both paragraphs = 9
        # The last paragraph is the one that breaks the limit.  How many words would we
        # have without it? 4.  But we want up to 6, so we might as well get that many.
        # 6 - 4 = 2, so we get 2 words from this node, but words #1-2 are indices #0-1, so
        # we subtract 1.  If this gives us -1, we want nothing from this node. So go back to
        # the previous node instead.
        index = num_words - (count - new_content.length) - 1
        if index >= 0
          new_content = new_content[0..index]
          current.add_previous_sibling(truncate_elem)
          new_node = Nokogiri::XML::Text.new(new_content.join(" "), doc)
          truncate_elem.add_previous_sibling(new_node)
        else
          current = previous
          # why would we do this next line? it just ends up xml escaping stuff
          # current.content = current.content
          current.add_next_sibling(truncate_elem)
        end
        current = truncate_elem
      end

      # remove everything else
      until current.is_a?(Nokogiri::HTML::Document)
        until current.next.nil?
          current.next.remove
        end
        current = current.parent
      end
    end

    # now we grab the html and not the text.
    # we do first because nokogiri adds html and body tags
    # which we don't want
    res = doc.at_css("body").inner_html rescue nil
    res ||= doc.root.children.first.inner_html rescue ""
    res&.html_safe
  end

  def self.make_subject_reply_to(subject)
    blank_re = I18n.t("#subject_reply_to", "Re: %{subject}", subject: "")
    return subject if subject.starts_with?(blank_re)

    I18n.t("#subject_reply_to", "Re: %{subject}", subject:)
  end

  class MarkdownSafeBuffer < String; end

  # use this to flag interpolated parameters as markdown-safe (see
  # mt below) so they get eval'ed rather than escaped, e.g.
  #  mt(:add_description, :example => markdown_safe('`1 + 1 = 2`'))
  def markdown_safe(string)
    MarkdownSafeBuffer.new(string)
  end

  def markdown_escape(string)
    return string if string.is_a?(MarkdownSafeBuffer)

    markdown_safe(string.gsub(/([\\`*_{}\[\]()\#+\-.!])/, "\\\\\\1"))
  end

  # use this rather than t() if the translation contains trusted markdown
  def mt(*args)
    inlinify = :auto
    if args.last.is_a?(Hash)
      options = args.last
      inlinify = options.delete(:inlinify) if options.key?(:inlinify)
      options.each_pair do |key, value|
        next unless value.is_a?(String) && !value.is_a?(MarkdownSafeBuffer) && !value.is_a?(ActiveSupport::SafeBuffer)
        next if key == :wrapper

        options[key] = markdown_escape(value).gsub("\\*", "\\\\\\*").gsub(/\s+/, " ").strip
      end
    end
    translated = t(*args)
    markdown(translated, inlinify)
  end

  def markdown(string, inlinify = :auto)
    string = ERB::Util.h(string) unless string.html_safe?
    result = Redcarpet::Markdown.new(Redcarpet::Render::XHTML.new).render(string).strip
    # Strip wrapping <p></p> if inlinify == :auto && they completely wrap the result && there are not multiple <p>'s
    result.gsub!(%r{</?p>}, "") if inlinify == :auto && result =~ %r{\A<p>.*</p>\z}m && result !~ /.*<p>.*<p>.*/m
    result.strip.html_safe
  end

  def round_if_whole(value)
    TextHelper.round_if_whole(value)
  end

  def self.round_if_whole(value)
    if value.is_a?(Float) && !value.nan? && (i = value.to_i) == value
      i
    else
      value
    end
  end
end
