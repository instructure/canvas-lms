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

require 'atom'

class AnnouncementsController < ApplicationController
  include Api::V1::DiscussionTopics

  before_filter :require_context, :except => :public_feed
  before_filter { |c| c.active_tab = "announcements" }

  def index
    return unless authorized_action(@context, @current_user, :read)
    return if @context.class.const_defined?('TAB_ANNOUNCEMENTS') && !tab_enabled?(@context.class::TAB_ANNOUNCEMENTS)

    log_asset_access([ "announcements", @context ], "announcements", "other")
    respond_to do |format|
      format.html do
        add_crumb(t(:announcements_crumb, "Announcements"))
        can_create = @context.announcements.scoped.new.grants_right?(@current_user, session, :create)
        js_env :permissions => {
          :create => can_create,
          :moderate => can_create
        }
        js_env :is_showing_announcements => true
        js_env :atom_feed_url => feeds_announcements_format_path((@context_enrollment || @context).feed_code, :atom)
      end
    end
  end

  def show
    redirect_to named_context_url(@context, :context_discussion_topic_url, params[:id])
  end

  def public_feed
    return unless get_feed_context
    announcements = @context.announcements.active.order('posted_at DESC').limit(15).
      select{|a| a.visible_for?(@current_user) }

    respond_to do |format|
      format.atom {
        feed = Atom::Feed.new do |f|
          f.title = t(:feed_name, "%{course} Announcements Feed", :course => @context.name)
          f.links << Atom::Link.new(:href => polymorphic_url([@context, :announcements]), :rel => 'self')
          f.updated = Time.now
          f.id = polymorphic_url([@context, :announcements])
        end
        announcements.each do |e|
          feed.entries << e.to_atom
        end
        render :text => feed.to_xml
      }
      format.rss {
        @announcements = announcements
        require 'rss/2.0'
        rss = RSS::Rss.new("2.0")
        channel = RSS::Rss::Channel.new
        channel.title = t(:podcast_feed_name, "%{course} Announcements Podcast Feed", :course => @context.name)
        if @context.is_a?(Course)
          channel.description = t(:podcast_feed_description_course, "Any media files linked from or embedded within announcements in the course \"%{course}\" will appear in this feed.", :course => @context.name)
        elsif @context.is_a?(Group)
          channel.description = t(:podcast_feed_description_group, "Any media files linked from or embedded within announcements in the group \"%{group}\" will appear in this feed.", :group => @context.name)
        end
        channel.link = polymorphic_url([@context, :announcements])
        channel.pubDate = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
        elements = Announcement.podcast_elements(announcements, @context)
        elements.each do |item|
          channel.items << item
        end
        rss.channel = channel
        render :text => rss.to_s
      }
    end
  end
end
