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
    field :workflow_state, String, null: false

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

    field :courses_connection, CourseType.connection_type, null: true do
      argument :career_learning_library_only,
               Boolean,
               "Whether or not to include or exclude Canvas Career learning library only courses",
               required: false
    end
    def courses_connection(career_learning_library_only: nil)
      return unless account.grants_right?(current_user, :read_course_list)

      courses = account.associated_courses

      if account.root_account.feature_enabled?(:horizon_learning_library_ms2) && !career_learning_library_only.nil?
        courses = if career_learning_library_only
                    courses.career_learning_library
                  else
                    courses.not_career_learning_library
                  end
      end

      courses
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

    field :users_connection, Types::UserType.connection_type, null: true do
      argument :filter, Types::AccountUsersFilterInputType, required: false
      argument :sort,   Types::AccountUsersSortInputType,   required: false
    end
    def users_connection(filter: {}, sort: {})
      return unless account.grants_any_right?(current_user, session, :read_roster, :manage_students)

      options = {
        enrollment_type: filter[:enrollment_types],
        enrollment_role_id: filter[:enrollment_role_ids],
        include_deleted_users: filter[:include_deleted_users],
        temporary_enrollment_recipients: filter[:temporary_enrollment_recipients],
        temporary_enrollment_providers: filter[:temporary_enrollment_providers],
        sort: sort[:field],
        order: sort[:direction],
      }.compact

      search_term = filter[:search_term].presence
      if search_term
        UserSearch.for_user_in_context(search_term, account, current_user, session, options)
      else
        UserSearch.scope_for(account, current_user, options)
      end
    end

    field :institutional_tag_categories_connection,
          Types::InstitutionalTagCategoryType.connection_type,
          null: true do
      argument :has_tags_in_state, Types::InstitutionalTagWorkflowStateType, required: false
      argument :search_term, String, required: false
      argument :workflow_state, Types::InstitutionalTagWorkflowStateType, required: false, default_value: "active"
    end
    def institutional_tag_categories_connection(search_term: nil, workflow_state: "active", has_tags_in_state: nil)
      root_account = account.root_account? ? account : nil
      return unless root_account
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_view)

      cats = root_account.institutional_tag_categories
      cats = cats.where(workflow_state:) unless workflow_state == "any"
      cats = cats.search_by_name(search_term) if search_term.present?

      if has_tags_in_state.present?
        matching_category_ids = InstitutionalTag
                                .where(root_account_id: root_account.id, workflow_state: has_tags_in_state)
                                .select(:category_id)
                                .distinct

        cats = if workflow_state == "any"
                 cats.where(workflow_state: has_tags_in_state).or(cats.where(id: matching_category_ids))
               else
                 cats.where(id: matching_category_ids)
               end
      end

      cats.order(:name)
    end

    field :institutional_tags_connection,
          Types::InstitutionalTagType.connection_type,
          null: true do
      argument :category_id,
               ID,
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("InstitutionalTagCategory")
      argument :search_term, String, required: false
      argument :workflow_state, Types::InstitutionalTagWorkflowStateType, required: false, default_value: "active"
    end
    def institutional_tags_connection(category_id: nil, search_term: nil, workflow_state: "active")
      root_account = account.root_account? ? account : nil
      return unless root_account
      raise GraphQL::ExecutionError, "feature flag is disabled" unless root_account.feature_enabled?(:institutional_tags)
      raise GraphQL::ExecutionError, "not authorized" unless root_account.grants_right?(current_user, session, :manage_institutional_tags_view)

      tags = InstitutionalTag.where(root_account_id: root_account.id, workflow_state:)
      tags = tags.where(category_id:) if category_id.present?
      tags = tags.search_by_name(search_term) if search_term.present?
      tags.order(:name)
    end

    field :rubrics_connection, RubricType.connection_type, null: true do
      argument :id,
               ID,
               "Filter by rubric ID",
               required: false,
               prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Rubric")
    end
    def rubrics_connection(id: nil)
      rubric_associations = account.rubric_associations
                                   .bookmarked
                                   .include_rubric
                                   .joins(:rubric)
                                   .where.not(rubrics: { workflow_state: "deleted" })

      rubric_associations = rubric_associations.where(rubric_id: id) if id

      rubric_associations = rubric_associations.to_a
      rubric_associations = Canvas::ICU.collate_by(rubric_associations.select(&:rubric_id).uniq(&:rubric_id)) { |r| r.rubric.title }
      rubric_associations.map(&:rubric)
    end
  end
end
