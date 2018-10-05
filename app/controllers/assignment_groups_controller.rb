#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
# API for accessing Assignment Group and Assignment information.
#
# @model GradingRules
#     {
#       "id": "GradingRules",
#       "description": "",
#       "properties": {
#         "drop_lowest": {
#           "description": "Number of lowest scores to be dropped for each user.",
#           "example": 1,
#           "type": "integer"
#         },
#         "drop_highest": {
#           "description": "Number of highest scores to be dropped for each user.",
#           "example": 1,
#           "type": "integer"
#         },
#         "never_drop": {
#           "description": "Assignment IDs that should never be dropped.",
#           "example": [33, 17, 24],
#           "type": "array",
#           "items": {"type": "integer"}
#         }
#       }
#     }
# @model AssignmentGroup
#     {
#       "id": "AssignmentGroup",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the id of the Assignment Group",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the Assignment Group",
#           "example": "group2",
#           "type": "string"
#         },
#         "position": {
#           "description": "the position of the Assignment Group",
#           "example": 7,
#           "type": "integer"
#         },
#         "group_weight": {
#           "description": "the weight of the Assignment Group",
#           "example": 20,
#           "type": "integer"
#         },
#         "sis_source_id": {
#           "description": "the sis source id of the Assignment Group",
#           "example": "1234",
#           "type": "string"
#         },
#         "integration_data": {
#           "description": "the integration data of the Assignment Group",
#           "example": {"5678": "0954"},
#           "type": "object"
#         },
#         "assignments": {
#           "description": "the assignments in this Assignment Group (see the Assignment API for a detailed list of fields)",
#           "example": [],
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "rules": {
#           "description": "the grading rules that this Assignment Group has",
#           "$ref": "GradingRules"
#         }
#       }
#     }
#
class AssignmentGroupsController < ApplicationController
  before_action :require_context

  include Api::V1::AssignmentGroup

  # @API List assignment groups
  #
  # Returns the paginated list of assignment groups for the current context.
  # The returned groups are sorted by their position field.
  #
  # @argument include[] [String, "assignments"|"discussion_topic"|"all_dates"|"assignment_visibility"|"overrides"|"submission"]
  #  Associations to include with the group. "discussion_topic", "all_dates"
  #  "assignment_visibility" & "submission" are only valid if "assignments" is also included.
  #  The "assignment_visibility" option additionally requires that the Differentiated Assignments course feature be turned on.
  #
  # @argument exclude_assignment_submission_types[] [String, "online_quiz"|"discussion_topic"|"wiki_page"|"external_tool"]
  #  If "assignments" are included, those with the specified submission types
  #  will be excluded from the assignment groups.
  #
  # @argument override_assignment_dates [Boolean]
  #   Apply assignment overrides for each assignment, defaults to true.
  #
  # @argument grading_period_id [Integer]
  #   The id of the grading period in which assignment groups are being requested
  #   (Requires grading periods to exist.)
  #
  # @argument scope_assignments_to_student [Boolean]
  #   If true, all assignments returned will apply to the current user in the
  #   specified grading period. If assignments apply to other students in the
  #   specified grading period, but not the current user, they will not be
  #   returned. (Requires the grading_period_id argument and grading periods to
  #   exist. In addition, the current user must be a student.)
  #
  # @returns [AssignmentGroup]
  def index
    if authorized_action(@context.assignment_groups.temp_record, @current_user, :read)
      groups = Api.paginate(@context.assignment_groups.active, self, api_v1_course_assignment_groups_url(@context))

      assignments = if include_params.include?('assignments')
        visible_assignments(@context, @current_user, groups)
      else
        []
      end

      if assignments.any? && include_params.include?('submission')
        submissions = submissions_hash(['submission'], assignments)
      end

      respond_to do |format|
        format.json do
          render json: index_groups_json(@context, @current_user, groups, assignments, submissions)
        end
      end
    end
  end

  def reorder
    if authorized_action(@context.assignment_groups.temp_record, @current_user, :update)
      order = params[:order].split(',')
      @context.assignment_groups.first.update_order(order)
      new_order = @context.assignment_groups.pluck(:id)
      render :json => {:reorder => true, :order => new_order}, :status => :ok
    end
  end

  def reorder_assignments
    @group = @context.assignment_groups.find(params[:assignment_group_id])
    if authorized_action(@group, @current_user, :update)
      order = params[:order].split(',').map{|id| id.to_i }
      group_ids = ([@group.id] + (order.empty? ? [] : @context.assignments.where(id: order).distinct.except(:order).pluck(:assignment_group_id)))
      assignments = @context.active_assignments.where(id: order)

      return render json: { message: t("Cannot move assignments due to closed grading periods") }, status: :unauthorized unless can_reorder_assignments?(assignments, @group)

      assignment_ids_to_update = assignments.where.not(:assignment_group_id => @group.id).pluck(:id)
      tags_to_update = []
      if assignment_ids_to_update.any?
        assignments.where(:id => assignment_ids_to_update).update_all(assignment_group_id: @group.id, updated_at: Time.now.utc)
        tags_to_update += MasterCourses::ChildContentTag.where(:content_type => "Assignment", :content_id => assignment_ids_to_update).to_a
        Canvas::LiveEvents.send_later_if_production(:assignments_bulk_updated, assignment_ids_to_update)
      end
      quizzes = @context.active_quizzes.where(assignment_id: order)
      quiz_ids_to_update = quizzes.where.not(:assignment_group_id => @group.id).pluck(:id)
      if quiz_ids_to_update.any?
        quizzes.where(:id => quiz_ids_to_update).update_all(assignment_group_id: @group.id, updated_at: Time.now.utc)
        tags_to_update += MasterCourses::ChildContentTag.where(:content_type => "Quizzes::Quiz", :content_id => quiz_ids_to_update).to_a
      end
      tags_to_update.each do |mc_tag|
        unless mc_tag.downstream_changes.include?("assignment_group_id")
          mc_tag.downstream_changes << "assignment_group_id"
          mc_tag.save!
        end
      end

      @group.assignments.first.update_order(order) unless @group.assignments.empty?
      groups = AssignmentGroup.where(id: group_ids)
      groups.touch_all
      groups.each{|assignment_group| AssignmentGroup.notify_observers(:assignments_changed, assignment_group)}
      ids = @group.active_assignments.map(&:id)
      @context.recompute_student_scores rescue nil
      render json: { reorder: true, order: ids}, status: :ok
    end
  end

  def show
    @assignment_group = @context.assignment_groups.find(params[:id])
    if @assignment_group.deleted?
      respond_to do |format|
        flash[:notice] = t 'notices.deleted', "This group has been deleted"
        format.html { redirect_to named_context_url(@context, :assignments_url) }
      end
      return
    end
    if authorized_action(@assignment_group, @current_user, :read)
      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url, @assignment_group.context_id)) }
        format.json { render :json => @assignment_group.as_json(:permissions => {:user => @current_user, :session => session}) }
      end
    end
  end

  def create
    unless valid_integration_data?
      return render :json => 'Invalid integration data', :status => :bad_request
    end
    @assignment_group = @context.assignment_groups.temp_record(assignment_group_params)
    if authorized_action(@assignment_group, @current_user, :create)
      respond_to do |format|
        if @assignment_group.save
          @assignment_group.insert_at(1)
          flash[:notice] = t 'notices.created', 'Assignment Group was successfully created.'
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.as_json(:permissions => {:user => @current_user, :session => session}), :status => :created}
        else
          format.json { render :json => @assignment_group.errors, :status => :bad_request }
        end
      end
    end
  end

  def update
    unless valid_integration_data?
      return render :json => 'Invalid integration data', :status => :bad_request
    end
    @assignment_group = @context.assignment_groups.find(params[:id])
    if authorized_action(@assignment_group, @current_user, :update)
      respond_to do |format|
        updated = update_assignment_group(@assignment_group, params['assignment_group'])
        if updated.present? && updated.save
          @assignment_group = updated
          flash[:notice] = t 'notices.updated', 'Assignment Group was successfully updated.'
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.as_json(:permissions => {:user => @current_user, :session => session}), :status => :ok }
        else
          format.json { render :json => @assignment_group.errors, :status => :bad_request }
        end
      end
    end
  end

  def destroy
    @assignment_group = AssignmentGroup.find(params[:id])
    if authorized_action(@assignment_group, @current_user, :delete)
      if @assignment_group.has_frozen_assignments?(@current_user)
        @assignment_group.errors.add('workflow_state', t('errors.cannot_delete_group', "You can not delete a group with a locked assignment.", :att_name => 'workflow_state'))
        respond_to do |format|
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
          format.json { render :json => @assignment_group.errors, :status => :bad_request }
        end
        return
      end

      if params[:move_assignments_to]
        @assignment_group.move_assignments_to params[:move_assignments_to]
      end
      @assignment_group.destroy

      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url)) }
        format.json { render :json => {
          assignment_group: @assignment_group.as_json(include_root: false, include: :active_assignments),
          new_assignment_group: @new_group.as_json(include_root: false, include: :active_assignments)
        }}
      end
    end
  end

  private

  def valid_integration_data?
    integration_data = assignment_group_params['integration_data']
    integration_data.is_a?(Hash) || integration_data.nil?
  end

  def assignment_group_params
    result = params.require(:assignment_group).
      permit(:assignment_weighting_scheme,
             :default_assignment_name,
             :group_weight,
             :name,
             :position,
             :rules,
             :sis_source_id,
             :integration_data => strong_anything)
    result[:integration_data] = nil if result[:integration_data] == ''
    result
  end

  def include_params
    params[:include] || []
  end

  def assignment_includes
    includes = [:context, :external_tool_tag, {:quiz => :context}]
    includes += [:rubric, :rubric_association] unless assignment_excludes.include?('rubric')
    includes << :discussion_topic if include_params.include?("discussion_topic")
    includes << :assignment_overrides if include_overrides?
    includes
  end

  def assignment_excludes
    params[:exclude_response_fields] || []
  end

  def filter_by_grading_period?
    params[:grading_period_id].present? && !all_grading_periods_selected?
  end

  def all_grading_periods_selected?
    params[:grading_period_id] == '0'
  end

  def include_overrides?
    override_dates? ||
      include_params.include?('all_dates') ||
      include_params.include?('overrides') ||
      filter_by_grading_period?
  end

  def assignment_visibilities(course, assignments)
    if include_visibility?
      AssignmentStudentVisibility.assignments_with_user_visibilities(course, assignments)
    else
      params.fetch(:include, []).delete('assignment_visibility')
      AssignmentStudentVisibility.none
    end
  end

  def index_groups_json(context, current_user, groups, assignments, submissions = [])
    include_overrides = include_params.include?('overrides')

    assignments_by_group = assignments.group_by(&:assignment_group_id)
    preloaded_attachments = user_content_attachments(assignments, context)

    unless assignment_excludes.include?('in_closed_grading_period')
      closed_grading_period_hash =
        EffectiveDueDates.for_course(context, assignments).to_hash([:in_closed_grading_period])
    end

    if assignments.any? && context.grants_right?(current_user, session, :manage_assignments)
      mc_status = setup_master_course_restrictions(assignments, context)
    end

    groups.map do |group|
      group.context = context
      group_assignments = assignments_by_group[group.id] || []

      options = {
        stringify_json_ids: stringify_json_ids?,
        override_assignment_dates: override_dates?,
        preloaded_user_content_attachments: preloaded_attachments,
        assignments: group_assignments,
        assignment_visibilities: assignment_visibilities(context, assignments),
        exclude_response_fields: assignment_excludes,
        include_overrides: include_overrides,
        submissions: submissions,
        closed_grading_period_hash: closed_grading_period_hash,
        master_course_status: mc_status
      }

      assignment_group_json(group, current_user, session, params[:include], options)
    end
  end

  def include_visibility?
    include_params.include?('assignment_visibility') && @context.grants_any_right?(@current_user, :read_as_admin, :manage_grades, :manage_assignments)
  end

  def override_dates?
    value_to_boolean(params.fetch(:override_assignment_dates, true))
  end

  def user_content_attachments(assignments, context)
    if assignment_excludes.include?('description')
      {}
    else
      api_bulk_load_user_content_attachments(assignments.map(&:description), context)
    end
  end

  def visible_assignments(context, current_user, groups)
    return Assignment.none unless include_params.include?('assignments')
    # TODO: possible keyword arguments refactor
    assignments = AssignmentGroup.visible_assignments(
      current_user,
      context,
      groups,
      assignment_includes
    )

    if params[:exclude_assignment_submission_types].present?
      exclude_types = params[:exclude_assignment_submission_types]
      exclude_types = Array.wrap(exclude_types) &
        %w(online_quiz discussion_topic wiki_page external_tool)
      assignments = assignments.where.not(submission_types: exclude_types)
    end

    assignments = assignments.with_student_submission_count.all

    if filter_by_grading_period?
      assignments = filter_assignments_by_grading_period(assignments, context)
    end

    # because of a bug with including content_tags, we are preloading
    # here rather than in assignments with multiple associations
    # referencing content_tags table and therefore aliased table names
    # the conditions on has_many :context_module_tags will break
    if include_params.include?("module_ids") || !context.grants_right?(@current_user, session, :read_as_admin)
      # loading the context module information here will improve performance for `locked_json` immensely
      Assignment.preload_context_module_tags(assignments)
    end

    if AssignmentOverrideApplicator.should_preload_override_students?(assignments, @current_user, "assignment_groups_api")
      AssignmentOverrideApplicator.preload_assignment_override_students(assignments, @current_user)
    end

    if assignment_includes.include?(:assignment_overrides)
      assignments.each { |a| a.has_no_overrides = true if a.assignment_overrides.size == 0 }
    end

    assignments
  end

  def filter_assignments_by_grading_period(assignments, course)
    grading_period = GradingPeriod.for(course).find_by(id: params.fetch(:grading_period_id))
    return assignments unless grading_period

    if params[:scope_assignments_to_student] &&
      course.user_is_student?(@current_user, include_future: true, include_fake_student: true)
      grading_period.assignments_for_student(assignments, @current_user)
    else
      grading_period.assignments(assignments)
    end
  end

  def can_reorder_assignments?(assignments, group)
    return true unless @context.grading_periods?
    return true if @context.account_membership_allows(@current_user)

    effective_due_dates = EffectiveDueDates.for_course(@context, assignments)
    assignments.none? do |assignment|
      # if the assignment is being moved into a different group and it's in
      # a closed period, do not allow it to be moved.
      assignment.assignment_group_id != group.id &&
        effective_due_dates.in_closed_grading_period?(assignment.id)
    end
  end
end
