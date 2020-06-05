#
# Copyright (C) 2020 - present Instructure, Inc.
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

module ConditionalRelease
  module Concerns
    module PermittedApiParameters
      extend ActiveSupport::Concern

      def rule_params_for_create
        params.permit(rule_keys_for_create)
      end

      def rule_params_for_update
        params.permit(rule_keys_for_update)
      end

      def scoring_range_params_for_create
        params.permit(scoring_range_keys_for_create)
      end

      def scoring_range_params_for_update
        params.permit(scoring_range_keys_for_update)
      end

      def assignment_set_association_params
        params.permit(assignment_set_association_keys)
      end


      private
      def base_rule_keys
        [ :trigger_assignment_id, :position ]
      end

      def base_scoring_range_keys
        [ :upper_bound, :lower_bound, :position ]
      end

      def base_assignment_set_association_keys
        [ :assignment_id, :position ]
      end

      # permitted inside nested api requests to allow
      # child updates
      def nested_update_keys
        [ :id, :position ]
      end

      def rule_keys_for_create
        base_rule_keys.concat [
          scoring_ranges: scoring_range_keys_for_create
        ]
      end

      def rule_keys_for_update
        base_rule_keys.concat [
          scoring_ranges: scoring_range_keys_for_nested_update
        ]
      end

      def scoring_range_keys_for_create
        base_scoring_range_keys.concat [
          assignment_sets: assignment_set_keys_for_create
        ]
      end

      def scoring_range_keys_for_update
        base_scoring_range_keys.concat [
          assignment_sets: assignment_set_keys_for_nested_update
        ]
      end

      def scoring_range_keys_for_nested_update
        scoring_range_keys_for_update | nested_update_keys
      end

      def assignment_set_association_keys
        base_assignment_set_association_keys
      end

      def assignment_set_association_keys_for_nested_update
        assignment_set_association_keys | nested_update_keys
      end

      def assignment_set_keys_for_create
        [
          assignment_set_associations: assignment_set_association_keys
        ]
      end

      def assignment_set_keys_for_nested_update
        nested_update_keys.concat [
          assignment_set_associations: assignment_set_association_keys_for_nested_update
        ]
      end
    end
  end
end
