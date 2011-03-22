#
# Copyright (C) 2011 Instructure, Inc.
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

class ExternalFeed < ActiveRecord::Base
  attr_accessible :url, :verbosity, :header_match
  belongs_to :user
  belongs_to :context, :polymorphic => true
  has_many :external_feed_entries, :dependent => :destroy
  
  before_save :infer_defaults
  
  def infer_defaults
    self.consecutive_failures ||= 0
    self.refresh_at ||= Time.now.utc
  end
  protected :infer_defaults
  
  def display_name(short=true)
    short_url = (self.url || "").split("/")[0,3].join("/")
    res = self.title || (short ? "#{short_url} feed" : self.url )
    
  end
  
  named_scope :to_be_polled, lambda {
    { :conditions => ['external_feeds.consecutive_failures < ? and external_feeds.refresh_at < ?', 5, Time.now ], :order => :refresh_at }
  }
  
  named_scope :for, lambda {|obj|
    { :conditions => ['external_feeds.feed_purpose = ?', obj] }
  }
  
  def add_rss_entries(rss)
    items = rss.items.map{|item| add_entry(item, rss, :rss) }.compact
    self.context.add_aggregate_entries(items, self) if self.context && self.context.respond_to?(:add_aggregate_entries)
    items
  end
  
  def add_atom_entries(atom)
    items = []
    atom.each_entry{|item| items << add_entry(item, atom, :atom) }
    items.compact!
    self.context.add_aggregate_entries(items, self) if self.context && self.context.respond_to?(:add_aggregate_entries)
    items
  end
  
  def add_ical_entries(cal)
    items = cal.events.map{|event| add_entry(event, cal, :ical) }.compact
    self.context.add_aggregate_entries(items, self) if self.context && self.context.respond_to?(:add_aggregate_entries)
    items
  end
  
  def format_description(desc)
    desc = (desc || "").to_s
    if self.verbosity == 'link_only'
      ""
    elsif self.verbosity == 'truncate'
      self.extend TextHelper
      truncate_html(desc, :max_length => 250)
    else
      desc
    end
  end
  
  def add_entry(item, feed, feed_type)
    if feed_type == :rss
      uuid = (item.respond_to?(:guid) && item.guid && item.guid.content.to_s) || Digest::MD5.hexdigest("#{item.title}#{item.date.strftime('%Y-%m-%d')}")
      entry = self.external_feed_entries.find_by_uuid(uuid)
      entry ||= self.external_feed_entries.find_by_url(item.link)
      description = entry && entry.message
      if !description || description.empty?
        description = "<a href='#{item.link}'>Original article</a><br/><br/>"
        description += format_description(item.description || item.title)
      end
      if entry
        entry.update_feed_attributes(
          :title => item.title,
          :message => description,
          :url => item.link
        )
        return entry
      end
      date = (item.respond_to?(:date) && item.date) || Date.today
      return nil if self.header_match && !item.title.match(Regexp.new(self.header_match, true))
      return nil if self.body_match && !item.description.match(Regexp.new(self.body_match, true))
      return nil if (date && self.created_at > date rescue false)
      description = "<a href='#{item.link}'>Original article</a><br/><br/>"
      description += format_description(item.description || item.title)
      entry = self.external_feed_entries.create(
        :title => item.title,
        :message => description,
        :source_name => feed.channel.title,
        :source_url => feed.channel.link,
        :posted_at => Time.parse(date.to_s),
        :user => self.user,
        :url => item.link,
        :uuid => uuid
      )
    elsif feed_type == :atom
      uuid = item.id || Digest::MD5.hexdigest("#{item.title}#{item.published.utc.strftime('%Y-%m-%d')}")
      entry = self.external_feed_entries.find_by_uuid(uuid)
      entry ||= self.external_feed_entries.find_by_url(item.links.alternate.to_s)
      description = entry && entry.message
      if !description || description.empty?
        description = "<a href='#{item.links.alternate.to_s}'>Original article</a><br/><br/>"
        description += format_description(item.content || item.title)
      end
      if entry
        entry.update_feed_attributes(
          :title => item.title,
          :message => description,
          :url => item.links.alternate.to_s,
          :author_name => author.name,
          :author_url => author.uri,
          :author_email => author.email
        )
        return entry
      end
      return nil if self.header_match && !item.title.match(Regexp.new(self.header_match, true))
      return nil if self.body_match && !item.content.match(Regexp.new(self.body_match, true))
      return nil if (item.published && self.created_at > item.published rescue false)
      author = item.authors.first || OpenObject.new
      description = "<a href='#{item.links.alternate.to_s}'>Original article</a><br/><br/>"
      description += format_description(item.content || item.title)
      entry = self.external_feed_entries.create(
        :title => item.title,
        :message => description,
        :source_name => feed.title,
        :source_url => feed.links.alternate.to_s,
        :posted_at => item.published,
        :url => item.links.alternate.to_s,
        :user => self.user,
        :author_name => author.name,
        :author_url => author.uri,
        :author_email => author.email,
        :uuid => uuid
      )
    elsif feed_type == :ical
      entry = self.external_feed_entries.find_by_uuid(uuid)
      entry ||= self.external_feed_entries.find_by_title_and_url(item.summary, item.url)
      description = entry && entry.message
      if !description || description.empty?
        description = "<a href='#{item.url}'>Original article</a><br/><br/>"
        description += (item.description || item.summary).to_s
      end
      if entry
        entry.update_feed_attributes(
          :title => item.summary,
          :message => description,
          :url => item.url,
          :start_at => item.start,
          :end_at => item.end
        )
        entry.cancel_it if item.status.downcase == 'cancelled' && entry.active?
        return entry
      end
      description = (item.description || item.summary).to_s
      description += "<br/><br/><a href='#{item.url}'>#{item.url}</a>"
      entry = self.external_feed_entries.create(
        :title => item.summary,
        :message => description,
        :source_name => self.title,
        :source_url => self.url,
        :posted_at => item.timestamp,
        :start_at => item.start,
        :end_at => item.end,
        :url => item.url,
        :user => self.user
      )
    end
  end
end
