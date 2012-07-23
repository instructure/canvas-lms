#
# Copyright (C) 2012 Instructure, Inc.
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
class AssignmentsController < ApplicationController
  include Api::V1::Assignment

  include GoogleDocs
  before_filter :require_context
  add_crumb(proc { t '#crumbs.assignments', "Assignments" }, :except => [:destroy, :syllabus, :index]) { |c| c.send :course_assignments_path, c.instance_variable_get("@context") }
  before_filter { |c| c.active_tab = "assignments" }
  
  def index
    if @context == @current_user || authorized_action(@context, @current_user, :read)
      get_all_pertinent_contexts
      get_sorted_assignments
      add_crumb(t('#crumbs.assignments', "Assignments"), (@just_viewing_one_course ? named_context_url(@context, :context_assignments_url) : "/assignments" ))
      @context= (@just_viewing_one_course ? @context : @current_user)
      return if @just_viewing_one_course && !tab_enabled?(@context.class::TAB_ASSIGNMENTS)

      respond_to do |format|
        if @contexts.empty?
          if @context
            format.html { redirect_to @context == @current_user ? dashboard_url : named_context_url(@context, :context_url) }
          else
            format.html { redirect_to root_url }
          end
        elsif @just_viewing_one_course && @context.assignments.new.grants_right?(@current_user, session, :update)
          format.html
        else
          @current_user_submissions ||= @current_user && @current_user.submissions.scoped(:select => 'id, assignment_id, score, workflow_state', :conditions => {:assignment_id => @upcoming_assignments.map(&:id)}) 
          format.html { render :action => "student_index" }
        end
        # TODO: eager load the rubric associations
        format.json { render :json => @assignments.to_json(:include => [ :rubric_association, :rubric ]) }
      end
    end
  end
  
  def show
    @assignment ||= @context.assignments.find(params[:id])
    if @assignment.deleted?
      respond_to do |format|
        flash[:notice] = t 'notices.assignment_delete', "This assignment has been deleted"
        format.html { redirect_to named_context_url(@context, :context_assignments_url) }
      end
      return
    end
    if authorized_action(@assignment, @current_user, :read)
      @context.require_assignment_group
      @assignment_groups = @context.assignment_groups.active
      if !@assignment.new_record? && !@assignment_groups.map(&:id).include?(@assignment.assignment_group_id)
        @assignment.assignment_group = @assignment_groups.first
        @assignment.save
      end
      @locked = @assignment.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
      @unlocked = !@locked || @assignment.grants_rights?(@current_user, session, :update)[:update]
      @assignment_module = ContextModuleItem.find_tag_with_preferred([@assignment], params[:module_item_id])
      @assignment.context_module_action(@current_user, :read) if @unlocked && !@assignment.new_record?
      if @assignment.grants_right?(@current_user, session, :grade)
        visible_student_ids = @context.enrollments_visible_to(@current_user).find(:all, :select => 'user_id').map(&:user_id)
        @current_student_submissions = @assignment.submissions.scoped(:conditions => "submissions.submission_type IS NOT NULL").select{|s| visible_student_ids.include?(s.user_id) }
      end
      if @assignment.grants_right?(@current_user, session, :read_own_submission) && @context.grants_right?(@current_user, session, :read_grades)
        @current_user_submission = @assignment.submissions.find_by_user_id(@current_user.id) if @current_user
        @current_user_submission = nil if @current_user_submission && !@current_user_submission.grade && !@current_user_submission.submission_type
        @current_user_rubric_assessment = @assignment.rubric_association.rubric_assessments.find_by_user_id(@current_user.id) if @current_user && @assignment.rubric_association
        @current_user_submission.send_later(:context_module_action) if @current_user_submission
      end
      if @assignment.submission_types && @assignment.submission_types.match(/online_upload/)
        # TODO: make this happen asynchronously via ajax, and only if the user selects the google docs tab
        @google_docs = google_doc_list(nil, @assignment.allowed_extensions) rescue nil
      end
      
      if @assignment.new_record?
        add_crumb(t('crumbs.new_assignment', "New Assignment"), request.url)
      else
        add_crumb(@assignment.title, named_context_url(@context, :context_assignment_url, @assignment))
      end
      log_asset_access(@assignment, "assignments", @assignment_group) unless @assignment.new_record?
      respond_to do |format|
        if @assignment.submission_types == 'online_quiz' && @assignment.quiz && !@editing
          format.html { redirect_to named_context_url(@context, :context_quiz_url, @assignment.quiz.id) }
        elsif @assignment.submission_types == 'discussion_topic' && @assignment.discussion_topic && !@editing && @assignment.discussion_topic.grants_right?(@current_user, session, :read)
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @assignment.discussion_topic.id) }
        elsif @assignment.submission_types == 'attendance' && !@editing
          format.html { redirect_to named_context_url(@context, :context_attendance_url, :anchor => "assignment/#{@assignment.id}") }
        elsif @assignment.submission_types == 'external_tool' && !@editing && @assignment.external_tool_tag && @unlocked
          format.html { content_tag_redirect(@context, @assignment.external_tool_tag, :context_url) }
        else
          format.html { render :action => 'show' }
        end
        format.json { render :json => @assignment.to_json(:permissions => {:user => @current_user, :session => session}) }
      end
    end
  end
  
  def rubric
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :read)
      render :partial => 'shared/assignment_rubric_dialog'
    end
  end
  
  def assign_peer_reviews
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      cnt = params[:peer_review_count].to_i
      @assignment.peer_review_count = cnt if cnt > 0
      @assignment.assign_peer_reviews
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url, @assignment.id) }
      end
    end
  end
  
  def assign_peer_review
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @student = @context.students_visible_to(@current_user).find params[:reviewer_id]
    @reviewee = @context.students_visible_to(@current_user).find params[:reviewee_id]
    if authorized_action(@assignment, @current_user, :grade)
      @request = @assignment.assign_peer_review(@student, @reviewee)
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url, @assignment.id) }
        format.json { render :json => @request.to_json(:methods => :asset_user_name) }
      end
    end
  end
  
  def remind_peer_review
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      @request = AssessmentRequest.find_by_id(params[:id]) if params[:id].present?
      respond_to do |format|
        if @request.asset.assignment == @assignment && @request.send_reminder!
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => @request.to_json }
        else
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => {:errors => {:base => t('errors.reminder_failed', "Reminder failed")}}.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def delete_peer_review
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      @request = AssessmentRequest.find_by_id(params[:id]) if params[:id].present?
      respond_to do |format|
        if @request.asset.assignment == @assignment && @request.destroy
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => @request.to_json }
        else
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => {:errors => {:base => t('errors.delete_reminder_failed', "Delete failed")}}.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def peer_reviews
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      if !@assignment.has_peer_reviews?
        redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
        return
      end
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @submissions = @assignment.submissions.include_assessment_requests
    end
  end
  
  def syllabus
    add_crumb t '#crumbs.syllabus', "Syllabus"
    active_tab = "Syllabus"
    if authorized_action(@context.assignments.new, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_SYLLABUS)
      @groups = @context.assignment_groups.active.find(:all, :order => 'position, name')
      @assignment_groups = @groups
      @events = @context.events_for(@current_user)
      @undated_events = @events.select {|e| e.start_at == nil}
      @dates = (@events.select {|e| e.start_at != nil}).map {|e| e.start_at.to_date}.uniq.sort.sort
      
      log_asset_access("syllabus:#{@context.asset_string}", "syllabus", 'other')
      respond_to do |format|
        format.html
      end
    end
  end

  def toggle_mute
    return nil unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
    @assignment = @context.assignments.active.find(params[:assignment_id])
    method = if params[:status] == "true" then :mute! else :unmute! end

    respond_to do |format|
      if @assignment && @assignment.send(method)
        format.json { render :json => @assignment.to_json }
      else
        format.json { render :json => @assignment.to_json, :status => :bad_request }
      end
    end
  end

  def new
    @assignment ||= Assignment.new(:context => @context)
    @assignment.title = params[:title]
    @assignment.due_at = params[:due_at]
    @assignment.points_possible = params[:points_possible]
    @assignment.assignment_group_id = params[:assignment_group_id]
    @assignment.submission_types = params[:submission_types]
    if authorized_action(@assignment, @current_user, :create)
      @assignment.title = params[:title]
      @assignment.due_at = params[:due_at]
      @assignment.assignment_group_id = params[:assignment_group_id]
      @assignment.submission_types = params[:submission_types]
      @editing = true
      params[:redirect_to] ||= named_context_url(@context, :context_assignments_url)
      show
    end
  end
  
  def create
    params[:assignment][:time_zone_edited] = Time.zone.name if params[:assignment]
    group = get_assignment_group(params[:assignment])
    @assignment ||= @context.assignments.build(params[:assignment])
    @assignment.workflow_state = "available"
    @assignment.content_being_saved_by(@current_user)
    @assignment.assignment_group = group if group
    # if no due_at was given, set it to 11:59 pm in the creator's time zone
    @assignment.infer_due_at
    if authorized_action(@assignment, @current_user, :create)
      respond_to do |format|
        if @assignment.save
          flash[:notice] = t 'notices.created', "Assignment was successfully created."
          format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
          format.json { render :json => @assignment.to_json(:permissions => {:user => @current_user, :session => session}), :status => :created}
        else
          format.html { render :action => "new" }
          format.json { render :json => @assignment.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def edit
    @assignment = @context.assignments.active.find(params[:id])
    if authorized_action(@assignment, @current_user, :update_content)
      @editing = true
      params[:return_to] = nil
      if @assignment.grants_right?(@current_user, session, :update)
        @assignment.title = params[:title] if params[:title]
        @assignment.due_at = params[:due_at] if params[:due_at]
        @assignment.submission_types = params[:submission_types] if params[:submission_types]
        @assignment.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      end
      show
    end
  end

  def update
    @assignment = @context.assignments.find(params[:id])
    if authorized_action(@assignment, @current_user, :update_content)
      params[:assignment][:time_zone_edited] = Time.zone.name if params[:assignment]
      if !@assignment.grants_rights?(@current_user, session, :update)[:update]
        p = {}
        p[:description] = params[:assignment][:description]
        params[:assignment] = p
      else
        params[:assignment] ||= {}
        @assignment.updating_user = @current_user
        if params[:assignment][:default_grade]
          params[:assignment][:overwrite_existing_grades] = (params[:assignment][:overwrite_existing_grades] == "1")
          @assignment.set_default_grade(params[:assignment])
          render :json => @assignment.submissions.to_json(:include => :quiz_submission)
          return
        end
        params[:assignment].delete :default_grade
        params[:assignment].delete :overwrite_existing_grades
        if params[:publish]
          @assignment.workflow_state = 'published'
        elsif params[:unpublish]
          @assignment.workflow_state = 'available'
        end
        if params[:assignment_type] == "quiz"
          params[:assignment][:submission_types] = "online_quiz"
        elsif params[:assignment_type] == "attendance"
          params[:assignment][:submission_types] = "attendance"
        elsif params[:assignment_type] == "discussion_topic"
          params[:assignment][:submission_types] = "discussion_topic"
        elsif params[:assignment_type] == "external_tool"
          params[:assignment][:submission_types] = "external_tool"
        end
      end
      respond_to do |format|
        @assignment.content_being_saved_by(@current_user)
        group = get_assignment_group(params[:assignment])
        @assignment.assignment_group = group if group
        if @assignment.update_attributes(params[:assignment])
          log_asset_access(@assignment, "assignments", @assignment_group, 'participate')
          @assignment.context_module_action(@current_user, :contributed)
          @assignment.reload
          flash[:notice] = t 'notices.updated', "Assignment was successfully updated."
          format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment) }
          format.json { render :json => @assignment.to_json(:permissions => {:user => @current_user, :session => session}, :methods => [:readable_submission_types], :include => [:quiz, :discussion_topic]), :status => :ok }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @assignment.errors.to_json, :status => :bad_request }
        end
      end
    end
  end

  # @API Delete an assignment
  #
  # Delete the given assignment.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/assignments/<assignment_id> \ 
  #          -X DELETE \ 
  #          -H 'Authorization: Bearer <token>'
  def destroy
    @assignment = @context.assignments.active.find(params[:id])
    if authorized_action(@assignment, @current_user, :delete)
      @assignment.destroy

      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url)) }
        format.json { render :json => assignment_json(@assignment, @current_user, session) }
      end
    end
  end
  
  protected

  def get_assignment_group(assignment_params)
    return unless assignment_params
    if (group_id = assignment_params.delete(:assignment_group_id)).present?
      group = @context.assignment_groups.find(group_id)
    end
  end
end
