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
  class DashboardObserveeFilterInputType < BaseInputObject
    graphql_name "DashboardObserveeFilter"
    argument :observed_user_id,
             ID,
             "Only view filtered user",
             required: false
  end

  class CourseDashboardCardLinkType < ApplicationObjectType
    graphql_name "CourseDashboardCardLink"
    description "A link on a course dashboard card"

    field :css_class, String, null: true
    field :hidden, Boolean, null: true
    field :icon, String, null: true
    field :label, String, null: true
    field :path, String, null: true
  end

  class CourseDashboardCardType < ApplicationObjectType
    include I18nUtilities
    graphql_name "CourseDashboardCard"

    description "A card on the course dashboard"
    alias_method :course, :object

    # Initialize the presenter
    def initialize(object, context)
      super
      @presenter = initialize_presenter
    end

    field :long_name, String, null: true
    def long_name
      @presenter[:longName]
    end

    field :short_name, String, null: true
    def short_name
      @presenter[:shortName]
    end

    field :original_name, String, null: true
    def original_name
      @presenter[:originalName]
    end

    field :course_code, String, null: true
    def course_code
      @presenter[:courseCode]
    end

    field :asset_string, String, null: true
    def asset_string
      @presenter[:assetString]
    end

    field :href, String, null: true
    def href
      @presenter[:href]
    end

    field :term, TermType, null: true
    def term
      load_association(:enrollment_term)
    end

    field :subtitle, String, null: true
    def subtitle
      @presenter[:subtitle]
    end

    field :enrollment_state, String, null: true
    def enrollment_state
      @presenter[:enrollmentState]
    end

    field :enrollment_type, String, null: true
    def enrollment_type
      @presenter[:enrollmentType]
    end

    field :observee, String, null: true
    def observee
      @presenter[:observee]
    end

    field :is_favorited, Boolean, null: true
    def is_favorited
      @presenter[:isFavorited]
    end

    field :is_k5_subject, Boolean, null: true
    def is_k5_subject
      @presenter[:isK5Subject]
    end

    field :is_homeroom, Boolean, null: true
    def is_homeroom
      @presenter[:isHomeroom]
    end

    field :use_classic_font, Boolean, null: true
    def use_classic_font
      @presenter[:useClassicFont]
    end

    field :can_manage, Boolean, null: true
    def can_manage
      @presenter[:canManage]
    end

    field :can_read_announcements, Boolean, null: true
    def can_read_announcements
      @presenter[:canReadAnnouncements]
    end

    field :image, UrlType, null: true
    def image
      @presenter[:image]
    end

    field :color, String, null: true
    def color
      @presenter[:color]
    end

    field :position, Integer, null: true
    def position
      @presenter[:position]
    end

    field :published, Boolean, null: true
    def published
      @presenter[:published]
    end

    field :links, [CourseDashboardCardLinkType], null: true
    def links
      return nil unless @presenter[:links].present?

      @presenter[:links].map do |link|
        {
          css_class: link[:css_class],
          hidden: link[:hidden],
          icon: link[:icon],
          label: link[:label],
          path: link[:path]
        }
      end
    end

    field :can_change_course_publish_state, Boolean, null: true
    def can_change_course_publish_state
      @presenter[:canChangeCoursePublishState]
    end

    field :default_view, String, null: true
    def default_view
      @presenter[:defaultView]
    end

    field :pages_url, UrlType, null: true
    def pages_url
      @presenter[:pagesUrl]
    end

    field :front_page_title, String, null: true
    def front_page_title
      @presenter[:frontPageTitle]
    end

    private

    # Initializes the presenter with dashboard card tabs and observed user
    def initialize_presenter
      opts = {}

      dashboard_filter = context[:dashboard_filter]
      if dashboard_filter&.dig(:observed_user_id).present?
        observed_user_id = dashboard_filter[:observed_user_id]
        observed_user = User.find_by(id: observed_user_id.to_i)
        if observed_user.present?
          opts[:observee_user] = observed_user
        else
          raise GraphQL::ExecutionError, "User with ID #{observed_user_id} not found"
        end
      elsif current_user.present?
        opts[:observee_user] = current_user
      end

      opts[:tabs] = UsersController::DASHBOARD_CARD_TABS

      CourseForMenuPresenter.new(
        course,
        current_user,
        domain_root_account,
        session,
        opts
      ).to_h
    end
  end
end
