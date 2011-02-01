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

module TextHelper
  def strip_and_truncate(text, options={})
    truncate_text(strip_tags(text), options)
  end
  def strip_tags(text)
    text ||= ""
    text.gsub(/<\/?[^>\n]*>/, "").gsub(/&#\d+;/) {|m| puts m; m[2..-1].to_i.chr rescue '' }.gsub(/&\w+;/, "")
  end
  
  def quote_clump(quote_lines)
    txt = "<div class='quoted_text_holder'><a href='#' class='show_quoted_text_link'>show quoted text</a><div class='quoted_text' style='display: none;'>"
    txt += quote_lines.join("\n")
    txt += "</div></div>"
    txt
  end
  
  # Converts a plaintext message to html, with newlinification, quotification, and linkification
  def format_message(message, url=nil, notification_id=nil)
    message = TextHelper.escape_html(message)
    message = message.gsub(/\r?\n/, "<br/>\r\n")
    processed_lines = []
    quote_block = []
    message.split("\n").each do |line|
      if line[0,5] == "&gt; " || line[0,2] == "> "
        quote_block << line
      else
        processed_lines << quote_clump(quote_block) if !quote_block.empty?
        quote_block = []
        processed_lines << line
      end
    end
    processed_lines << quote_clump(quote_block) if !quote_block.empty?
    message = processed_lines.join("\n")
    links = []
    message = message.gsub(/((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?)/ix) do |s|
      link = s
      link = add_notification_to_link(link, notification_id) if notification_id
      links << link
      "<a href='#{link}'>#{s}</a>";
    end
    if url
      url = add_notification_to_link(url, notification_id) if notification_id
      links.unshift url
    end
    links.unshift message
  end
  
  def add_notification_to_link(url, notification_id)
    parts = "#{url}".split("#", 2)
    link = parts[0]
    link += link.match(/\?/) ? "&" : "?"
    link += "clear_notification_id=#{notification_id}"
    link += parts[1] if parts[1]
    link
  rescue
    return ""
  end

  def truncate_text(text, options={})
    max_length = options[:max_length] || 30
    ellipsis = options[:ellipsis] || "..."
    words = options[:words] || false
    ellipsis_length = ellipsis.length
    content_length = text.length
    actual_length = max_length - ellipsis_length
    if content_length > max_length
      truncated = text[0, actual_length] + ellipsis
    else
      text
    end
  end
  
  def self.escape_html(text)
    CGI::escapeHTML text
  end
  
  def self.unescape_html(text)
    CGI::unescapeHTML text
  end
  
  def hours_ago_in_words(from_time)
    diff = (Time.now - from_time).abs
    if diff < 60
      "< 1 minute"
    elsif diff < 3600
      "#{(diff / 60).to_i} minutes"
    else
      "#{(diff / 3600).to_i} hours"
    end
  end
  
  def indent(text, spaces=2)
    text = text.to_s rescue ""
    indentation = " " * spaces
    text.gsub(/\n/, "\n#{indentation}")
  end
  
  def force_zone(time)
    time_zone ||= @time_zone || Time.zone
    res = ActiveSupport::TimeWithZone.new(time.utc, time_zone) rescue nil
    res || time
  end

  def date_string(start_date, style=:normal)
    return nil unless start_date
    start_date = start_date.in_time_zone.to_date rescue start_date.to_date
    today = ActiveSupport::TimeWithZone.new(Time.now, Time.zone).to_date
    if style != :long
      return "Today" if style != :no_words && start_date == today
      return "Tomorrow" if style != :no_words && start_date == today + 1
      return "Yesterday" if style != :no_words && start_date == today - 1
      return start_date.strftime("%A") if style != :no_words && start_date < today + 1.week && start_date >= today
      return start_date.strftime("%b #{start_date.day}") if start_date.year == today.year || style == :short
    end
    return start_date.strftime("%b #{start_date.day}, %Y")
  end

  def time_string(start_time, end_time=nil)
    start_time = start_time.in_time_zone rescue start_time
    end_time = end_time.in_time_zone rescue end_time
    return nil unless start_time
    hr = start_time.hour % 12
    hr = 12 if hr == 0
    result = hr.to_s + (start_time.min == 0 ? start_time.strftime("%p").downcase : start_time.strftime(":%M%p").downcase)
    if end_time && end_time != start_time
      result = result + " to " + time_string(end_time)
    end
    result
  end
  
  def datetime_span(*args)
    string = datetime_string(*args)
    if string && !string.empty? && args[0]
      "<span class='zone_cached_datetime' title='#{args[0].iso8601 rescue ""}'>#{string}</span>"
    else
      nil
    end
  end

  def datetime_string(start_datetime, datetime_type=:event, end_datetime=nil, shorten_midnight=false)
    start_datetime = start_datetime.in_time_zone rescue start_datetime
    return nil unless start_datetime
    end_datetime = end_datetime.in_time_zone rescue end_datetime
    if !datetime_type.is_a?(Symbol)
      datetime_type = :event
      end_datetime = nil
    end
    start_time = time_string(start_datetime)
    by_at = datetime_type == :due_date ? ' by' : ' at'
    # I am assuming that by the time we get here that start_datetime will be in the same time zone as @current_user's timezone
    if shorten_midnight && start_datetime && ((datetime_type == :due_date  && start_datetime.hour == 23 && start_datetime.min == 59) || (datetime_type == :event && start_datetime.hour == 0 && start_datetime.min == 0))
      start_time = ''
      by_at = ''
    end
    def datestring(datetime)
      return datetime.strftime("%b #{datetime.day}") if datetime.year == ActiveSupport::TimeWithZone.new(Time.now, Time.zone).to_date.year
      return datetime.strftime("%b #{datetime.day}, %Y")
    end
    unless(end_datetime && end_datetime != start_datetime)
      result = (datetime_type == :verbose ? start_datetime.strftime("%a, ") : "") + datestring(start_datetime) + by_at + " " + start_time
    else
      end_time = time_string(end_datetime)
      unless start_datetime.to_date != end_datetime.to_date
        result = datestring(start_datetime) + " from " + start_time + " to " + end_time
      else
        result = (datetime_type == :verbose ? start_datetime.strftime("%a, ") : "") + datestring(start_datetime) + by_at + " " + start_time + " to " + (datetime_type == :verbose ? end_datetime.strftime("%a, ") : "") + datestring(end_datetime) + by_at + " " + end_time
      end
    end
    result
  rescue
    nil
  end


  def truncate_html(input, options={})
    doc = Nokogiri::HTML(input)
    options[:max_length] ||= 250
    num_words = options[:num_words] || (options[:max_length] / 5) || 30
    truncate_string = options[:ellipsis] || "..."
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
   
      if current.children.length > 0
        # this node has children, can't be a text node,
        # lets descend and look for text nodes
        current = current.children.first
      elsif !current.next.nil?
        #this has no children, but has a sibling, let's check it out
        current = current.next
      else 
        # we are the last child, we need to ascend until we are
        # either done or find a sibling to continue on to
        n = current
        while !n.is_a?(Nokogiri::HTML::Document) and n.parent.next.nil?
          n = n.parent
        end
   
        # we've reached the top and found no more text nodes, break
        if n.is_a?(Nokogiri::HTML::Document)
          break;
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
        index = num_words-(count-new_content.length)-1
        if index >= 0
          new_content = new_content[0..index]
          current.add_previous_sibling(truncate_elem)
          new_node = Nokogiri::XML::Text.new(new_content.join(' '), doc)
          truncate_elem.add_previous_sibling(new_node)
          current = current.previous
        else
          current = previous
          # why would we do this next line? it just ends up xml escaping stuff
          #current.content = current.content
          current.add_next_sibling(truncate_elem)
          current = current.next
        end
      end
   
      # remove everything else
      while !current.is_a?(Nokogiri::HTML::Document)
        while !current.next.nil?
          current.next.remove
        end
        current = current.parent
      end
    end
   
    # now we grab the html and not the text.
    # we do first because nokogiri adds html and body tags
    # which we don't want
    res = doc.at_css('body').inner_html rescue nil
    res ||= doc.root.children.first.inner_html rescue ""
    res && res.html_safe
  end
end
