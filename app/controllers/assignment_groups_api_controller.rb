#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Assignment Groups
class AssignmentGroupsApiController < ApplicationController
  before_filter :require_context
  before_filter :get_assignment_group, :except => [:create]

  include Api::V1::AssignmentGroup

  # @API Get an Assignment Group
  #
  # Returns the assignment group with the given id.
  #
  # @argument include[] ["assignments"|"discussion_topic"|"assignment_visibility"]
  #   Associations to include with the group. "discussion_topic" and "assignment_visibility"
  #   are only valid if "assignments" is also included. The "assignment_visibility" option additionally
  #   requires that the Differentiated Assignments course feature be turned on.
  #
  # @argument override_assignment_dates [Boolean]
  #   Apply assignment overrides for each assignment, defaults to true.
  #
  # @argument grading_period_id [Integer]
  #   The id of the grading period in which assignment groups are being requested
  #   (Requires the Multiple Grading Periods account feature turned on)
  #
  # @returns AssignmentGroup
  def show
    if authorized_action(@assignment_group, @current_user, :read)
      includes = Array(params[:include])
      override_dates = value_to_boolean(params[:override_assignment_dates] || true)
      assignments = @assignment_group.visible_assignments(@current_user)
      if params[:grading_period_id] && multiple_grading_periods?
        assignments = GradingPeriod.find(params[:grading_period_id]).assignments(assignments)
      end
      includes.delete('assignment_visibility') unless @context.grants_any_right?(@current_user, :read_as_admin, :manage_grades, :manage_assignments)
      render :json => assignment_group_json(@assignment_group, @current_user, session, includes, {
        stringify_json_ids: stringify_json_ids?,
        override_dates: override_dates,
        assignments: assignments
      })
    end
  end

  # @API Create an Assignment Group
  #
  # Create a new assignment group for this course.
  #
  # @argument name [String]
  #   The assignment group's name
  #
  # @argument position [Integer]
  #   The position of this assignment group in relation to the other assignment groups
  #
  # @argument group_weight [Float]
  #   The percent of the total grade that this assignment group represents
  #
  # @argument rules
  #   The grading rules that are applied within this assignment group
  #   See the Assignment Group object definition for format
  #
  # @returns AssignmentGroup
  def create
    @assignment_group = @context.assignment_groups.scoped.new
    if authorized_action(@assignment_group, @current_user, :create)
      process_assignment_group
    end
  end

  # @API Edit an Assignment Group
  #
  # Modify an existing Assignment Group.
  # Accepts the same parameters as Assignment Group creation
  #
  # @returns AssignmentGroup
  def update
    if authorized_action(@assignment_group, @current_user, :update)
      process_assignment_group
    end
  end

  # @API Destroy an Assignment Group
  #
  # Deletes the assignment group with the given id.
  #
  # @argument move_assignment_to [String]
  #   The ID of an active Assignment Group to which the assignments that are
  #   currently assigned to the destroyed Assignment Group will be assigned.
  #   NOTE: If this argument is not provided, any assignments in this Assignment
  #   Group will be deleted.
  #
  # @returns AssignmentGroup
  def destroy
    if authorized_action(@assignment_group, @current_user, :delete)

      if @assignment_group.assignments.active.exists?
        if @assignment_group.has_frozen_assignment_group_id_assignment?(@current_user)
          err_msg = t('errors.frozen_assignments_error', "You cannot delete a group with a locked assignment.")
          @assignment_group.errors.add('workflow_state', err_msg, :att_name => 'workflow_state')
          render :json => @assignment_group.errors, :status => :bad_request
          return
        end

        if params[:move_assignments_to]
          @assignment_group.move_assignments_to params[:move_assignments_to]
        end
      end

      @assignment_group.destroy
      render :json => assignment_group_json(@assignment_group, @current_user, session, [], { stringify_json_ids: stringify_json_ids? })
    end
  end

  def get_assignment_group
    @assignment_group = @context.assignment_groups.active.find(params[:assignment_group_id])
  end

  def process_assignment_group
    if update_assignment_group @assignment_group, params
      render :json => assignment_group_json(@assignment_group, @current_user, session, [], { stringify_json_ids: stringify_json_ids? })
    else
      render :json => @assignment_group.errors, :status => :bad_request
    end
  end

end
