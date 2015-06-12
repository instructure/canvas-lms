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

# @API Sections
#
# API for accessing section information.
#
# @model Section
#     {
#       "id": "Section",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the section.",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the section.",
#           "example": "Section A",
#           "type": "string"
#         },
#         "sis_section_id": {
#           "description": "The sis id of the section. This field is only included if the user has permission to view SIS information.",
#           "example": "s34643",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "Optional: The integration ID of the section. This field is only included if the user has permission to view SIS information.",
#           "example": "3452342345",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "The unique identifier for the SIS import if created through SIS. This field is only included if the user has permission to manage SIS information.",
#           "example": 47,
#           "type": "integer"
#         },
#         "course_id": {
#           "description": "The unique Canvas identifier for the course in which the section belongs",
#           "example": 7,
#           "type": "integer"
#         },
#         "sis_course_id": {
#           "description": "The unique SIS identifier for the course in which the section belongs. This field is only included if the user has permission to view SIS information.",
#           "example": 7,
#           "type": "string"
#         },
#         "start_at": {
#           "description": "the start date for the section, if applicable",
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "the end date for the section, if applicable",
#           "type": "datetime"
#         },
#         "nonxlist_course_id": {
#           "description": "The unique identifier of the original course of a cross-listed section",
#           "type": "integer"
#         },
#         "total_students": {
#           "description": "optional: the total number of active and invited students in the section",
#           "example": 13,
#           "type": "integer"
#         }
#       }
#     }
#
class SectionsController < ApplicationController
  before_filter :require_context
  before_filter :require_section, :except => [:index, :create]

  include Api::V1::Section

  # @API List course sections
  # Returns the list of sections for this course.
  #
  # @argument include[] [String, "students"|"avatar_url"|"enrollments"|"total_students"|"passback_status"]
  #   - "students": Associations to include with the group. Note: this is only
  #     available if you have permission to view users or grades in the course
  #   - "avatar_url": Include the avatar URLs for students returned.
  #   - "enrollments": If 'students' is also included, return the section
  #      enrollment for each student
  #   - "total_students": Returns the total amount of active and invited students
  #      for the course section
  #   - "passback_status": Include the grade passback status.
  #
  # @returns [Section]
  def index
    if authorized_action(@context, @current_user, [:read, :read_roster, :view_all_grades, :manage_grades])
      if params[:include].present? && !@context.grants_any_right?(@current_user, session, :read_roster, :view_all_grades, :manage_grades)
        params[:include] = nil
      end

      includes = Array(params[:include])
      result = @context.active_course_sections.map { |section| section_json(section, @current_user, session, includes) }

      render :json => result
    end
  end

  # @API Create course section
  # Creates a new section for this course.
  #
  # @argument course_section[name] [String]
  #   The name of the section
  #
  # @argument course_section[sis_section_id] [String]
  #   The sis ID of the section
  #
  # @argument course_section[start_at] [DateTime]
  #   Section start date in ISO8601 format, e.g. 2011-01-01T01:00Z
  #
  # @argument course_section[end_at] [DateTime]
  #   Section end date in ISO8601 format. e.g. 2011-01-01T01:00Z
  #
  # @argument course_section[restrict_enrollments_to_section_dates] [Boolean]
  #   Set to true to restrict user enrollments to the start and end dates of the section.
  #
  # @argument enable_sis_reactivation [Boolean]
  #   When true, will first try to re-activate a deleted section with matching sis_section_id if possible.
  #
  # @returns Section
  def create
    if authorized_action(@context.course_sections.scoped.new, @current_user, :create)
      sis_section_id = params[:course_section].try(:delete, :sis_section_id)
      can_manage_sis = api_request? && sis_section_id.present? &&
        @context.root_account.grants_right?(@current_user, session, :manage_sis)

      if can_manage_sis && value_to_boolean(params[:enable_sis_reactivation])
        @section = @context.course_sections.where(:sis_source_id => sis_section_id, :workflow_state => 'deleted').first
        @section.workflow_state = 'active' if @section
      end
      @section ||= @context.course_sections.build(params[:course_section])
      @section.sis_source_id = sis_section_id if can_manage_sis

      respond_to do |format|
        if @section.save
          @context.touch
          flash[:notice] = t('section_created', "Section successfully created!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => (api_request? ? section_json(@section, @current_user, session, []) : @section) }
        else
          flash[:error] = t('section_creation_failed', "Section creation failed")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.errors, :status => :bad_request }
        end
      end
    end
  end

  def require_section
    case @context
      when Course
        section_id = params[:section_id] || params[:id]
        @section = api_find(@context.active_course_sections, section_id)
      when CourseSection
        @section = @context
        raise ActiveRecord::RecordNotFound if @section.deleted? || @section.course.try(:deleted?)
      else
        raise ActiveRecord::RecordNotFound
    end
  end

  def crosslist_check
    course_id = params[:new_course_id]
    # cross-listing should only be allowed within the same root account
    @new_course = @section.root_account.all_courses.not_deleted.where(id: course_id).first if course_id =~ Api::ID_REGEX
    @new_course ||= @section.root_account.all_courses.not_deleted.where(sis_source_id: course_id).first if course_id.present?
    allowed = @new_course && @section.grants_right?(@current_user, session, :update) && @new_course.grants_right?(@current_user, session, :manage_admin_users)
    res = {:allowed => !!allowed}
    if allowed
      @account = @new_course.account
      res[:section] = @section.as_json(include_root: false)
      res[:course] = @new_course.as_json(include_root: false)
      res[:account] = @account.as_json(include_root: false)
    end
    render :json => res
  end

  # @API Cross-list a Section
  # Move the Section to another course.  The new course may be in a different account (department),
  # but must belong to the same root account (institution).
  #
  # @returns Section
  def crosslist
    @new_course = api_find(@section.root_account.all_courses.not_deleted, params[:new_course_id])
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.crosslist_to_course @new_course
      respond_to do |format|
        flash[:notice] = t('section_crosslisted', "Section successfully cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => (api_request? ? section_json(@section, @current_user, session, []) : @section) }
      end
    end
  end
  
  # @API De-cross-list a Section
  # Undo cross-listing of a Section, returning it to its original course.
  #
  # @returns Section
  def uncrosslist
    @new_course = @section.nonxlist_course
    return render(:json => {:message => "section is not cross-listed"}, :status => :bad_request) if @new_course.nil?
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.uncrosslist
      respond_to do |format|
        flash[:notice] = t('section_decrosslisted', "Section successfully de-cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => (api_request? ? section_json(@section, @current_user, session, []) : @section) }
      end
    end
  end

  # @API Edit a section
  # Modify an existing section.  See the documentation for {api:SectionsController#create create API action}.
  #
  # @returns Section
  def update
    params[:course_section] ||= {}
    if authorized_action(@section, @current_user, :update)
      params[:course_section][:sis_source_id] = params[:course_section].delete(:sis_section_id) if api_request?
      if sis_id = params[:course_section].delete(:sis_source_id)
        if sis_id != @section.sis_source_id && @section.root_account.grants_right?(@current_user, session, :manage_sis)
          if sis_id == ''
            @section.sis_source_id = nil
          else
            @section.sis_source_id = sis_id
          end
        end
      end
      respond_to do |format|
        if @section.update_attributes(params[:course_section])
          @context.touch
          flash[:notice] = t('section_updated', "Section successfully updated!")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => (api_request? ? section_json(@section, @current_user, session, []) : @section) }
        else
          flash[:error] = t('section_update_error', "Section update failed")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.errors, :status => :bad_request }
        end
      end
    end
  end

  # @API Get section information
  # Gets details about a specific section
  #
  # @returns Section
  def show
    if authorized_action(@section, @current_user, :read)
      respond_to do |format|
        format.html do
          add_crumb(@section.name, named_context_url(@context, :context_section_url, @section))
          @enrollments_count = @section.enrollments.not_fake.where(:workflow_state => 'active').count
          @completed_enrollments_count = @section.enrollments.not_fake.where(:workflow_state => 'completed').count
          @pending_enrollments_count = @section.enrollments.not_fake.where(:workflow_state => %w{invited pending}).count
          @student_enrollments_count = @section.enrollments.not_fake.where(:type => 'StudentEnrollment').count
          js_env(
            :PERMISSIONS => {
              :manage_students => @context.grants_right?(@current_user, session, :manage_students) || @context.grants_right?(@current_user, session, :manage_admin_users),
              :manage_account_settings => @context.account.grants_right?(@current_user, session, :manage_account_settings)
            })
        end
        format.json { render :json => section_json(@section, @current_user, session, []) }
      end
    end
  end

  # @API Delete a section
  # Delete an existing section.  Returns the former Section.
  #
  # @returns Section
  def destroy
    if authorized_action(@section, @current_user, :delete)
      respond_to do |format|
        if @section.enrollments.not_fake.empty?
          @section.destroy
          @context.touch
          flash[:notice] = t('section_deleted', "Course section successfully deleted!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => (api_request? ? section_json(@section, @current_user, session, []) : @section) }
        else
          flash[:error] = t('section_delete_not_allowed', "You can't delete a section that has enrollments")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => (api_request? ? { :message => "You can't delete a section that has enrollments" } : @section), :status => :bad_request }
        end
      end
    end
  end
end
