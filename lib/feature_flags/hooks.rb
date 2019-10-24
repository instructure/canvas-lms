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

module FeatureFlags
  module Hooks
    def self.new_gradebook_custom_transition_hook(user, context, _from_state, transitions)
      if context.is_a?(Course)
        is_admin = context.account_membership_allows(user)
        is_teacher = user.teacher_enrollments.active.where(course_id: context.id).exists?

        if is_admin || is_teacher
          should_lock = context.gradebook_backwards_incompatible_features_enabled?
          transitions['off']['locked'] = should_lock if transitions&.dig('off')
        else
          transitions['on']['locked'] = true if transitions&.dig('on')
          transitions['off']['locked'] = true if transitions&.dig('off')
        end
      elsif context.is_a?(Account)
        backwards_incompatible_feature_flags =
          FeatureFlag.where(feature: [:new_gradebook, :final_grades_override], state: :on)
        all_active_sub_account_ids = Account.sub_account_ids_recursive(context.id)
        relevant_accounts = Account.joins(:feature_flags).where(id: [context.id].concat(all_active_sub_account_ids))
        relevant_courses = Course.joins(:feature_flags).where(account_id: all_active_sub_account_ids)

        accounts_with_feature = relevant_accounts.merge(backwards_incompatible_feature_flags)
        courses_with_feature = relevant_courses.merge(backwards_incompatible_feature_flags)

        if accounts_with_feature.exists? || courses_with_feature.exists?
          transitions['off'] ||= {}
          transitions['off']['locked'] = true
          transitions['off']['warning'] =
            I18n.t("This feature can't be disabled because there is at least one sub-account or course with this feature enabled.")
        end

        if context.feature_enabled?(:final_grades_override)
          # state is locked to `on`
          transitions['off'] ||= {}
          transitions['off']['locked'] = true
          transitions['allowed'] ||= {}
          transitions['allowed']['locked'] = true
        elsif context.feature_allowed?(:final_grades_override, exclude_enabled: true)
          # Lock `off` since Final Grade Override is set to `allowed`
          transitions['off'] ||= {}
          transitions['off']['locked'] = true
        end
      end
    end

    def self.final_grades_override_custom_transition_hook(_user, context, from_state, transitions)
      transitions['off'] ||= {}
      transitions['on'] ||= {}

      # The goal here is to make Final Grade Override fully dependent upon New Gradebook's status.
      # In other words this is a "one-way" flag:
      #  - Once Allowed, it can no longer be set to Off.
      #  - Once On, it can no longer be Off nor Allowed.
      #  - For Final Grade Override to be set to `allowed`, New Gradebook must be at least `allowed` or `on`
      #  - For Final Grade Override to be set to `on`, New Gradebook must be `on`.
      if context.is_a?(Course)
        if context.feature_enabled?(:new_gradebook)
          transitions['off']['locked'] = true if from_state == 'on' # lock off to enforce no take backs
        else
          transitions['on']['locked'] = true # feature unavailable without New Gradebook
        end
      elsif context.is_a?(Account)
        transitions['allowed'] ||= {}
        if context.feature_enabled?(:new_gradebook)
          if from_state == 'allowed'
            transitions['off']['locked'] = true # lock off to enforce no take backs
          elsif from_state == 'on'
            # lock both `off` and `allowed` to enforce no take backs
            transitions['off']['locked'] = true
            transitions['allowed']['locked'] = true
          end
        elsif context.feature_allowed?(:new_gradebook, exclude_enabled: true)
          # Locked into `allowed` since Final Grade Override can't go back to `off` and can't
          # set to `on` without New Gradebook also set to `on`.
          transitions['off']['locked'] = true
          transitions['on']['locked'] = true
        else
          # feature unavailable without New Gradebook
          transitions['allowed']['locked'] = true
          transitions['on']['locked'] = true
        end
      end
    end

    def self.use_semi_colon_field_separators_in_gradebook_exports_custom_transition_hook(_user, context, _from_state, transitions)
      if context.feature_enabled?(:autodetect_field_separators_for_gradebook_exports)
        transitions['on'] ||= {}
        transitions['on']['locked'] = true
        transitions['on']['warning'] = I18n.t("This feature can't be enabled while autodetection of field separators is enabled")
      end
    end

    def self.autodetect_field_separators_for_gradebook_exports_custom_transition_hook(_user, context, _from_state, transitions)
      if context.feature_enabled?(:use_semi_colon_field_separators_in_gradebook_exports)
        transitions['on'] ||= {}
        transitions['on']['locked'] = true
        transitions['on']['warning'] = I18n.t("This feature can't be enabled while semicolons are forced to be field separators")
      end
    end

    def self.quizzes_next_visible_on_hook(context)
      root_account = context.root_account
      # assume all Quizzes.Next provisions so far have been done through uuid_provisioner
      #  so all provisioned accounts will have the FF in Canvas UI
      root_account.settings&.dig(:provision, 'lti').present?
    end

    def self.conditional_release_after_state_change_hook(user, context, _old_state, new_state)
      if %w(on allowed).include?(new_state) && context.is_a?(Account)
        @service_account = ConditionalRelease::Setup.new(context.id, user.id)
        @service_account.activate!
      end
    end

    def self.analytics_2_after_state_change_hook(_user, context,_old_state, _new_state)
      Lti::NavigationCache.new(context.root_account).invalidate_cache_key
    end
  end
end
