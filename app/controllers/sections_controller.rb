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

class SectionsController < ApplicationController
  before_filter :require_context
  
  def create
    if authorized_action(@context.course_sections.new, @current_user, :create)
      @section = @context.course_sections.build(params[:course_section])
      respond_to do |format|
        if @section.save
          flash[:notice] = "Section successfully created!"
          format.html { redirect_to course_details_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = "Section creation failed"
          format.html { redirect_to course_details_url(@context) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def update
    @section = @context.course_sections.find(params[:id])
    params[:course_section][:name]
    if authorized_action(@section, @current_user, :update)
      respond_to do |format|
        if @section.update_attributes(params[:course_section])
          flash[:notice] = "Section successfully updated!"
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = "Section update failed"
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def show
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@context, @current_user, :manage_students)
      add_crumb(@section.name, named_context_url(@context, :context_section_url, @section))
      @enrollments = @section.enrollments.sort_by{|e| e.user.sortable_name }
      @current_enrollments = @enrollments.select{|e| !e.completed? }
      @completed_enrollments = @enrollments.select{|e| e.completed? }
    end
  end
  
  def destroy
    @section = @context.course_sections.find(params[:id])
    if authorized_action(@section, @current_user, :delete)
      respond_to do |format|
        if @section.enrollments.empty?
          @section.destroy
          flash[:notice] = "Course section successfully deleted!"
          format.html { redirect_to course_details_url(@context) }
          format.json { render :json => @section.to_json }
        else
          flash[:error] = "You can't delete a section that has enrollments"
          format.html { redirect_to course_section_url(@context, @section) }
          format.json { render :json => @section.to_json, :status => :bad_request  }
        end
      end
    end
  end
  
  
end
