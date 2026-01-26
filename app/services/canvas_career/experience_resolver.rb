# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# This service class should be used exclusively to determine which experience app to load. It does not
# handle loading any app or managing its configuration.
module CanvasCareer
  class ExperienceResolver
    LEARNER_ENROLLMENT_TYPES = %w[StudentEnrollment StudentViewEnrollment ObserverEnrollment].freeze
    LEARNING_PROVIDER_ENROLLMENT_TYPES = %w[TeacherEnrollment TaEnrollment DesignerEnrollment].freeze

    def initialize(user, context, domain_root_account, session)
      @user = user
      @context = context
      @domain_root_account = domain_root_account
      @session = session
    end

    def resolve
      GuardRail.activate(:secondary) do
        # Bail to academic ASAP
        return Constants::App::ACADEMIC if resolve_academic?
        return Constants::App::CAREER_LEARNING_PROVIDER if resolve_learning_provider?
        return Constants::App::CAREER_LEARNER if resolve_learner?

        # No enrollments but career at root account should default to career learner
        return Constants::App::CAREER_LEARNER if career_at_root_account?

        # Failsafe / no enrollments
        Constants::App::ACADEMIC
      end
    end

    def available_apps
      GuardRail.activate(:secondary) do
        apps = []
        apps << Constants::App::ACADEMIC if has_academic_associations?
        apps << Constants::App::CAREER_LEARNING_PROVIDER if has_career_learning_provider_roles?
        apps << Constants::App::CAREER_LEARNER if has_career_learner_roles?
        apps
      end
    end

    def self.career_affiliated_institution?(root_account)
      return false if root_account.nil?

      root_account.settings[:horizon_account_ids].present?
    end

    private

    # In an account or course context -> is it a career account/course?
    # When contextless -> do they have exclusively academic enrollments or at least prefer academic
    def resolve_academic?
      if @context.is_a?(Account)
        !horizon_account?
      elsif @context.is_a?(Course)
        !horizon_course?
      else # contextless
        has_academic_associations? &&
          (user_preference.prefers_academic? || !has_career_associations?)
      end
    end

    # In an account context -> are they an account user in the context?
    # In a course context -> do they have an admin enrollment or account user in the context? If so,
    # make sure they're not a student too, or that they're role preference is LP
    # When contextless -> do they have exclusively career enrollments or at least prefer career experience AND
    # do they have exclusively LP roles or at least prefer LP role
    def resolve_learning_provider?
      return false unless config.learning_provider_app_launch_url.present?

      if @context.is_a?(Account)
        horizon_account? && learning_provider_in_context?
      elsif @context.is_a?(Course)
        horizon_course? &&
          learning_provider_in_context? &&
          (user_preference.prefers_learning_provider? || !learner_in_context?)
      else # contextless
        has_career_associations? &&
          (user_preference.prefers_career? || !has_academic_associations?) &&
          has_career_learning_provider_roles? &&
          (user_preference.prefers_learning_provider? || !has_career_learner_roles?)
      end
    end

    # In a course context -> do they have a learner enrollment in the course? If so, make sure they're
    # not also an LP, or at least prefer learner role
    # When contextless -> do they have exclusively career enrollments or at least prefer career experience AND
    # do they have exclusively learner roles or at least prefer learner role
    def resolve_learner?
      return false unless config.learner_app_launch_url.present?

      if @context.is_a?(Course)
        horizon_course? &&
          learner_in_context? &&
          (user_preference.prefers_learner? || !learning_provider_in_context?)
      else # contextless
        has_career_associations? &&
          (user_preference.prefers_career? || !has_academic_associations?) &&
          has_career_learner_roles? &&
          (user_preference.prefers_learner? || !has_career_learning_provider_roles?)
      end
    end

    def config
      @_config ||= Config.new(@domain_root_account)
    end

    def user_preference
      @_user_preference ||= UserPreferenceManager.new(@session)
    end

    def horizon_account?
      return @_horizon_account unless @_horizon_account.nil?

      @_horizon_account = @context.is_a?(Account) && @context.horizon_account?
    end

    def horizon_course?
      return @_horizon_course unless @_horizon_course.nil?

      @_horizon_course = @context.is_a?(Course) && @context.horizon_course?
    end

    def learner_in_context?
      return false unless @context.is_a?(Course)

      @_learner_in_context ||= @context.user_is_student?(@user, include_fake_student: true, include_all: true)
    end

    def learning_provider_in_context?
      return false unless @context.is_a?(Course) || @context.is_a?(Account)

      @_learning_provider_in_context ||= @context.grants_right?(@user, :read_as_admin)
    end

    # Allows for short-circuiting if this institution has nothing to do with career
    def career_unaffiliated_institution?
      @domain_root_account.settings[:horizon_account_ids].blank?
    end

    # Allows for short-circuiting if this institution is always career
    def career_at_root_account?
      return @_career_at_root_account unless @_career_at_root_account.nil?

      @domain_root_account.horizon_account?
    end

    def enrollment_types
      @_enrollment_types ||= Rails.cache.fetch_with_batched_keys("career_enrollment_types", batch_object: @user, batched_keys: :enrollments) do
        Course
          .active
          .where(id: @user.enrollments.shard(Shard.current).active_or_pending_by_date.select(:course_id))
          .distinct
          .pluck(:horizon_course)
      end
    end

    def has_career_associations?
      # Optimizations to avoid queries when possible
      return false if career_unaffiliated_institution?
      return true if career_at_root_account?

      enrollment_types.include?(true) || has_career_account_users?
    end

    def has_academic_associations?
      # Optimizations to avoid queries when possible
      return true if career_unaffiliated_institution?
      return false if career_at_root_account?

      enrollment_types.include?(false) || has_academic_account_users?
    end

    def career_enrollment_roles
      @_career_enrollment_roles ||= Rails.cache.fetch_with_batched_keys("career_enrollment_roles", batch_object: @user, batched_keys: :enrollments) do
        @user
          .enrollments
          .shard(Shard.current)
          .active_or_pending_by_date
          .where(course_id: Course.active.horizon.select(:id))
          .distinct
          .pluck(:type)
      end
    end

    def has_career_enrollment_roles?(types)
      career_enrollment_roles.intersect?(types)
    end

    def has_career_learner_roles?
      # Optimization to avoid queries when possible
      return false if career_unaffiliated_institution?

      has_career_enrollment_roles?(LEARNER_ENROLLMENT_TYPES)
    end

    def has_career_learning_provider_roles?
      # Optimization to avoid queries when possible
      return false if career_unaffiliated_institution?

      has_career_enrollment_roles?(LEARNING_PROVIDER_ENROLLMENT_TYPES) || has_career_account_users?
    end

    def has_career_account_users?
      return @_has_career_account_users unless @_has_career_account_users.nil?

      @_has_career_account_users = begin
        career_account_ids = @domain_root_account.settings[:horizon_account_ids]
        if career_account_ids.blank? || account_user_account_ids.blank?
          false
        # Check if any directly-set account users are career accounts (optimization to avoid account chain query)
        elsif account_user_account_ids.intersect?(career_account_ids)
          true
        else
          # Check if any of those accounts' ancestors are career accounts (load the account chain for each
          # account user and see if any of those are career accounts)
          account_user_account_chain_ids.values.flatten.intersect?(career_account_ids)
        end
      end
    end

    def has_academic_account_users?
      return @_has_academic_account_users unless @_has_academic_account_users.nil?

      @_has_academic_account_users = begin
        career_account_ids = @domain_root_account.settings[:horizon_account_ids]
        if account_user_account_ids.blank?
          false
        elsif career_account_ids.blank?
          # Short-circuit if none of their account users are possibly on a career account
          true
        else
          # For each account user, check if its part of a career account (load the account chain for each account
          # user - if any chain does not intersect with the career accounts, then it is an academic account)
          account_user_account_ids.any? do |account_id|
            !account_user_account_chain_ids[account_id].intersect?(career_account_ids)
          end
        end
      end
    end

    def account_user_account_ids
      Rails.cache.fetch_with_batched_keys("account_user_account_ids", batch_object: @user, batched_keys: :account_users) do
        @user.account_users.shard(Shard.current).active.pluck(:account_id)
      end
    end

    # Note this cache is not busted if the account chain changes, so there's a 1 hour TTL
    def account_user_account_chain_ids
      Rails.cache.fetch_with_batched_keys("account_user_account_chain_ids", batch_object: @user, batched_keys: [:account_users], expires_in: 1.hour) do
        Account.account_chain_ids_for_multiple_accounts(account_user_account_ids)
      end
    end
  end
end
