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

class GradebooksController < ApplicationController
  include ActionView::Helpers::NumberHelper
  include GradebooksHelper
  include KalturaHelper
  include Api::V1::AssignmentGroup
  include Api::V1::Submission

  before_filter :require_context
  before_filter :require_user, only: %w(speed_grader speed_grader_settings)
  batch_jobs_in_actions :only => :update_submission, :batch => { :priority => Delayed::LOW_PRIORITY }

  add_crumb(proc { t '#crumbs.grades', "Grades" }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_filter { |c| c.active_tab = "grades" }

  def grade_summary
    @presenter = GradeSummaryPresenter.new(@context, @current_user, params[:id])
    # do this as the very first thing, if the current user is a teacher in the course and they are not trying to view another user's grades, redirect them to the gradebook
    if @presenter.user_needs_redirection?
      return redirect_to_appropriate_gradebook_version
    end

    if !@presenter.student || !@presenter.student_enrollment
      return authorized_action(nil, @current_user, :permission_fail)
    end

    if authorized_action(@presenter.student_enrollment, @current_user, :read_grades)
      log_asset_access("grades:#{@context.asset_string}", "grades", "other")
      if @presenter.student
        add_crumb(@presenter.student_name, named_context_url(@context, :context_student_grades_url, @presenter.student_id))

        Shackles.activate(:slave) do
          #run these queries on the slave database for speed
          @presenter.assignments
          @presenter.groups_assignments = groups_as_assignments(@presenter.groups, :out_of_final => true, :exclude_total => @context.hide_final_grades?)
          @presenter.submissions
          @presenter.submission_counts
          @presenter.assignment_stats
        end

        submissions_json = @presenter.submissions.map { |s|
          {
            'assignment_id' => s.assignment_id,
            'score' => s.grants_right?(@current_user, :read_grade)? s.score  : nil
          }
        }
        ags_json = light_weight_ags_json(@presenter.groups)
        js_env submissions: submissions_json,
               assignment_groups: ags_json,
               group_weighting_scheme: @context.group_weighting_scheme,
               show_total_grade_as_points: @context.settings[:show_total_grade_as_points],
               grading_scheme: @context.grading_standard.try(:data) || GradingStandard.default_grading_standard,
               student_outcome_gradebook_enabled: @context.feature_enabled?(:student_outcome_gradebook),
               student_id: @presenter.student_id
        render :action => 'grade_summary'
      else
        render :action => 'grade_summary_list'
      end
    end
  end

  def light_weight_ags_json(assignment_groups)
    assignment_groups.map do |ag|
      assignment_scope = AssignmentGroup.assignment_scope_for_grading(@context)
      assignments = ag.send(assignment_scope).map do |a|
        {
          :id => a.id,
          :submission_types => a.submission_types_array,
          :points_possible => a.points_possible,
        }
      end
      {
        :id           => ag.id,
        :rules        => ag.rules_hash({stringify_json_ids: true}),
        :group_weight => ag.group_weight,
        :assignments  => assignments,
      }
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
      render :json => @rubric_associations.map{ |r| r.as_json(methods: [:context_name], include: :rubric) }
    else
      render :json => @rubric_contexts
    end
  end

  def submissions_json
    Shackles.activate(:slave) do
      updated = Time.parse(params[:updated]) rescue nil
      updated ||= Time.parse("Jan 1 2000")
      @new_submissions = @context.submissions.
        includes(:submission_comments, :attachments).
          where('submissions.updated_at > ?', updated).all

      respond_to do |format|
        if @new_submissions.empty?
          format.json { render :json => [] }
        else
          format.json { render :json => @new_submissions.map{ |s| s.as_json(include: [:quiz_submission, :submission_comments, :attachments]) }}
        end
      end
    end
  end
  protected :submissions_json

  def attendance
    @enrollment = @context.all_student_enrollments.find_by_user_id(params[:user_id]) if params[:user_id].present?
    @enrollment ||= @context.all_student_enrollments.find_by_user_id(@current_user.id) if !@context.grants_right?(@current_user, session, :manage_grades)
    add_crumb t(:crumb, 'Attendance')
    if !@enrollment && @context.grants_right?(@current_user, session, :manage_grades)
      @assignments = @context.assignments.active.where(:submission_types => 'attendance').all
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @at_least_one_due_at = @assignments.any?{|a| a.due_at }
      # Find which assignment group most attendance items belong to,
      # it'll be a better guess for default assignment group than the first
      # in the list...
      @default_group_id = @assignments.to_a.inject(Hash.new(0)){|h,a| h[a.assignment_group_id] += 1; h}.sort_by{|id, cnt| cnt }.reverse.first[0] rescue nil
    elsif @enrollment && @enrollment.grants_right?(@current_user, session, :read_grades)
      @assignments = @context.assignments.active.where(:submission_types => 'attendance').all
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

  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      if !@context.old_gradebook_visible? && request.format == :json
        render :json => {:error => "gradebook is disabled for this course"},
               :status => 404
        return
      end
      return submissions_json if params[:updated] && request.format == :json
      return gradebook_init_json if params[:init] && request.format == :json

      @context.require_assignment_group

      log_asset_access("gradebook:#{@context.asset_string}", "grades", "other")
      respond_to do |format|
        format.html {
          unless @context.old_gradebook_visible?
            redirect_to polymorphic_url([@context, 'gradebook2'])
            return
          end

          Shackles.activate(:slave) do
            @groups = @context.assignment_groups.active
            @groups_order = {}
            @groups.each_with_index{|group, idx| @groups_order[group.id] = idx }
            @just_assignments = @context.assignments.active.gradeable.
              order(:due_at, Assignment.best_unicode_collation_key('title')).
              select{|a| @groups_order[a.assignment_group_id] }

            newest = Time.parse("Jan 1 2010")
            @just_assignments = @just_assignments.sort_by do |a|
              [a.due_at || newest, @groups_order[a.assignment_group_id] || 0, a.position || 0]
            end
            if @context.feature_enabled?(:draft_state)
              @just_assignments = @just_assignments.select(&:published?)
            end
            @assignments = @just_assignments.dup + groups_as_assignments(@groups)
            @enrollments_hash = Hash.new{ |hash,key| hash[key] = [] }
            @context.enrollments.sort_by{|e| [e.state_sortable, e.rank_sortable] }.each{ |e| @enrollments_hash[e.user_id] << e }
            @students = @context.students_visible_to(@current_user).order_by_sortable_name.uniq.all
          end

          # this can't happen in the slave block because this may trigger
          # writes in ContextModule
          js_env :assignment_groups => assignment_groups_json({:stringify_json_ids => true}),
                 :speed_grader_enabled => @context.allows_speed_grader?
          set_gradebook_warnings(@groups, @just_assignments)
          if params[:view] == "simple"
            @headers = false
            render :action => "show_simple"
          else
            render :action => "show"
          end
        }
        format.csv {
          cancel_cache_buster
          Shackles.activate(:slave) do
            send_data(
              @context.gradebook_to_csv(:include_sis_id => @context.grants_rights?(@current_user, session, :read_sis, :manage_sis).values.any?, :user => @current_user),
              :type => "text/csv",
              :filename => t('grades_filename', "Grades").gsub(/ /, "_") + "-" + @context.name.to_s.gsub(/ /, "_") + ".csv",
              :disposition => "attachment"
            )
          end
        }
        format.json  {
          Shackles.activate(:slave) do
            @submissions = @context.submissions.includes(:quiz_submission)
            @new_submissions = @submissions
            render :json => @new_submissions.map{ |s| s.as_json(include: [:quiz_submission, :submission_comments, :attachments]) }
          end
        }
      end
    end
  end

  def gradebook_init_json
    Shackles.activate(:slave) do
      if params[:assignments]
        # you need to specify specifically which assignment fields you want returned to the gradebook via json here
        # that makes it so we do a lot less querying to the db, which means less active record instantiation,
        # which means less AR -> JSON serialization overhead which means less data transfer over the wire and faster request.
        # (in this case, the worst part was the assignment 'description' which could be a massive wikipage)

        assignment_fields = ["id", "title", "due_at", "unlock_at", "lock_at",
          "points_possible", "grading_type", "submission_types",
          "assignment_group_id", "grading_scheme_id", "grading_standard_id",
          "grade_group_students_individually"].map do |field|
            "assignments.#{field}"
        end
        workflow_scope = @context.feature_enabled?(:draft_state) ? :published : :active
        render :json => @context.assignments.send(workflow_scope).gradeable.
          select(assignment_fields + ["group_categories.name as group_category", "quizzes.id as quiz_id"]).
          joins("LEFT OUTER JOIN group_categories ON group_categories.id=assignments.group_category_id").
          joins("LEFT OUTER JOIN quizzes on quizzes.assignment_id=assignments.id") + groups_as_assignments
      elsif params[:students]
        # you need to specify specifically which student fields you want returned to the gradebook via json here
        render :json => @context.students_visible_to(@current_user).order_by_sortable_name.map{ |s| s.as_json(only: ["id", "name", "sortable_name", "short_name"]) }
      else
        params[:user_ids] ||= params[:user_id]
        user_ids = params[:user_ids].split(",").map(&:to_i) if params[:user_ids]
        assignment_ids = params[:assignment_ids].split(",").map(&:to_i) if params[:assignment_ids]
        @submissions = @context.submissions.
          includes(:submission_comments, :attachments)
        @submissions = @submissions.where(:user_id => user_ids) if user_ids
        @submissions = @submissions.where(:assignment_id => assignment_ids) if assignment_ids
        render :json => @submissions.map{ |s| s.as_json(include: [:attachments, :submission_comments]) }
      end
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
            render :json => @submissions.map{ |s| s.as_json(Submission.json_serialization_full_parameters) }, :status => :created, :location => course_gradebook_url(@assignment.context)
          }
          format.text {
            render :json => @submissions.map{ |s| s.as_json(Submission.json_serialization_full_parameters) }, :status => :created, :location => course_gradebook_url(@assignment.context),
                   :as_text => true
          }
        else
          flash[:error] = t('errors.submission_failed', "Submission was unsuccessful: %{error}", :error => @error_message || t('errors.submission_failed_default', 'Submission Failed'))
          format.html { render :action => "show", :course_id => @assignment.context.id }
          format.json { render :json => {:errors => {:base => @error_message}}, :status => :bad_request }
          format.text { render :json => {:errors => {:base => @error_message}}, :status => :bad_request }
        end
      end
    end
  end

  def submissions_zip_upload
    unless @context.allows_gradebook_uploads?
      flash[:error] = t('errors.not_allowed', "This course does not allow score uploads.")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if !params[:submissions_zip] || params[:submissions_zip].is_a?(String)
      flash[:error] = t('errors.missing_file', "Could not find file to upload")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end
    @comments, @failures = @assignment.generate_comments_from_files(params[:submissions_zip].path, @current_user)
    flash[:notice] = t('notices.uploaded',
                       { :one => "Files and comments created for 1 submission",
                         :other => "Files and comments created for %{count} submissions" },
                       :count => @comments.length)
  end

  def speed_grader
    if !@context.allows_speed_grader?
      flash[:notice] = t(:speed_grader_disabled, 'SpeedGrader is disabled for this course')
      return redirect_to(course_gradebook_path(@context))
    end

    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    @assignment = @context.assignments.active.find(params[:assignment_id])
    if @context.feature_enabled?(:draft_state) && @assignment.unpublished?
      flash[:notice] = t(:speedgrader_enabled_only_for_published_content,
                         'Speedgrader is enabled only for published content.')
      return redirect_to polymorphic_url([@context, @assignment])
    end

    respond_to do |format|
      format.html do
        @headers = false
        @outer_frame = true
        log_asset_access("speed_grader:#{@context.asset_string}", "grades", "other")
        env = {
          :CONTEXT_ACTION_SOURCE => :speed_grader,
          :settings_url => speed_grader_settings_course_gradebook_path,
        }
        append_sis_data(env)
        js_env(env)
        render :action => "speed_grader"
      end

      format.json do
        render :json => @assignment.speed_grader_json(@current_user, service_enabled?(:avatars))
      end
    end
  end

  def speed_grader_settings
    grade_by_question = value_to_boolean(params[:enable_speedgrader_grade_by_question])
    @current_user.preferences[:enable_speedgrader_grade_by_question] = grade_by_question
    @current_user.save!
    render nothing: true
  end

  def blank_submission
    @headers = false
    render :action => "blank_submission"
  end

  def change_gradebook_version
    if @context.feature_enabled?(:screenreader_gradebook)
      @current_user.preferences[:gradebook_version] = params[:version]
    else
      @current_user.preferences[:use_gradebook2] = params[:version] == '2'
    end
    @current_user.save!
    redirect_to_appropriate_gradebook_version
  end

  def redirect_to_appropriate_gradebook_version
    redirect_to gradebook_url_for(@current_user, @context)
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

    groups = groups.map { |group|
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
        :points_possible => (options[:out_of_final] ? '' : percentage[100]),
        :hard_coded => true,
        :special_class => 'final_grade',
        :asset_string => "final_grade_column") unless options[:exclude_total]
    groups = [] if options[:exclude_total] && groups.length == 1
    groups
  end

  def set_gradebook_warnings(groups, assignments)
    @assignments_in_bad_groups = Set.new

    if @context.group_weighting_scheme == "percent"
      assignments_by_group = assignments.group_by(&:assignment_group_id)
      bad_groups = groups.select do |group|
        group_assignments = assignments_by_group[group.id] || []
        points_in_group = group_assignments.map(&:points_possible).compact.sum
        points_in_group.zero?
      end

      bad_group_ids = bad_groups.map(&:id)
      bad_assignment_ids = assignments_by_group.
        slice(*bad_group_ids).
        values.
        flatten

      @assignments_in_bad_groups.replace bad_assignment_ids

      warning = t('invalid_assignment_groups_warning',
                  {:one => "Score does not include %{groups} because " \
                           "it has no points possible",
                   :other => "Score does not include %{groups} because " \
                           "they have no points possible"},
                  :groups => bad_groups.map(&:name).to_sentence,
                  :count  => bad_groups.size)
    else
      if assignments.all? { |a| (a.points_possible || 0).zero? }
        warning = t(:no_assignments_have_points_warning,
                    "Can't compute score until an assignment " \
                    "has points possible")
      end
    end

    js_env :total_grade_warning => warning if warning
  end
  private :set_gradebook_warnings


  def assignment_groups_json(opts={})
    assignment_scope = AssignmentGroup.assignment_scope_for_grading(@context)
    @context.assignment_groups.active.includes(assignment_scope).map { |g|
      assignment_group_json(g, @current_user, session, ['assignments'], {
        stringify_json_ids: opts[:stringify_json_ids] || stringify_json_ids?,
        assignment_group_assignment_scope: assignment_scope
      })
    }
  end
end
