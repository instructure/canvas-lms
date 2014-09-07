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
  include Api::V1::Section
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride
  include Api::V1::AssignmentGroup
  include Api::V1::Outcome
  include Api::V1::ExternalTools

  include KalturaHelper
  before_filter :require_context
  add_crumb(proc { t '#crumbs.assignments', "Assignments" }, :except => [:destroy, :syllabus, :index]) { |c| c.send :course_assignments_path, c.instance_variable_get("@context") }
  before_filter { |c| c.active_tab = "assignments" }
  before_filter :normalize_title_param, :only => [:new, :edit]

  def index
    return old_index if @context == @current_user || !@context.feature_enabled?(:draft_state)

    if authorized_action(@context, @current_user, :read)
      return unless tab_enabled?(@context.class::TAB_ASSIGNMENTS)
      add_crumb(t('#crumbs.assignments', "Assignments"), named_context_url(@context, :context_assignments_url))

      # It'd be nice to do this as an after_create, but it's not that simple
      # because of course import/copy.
      @context.require_assignment_group

      permissions = @context.rights_status(@current_user, :manage_assignments, :manage_grades)
      permissions[:manage] = permissions[:manage_assignments]
      js_env({
        :URLS => {
          :new_assignment_url => new_polymorphic_url([@context, :assignment]),
          :course_url => api_v1_course_url(@context),
          :sort_url => reorder_course_assignment_groups_url,
          :assignment_sort_base_url => course_assignment_groups_url,
          :context_modules_url => api_v1_course_context_modules_path(@context),
          :course_student_submissions_url => api_v1_course_student_submissions_url(@context)
        },
        :PERMISSIONS => permissions,
        :assignment_menu_tools => external_tools_display_hashes(:assignment_menu)
      })


      respond_to do |format|
        format.html do
          @padless = true
          render :action => :new_index
        end
      end
    end
  end

  def old_index
    return redirect_to(dashboard_url) if @context == @current_user
    if authorized_action(@context, @current_user, :read)
      get_all_pertinent_contexts  # NOTE: this crap is crazy.  can we get rid of it?
      get_sorted_assignments
      add_crumb(t('#crumbs.assignments', "Assignments"), (@just_viewing_one_course ? named_context_url(@context, :context_assignments_url) : "/assignments" ))
      @context = (@just_viewing_one_course ? @context : @current_user)
      return if @just_viewing_one_course && !tab_enabled?(@context.class::TAB_ASSIGNMENTS)

      respond_to do |format|
        if @contexts.empty?
          if @context
            format.html { redirect_to @context == @current_user ? dashboard_url : named_context_url(@context, :context_url) }
          else
            format.html { redirect_to root_url }
          end
        elsif @just_viewing_one_course && @context.assignments.scoped.new.grants_right?(@current_user, session, :update)
          format.html {
            render :action => :index
          }
        else
          @current_user_submissions ||= @current_user && @current_user.submissions.
              select([:id, :assignment_id, :score, :workflow_state]).
              where(:assignment_id => @upcoming_assignments)
          js_env(:submissions_hash => @submissions_hash)
          format.html { render :action => :student_index }
        end
        # TODO: eager load the rubric associations
        format.json { render :json => @assignments.map{ |a| a.as_json(include: [:rubric_association, :rubric]) } }
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

      if @context.feature_enabled?(:differentiated_assignments) && @current_user && @assignment && !@assignment.visible_to_user?(@current_user)
        respond_to do |format|
          flash[:error] = t 'notices.assignment_not_availible', "The assignment you requested is not availible to your course section."
          format.html { redirect_to named_context_url(@context, :context_assignments_url) }
        end
        return
      end

      @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @current_user)
      @assignment.ensure_assignment_group

      if @assignment.submission_types.include?("online_upload") || @assignment.submission_types.include?("online_url")
        @external_tools = ContextExternalTool.all_tools_for(@context, :user => @current_user, :type => :homework_submission)
      else
        @external_tools = []
      end

      js_env({
        :ROOT_OUTCOME_GROUP => outcome_group_json(@context.root_outcome_group, @current_user, session),
        :DRAFT_STATE => @context.feature_enabled?(:draft_state),
        :COURSE_ID => @context.id,
        :ASSIGNMENT_ID => @assignment.id,
        :EXTERNAL_TOOLS => external_tools_json(@external_tools, @context, @current_user, session)
      })

      @locked = @assignment.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
      @locked.delete(:lock_at) if @locked.is_a?(Hash) && @locked.has_key?(:unlock_at) # removed to allow proper translation on show page
      @unlocked = !@locked || @assignment.grants_right?(@current_user, session, :update)
      @assignment.context_module_action(@current_user, :read) if @unlocked && !@assignment.new_record?

      if @assignment.grants_right?(@current_user, session, :grade)
        visible_student_ids = @context.enrollments_visible_to(@current_user).pluck(:user_id)
        @current_student_submissions = @assignment.submissions.where("submissions.submission_type IS NOT NULL").where(:user_id => visible_student_ids).all
      end

      if @assignment.grants_right?(@current_user, session, :read_own_submission) && @context.grants_right?(@current_user, session, :read_grades)
        @current_user_submission = @assignment.submissions.find_by_user_id(@current_user.id) if @current_user
        @current_user_submission = nil if @current_user_submission && !@current_user_submission.grade && !@current_user_submission.submission_type
        @current_user_rubric_assessment = @assignment.rubric_association.rubric_assessments.find_by_user_id(@current_user.id) if @current_user && @assignment.rubric_association
        @current_user_submission.send_later(:context_module_action) if @current_user_submission
      end

      begin
        google_docs = google_docs_connection
        @google_docs_token = google_docs.retrieve_access_token
      rescue GoogleDocs::NoTokenError
        #do nothing
      end

      add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
      log_asset_access(@assignment, "assignments", @assignment.assignment_group)

      @assignment_menu_tools = external_tools_display_hashes(:assignment_menu)

      respond_to do |format|
        if @assignment.submission_types == 'online_quiz' && @assignment.quiz
          format.html { redirect_to named_context_url(@context, :context_quiz_url, @assignment.quiz.id) }
        elsif @assignment.submission_types == 'discussion_topic' && @assignment.discussion_topic && @assignment.discussion_topic.grants_right?(@current_user, session, :read)
          format.html { redirect_to named_context_url(@context, :context_discussion_topic_url, @assignment.discussion_topic.id) }
        elsif @assignment.submission_types == 'attendance'
          format.html { redirect_to named_context_url(@context, :context_attendance_url, :anchor => "assignment/#{@assignment.id}") }
        elsif @assignment.submission_types == 'external_tool' && @assignment.external_tool_tag && @unlocked
          tag_type = params[:module_item_id].present? ? :modules : :assignments
          format.html { content_tag_redirect(@context, @assignment.external_tool_tag, :context_url, tag_type) }
        else
          format.html { render :action => 'show' }
        end
        format.json { render :json => @assignment.as_json(:permissions => {:user => @current_user, :session => session}) }
      end
    end
  end

  def list_google_docs
    assignment ||= @context.assignments.find(params[:id])
    # prevent masquerading users from accessing google docs
    if assignment.allow_google_docs_submission? && @real_current_user.blank?
      docs = {}
      begin
        google_docs = google_docs_connection
        docs = google_docs.list_with_extension_filter(assignment.allowed_extensions)
      rescue GoogleDocs::NoTokenError
        #do nothing
      rescue => e
        ErrorReport.log_exception(:oauth, e)
        raise e
      end
      respond_to do |format|
        format.json { render :json => docs.to_hash }
      end
    else
      error_object = {:errors =>
        {:base => t('errors.google_docs_masquerade_rejected', "Unable to connect to Google Docs as a masqueraded user.")}
      }
      respond_to do |format|
        format.json { render :json => error_object, :status => :bad_request }
      end
    end
  end

  def rubric
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @root_outcome_group = outcome_group_json(@context.root_outcome_group, @current_user, session).to_json
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
        format.json { render :json => @request.as_json(:methods => :asset_user_name) }
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
          format.json { render :json => @request }
        else
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => {:errors => {:base => t('errors.reminder_failed', "Reminder failed")}}, :status => :bad_request }
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
          format.json { render :json => @request }
        else
          format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
          format.json { render :json => {:errors => {:base => t('errors.delete_reminder_failed', "Delete failed")}}, :status => :bad_request }
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

      student_scope = if @assignment.differentiated_assignments_applies?
                        @context.students_visible_to(@current_user).able_to_see_assignment_in_course_with_da(@assignment.id, @context.id)
                      else
                        @context.students_visible_to(@current_user)
                      end

      @students = student_scope.uniq.order_by_sortable_name
      @submissions = @assignment.submissions.include_assessment_requests
    end
  end

  def syllabus
    add_crumb t '#crumbs.syllabus', "Syllabus"
    active_tab = "Syllabus"
    if authorized_action(@context, @current_user, [:read, :read_syllabus])
      return unless tab_enabled?(@context.class::TAB_SYLLABUS)
      @groups = @context.assignment_groups.active.order(:position, AssignmentGroup.best_unicode_collation_key('name')).all
      @assignment_groups = @groups
      @events = @context.events_for(@current_user)
      @undated_events = @events.select {|e| e.start_at == nil}
      @dates = (@events.select {|e| e.start_at != nil}).map {|e| e.start_at.to_date}.uniq.sort.sort
      if @context.grants_right?(@current_user, session, :read)
        @syllabus_body = api_user_content(@context.syllabus_body, @context)
      else
        # the requesting user may not have :read if the course syllabus is public, in which
        # case, we pass nil as the user so verifiers are added to links in the syllabus body
        # (ability for the user to read the syllabus was checked above as :read_syllabus)
        @syllabus_body = api_user_content(@context.syllabus_body, @context, nil)
      end

      hash = { :CONTEXT_ACTION_SOURCE => :syllabus }
      append_sis_data(hash)
      js_env(hash)

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
        format.json { render :json => @assignment }
      else
        format.json { render :json => @assignment, :status => :bad_request }
      end
    end
  end

  def create
    params[:assignment][:time_zone_edited] = Time.zone.name if params[:assignment]
    group = get_assignment_group(params[:assignment])
    @assignment ||= @context.assignments.build(params[:assignment])
    @assignment.workflow_state ||= @context.feature_enabled?(:draft_state) ? "unpublished" : "published"
    @assignment.post_to_sis ||= @context.feature_enabled?(:post_to_sis) ? true : false
    @assignment.updating_user = @current_user
    @assignment.content_being_saved_by(@current_user)
    @assignment.assignment_group = group if group
    # if no due_at was given, set it to 11:59 pm in the creator's time zone
    @assignment.infer_times
    if authorized_action(@assignment, @current_user, :create)
      respond_to do |format|
        if @assignment.save
          flash[:notice] = t 'notices.created', "Assignment was successfully created."
          format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
          format.json { render :json => @assignment.as_json(:permissions => {:user => @current_user, :session => session}), :status => :created}
        else
          format.html { render :action => "new" }
          format.json { render :json => @assignment.errors, :status => :bad_request }
        end
      end
    end
  end

  def new
    @assignment ||= @context.assignments.scoped.new
    @assignment.workflow_state = 'unpublished' if @context.feature_enabled?(:draft_state)
    add_crumb t :create_new_crumb, "Create new"

    if params[:submission_types] == 'online_quiz'
      redirect_to new_course_quiz_url(@context, index_edit_params)
    elsif params[:submission_types] == 'discussion_topic'
      redirect_to new_polymorphic_url([@context, :discussion_topic], index_edit_params)
    else
      edit
    end
  end

  def edit
    @assignment ||= @context.assignments.active.find(params[:id])
    if authorized_action(@assignment, @current_user, @assignment.new_record? ? :create : :update)
      @assignment.title = params[:title] if params[:title]
      @assignment.due_at = params[:due_at] if params[:due_at]
      @assignment.points_possible = params[:points_possible] if params[:points_possible]
      @assignment.submission_types = params[:submission_types] if params[:submission_types]
      @assignment.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      @assignment.ensure_assignment_group(false)
      @assignment.post_to_sis = params[:post_to_sis] if params[:post_to_sis]
      if @assignment.submission_types == 'online_quiz' && @assignment.quiz
        return redirect_to edit_course_quiz_url(@context, @assignment.quiz, index_edit_params)
      elsif @assignment.submission_types == 'discussion_topic' && @assignment.discussion_topic
        return redirect_to edit_polymorphic_url([@context, @assignment.discussion_topic], index_edit_params)
      end

      assignment_groups = @context.assignment_groups.active
      group_categories = @context.group_categories.
        select { |c| !c.student_organized? }.
        map { |c| { :id => c.id, :name => c.name } }

      json_for_assignment_groups = assignment_groups.map do |group|
        assignment_group_json(group, @current_user, session, [], {stringify_json_ids: true})
      end

      hash = {
        :ASSIGNMENT_GROUPS => json_for_assignment_groups,
        :GROUP_CATEGORIES => group_categories,
        :KALTURA_ENABLED => !!feature_enabled?(:kaltura),
        :POST_TO_SIS => @context.feature_enabled?(:post_grades),
        :SECTION_LIST => (@context.course_sections.active.map { |section|
          {:id => section.id, :name => section.name }
        }),
        :ASSIGNMENT_OVERRIDES =>
          (assignment_overrides_json(
            @assignment.overrides_for(@current_user)
            )),
        :ASSIGNMENT_INDEX_URL => polymorphic_url([@context, :assignments]),
        :DIFFERENTIATED_ASSIGNMENTS_ENABLED => @context.feature_enabled?(:differentiated_assignments)
      }

      hash[:ASSIGNMENT] = assignment_json(@assignment, @current_user, session, override_dates: false)
      hash[:ASSIGNMENT][:has_submitted_submissions] = @assignment.has_submitted_submissions?
      hash[:URL_ROOT] = polymorphic_url([:api_v1, @context, :assignments])
      hash[:CANCEL_TO] = @assignment.new_record? ? polymorphic_url([@context, :assignments]) : polymorphic_url([@context, @assignment])
      hash[:CONTEXT_ID] = @context.id
      hash[:CONTEXT_ACTION_SOURCE] = :assignments
      append_sis_data(hash)
      js_env(hash)
      @padless = true
      render :action => "edit"
    end
  end

  def update
    @assignment = @context.assignments.find(params[:id])
    if authorized_action(@assignment, @current_user, :update)
      params[:assignment][:time_zone_edited] = Time.zone.name if params[:assignment]
      params[:assignment] ||= {}
      @assignment.post_to_sis = params[:assignment][:post_to_sis]
      @assignment.updating_user = @current_user
      if params[:assignment][:default_grade]
        params[:assignment][:overwrite_existing_grades] = (params[:assignment][:overwrite_existing_grades] == "1")
        @assignment.set_default_grade(params[:assignment])
        render :json => @assignment.submissions.map{ |s| s.as_json(:include => :quiz_submission) }
        return
      end
      params[:assignment].delete :default_grade
      params[:assignment].delete :overwrite_existing_grades
      if params[:publish]
        @assignment.workflow_state = 'published'
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
          format.json { render :json => @assignment.as_json(:permissions => {:user => @current_user, :session => session}, :include => [:quiz, :discussion_topic]), :status => :ok }
        else
          format.html { render :action => "edit" }
          format.json { render :json => @assignment.errors, :status => :bad_request }
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
  # @returns Assignment
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

  def normalize_title_param
    if title = params.delete(:name)
      params[:title] = title
    end
  end

  def index_edit_params
    params.slice(*[:title, :due_at, :points_possible, :assignment_group_id])
  end

end
