#
# Copyright (C) 2011 Instructure, Inc.
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
# @object Section
#     {
#       // The unique identifier for the section.
#       "id": 1,
#
#       // The name of the section.
#       "name": "Section A",
#
#       // The sis id of the section.
#       "sis_section_id": null,
#
#       // The unique identifier for the course the section belongs to
#       "course_id": 7,
#
#       // The unique identifier of the original course of a cross-listed section
#       "nonxlist_course_id": null
#     }
class SectionsController < ApplicationController
  before_filter :require_context

  include Api::V1::Section

  # @API List course sections
  # Returns the list of sections for this course.
  #
  # @argument include[] [optional, "students"] Associations to include with the group.
  # @argument include[] [optional, "avatar_url"] Include the avatar URLs for students returned.
  #
  # @returns [Section]
  def index
    if authorized_action(@context, @current_user, :read_roster)
      includes = Array(params[:include])

      result = @context.active_course_sections.map { |section| section_json(section, @current_user, session, includes) }

      render :json => result
    end
  end

  def create
    if authorized_action(@context.course_sections.new, @current_user, :create)
      @section = @context.course_sections.build(params[:course_section])
      respond_to do |format|
        if @section.save
          flash[:notice] = t('section_created', "Section successfully created!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_creation_failed', "Section creation failed")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def crosslist_check
    @section = @context.course_sections.find(params[:section_id])
    course_id = params[:new_course_id]
    # cross-listing should only be allowed within the same root account
    @new_course = @section.root_account.all_courses.find_by_id(course_id) if course_id.present?
    @new_course ||= @section.root_account.all_courses.find_by_sis_source_id(course_id) if course_id.present?
    allowed = @new_course && @section.grants_right?(@current_user, session, :update) && @new_course.grants_right?(@current_user, session, :manage_admin_users)
    res = {:allowed => !!allowed}
    if allowed
      @account = @new_course.account
      res[:section] = @section
      res[:course] = @new_course
      res[:account] = @account
    end
    render :json => res.to_json(:include_root => false)
  end
  
  def crosslist
    @section = @context.course_sections.find(params[:section_id])
    course_id = params[:new_course_id]
    @new_course = Course.find_by_id(course_id) if course_id.present?
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.crosslist_to_course @new_course
      respond_to do |format|
        flash[:notice] = t('section_crosslisted', "Section successfully cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => @section.to_json }
      end
    end
  end
  
  def uncrosslist
    @section = @context.course_sections.find(params[:section_id])
    @new_course = @section.nonxlist_course
    if authorized_action(@section, @current_user, :update) && authorized_action(@new_course, @current_user, :manage)
      @section.uncrosslist
      respond_to do |format|
        flash[:notice] = t('section_decrosslisted', "Section successfully de-cross-listed!")
        format.html { redirect_to named_context_url(@new_course, :context_section_url, @section.id) }
        format.json { render :json => @section.to_json }
      end
    end
  end
  
  def update
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :update)
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
          flash[:notice] = t('section_updated', "Section successfully updated!")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_update_error', "Section update failed")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # @API Get section information
  # Gets details about a specific section
  #
  # @returns Section
  def show
    @section = @context if @context.is_a?(CourseSection)
    @section ||= api_request? ? api_find(@context.course_sections, params[:id]) :
        @context.course_sections.find(params[:id])
    return unless authorized_action(@section, @current_user, :read)

    respond_to do |format|
      format.html do
        add_crumb(@section.name, named_context_url(@context, :context_section_url, @section))
        @enrollments_count = @section.enrollments.not_fake.scoped(:conditions => { :workflow_state => 'active' }).count
        @completed_enrollments_count = @section.enrollments.not_fake.scoped(:conditions => { :workflow_state => 'completed' }).count
        @pending_enrollments_count = @section.enrollments.not_fake.scoped(:conditions => { :workflow_state => %w{invited pending} }).count
        @student_enrollments_count = @section.enrollments.not_fake.scoped(:conditions => { :type => 'StudentEnrollment' }).count
        js_env(
          :PERMISSIONS => {
            :manage_students => @context.grants_right?(@current_user, session, :manage_students) || @context.grants_right?(@current_user, session, :manage_admin_users),
            :manage_account_settings => @context.account.grants_right?(@current_user, session, :manage_account_settings)
          })
      end
      format.json { render :json => section_json(@section, @current_user, session, []) }
    end
  end

  def destroy
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :delete)
      respond_to do |format|
        if @section.enrollments.not_fake.empty?
          @section.destroy
          flash[:notice] = t('section_deleted', "Course section successfully deleted!")
          format.html { redirect_to course_settings_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = t('section_delete_not_allowed', "You can't delete a section that has enrollments")
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json, :status => :bad_request  }
        end
      end
    end
  end
end
