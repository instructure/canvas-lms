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
    def self.final_grades_override_custom_transition_hook(_user, context, from_state, transitions)
      transitions['off'] ||= {}
      transitions['on'] ||= {}

      # This is a "one-way" flag:
      #  - Once Allowed, it can no longer be set to Off.
      #  - Once On, it can no longer be Off nor Allowed.
      if context.is_a?(Course)
        transitions['off']['locked'] = true if from_state == 'on' # lock off to enforce no take backs
      elsif context.is_a?(Account)
        transitions['allowed'] ||= {}
        if from_state == 'allowed'
          transitions['off']['locked'] = true # lock off to enforce no take backs
        elsif from_state == 'on'
          # lock both `off` and `allowed` to enforce no take backs
          transitions['off']['locked'] = true
          transitions['allowed']['locked'] = true
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

    def self.analytics_2_after_state_change_hook(_user, context, _old_state, _new_state)
      # if we clear the nav cache before HAStore clears, it can be recached with stale FF data
      nav_cache = Lti::NavigationCache.new(context.root_account)
      nav_cache.send_later_if_production_enqueue_args(:invalidate_cache_key, {run_at: 1.minute.from_now, max_attempts: 1})
      nav_cache.send_later_if_production_enqueue_args(:invalidate_cache_key, {run_at: 5.minutes.from_now, max_attempts: 1})
    end

    def self.k6_theme_hook(_user, _context, _from_state, transitions)
      transitions['on'] ||= {}
      transitions['on']['message'] =
        I18n.t("Enabling the Elementary Theme will change the font in the Canvas interface and simplify "\
        "the Course Navigation Menu for all users in your course.")
      transitions['on']['reload_page'] = true
      transitions['off'] ||= {}
      transitions['off']['message'] =
        I18n.t("Disabling the Elementary Theme will change the font in the Canvas interface for all users in your course.")
      transitions['off']['reload_page'] = true
    end
  end
end
