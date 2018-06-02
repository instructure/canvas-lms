# encoding: UTF-8
#
# Copyright (C) 2014 - present Instructure, Inc.
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
#
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

require 'nokogiri'
require 'cgi'
require 'iconv'
require 'active_support/core_ext/module/remove_method' # https://github.com/rails/rails/issues/28918
require 'active_support'
require 'active_support/core_ext'
require 'sanitize'
require 'canvas_text_helper'

module HtmlTextHelper
  def self.strip_tags(text)
    text ||= ""
    text.gsub(/<\/?[^<>\n]*>?/, "").gsub(/&#\d+;/) { |m| puts m; m[2..-1].to_i.chr(text.encoding) rescue '' }.gsub(/&\w+;/, "")
  end

  def strip_tags(text)
    HtmlTextHelper.strip_tags(text)
  end

  # Converts a string of html to plain text, preserving as much of the
  # formatting and information as possible
  #
  # This is still a pretty basic implementation, I'm sure we'll find ways to
  # tweak and improve it as time goes on.
  def html_to_text(html_str, opts = {})
    return '' if html_str.blank?
    doc = Nokogiri::HTML::DocumentFragment.parse(html_str)
    text = html_node_to_text(doc, opts)
    text.squeeze!(' ')
    text.gsub!(/\r\n?/, "\n")
    text.gsub!(/\n +/, "\n")
    text.gsub!(/ +\n/, "\n")
    text.gsub!(/\n\n\n+/, "\n\n")
    text.strip!
    text = word_wrap(text, line_width: opts[:line_width]) if opts[:line_width]
    text
  end

  # turns a nokogiri element, node, or fragment into text (recursively!)
  def html_node_to_text(node, opts={})
    if node.text?
      text = node.text
      text.gsub!(/\s+/, ' ') unless opts[:pre]
      return text
    end

    text = case node.name
           when 'link', 'script'
             ''
           when 'pre'
             node.children.map{|c| html_node_to_text(c, opts.merge(pre: true))}.join
           when 'img'
             src = node['src']
             if src
               if opts[:preserve_links]
                 node.to_html
               else
                 begin
                   src = URI.join(opts[:base_url], src) if opts[:base_url]
                 rescue URI::Error
                   # do nothing, let src pass through as is
                 end
                 node['alt'] ? "[#{node['alt']}] (#{src})" : src
               end
             else
               ''
             end
           when 'br'
             "\n"
           else
             subtext = node.children.map{|c| html_node_to_text(c, opts)}.join
             case node.name
             when 'a'
               href = node['href']
               if href
                 if opts[:preserve_links]
                   node.to_html
                 else
                   begin
                     href = URI.join(opts[:base_url], href) if opts[:base_url]
                   rescue URI::Error
                     # do nothing, let href pass through as is
                   end
                   href == subtext ? subtext : "[#{subtext}] (#{href})"
                 end
               else
                 subtext
               end
             when 'h1'
               banner(subtext, char: '*', line_width: opts[:line_width])
             when 'h2'
               banner(subtext, char: '-', line_width: opts[:line_width])
             when /h[3-6]/
               banner(subtext, char: '-', underline: true, line_width: opts[:line_width])
             when 'li'
               "* #{subtext}"
             else
               subtext
             end
           end
    return "\n\n#{text}\n\n" if node.description.try(:block?)
    text
  end

  # Adds a string of characters above and below some text
  # *******
  # like so
  # *******
  def banner(text, opts={})
    return text if text.empty?

    char = opts.fetch(:char, '*')
    text_width = text.lines.map{|l| l.strip.length}.max
    text_width = [text_width, opts[:line_width]].min if opts[:line_width]
    line = char * text_width

    (opts[:underline] ? '' : line + "\n") + text + "\n" + line
  end

  # as seen in ActionView::Helpers::TextHelper
  def word_wrap(text, options = {})
    line_width = options.fetch(:line_width, 80)

    text.split("\n").collect do |line|
      line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
    end * "\n"
  end

  # Public: Strip (most) HTML from an HTML string.
  #
  # html - The original HTML string to format.
  # options - Formatting options.
  #   - base_url: The protocol and domain to prepend to relative links (e.g. "https://instructure.com").
  #   - elements: elements (in addition to those allowed by BASIC) to be permitted
  #   - attributes: a { element: attributes } hash of which attributes should be
  #                 allowed for which elements.  This is in addition to whatever BASIC
  #                 permits.
  # Returns an HTML string.
  def html_to_simple_html(html, options = {})
    return '' if html.blank?
    base_url = options.fetch(:base_url, '')
    config = Sanitize::Config::BASIC
    if options[:tags] || options[:attributes]
      elements = config[:elements] + (options[:tags] || [])
      final_attributes = {}
      # Make sure if the basic config allows attriutes for a given element, and
      # we pass in other attributes for that same element, that we permit both.
      elements_with_attributes =
        (config[:attributes]&.keys || []) | (options[:attributes]&.keys || [])
      elements_with_attributes.each do |element|
        basic_attributes = config[:attributes][element] || []
        given_attributes = options[:attributes][element] || []
        final_attributes[element] = basic_attributes | given_attributes
      end
      output = Sanitize.clean(html, :elements => elements, :attributes => final_attributes)
    else
      output = Sanitize.clean(html, config)
    end
    append_base_url(output, base_url).html_safe
  end

  # Internal: Append given base URL to relative links in the source.
  #
  # subject - A string to HTML.
  # base - A base protocol/domain string (e.g. "https://instructure.com").
  #
  # Returns a string.
  def append_base_url(subject, base)
    output = Nokogiri::HTML.fragment(subject)
    tags = output.css('*[href]')

    tags.each do |tag|
      url = tag.attributes['href'].value
      next if url.match(/^https?|mailto|ftp/)

      url.sub!("/", "") if url.start_with?("/") && base.end_with?("/")
      tag.attributes['href'].value = "#{base}#{url}"
    end

    output.to_s
  end

  def quote_clump(quote_lines)
    txt = "<div class='quoted_text_holder'><a href='#' class='show_quoted_text_link'>#{HtmlTextHelper.escape_html(I18n.t('lib.text_helper.quoted_text_toggle', "show quoted text"))}</a><div class='quoted_text' style='display: none;'>"
    txt += quote_lines.join("\n")
    txt += "</div></div>"
    txt
  end

  # http://daringfireball.net/2010/07/improved_regex_for_matching_urls
  # released to the public domain
  AUTO_LINKIFY_PLACEHOLDER = "LINK-PLACEHOLDER"
  AUTO_LINKIFY_REGEX = %r{
    \b
    (                                            # Capture 1: entire matched URL
      (?:
        https?://                                # http or https protocol
        |                                        # or
        www\d{0,3}[.]                            # "www.", "www1.", "www2." … "www999."
        |                                        # or
        [a-z0-9.\-]+[.][a-z]{2,4}/               # looks like domain name followed by a slash
      )

      (?:
        [^\s()<>]+                               # Run of non-space, non-()<>
        |                                        # or
        \([^\s()<>]*\)                           # balanced parens, single level
      )+
      (?:
        \([^\s()<>]*\)                           # balanced parens, single level
        |                                        # or
        [^\s`!()\[\]{};:'".,<>?«»“”‘’]           # End with: not a space or one of these punct chars
      )
    ) | (
      #{AUTO_LINKIFY_PLACEHOLDER}
    )
  }xi

  # Converts a plaintext message to html, with newlinification, quotification, and linkification
  def format_message(message, opts={:url => nil, :notification_id => nil})
    return '' unless message
    # insert placeholders for the links we're going to generate, before we go and escape all the html
    links = []
    placeholder_blocks = []
    message ||= ''
    message = message.gsub(AUTO_LINKIFY_REGEX) do |match|
      placeholder_blocks << if match == AUTO_LINKIFY_PLACEHOLDER
                              AUTO_LINKIFY_PLACEHOLDER
                            else
                              s = $1
                              link = s
                              link = "http://#{link}" if link[0, 3] == 'www'
                              link = add_notification_to_link(link, opts[:notification_id]) if opts[:notification_id]
                              link = link.gsub("'", "%27")
                              links << link
                              "<a href='#{ERB::Util.h(link)}'>#{ERB::Util.h(s)}</a>"
                            end
      AUTO_LINKIFY_PLACEHOLDER
    end

    # now escape any html
    message = HtmlTextHelper.escape_html(message)

    # now put the links back in
    message = message.gsub(AUTO_LINKIFY_PLACEHOLDER) do |match|
      placeholder_blocks.shift
    end

    message = message.gsub(/\r?\n/, "<br/>\r\n")
    processed_lines = []
    quote_block = []
    message.split("\n").each do |line|
      # check for lines starting with '>'
      if /^(&gt;|>)/ =~ line
        quote_block << line
      else
        processed_lines << quote_clump(quote_block) if !quote_block.empty?
        quote_block = []
        processed_lines << line
      end
    end
    processed_lines << quote_clump(quote_block) if !quote_block.empty?
    message = processed_lines.join("\n")
    if opts[:url]
      url = add_notification_to_link(opts[:url], opts[:notification_id]) if opts[:notification_id]
      links.unshift opts[:url]
    end
    links.unshift message.html_safe
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

  def self.escape_html(text)
    CGI::escapeHTML text
  end

  def self.unescape_html(text)
    CGI::unescapeHTML text
  end

  def self.strip_and_truncate(text, options={})
    CanvasTextHelper::truncate_text(strip_tags(text), options)
  end
end
