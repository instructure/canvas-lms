# frozen_string_literal: true

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
  class RulesController < ApplicationController
    include Concerns::PermittedApiParameters
    include Concerns::ApiToNestedAttributes

    before_action :get_context, :require_user
    before_action :require_course_assignment_edit_permissions, only: [:update, :destroy]
    before_action :require_course_assignment_add_or_edit_permissions, only: [:create]
    before_action :require_course_view_permissions

    # GET /api/rules
    def index
      rules = get_rules
      rules = rules.preload(Rule.preload_associations) if include_param.include?("all")
      rules = rules.with_assignments if value_to_boolean(params[:active])

      render json: rules.as_json(include: json_includes, include_root: false, except: [:root_account_id, :deleted_at])
    end

    # GET /api/rules/:id
    def show
      rule = get_rule
      render json: rule.as_json(include: json_includes, include_root: false, except: [:root_account_id, :deleted_at])
    end

    # POST /api/rules
    def create
      create_params = api_params_to_nested_attributes_params(
        nil,
        rule_params_for_create,
        :scoring_ranges,
        :assignment_sets,
        :assignment_set_associations
      ).merge(course: @context)

      rule = Rule.new(create_params)

      if rule.save
        render json: rule.as_json(include: Rule.includes_for_json, include_root: false, except: [:root_account_id, :deleted_at])
      else
        render json: rule.errors, status: :bad_request
      end
    end

    # POST/PUT /api/rules/:id(.:format)
    def update
      rule = get_rule
      ordered_params = add_ordering_to rule_params_for_update
      update_params = api_params_to_nested_attributes_params(
        rule,
        ordered_params,
        :scoring_ranges,
        :assignment_sets,
        :assignment_set_associations
      )
      if rule.update(update_params)
        render json: rule.as_json(include: Rule.includes_for_json, include_root: false, except: [:root_account_id, :deleted_at])
      else
        render json: rule.errors, status: :bad_request
      end
    end

    # DELETE /api/rules/:id
    def destroy
      rule = get_rule
      rule.destroy!
      render json: { success: true }
    end

    private

    def get_rules
      rules = @context.conditional_release_rules.active
      rules = rules.where(trigger_assignment_id: params[:trigger_assignment_id]) unless params[:trigger_assignment_id].blank?
      rules
    end

    def get_rule
      @context.conditional_release_rules.active.find(params[:id])
    end

    def include_param
      Array.wrap(params[:include])
    end

    def json_includes
      Rule.includes_for_json if include_param.include? "all"
    end

    def add_ordering_to(attrs)
      # Loop through each of the ranges, ordering them
      arrange_items(attrs[:scoring_ranges]) do |range|
        # Then through each of the sets, ordering them within the context
        # of the range
        arrange_items(range[:assignment_sets]) do |set|
          # Then the assignments, in the context of the assignment set within
          # the range
          arrange_items(set[:assignment_set_associations])
        end
      end

      attrs
    end

    def arrange_items(items)
      if items.present?
        items.map.with_index(1) do |item, position|
          item[:position] = position if item.present?
          yield item if block_given?
        end
      end
    end

    def require_course_view_permissions
      authorized_action(@context, @current_user, :read)
    end

    def require_course_assignment_edit_permissions
      authorized_action(@context, @current_user, %i[manage_assignments manage_assignments_edit])
    end

    def require_course_assignment_add_or_edit_permissions
      authorized_action(@context, @current_user, %i[manage_assignments manage_assignments_add manage_assignments_edit])
    end
  end
end
