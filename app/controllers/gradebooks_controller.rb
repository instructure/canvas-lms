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

class GradebooksController < ApplicationController
  include ActionView::Helpers::NumberHelper

  before_filter :require_context, :except => :public_feed

  add_crumb("Grades", :except => :public_feed) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_filter { |c| c.active_tab = "grades" }

  def grade_summary
    # do this as the very first thing, if the current user is a teacher in the course and they are not trying to view another user's grades, redirect them to the gradebook
    if (@context.grants_right?(@current_user, nil, :manage_grades) || @context.grants_right?(@current_user, nil, :view_all_grades)) && !params[:id]
      redirect_to_appropriate_gradebook_version
      return
    end

    @observed_students = ObserverEnrollment.observed_students(@context, @current_user)

    # always use id if given
    if params[:id]
      @student_enrollment = @context.all_student_enrollments.find_by_user_id(params[:id])
    # otherwise try to find an observed student
    elsif @observed_students.present?
      # be consistent about which student we return by default
      @student_enrollment = (@observed_students.to_a.sort_by {|e| e[0].sortable_name}.first)[1].first
    # or just fall back to @current_user
    else
      @student_enrollment = @context.all_student_enrollments.find_by_user_id(@current_user.id)
    end

    @student = @student_enrollment && @student_enrollment.user
    if !@student || !@student_enrollment
      authorized_action(nil, @current_user, :permission_fail)
      return
    end
    if authorized_action(@student_enrollment, @current_user, :read_grades)
      log_asset_access("grades:#{@context.asset_string}", "grades", "other")
      respond_to do |format|
        if @student
          add_crumb(@student.name, named_context_url(@context, :context_student_grades_url, @student.id))

          @groups = @context.assignment_groups.active.all
          @assignments = @context.assignments.active.gradeable.find(:all, :order => 'due_at, title')
          groups_assignments =
            groups_as_assignments(@groups, :out_of_final => true, :exclude_total => @context.settings[:hide_final_grade])
          @no_calculations = groups_assignments.empty?
          @assignments.concat(groups_assignments)
          @submissions = @context.submissions.find(:all, :conditions => ['user_id = ?', @student.id], :include => [ :submission_comments, :rubric_assessments ])
          # pre-cache the assignment group for each assignment object
          @assignments.each { |a| a.assignment_group = @groups.find { |g| g.id == a.assignment_group_id } }
          # Yes, fetch *all* submissions for this course; otherwise the view will end up doing a query for each
          # assignment in order to calculate grade distributions
          @all_submissions = @context.submissions.all(:select => "submissions.assignment_id, submissions.score, submissions.grade, submissions.quiz_submission_id")
          @courses_with_grades = @student.available_courses.select{|c| c.grants_right?(@student, nil, :participate_as_student)}
          format.html { render :action => 'grade_summary' }
        else
          format.html { render :action => 'grade_summary_list' }
        end
      end
    end
  end

  def grading_rubrics
    @rubric_contexts = @context.rubric_contexts(@current_user)
    if params[:context_code]
      context = @rubric_contexts.detect{|r| r[:context_code] == params[:context_code] }
      @rubric_context = @context
      if context
        @rubric_context = Context.find_by_asset_string(params[:context_code])
      end
      @rubric_associations = @context.sorted_rubrics(@current_user, @rubric_context)
      render :json => @rubric_associations.to_json(:methods => [:context_name], :include => :rubric)
    else
      render :json => @rubric_contexts.to_json
    end
  end

  def submissions_json
    updated = Time.parse(params[:updated]) rescue nil
    updated ||= Time.parse("Jan 1 2000")
    @submissions = @context.submissions.find(:all, :include => [:quiz_submission, :submission_comments, :attachments], :conditions => ['submissions.updated_at > ?', updated]).to_a
    @new_submissions = @submissions

    respond_to do |format|
      if @new_submissions.empty?
        format.json { render :json => [].to_json }
      else
        format.json { render :json => @new_submissions.to_json(:include => [:quiz_submission, :submission_comments, :attachments]) }
      end
    end
  end
  protected :submissions_json

  def attendance
    @enrollment = @context.all_student_enrollments.find_by_user_id(params[:user_id]) if params[:user_id].present?
    @enrollment ||= @context.all_student_enrollments.find_by_user_id(@current_user.id) if !@context.grants_right?(@current_user, session, :manage_grades)
    add_crumb t(:crumb, 'Attendance')
    if !@enrollment && @context.grants_right?(@current_user, session, :manage_grades)
      @assignments = @context.assignments.active.select{|a| a.submission_types == "attendance" }
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @submissions = @context.submissions
      @at_least_one_due_at = @assignments.any?{|a| a.due_at }
      # Find which assignment group most attendance items belong to,
      # it'll be a better guess for default assignment group than the first
      # in the list...
      @default_group_id = @assignments.to_a.count_per(&:assignment_group_id).sort_by{|id, cnt| cnt }.reverse.first[0] rescue nil
    elsif @enrollment && @enrollment.grants_right?(@current_user, session, :read_grades)
      @assignments = @context.assignments.active.select{|a| a.submission_types == "attendance" }
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @submissions = @context.submissions.find_all_by_user_id(@enrollment.user_id)
      @user = @enrollment.user
      render :action => "student_attendance"
      # render student_attendance, optional params[:assignment_id] to highlight and scroll to that particular assignment
    else
      flash[:notice] = t('notices.unauthorized', "You are not authorized to view attendance for this course")
      redirect_to named_context_url(@context, :context_url)
      # redirect
    end
  end

  # GET /gradebooks/1
  # GET /gradebooks/1.json
  # GET /gradebooks/1.csv
  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      return submissions_json if params[:updated] && request.format == :json
      return gradebook_init_json if params[:init] && request.format == :json
      @context.require_assignment_group

      log_asset_access("gradebook:#{@context.asset_string}", "grades", "other")
      respond_to do |format|
        format.html {
          @groups = @context.assignment_groups.active
          @groups_order = {}
          @groups.each_with_index{|group, idx| @groups_order[group.id] = idx }
          @just_assignments = @context.assignments.active.gradeable.find(:all, :order => 'due_at, title').select{|a| @groups_order[a.assignment_group_id] }
          newest = Time.parse("Jan 1 2010")
          @just_assignments = @just_assignments.sort_by{|a| [a.due_at || newest, @groups_order[a.assignment_group_id] || 0, a.position || 0] }
          @assignments = @just_assignments.dup + groups_as_assignments(@groups)
          @gradebook_upload = @context.build_gradebook_upload
          @submissions = @context.submissions
          @new_submissions = @submissions
          if params[:updated]
            d = DateTime.parse(params[:updated])
            @new_submissions = @submissions.select{|s| s.updated_at > d}
          end
          @enrollments_hash = Hash.new{ |hash,key| hash[key] = [] }
          @context.enrollments.sort_by{|e| [e.state_sortable, e.rank_sortable] }.each{ |e| @enrollments_hash[e.user_id] << e }
          @students = @context.students_visible_to(@current_user).order_by_sortable_name.uniq
          if params[:view] == "simple"
            @headers = false
            render :action => "show_simple"
          else
            render :action => "show"
          end
        }
        format.csv {
          cancel_cache_buster
          Enrollment.recompute_final_score_if_stale @context
          send_data(
            @context.gradebook_to_csv(:include_sis_id => @context.grants_rights?(@current_user, session, :read_sis, :manage_sis).values.any?),
            :type => "text/csv",
            :filename => t('grades_filename', "Grades").gsub(/ /, "_") + "-" + @context.name.to_s.gsub(/ /, "_") + ".csv",
            :disposition => "attachment"
          )
        }
        format.json  {
          @submissions = @context.submissions
          @new_submissions = @submissions
          render :json => @new_submissions.to_json(:include => [:quiz_submission, :submission_comments, :attachments])
        }
      end
    end
  end

  def gradebook_init_json
    # res = "{"
    if params[:assignments]
      # you need to specify specifically which assignment fields you want returned to the gradebook via json here
      # that makes it so we do a lot less querying to the db, which means less active record instantiation,
      # which means less AR -> JSON serialization overhead which means less data transfer over the wire and faster request.
      # (in this case, the worst part was the assignment 'description' which could be a massive wikipage)
      render :json => @context.assignments.active.gradeable.scoped(
        :select => ["id", "title", "due_at", "unlock_at", "lock_at",
                    "points_possible", "min_score", "max_score",
                    "mastery_score", "grading_type", "submission_types",
                    "assignment_group_id", "grading_scheme_id",
                    "grading_standard_id", "grade_group_students_individually",
                    "(select name from group_categories where
                       id=assignments.group_category_id) AS group_category"].join(", ")) + groups_as_assignments
    elsif params[:students]
      # you need to specify specifically which student fields you want returned to the gradebook via json here
      render :json => @context.students_visible_to(@current_user).order_by_sortable_name.to_json(:only => ["id", "name", "sortable_name", "short_name"])
    else
      params[:user_ids] ||= params[:user_id]
      user_ids = params[:user_ids].split(",").map(&:to_i) if params[:user_ids]
      assignment_ids = params[:assignment_ids].split(",").map(&:to_i) if params[:assignment_ids]
      # you need to specify specifically which submission fields you want returned to the gradebook here
      scope_options = {
        :select => ["assignment_id", "attachment_id", "grade", "grade_matches_current_submission", "group_id", "has_rubric_assessment", "id", "score", "submission_comments_count", "submission_type", "submitted_at", "url", "user_id"].join(" ,")
      }
      if user_ids && assignment_ids
        @submissions = @context.submissions.scoped(scope_options).find(:all, :conditions => {:user_id => user_ids, :assignment_id => assignment_ids})
      elsif user_ids
        @submissions = @context.submissions.scoped(scope_options).find(:all, :conditions => {:user_id => user_ids})
      else
        @submissions = @context.submissions.scoped(scope_options)
      end
      render :json => @submissions.to_json(:include => [:attachments, :quiz_submission, :submission_comments])
    end
  end
  protected :gradebook_init_json

  def history
    if authorized_action(@context, @current_user, :manage_grades)
      #
      # Temporary disabling of this page for large courses
      # We need some reworking of the gradebook history to allow using it
      # in large courses in a performant manner. Until that happens, we're
      # disabling it over a certain threshold.
      #
      submissions_count = @context.submissions.count
      submissions_limit = Setting.get('gradebook_history_submission_count_threshold', '0').to_i
      if submissions_limit == 0 || submissions_count <= submissions_limit
        # TODO this whole thing could go a LOT faster if you just got ALL the versions of ALL the submissions in this course then did a ruby sort_by day then grader
        @days = SubmissionList.days(@context)
      end

      respond_to do |format|
        format.html
      end
    end
  end

  def update_submission
    if authorized_action(@context, @current_user, :manage_grades)
      submissions = [params[:submission]]
      if params[:submissions]
        submissions = []
        params[:submissions].each do |key, submission|
          submissions << submission
        end
      end
      @submissions = []
      submissions.compact.each do |submission|
        @assignment = @context.assignments.active.find(submission[:assignment_id])
        begin
          @user = @context.students_visible_to(@current_user).find(submission[:user_id].to_i)
        rescue ActiveRecord::RecordNotFound
          next
        end
        submission[:grader] = @current_user
        submission.delete :comment_attachments
        if params[:attachments]
          attachments = []
          params[:attachments].each do |idx, attachment|
            attachment[:user] = @current_user
            attachments << @assignment.attachments.create(attachment)
          end
          submission[:comment_attachments] = attachments
        end
        begin
          # if it's a percentage graded assignment, we need to ensure there's a
          # percent sign on the end. eventually this will probably be done in
          # the javascript.
          if @assignment.grading_type == "percent" && submission[:grade] && submission[:grade] !~ /%\z/
            submission[:grade] = "#{submission[:grade]}%"
          end
          # requires: assignment_id, user_id, and grade or comment
          @submissions += @assignment.grade_student(@user, submission)
        rescue => e
          @error_message = e.to_s
        end
      end
      @submissions = @submissions.reverse.uniq.reverse
      @submissions = nil if @submissions.empty?

      respond_to do |format|
        if @submissions && !@error_message#&& !@submission.errors || @submission.errors.empty?
          flash[:notice] = t('notices.updated', 'Assignment submission was successfully updated.')
          format.html { redirect_to course_gradebook_url(@assignment.context) }
          format.json {
            render :json => @submissions.to_json(Submission.json_serialization_full_parameters), :status => :created, :location => course_gradebook_url(@assignment.context)
          }
          format.text {
            render :json => @submissions.to_json(Submission.json_serialization_full_parameters), :status => :created, :location => course_gradebook_url(@assignment.context),
                   :as_text => true
          }
        else
          flash[:error] = t('errors.submission_failed', "Submission was unsuccessful: %{error}", :error => @error_message || t('errors.submission_failed_default', 'Submission Failed'))
          format.html { render :action => "show", :course_id => @assignment.context.id }
          format.json { render :json => {:errors => {:base => @error_message}}.to_json, :status => :bad_request }
          format.text { render :json => {:errors => {:base => @error_message}}.to_json, :status => :bad_request }
        end
      end
    end
  end

  def submissions_zip_upload
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if !params[:submissions_zip] || params[:submissions_zip].is_a?(String)
      flash[:error] = t('errors.missing_file', "Could not find file to upload")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end
    @comments, @failures = @assignment.generate_comments_from_files(params[:submissions_zip].path, @current_user)
    flash[:notice] = t('notices.uploaded',
                       { :one => "Files and comments created for 1 user submission",
                         :other => "Files and comments created for %{count} user submissions" },
                       :count => @comments.length)
  end

  def speed_grader
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @assignment = @context.assignments.active.find(params[:assignment_id])
      respond_to do |format|
        format.html {
          @headers = false
          log_asset_access("speed_grader:#{@context.asset_string}", "grades", "other")
          render :action => "speed_grader"
        }
        format.json { render :json => @assignment.speed_grader_json(@current_user, service_enabled?(:avatars)) }
      end
    end
  end

  def blank_submission
    @headers = false
    render :action => "blank_submission"
  end

  def public_feed
    return unless get_feed_context(:only => [:course])

    respond_to do |format|
      feed = Atom::Feed.new do |f|
        f.title = t('titles.feed_for_course', "%{course} Gradebook Feed", :course => @context.name)
        f.links << Atom::Link.new(:href => course_gradebook_url(@context), :rel => 'self')
        f.updated = Time.now
        f.id = course_gradebook_url(@context)
      end
      @context.submissions.each do |e|
        feed.entries << e.to_atom
      end
      format.atom { render :text => feed.to_xml }
    end
  end

  def change_gradebook_version
    if params[:reset]
      @current_user.preferences.delete :use_gradebook2
    else
      @current_user.preferences[:use_gradebook2] = true
    end
    @current_user.save!
    redirect_to_appropriate_gradebook_version
  end

  def redirect_to_appropriate_gradebook_version
    gradebook_version_to_use = @current_user.preferences[:use_gradebook2] ? 'gradebook2' : 'gradebook'
    redirect_to named_context_url(@context, "context_#{gradebook_version_to_use}_url")
  end
  protected :redirect_to_appropriate_gradebook_version

  def groups_as_assignments(groups=nil, options = {})
    groups ||= @context.assignment_groups.active

    percentage = lambda do |weight|
      # find the smallest precision necessary to capture up to two digits of
      # significant decimals, but to avoid unnecessary zeros on the end. (so we
      # can have 100%, but still have 33.33%, for example)
      precision = sprintf('%.2f', weight % 1).sub(/^(?:0|1)\.(\d?[1-9])?0*$/, '\1').length
      number_to_percentage(weight, :precision => precision)
    end

    points_possible =
      (@context.group_weighting_scheme == "percent") ?
        (options[:out_of_final] ?
          lambda{ |group| t(:out_of_final, "%{weight} of Final", :weight => percentage[group.group_weight]) } :
          lambda{ |group| percentage[group.group_weight] }) :
        lambda{ |group| nil }

    groups = groups.map{ |group|
      OpenObject.build('assignment',
        :id => 'group-' + group.id.to_s,
        :rules => group.rules,
        :title => group.name,
        :points_possible => points_possible[group],
        :hard_coded => true,
        :special_class => 'group_total',
        :assignment_group_id => group.id,
        :group_weight => group.group_weight,
        :asset_string => "group_total_#{group.id}")
    }
    groups << OpenObject.build('assignment',
        :id => 'final-grade',
        :title => t('titles.total', 'Total'),
        :points_possible => (options[:out_of_final] ? '-' : percentage[100]),
        :hard_coded => true,
        :special_class => 'final_grade',
        :asset_string => "final_grade_column") unless options[:exclude_total]
    groups = [] if options[:exclude_total] && groups.length == 1
    groups
  end
end
