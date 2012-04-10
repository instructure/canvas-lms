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

class GettingStartedController < ApplicationController

  before_filter :require_user
  before_filter :require_course_creation_auth, :except => [:teacherless]
  before_filter :set_course, :except => [:teacherless]
  
  before_filter :set_no_left_side
  def set_no_left_side; @show_left_side = false; end
  protected :set_no_left_side
  
  def require_course_creation_auth
    authorized_action(@domain_root_account.manually_created_courses_account, @current_user, [:create_courses, :manage_courses])
  end
  protected :require_course_creation_auth
  
  def index
    render :action => :name
  end
  
  def teacherless
  end

  def assignments
    @context.assert_assignment_group rescue nil
    @groups = @context.assignment_groups.active.find(:all, :order => 'position, name')
    @assignment_groups = @groups
    @assignments = @context.assignments.active.find(:all, :order => 'due_at, title')
    respond_to do |format|
      format.html
      format.json { render :json => @assignments.to_json, :status => :ok}
    end
  end

  def students
    @students = @context.detailed_enrollments.select{ |e|
      e.type == 'StudentEnrollment' && e.active?
    }.sort_by{ |e|
      e.user.sortable_name.downcase
    }
    respond_to do |format|
      format.html
      format.json { render :json => @students.to_json(:methods => :email), :status => :ok}
    end
  end
  
  def finalize
    session[:saved_course_uuid] = @context.uuid
    session[:claim_course_uuid] = @context.uuid
    session[:course_uuid] = nil
    if @current_user
      redirect_to course_url(@context)
    else
      session[:return_to] = course_url(@context)
      flash[:notice] = t :course_created_notice, "Course created! You'll need to log in or register to claim this course."
      redirect_to course_url(@context)
    end
  end
  
  def setup
    @students = @context.students.find(:all, :order => :name)
    @assignments = @context.assignments.active.find(:all, :order => 'due_at, title')
  end

  def name
    # Just needs course to set the name of the course.
    respond_to do |format|
      format.html
      format.json { render :json => @context.to_json, :status => :ok}
    end
  end
    
  # Sets the @context and session[:course_uuid] for every method in this controller
  def set_course
    # create_unique finds or creates, but always returns a context
    session[:course_uuid] = nil if params[:fresh]
    # TODO i18n
    @context = Course.create_unique(session[:course_uuid], session[:course_creation_account_id] || @domain_root_account.manually_created_courses_account.id, @domain_root_account.id)
    if session[:course_uuid] != @context.uuid && @current_user
      if params[:teacherless]
        @context.account = @domain_root_account.sub_accounts.find_or_create_by_name("Student-Generated Courses")
        @context.root_account = @domain_root_account
        @context.offer
        @context.enroll_user(@current_user, 'StudentEnrollment', :enrollment_state => 'active')
      else
        @context.claim_with_teacher(@current_user)
      end
      session[:course_uuid] = @context.uuid
    end
    if params[:fresh]
      redirect_to getting_started_url
      return false
    end
  end
  protected :set_course
  
end
