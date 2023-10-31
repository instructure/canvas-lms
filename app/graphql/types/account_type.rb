# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Types
  class AccountType < ApplicationObjectType
    implements GraphQL::Types::Relay::Node
    implements Interfaces::LegacyIDInterface

    alias_method :account, :object

    global_id_field :id

    field :name, String, null: true

    field :outcome_proficiency, OutcomeProficiencyType, null: true
    def outcome_proficiency
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      account.resolved_outcome_proficiency
    end

    field :proficiency_ratings_connection, ProficiencyRatingType.connection_type, null: true
    def proficiency_ratings_connection
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      outcome_proficiency&.outcome_proficiency_ratings
    end

    field :outcome_calculation_method, OutcomeCalculationMethodType, null: true
    def outcome_calculation_method
      # This does a recursive lookup of parent accounts, not sure how we could
      # batch load it in a reasonable way.
      account.resolved_outcome_calculation_method
    end

    field :courses_connection, CourseType.connection_type, null: true
    def courses_connection
      return unless account.grants_right?(current_user, :read_course_list)

      account.associated_courses
    end

    field :custom_grade_statuses_connection, CustomGradeStatusType.connection_type, null: true
    def custom_grade_statuses_connection
      return unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
      return unless account.root_account.grants_right?(current_user, session, :manage)

      account.custom_grade_statuses.active.order(:id)
    end

    field :standard_grade_statuses_connection, StandardGradeStatusType.connection_type, null: true
    def standard_grade_statuses_connection
      return unless Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
      return unless account.root_account.grants_right?(current_user, session, :manage)

      account.standard_grade_statuses.order(:id)
    end

    field :sub_accounts_connection, AccountType.connection_type, null: true
    def sub_accounts_connection
      account.sub_accounts.order(:id)
    end

    field :sis_id, String, null: true
    def sis_id
      return if account.root_account?

      load_association(:root_account).then do |root_account|
        account.sis_source_id if root_account.grants_any_right?(current_user, :read_sis, :manage_sis)
      end
    end

    field :root_outcome_group, LearningOutcomeGroupType, null: false

    field :parent_accounts_connection, AccountType.connection_type, null: false
    def parent_accounts_connection
      account.account_chain - [account]
    end

    field :rubrics_connection, RubricType.connection_type, null: true
    def rubrics_connection
      rubric_associations = account.rubric_associations.bookmarked.include_rubric.to_a
      rubric_associations = Canvas::ICU.collate_by(rubric_associations.select(&:rubric_id).uniq(&:rubric_id)) { |r| r.rubric.title }
      rubric_associations.map(&:rubric)
    end
  end
end
