#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

# @API Assignments
# @subtopic Assignment Overrides
#
# @model AssignmentOverride
#     {
#       "id": "AssignmentOverride",
#       "description": "NOTE: The Assignment Override feature is in beta! This API is not finalized and there could be breaking changes before its final release.",
#       "properties": {
#         "id": {
#           "description": "the ID of the assignment override",
#           "example": 4,
#           "type": "integer"
#         },
#         "assignment_id": {
#           "description": "the ID of the assignment the override applies to",
#           "example": 123,
#           "type": "integer"
#         },
#         "student_ids": {
#           "description": "the IDs of the override's target students (present if the override targets an ad-hoc set of students)",
#           "example": [1, 2, 3],
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "group_id": {
#           "description": "the ID of the override's target group (present if the override targets a group and the assignment is a group assignment)",
#           "example": 2,
#           "type": "integer"
#         },
#         "course_section_id": {
#           "description": "the ID of the overrides's target section (present if the override targets a section)",
#           "example": 1,
#           "type": "integer"
#         },
#         "title": {
#           "description": "the title of the override",
#           "example": "an assignment override",
#           "type": "string"
#         },
#         "due_at": {
#           "description": "the overridden due at (present if due_at is overridden)",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "all_day": {
#           "description": "the overridden all day flag (present if due_at is overridden)",
#           "example": true,
#           "type": "integer"
#         },
#         "all_day_date": {
#           "description": "the overridden all day date (present if due_at is overridden)",
#           "example": "2012-07-01",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "the overridden unlock at (present if unlock_at is overridden)",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "the overridden lock at, if any (present if lock_at is overridden)",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
class AssignmentOverridesController < ApplicationController
  before_action :require_group, :only => :group_alias
  before_action :require_section, :only => :section_alias
  before_action :require_course
  before_action :require_assignment, :except => [:batch_retrieve, :batch_update, :batch_create]
  before_action :require_assignment_edit, :only => [:create, :update, :destroy]
  before_action :require_all_assignments_edit, :only => [:batch_update, :batch_create]
  before_action :require_override, :only => [:show, :update, :destroy]

  include Api::V1::AssignmentOverride

  # @API List assignment overrides
  # @beta
  #
  # Returns the list of overrides for this assignment that target
  # sections/groups/students visible to the current user.
  #
  # @returns [AssignmentOverride]
  def index
    @overrides = assignment_override_collection(@assignment, true)
    render :json => assignment_overrides_json(@overrides, @current_user)
  end

  # @API Get a single assignment override
  # @beta
  #
  # Returns details of the the override with the given id.
  #
  # @returns AssignmentOverride
  def show
    render :json => assignment_override_json(@override)
  end

  # @API Redirect to the assignment override for a group
  # @beta
  #
  # Responds with a redirect to the override for the given group, if any
  # (404 otherwise).
  def group_alias
    @override = find_assignment_override(@assignment, @group)
    raise ActiveRecord::RecordNotFound unless @override
    redirect_to api_v1_assignment_override_url(
      :course_id => @course.id,
      :assignment_id => @assignment.id,
      :id => @override)
  end

  # @API Redirect to the assignment override for a section
  # @beta
  #
  # Responds with a redirect to the override for the given section, if any
  # (404 otherwise).
  def section_alias
    @override = find_assignment_override(@assignment, @section)
    raise ActiveRecord::RecordNotFound unless @override
    redirect_to api_v1_assignment_override_url(
      :course_id => @course.id,
      :assignment_id => @assignment.id,
      :id => @override)
  end

  # @API Create an assignment override
  # @beta
  #
  # @argument assignment_override[student_ids][] [Integer] The IDs of
  #   the override's target students. If present, the IDs must each identify a
  #   user with an active student enrollment in the course that is not already
  #   targetted by a different adhoc override.
  #
  # @argument assignment_override[title] The title of the adhoc
  #   assignment override. Required if student_ids is present, ignored
  #   otherwise (the title is set to the name of the targetted group or section
  #   instead).
  #
  # @argument assignment_override[group_id] [Integer] The ID of the
  #   override's target group. If present, the following conditions must be met
  #   for the override to be successful:
  #
  #   1. the assignment MUST be a group assignment (a group_category_id is assigned to it)
  #   2. the ID must identify an active group in the group set the assignment is in
  #   3. the ID must not be targetted by a different override
  #
  #   See {Appendix: Group assignments} for more info.
  #
  # @argument assignment_override[course_section_id] [Integer] The ID
  #   of the override's target section. If present, must identify an active
  #   section of the assignment's course not already targetted by a different
  #   override.
  #
  # @argument assignment_override[due_at] [DateTime] The day/time
  #   the overridden assignment is due. Accepts times in ISO 8601 format, e.g.
  #   2014-10-21T18:48:00Z. If absent, this override will not affect due date.
  #   May be present but null to indicate the override removes any previous due
  #   date.
  #
  # @argument assignment_override[unlock_at] [DateTime] The day/time
  #   the overridden assignment becomes unlocked. Accepts times in ISO 8601
  #   format, e.g. 2014-10-21T18:48:00Z. If absent, this override will not
  #   affect the unlock date. May be present but null to indicate the override
  #   removes any previous unlock date.
  #
  # @argument assignment_override[lock_at] [DateTime] The day/time
  #   the overridden assignment becomes locked. Accepts times in ISO 8601
  #   format, e.g. 2014-10-21T18:48:00Z. If absent, this override will not
  #   affect the lock date. May be present but null to indicate the override
  #   removes any previous lock date.
  #
  # One of student_ids, group_id, or course_section_id must be present. At most
  # one should be present; if multiple are present only the most specific
  # (student_ids first, then group_id, then course_section_id) is used and any
  # others are ignored.
  #
  # @returns AssignmentOverride
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/overrides.json' \
  #        -X POST \
  #        -F 'assignment_override[student_ids][]=8' \
  #        -F 'assignment_override[title]=Fred Flinstone' \
  #        -F 'assignment_override[due_at]=2012-10-08T21:00:00Z' \
  #        -H "Authorization: Bearer <token>"
  #
  def create
    @override = @assignment.assignment_overrides.build

    data, errors = interpret_assignment_override_data(@assignment, params[:assignment_override])
    return bad_request(:errors => errors) if errors

    if update_assignment_override(@override, data)
      render :json => assignment_override_json(@override), :status => 201
    else
      bad_request(@override.errors)
    end
  end

  # @API Update an assignment override
  # @beta
  #
  # @argument assignment_override[student_ids][] [Integer] The IDs of the
  #   override's target students. If present, the IDs must each identify a
  #   user with an active student enrollment in the course that is not already
  #   targetted by a different adhoc override. Ignored unless the override
  #   being updated is adhoc.
  #
  # @argument assignment_override[title] [String] The title of an adhoc
  #   assignment override. Ignored unless the override being updated is adhoc.
  #
  # @argument assignment_override[due_at] [DateTime] The day/time
  #   the overridden assignment is due. Accepts times in ISO 8601 format, e.g.
  #   2014-10-21T18:48:00Z. If absent, this override will not affect due date.
  #   May be present but null to indicate the override removes any previous due
  #   date.
  #
  # @argument assignment_override[unlock_at] [DateTime] The day/time
  #   the overridden assignment becomes unlocked. Accepts times in ISO 8601
  #   format, e.g. 2014-10-21T18:48:00Z. If absent, this override will not
  #   affect the unlock date. May be present but null to indicate the override
  #   removes any previous unlock date.
  #
  # @argument assignment_override[lock_at] [DateTime] The day/time
  #   the overridden assignment becomes locked. Accepts times in ISO 8601
  #   format, e.g. 2014-10-21T18:48:00Z. If absent, this override will not
  #   affect the lock date. May be present but null to indicate the override
  #   removes any previous lock date.
  #
  # All current overridden values must be supplied if they are to be retained;
  # e.g. if due_at was overridden, but this PUT omits a value for due_at,
  # due_at will no longer be overridden. If the override is adhoc and
  # student_ids is not supplied, the target override set is unchanged. Target
  # override sets cannot be changed for group or section overrides.
  #
  # @returns AssignmentOverride
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/overrides/3.json' \
  #        -X PUT \
  #        -F 'assignment_override[title]=Fred Flinstone' \
  #        -F 'assignment_override[due_at]=2012-10-08T21:00:00Z' \
  #        -H "Authorization: Bearer <token>"
  #
  def update
    data, errors = interpret_assignment_override_data(@assignment, params[:assignment_override], @override.set_type)
    return bad_request(:errors => errors) if errors

    if update_assignment_override(@override, data)
      render :json => assignment_override_json(@override)
    else
      bad_request(@override.errors)
    end
  end

  # @API Delete an assignment override
  # @beta
  #
  # Deletes an override and returns its former details.
  #
  # @returns AssignmentOverride
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/overrides/3.json' \
  #        -X DELETE \
  #        -H "Authorization: Bearer <token>"
  #
  def destroy
    if @override.destroy
      render :json => assignment_override_json(@override)
    else
      bad_request(@override.errors)
    end
  end

  # @API Batch retrieve overrides in a course
  # @beta
  #
  # Returns a list of specified overrides in this course, providing
  # they target sections/groups/students visible to the current user.
  # Returns null elements in the list for requests that were not found.
  #
  # @argument assignment_overrides[][id] [Required, String] Ids of overrides to retrieve
  #
  # @argument assignment_overrides[][assignment_id] [Required, String] Ids of assignments for each override
  #
  # @returns [AssignmentOverride]
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/12/assignments/overrides.json?assignment_overrides[][id]=109&assignment_overrides[][assignment_id]=122&assignment_overrides[][id]=99&assignment_overrides[][assignment_id]=111' \
  #        -H "Authorization: Bearer <token>"
  #
  def batch_retrieve
    # check request format
    override_params = deserialize_overrides(params[:assignment_overrides])
    if override_params.blank?
      return bad_request(errors: [ 'no assignment_overrides values present' ])
    elsif !override_params.is_a? Array
      return bad_request(errors: [ 'must specify an array with entry format { id, assignment_id }' ])
    elsif !override_params.all? { |o| o.is_a?(ActionController::Parameters) && o.key?('assignment_id') && o.key?('id') }
      return bad_request(errors: [ 'must specify an array with entry format { id, assignment_id }' ])
    end

    all_requests = override_params.group_by { |req| req['assignment_id'].to_i }
    assignments = @course.active_assignments.where(id: all_requests.keys).preload(:assignment_overrides)

    overrides = all_requests.map do |assignment_id, requests|
      override_ids = requests.map { |r| r['id'].to_i }
      assignment = assignments.find { |a| a.id == assignment_id }
      next unless assignment
      find_assignment_overrides(assignment, override_ids)
    end.flatten.compact

    # reorder to match request
    sorted = override_params.map do |req|
      overrides.find do |o|
        o.id == req['id'].to_i
      end
    end

    render json: assignment_overrides_json(sorted, @current_user)
  end

  # @API Batch create overrides in a course
  # @beta
  #
  # Creates the specified overrides for each assignment.  Handles creation in a
  # transaction, so all records are created or none are.
  #
  # One of student_ids, group_id, or course_section_id must be present. At most
  # one should be present; if multiple are present only the most specific
  # (student_ids first, then group_id, then course_section_id) is used and any
  # others are ignored.
  #
  # Errors are reported in an errors attribute, an array of errors corresponding
  # to inputs.  Global errors will be reported as a single element errors array
  #
  # @argument assignment_overrides[] [Required, AssignmentOverride] Attributes for the new assignment overrides.
  #     See {api:AssignmentOverridesController#create Create an assignment override} for available
  #     attributes
  #
  # @returns [AssignmentOverride]
  #
  # @example_request
  #
  #   curl "https://<canvas>/api/v1/courses/12/assignments/overrides.json" \
  #        -X POST \
  #        -F "assignment_overrides[][assignment_id]=109" \
  #        -F 'assignment_overrides[][student_ids][]=8' \
  #        -F "assignment_overrides[][title]=foo" \
  #        -F "assignment_overrides[][assignment_id]=13" \
  #        -F "assignment_overrides[][course_section_id]=200" \
  #        -F "assignment_overrides[][due_at]=2012-10-08T21:00:00Z" \
  #        -H "Authorization: Bearer <token>"
  #
  def batch_create
    batch_edit(false)
  end

  # @API Batch update overrides in a course
  # @beta
  #
  # Updates a list of specified overrides for each assignment.  Handles overrides
  # in a transaction, so either all updates are applied or none.
  # See {api:AssignmentOverridesController#update Update an assignment override} for
  # available attributes.
  #
  # All current overridden values must be supplied if they are to be retained;
  # e.g. if due_at was overridden, but this PUT omits a value for due_at,
  # due_at will no longer be overridden. If the override is adhoc and
  # student_ids is not supplied, the target override set is unchanged. Target
  # override sets cannot be changed for group or section overrides.
  #
  # Errors are reported in an errors attribute, an array of errors corresponding
  # to inputs.  Global errors will be reported as a single element errors array
  #
  # @argument assignment_overrides[] [Required, AssignmentOverride] Attributes for the updated overrides.
  #
  # @returns [AssignmentOverride]
  #
  # @example_request
  #
  #   curl "https://<canvas>/api/v1/courses/12/assignments/overrides.json" \
  #        -X PUT \
  #        -F "assignment_overrides[][id]=122" \
  #        -F "assignment_overrides[][assignment_id]=109" \
  #        -F "assignment_overrides[][title]=foo" \
  #        -F "assignment_overrides[][id]=993" \
  #        -F "assignment_overrides[][assignment_id]=13" \
  #        -F "assignment_overrides[][due_at]=2012-10-08T21:00:00Z" \
  #        -H "Authorization: Bearer <token>"
  #
  def batch_update
    batch_edit(true)
  end

  protected

  def require_group
    @group = find_group(nil, params[:group_id])
    @course = @group.context
  end

  def require_section
    @section = find_section(nil, params[:course_section_id])
    @course = @section.course
  end

  def require_course
    @course ||= api_find(Course.active, params[:course_id])
    raise ActiveRecord::RecordNotFound if @course.deleted?
    @context = @course
    authorized_action(@course, @current_user, :read)
  end

  def require_assignment
    @assignment = @course.active_assignments.find(params[:assignment_id])
  end

  def require_assignment_edit
    authorized_action(@assignment, @current_user, :update)
  end

  def require_all_assignments_edit
    authorized_action(@course, @current_user, :manage_assignments)
  end

  def require_override
    @override = find_assignment_override(@assignment, params[:id])
    raise ActiveRecord::RecordNotFound unless @override # i.e. if params[:id] was nil
  end

  def bad_request(errors)
    render :json => errors, :status => :bad_request
  end

  def batch_edit(is_update)
    override_params = deserialize_overrides(params[:assignment_overrides])
    all_data, all_errors = interpret_batch_assignment_overrides_data(@course, override_params, is_update)
    return bad_request(errors: all_errors) if all_errors.present?

    overrides = all_data.map do |data|
      is_update ? data['override'] : data['assignment'].assignment_overrides.build
    end

    if update_assignment_overrides(overrides, all_data)
      render json: assignment_overrides_json(overrides, @current_user)
    else
      errors = overrides.map do |override|
        override.errors if override.errors.present?
      end
      errors = ['unknown error'] unless errors.compact.present?
      bad_request(errors: errors)
    end
  end

  # @!appendix Group assignments
  #
  #  {include:file:doc/examples/group_assignment.md}
  #
  #  @see api:AssignmentOverridesController#create Creating an assignment override
  #  @see api:AssignmentsApiController#create Creating an assignment
  #  @see api:Assignments:Assignment
end
