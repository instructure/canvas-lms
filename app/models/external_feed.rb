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
#

class ExternalFeed < ActiveRecord::Base
  belongs_to :user
  belongs_to :context, polymorphic: [:course, :group]

  has_many :external_feed_entries
  has_many :discussion_topics

  before_destroy :destroy_entries_and_unlink_topics
  before_validation :infer_defaults

  include CustomValidations
  validates :url, :context_id, :context_type, presence: true
  validates_as_url :url
  validates :url,
    uniqueness: { scope: [:context_id, :context_type, :verbosity, :header_match] },
    length: { maximum: maximum_string_length }

  VERBOSITIES = %w(full link_only truncate).freeze
  validates_inclusion_of :verbosity, :in => VERBOSITIES, :allow_nil => true

  def infer_defaults
    self.consecutive_failures ||= 0
    self.refresh_at ||= Time.now.utc
    unless VERBOSITIES.include?(self.verbosity)
      self.verbosity = "full"
    end
    true
  end
  protected :infer_defaults

  def display_name(short=true)
    short_url = (self.url || "").split("/")[0,3].join("/")
    res = self.title || (short ? t(:short_feed_title, "%{short_url} feed", :short_url => short_url) : self.url )

  end

  def header_match=(str)
    write_attribute(:header_match, str.to_s.strip.presence)
  end

  scope :to_be_polled, ->(start) {
    where("external_feeds.consecutive_failures<5 AND external_feeds.refresh_at<?", start).order(:refresh_at)
  }

  def destroy_entries_and_unlink_topics
    while self.external_feed_entries.limit(100).delete_all > 0; end
    while self.discussion_topics.limit(100).update_all(:external_feed_id => nil) > 0; end
  end

  def inactive?
    !self.context || self.context.root_account.deleted? || self.context.inactive?
  end

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
      uuid = item.respond_to?(:guid) && item.guid && item.guid.content.to_s
      if uuid && uuid.length > 255
        uuid = Digest::SHA256.hexdigest(uuid)
      end
      uuid ||= Digest::SHA256.hexdigest("#{item.title}#{item.date.strftime('%Y-%m-%d')}")

      entry = self.external_feed_entries.where(uuid: uuid).first
      entry ||= self.external_feed_entries.where(url: item.link).first
      description = entry && entry.message
      if !description || description.empty?
        description = "<a href='#{ERB::Util.h(item.link)}'>#{ERB::Util.h(t(:original_article, "Original article"))}</a><br/><br/>"
        description += format_description(item.description || item.title)
      end
      if entry
        entry.update_feed_attributes(
          :title => item.title.to_s,
          :message => description,
          :url => item.link
        )
        return entry
      end
      date = (item.respond_to?(:date) && item.date) || Time.zone.today
      return nil if self.header_match && !item.title.downcase.include?(self.header_match.downcase)
      return nil if (date && self.created_at > date rescue false)
      description = "<a href='#{ERB::Util.h(item.link)}'>#{ERB::Util.h(t(:original_article, "Original article"))}</a><br/><br/>"
      description += format_description(item.description || item.title)
      entry = self.external_feed_entries.new(
        :title => item.title.to_s,
        :message => description,
        :source_name => feed.channel.title,
        :source_url => feed.channel.link,
        :posted_at => Time.parse(date.to_s),
        :user => self.user,
        :url => item.link,
        :uuid => uuid
      )
      return entry if entry.save
    elsif feed_type == :atom
      uuid = item.id || Digest::SHA256.hexdigest("#{item.title}#{item.published.utc.strftime('%Y-%m-%d')}")
      entry = self.external_feed_entries.where(uuid: uuid).first
      entry ||= self.external_feed_entries.where(url: item.links.alternate.to_s).first
      author = item.authors.first || OpenObject.new
      description = entry && entry.message
      if !description || description.empty?
        description = "<a href='#{ERB::Util.h(item.links.alternate.to_s)}'>#{ERB::Util.h(t(:original_article, "Original article"))}</a><br/><br/>"
        description += format_description(item.content || item.title)
      end
      if entry
        entry.update_feed_attributes(
          :title => item.title.to_s,
          :message => description,
          :url => item.links.alternate.to_s,
          :author_name => author.name,
          :author_url => author.uri,
          :author_email => author.email
        )
        return entry
      end
      return nil if self.header_match && !item.title.downcase.include?(self.header_match.downcase)
      return nil if (item.published && self.created_at > item.published rescue false)
      description = "<a href='#{ERB::Util.h(item.links.alternate.to_s)}'>#{ERB::Util.h(t(:original_article, "Original article"))}</a><br/><br/>"
      description += format_description(item.content || item.title)
      entry = self.external_feed_entries.new(
        :title => item.title,
        :message => description,
        :source_name => feed.title.to_s,
        :source_url => feed.links.alternate.to_s,
        :posted_at => item.published,
        :url => item.links.alternate.to_s,
        :user => self.user,
        :author_name => author.name,
        :author_url => author.uri,
        :author_email => author.email,
        :uuid => uuid
      )
      return entry if entry.save
    end
  end
end
