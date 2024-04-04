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

class AnnouncementsController < ApplicationController
  include Api::V1::DiscussionTopics

  before_action :require_context, except: :public_feed
  before_action { |c| c.active_tab = "announcements" }

  include K5Mode

  module AnnouncementsIndexHelper
    def announcements_locked?
      return false unless @context.is_a?(Course)

      @context.lock_all_announcements?
    end

    def load_announcements
      can_create = @context.announcements.temp_record.grants_right?(@current_user, session, :create)
      can_edit = @context.grants_any_right?(@current_user, session, :manage_content, :manage_course_content_edit)
      can_delete = @context.grants_any_right?(@current_user, session, :manage_content, :manage_course_content_delete)

      js_env permissions: {
        create: can_create,
        moderate: can_create,
        manage_course_content_edit: can_edit,
        manage_course_content_delete: can_delete
      }
      js_env is_showing_announcements: true
      js_env atom_feed_url: feeds_announcements_format_path((@context_enrollment || @context).feed_code, :atom)
      js_env(COURSE_ID: @context.id.to_s) if @context.is_a?(Course)
      js_env ANNOUNCEMENTS_LOCKED: announcements_locked?
    end
  end

  include AnnouncementsIndexHelper

  def index
    return unless authorized_action(@context, @current_user, :read)
    return if @context.class.const_defined?(:TAB_ANNOUNCEMENTS) && !tab_enabled?(@context.class::TAB_ANNOUNCEMENTS)

    redirect_to named_context_url(@context, :context_url) if @context.is_a?(Course) && @context.elementary_homeroom_course?

    log_asset_access(["announcements", @context], "announcements", "other")
    respond_to do |format|
      format.html do
        add_crumb(t(:announcements_crumb, "Announcements"))
        load_announcements

        js_bundle :announcements
        css_bundle :announcements_index

        set_tutorial_js_env

        feed_key = nil
        if @context_enrollment
          feed_key = @context_enrollment.feed_code
        elsif can_do(@context, @current_user, :manage)
          feed_key = @context.feed_code
        elsif @context.available? && @context.respond_to?(:is_public) && @context.is_public
          feed_key = @context.asset_string
        end
        if feed_key
          case @context
          when Course
            content_for_head helpers.auto_discovery_link_tag(:atom, feeds_announcements_format_path(feed_key, :atom), { title: t(:feed_title_course, "Course Announcements Atom Feed") })
            content_for_head helpers.auto_discovery_link_tag(:rss, feeds_announcements_format_path(feed_key, :rss), { title: t(:podcast_title_course, "Course Announcements Podcast Feed") })
          when Group
            content_for_head helpers.auto_discovery_link_tag(:atom, feeds_announcements_format_path(feed_key, :atom), { title: t(:feed_title_group, "Group Announcements Atom Feed") })
            content_for_head helpers.auto_discovery_link_tag(:rss, feeds_announcements_format_path(feed_key, :rss), { title: t(:podcast_title_group, "Group Announcements Podcast Feed") })
          end
        end
      end
    end
  end

  def show
    redirect_to named_context_url(@context, :context_discussion_topic_url, params[:id])
  end

  def public_feed
    return unless get_feed_context

    announcements = @context.announcements.published.by_posted_at.limit(15)
                            .select { |a| a.visible_for?(@current_user) }

    respond_to do |format|
      format.atom do
        title = t(:feed_name, "%{course} Announcements Feed", course: @context.name)
        link = polymorphic_url([@context, :announcements])

        render plain: AtomFeedHelper.render_xml(title:, link:, entries: announcements)
      end

      format.rss do
        @announcements = announcements
        require "rss/2.0"
        rss = RSS::Rss.new("2.0")
        channel = RSS::Rss::Channel.new
        channel.title = t(:podcast_feed_name, "%{course} Announcements Podcast Feed", course: @context.name)
        case @context
        when Course
          channel.description = t(:podcast_feed_description_course, "Any media files linked from or embedded within announcements in the course \"%{course}\" will appear in this feed.", course: @context.name)
        when Group
          channel.description = t(:podcast_feed_description_group, "Any media files linked from or embedded within announcements in the group \"%{group}\" will appear in this feed.", group: @context.name)
        end
        channel.link = polymorphic_url([@context, :announcements])
        channel.pubDate = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
        elements = Announcement.podcast_elements(announcements, @context)
        elements.each do |item|
          channel.items << item
        end
        rss.channel = channel
        render plain: rss.to_s
      end
    end
  end
end
