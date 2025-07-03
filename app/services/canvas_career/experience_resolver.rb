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

        # Failsafe (career flags disabled or launch configs not present)
        Constants::App::ACADEMIC
      end
    end

    def available_apps
      GuardRail.activate(:secondary) do
        apps = []
        apps << Constants::App::ACADEMIC if has_academic_enrollments?
        apps << Constants::App::CAREER_LEARNING_PROVIDER if has_career_learning_provider_roles?
        apps << Constants::App::CAREER_LEARNER if has_career_learner_roles?
        apps
      end
    end

    private

    # In an account or course context -> is it a career account/course?
    # When contextless -> true if they don't have career enrollments. If they do, check that their preferred
    # experience is academic
    def resolve_academic?
      if @context.is_a?(Account)
        !horizon_account?
      elsif @context.is_a?(Course)
        !horizon_course?
      else # contextless
        user_preference.prefers_academic? || !has_career_enrollments?
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
        horizon_account? &&
          @domain_root_account.feature_enabled?(:horizon_learning_provider_app_for_accounts) &&
          learning_provider_in_context?
      elsif @context.is_a?(Course)
        horizon_course? &&
          @domain_root_account.feature_enabled?(:horizon_learning_provider_app_for_courses) &&
          learning_provider_in_context? &&
          (user_preference.prefers_learning_provider? || !learner_in_context?)
      else # contextless
        @domain_root_account.feature_enabled?(:horizon_learning_provider_app_on_contextless_routes) &&
          has_career_enrollments? &&
          (user_preference.prefers_career? || !has_academic_enrollments?) &&
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
        has_career_enrollments? &&
          (user_preference.prefers_career? || !has_academic_enrollments?) &&
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

    def enrollment_types
      @_enrollment_types ||= Rails.cache.fetch_with_batched_keys("career_enrollment_types", batch_object: @user, batched_keys: :enrollments) do
        Course
          .active
          .where(id: @user.enrollments.shard(Shard.current).active_or_pending_by_date.select(:course_id))
          .distinct
          .pluck(:horizon_course)
      end
    end

    def has_career_enrollments?
      enrollment_types.include?(true)
    end

    def has_academic_enrollments?
      enrollment_types.include?(false)
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

    def has_roles?(types)
      career_enrollment_roles.intersect?(types)
    end

    def has_career_learner_roles?
      has_roles?(LEARNER_ENROLLMENT_TYPES)
    end

    def has_career_learning_provider_roles?
      has_roles?(LEARNING_PROVIDER_ENROLLMENT_TYPES)
    end
  end
end
