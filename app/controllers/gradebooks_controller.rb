#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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
  include Api::V1::CustomGradebookColumn

  before_filter :require_context
  before_filter :require_user, only: %w(speed_grader speed_grader_settings)

  batch_jobs_in_actions :only => :update_submission, :batch => { :priority => Delayed::LOW_PRIORITY }

  add_crumb(proc { t '#crumbs.grades', "Grades" }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_filter { |c| c.active_tab = "grades" }

  def grade_summary
    @presenter = GradeSummaryPresenter.new(@context, @current_user, params[:id])
    # do this as the very first thing, if the current user is a teacher in the course and they are not trying to view another user's grades, redirect them to the gradebook
    if @presenter.user_needs_redirection?
      return redirect_to polymorphic_url([@context, 'gradebook'])
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
        ags_json = light_weight_ags_json(@presenter.groups, {student: @presenter.student})
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

  def light_weight_ags_json(assignment_groups, opts={})
    assignment_groups.map do |ag|
      assignments = ag.visible_assignments(opts[:student] || @current_user).map do |a|
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
      render :json => @rubric_associations.map{ |r| r.as_json(methods: [:context_name], include: {:rubric => {:include_root => false}}) }
    else
      render :json => @rubric_contexts
    end
  end

  def attendance
    @enrollment = @context.all_student_enrollments.where(user_id: params[:user_id]).first if params[:user_id].present?
    @enrollment ||= @context.all_student_enrollments.where(user_id: @current_user).first if !@context.grants_right?(@current_user, session, :manage_grades)
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
      @submissions = @context.submissions.where(user_id: @enrollment.user_id).to_a
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
      respond_to do |format|
        format.html {
          set_js_env
          case @current_user.preferred_gradebook_version
          when "2"
            render :action => "gradebook2"
            return
          when "srgb"
            render :action => "screenreader"
            return
          end
        }
        format.csv {
          cancel_cache_buster
          Shackles.activate(:slave) do
            send_data(
              @context.gradebook_to_csv(
                :user => @current_user,
                :include_priors => value_to_boolean(params[:include_priors]),
                :include_sis_id => @context.grants_any_right?(@current_user, session, :read_sis, :manage_sis)
              ),
              :type => "text/csv",
              :filename => t('grades_filename', "Grades").gsub(/ /, "_") + "-" + @context.name.to_s.gsub(/ /, "_") + ".csv",
              :disposition => "attachment"
            )
          end
        }
      end
    end
  end

  def gradebook2
    redirect_to action: :show
  end

  def set_js_env
    @gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    per_page = Setting.get('api_max_per_page', '50').to_i
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(:teacher_notes=> true).first
    ag_includes = [:assignments]
    ag_includes << :assignment_visibility if @context.feature_enabled?(:differentiated_assignments)
    js_env  :GRADEBOOK_OPTIONS => {
      :chunk_size => Setting.get('gradebook2.submissions_chunk_size', '35').to_i,
      :assignment_groups_url => api_v1_course_assignment_groups_url(@context, :include => ag_includes, :override_assignment_dates => "false"),
      :sections_url => api_v1_course_sections_url(@context),
      :students_url => api_v1_course_enrollments_url(@context, :include => [:avatar_url], :type => ['StudentEnrollment', 'StudentViewEnrollment'], :per_page => per_page),
      :students_url_with_concluded_enrollments => api_v1_course_enrollments_url(@context, :include => [:avatar_url], :type => ['StudentEnrollment', 'StudentViewEnrollment'], :state => ['active', 'invited', 'completed'], :per_page => per_page),
      :submissions_url => api_v1_course_student_submissions_url(@context, :grouped => '1'),
      :outcome_links_url => api_v1_course_outcome_group_links_url(@context),
      :outcome_rollups_url => api_v1_course_outcome_rollups_url(@context, :per_page => 100),
      :change_grade_url => api_v1_course_assignment_submission_url(@context, ":assignment", ":submission", :include =>[:visibility]),
      :context_url => named_context_url(@context, :context_url),
      :download_assignment_submissions_url => named_context_url(@context, :context_assignment_submissions_url, "{{ assignment_id }}", :zip => 1),
      :re_upload_submissions_url => named_context_url(@context, :submissions_upload_context_gradebook_url, "{{ assignment_id }}"),
      :context_id => @context.id,
      :context_code => @context.asset_string,
      :context_sis_id => @context.sis_source_id,
      :group_weighting_scheme => @context.group_weighting_scheme,
      :grading_standard =>  @context.grading_standard_enabled? && (@context.grading_standard.try(:data) || GradingStandard.default_grading_standard),
      :course_is_concluded => @context.completed?,
      :gradebook_is_editable => @gradebook_is_editable,
      :setting_update_url => api_v1_course_settings_url(@context),
      :show_total_grade_as_points => @context.settings[:show_total_grade_as_points],
      :publish_to_sis_enabled => @context.allows_grade_publishing_by(@current_user) && @gradebook_is_editable,
      :publish_to_sis_url => context_url(@context, :context_details_url, :anchor => 'tab-grade-publishing'),
      :speed_grader_enabled => @context.allows_speed_grader?,
      :draft_state_enabled => @context.feature_enabled?(:draft_state),
      :differentiated_assignments_enabled => @context.feature_enabled?(:differentiated_assignments),
      :outcome_gradebook_enabled => @context.feature_enabled?(:outcome_gradebook),
      :custom_columns_url => api_v1_course_custom_gradebook_columns_url(@context),
      :custom_column_url => api_v1_course_custom_gradebook_column_url(@context, ":id"),
      :custom_column_data_url => api_v1_course_custom_gradebook_column_data_url(@context, ":id", per_page: per_page),
      :custom_column_datum_url => api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      :reorder_custom_columns_url => api_v1_custom_gradebook_columns_reorder_url(@context),
      :teacher_notes => teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      :change_gradebook_version_url => context_url(@context, :change_gradebook_version_context_gradebook_url, :version => 2),
      :sis_app_url => Setting.get('sis_app_url', nil),
      :sis_app_token => Setting.get('sis_app_token', nil),
      :list_students_by_sortable_name_enabled => @context.feature_enabled?(:gradebook_list_students_by_sortable_name)
    }
  end

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
      if params[:submissions].blank? && params[:submission].blank?
        render nothing: true, status: 400
        return
      end

      submissions = if params[:submissions]
                      params[:submissions].values
                    else
                      [params[:submission]]
                    end

      valid_user_ids = Set.new(@context.students_visible_to(@current_user).pluck(:id))
      submissions.select! { |s| valid_user_ids.include? s[:user_id].to_i }
      users = @context.students.uniq.find(submissions.map { |s| s[:user_id] })
        .index_by(&:id)
      assignments = @context.assignments.active.find(submissions.map { |s|
        s[:assignment_id]
      }).index_by(&:id)

      @submissions = []
      submissions.compact.each do |submission|
        @assignment = assignments[submission[:assignment_id].to_i]
        @user = users[submission[:user_id].to_i]
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

          submission[:dont_overwrite_grade] = value_to_boolean(params[:dont_overwrite_grades])
          @submissions += @assignment.grade_student(@user, submission)
        rescue => e
          @error_message = e.to_s
        end
      end
      @submissions = @submissions.reverse.uniq.reverse
      @submissions = nil if submissions.empty?  # no valid submissions

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
        if @assignment.quiz
          env[:quiz_history_url] = course_quiz_history_path @context.id,
                                                            @assignment.quiz.id,
                                                            :user_id => "{{user_id}}"
        end
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
    @current_user.preferences[:gradebook_version] = params[:version]
    @current_user.save!
    redirect_to polymorphic_url([@context, 'gradebook'])
  end

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
    assignment_scope = AssignmentGroup.assignment_scope_for_draft_state(@context)
    @context.assignment_groups.active.includes(assignment_scope).map { |g|
      assignment_group_json(g, @current_user, session, ['assignments'], {
        stringify_json_ids: opts[:stringify_json_ids] || stringify_json_ids?
      })
    }
  end
end
