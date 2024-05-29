# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Types
  class CourseDashboardCardType < ApplicationObjectType
    graphql_name "CourseDashboardCard"

    description "A card on the course dashboard"
    global_id_field :id

    alias_method :course, :object

    field :long_name, String, null: true
    def long_name
      presenter[:longName]
    end

    field :short_name, String, null: true
    def short_name
      presenter[:shortName]
    end

    field :original_name, String, null: true
    def original_name
      presenter[:originalName]
    end

    field :course_code, String, null: true
    def course_code
      presenter[:courseCode]
    end

    field :asset_string, String, null: true
    def asset_string
      presenter[:assetString]
    end

    field :href, String, null: true
    def href
      presenter[:href]
    end

    field :term, TermType, null: true
    def term
      load_association(:enrollment_term)
    end

    field :is_favorited, Boolean, null: true
    def is_favorited
      presenter[:isFavorited]
    end

    field :course_id, ID, null: false
    delegate :id, to: :course, prefix: true

    field :is_k5_subject, Boolean, null: true
    def is_k5_subject
      presenter[:isK5Subject]
    end

    field :is_homeroom, Boolean, null: true
    def is_homeroom
      presenter[:isHomeroom]
    end

    field :use_classic_font, Boolean, null: true
    def use_classic_font
      presenter[:useClassicFont]
    end

    field :can_manage, Boolean, null: true
    def can_manage
      presenter[:canManage]
    end

    field :can_read_announcements, Boolean, null: true
    def can_read_announcements
      presenter[:canReadAnnouncements]
    end

    field :image, UrlType, null: true
    def image
      presenter[:image]
    end

    field :color, String, null: true
    def color
      presenter[:color]
    end

    field :position, Integer, null: true
    def position
      presenter[:position]
    end

    field :published, Boolean, null: true
    def published
      presenter[:published]
    end

    field :can_change_course_publish_state, Boolean, null: true
    def can_change_course_publish_state
      presenter[:canChangeCoursePublishState]
    end

    field :default_view, String, null: true
    def default_view
      presenter[:defaultView]
    end

    field :pages_url, UrlType, null: true
    def pages_url
      presenter[:pagesUrl]
    end

    field :front_page_title, String, null: true
    def front_page_title
      presenter[:frontPageTitle]
    end

    private

    def presenter
      opts = {}

      @presenter ||= CourseForMenuPresenter.new(
        course,
        context[:current_user],
        context[:domain_root_account],
        context[:session],
        opts
      ).to_h
    end
  end
end
