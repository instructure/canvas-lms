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
  include Api::V1::Section

  before_action :require_context
  before_action :require_user, only: [:speed_grader, :speed_grader_settings, :grade_summary]

  batch_jobs_in_actions :only => :update_submission, :batch => { :priority => Delayed::LOW_PRIORITY }

  add_crumb(proc { t '#crumbs.grades', "Grades" }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_grades_url }
  before_action { |c| c.active_tab = "grades" }

  MAX_POST_GRADES_TOOLS = 10

  def grade_summary
    set_current_grading_period if multiple_grading_periods?
    @presenter = grade_summary_presenter
    # do this as the very first thing, if the current user is a
    # teacher in the course and they are not trying to view another
    # user's grades, redirect them to the gradebook
    if @presenter.user_needs_redirection?
      return redirect_to polymorphic_url([@context, 'gradebook'])
    end

    if !@presenter.student || !@presenter.student_enrollment
      return render_unauthorized_action
    end

    return unless authorized_action(@context, @current_user, :read) &&
      authorized_action(@presenter.student_enrollment, @current_user, :read_grades)

    log_asset_access([ "grades", @context ], "grades", "other")

    return render :grade_summary_list unless @presenter.student

    add_crumb(@presenter.student_name, named_context_url(@context, :context_student_grades_url,
                                                         @presenter.student_id))
    gp_id = nil
    if multiple_grading_periods?
      @grading_periods = active_grading_periods_json
      gp_id = @current_grading_period_id unless view_all_grading_periods?
    end

    @exclude_total = exclude_total?(@context)
    Shackles.activate(:slave) do
      # run these queries on the slave database for speed
      @presenter.assignments
      @presenter.groups_assignments = groups_as_assignments(@presenter.groups,
                                                            :out_of_final => true,
                                                            :exclude_total => @exclude_total)
      @presenter.submissions
      @presenter.submission_counts
      @presenter.assignment_stats
    end

    submissions_json = @presenter.submissions.
      select { |s| s.user_can_read_grade?(@current_user) }.
      map do |s|
      {
        assignment_id: s.assignment_id,
        score: s.score,
        excused: s.excused?,
        workflow_state: s.workflow_state,
      }
    end

    grading_period = @grading_periods && @grading_periods.find { |period| period[:id] == gp_id }


    ags_json = light_weight_ags_json(@presenter.groups, {student: @presenter.student})

    grading_scheme = @context.grading_standard.try(:data) ||
                     GradingStandard.default_grading_standard

    js_env(submissions: submissions_json,
           assignment_groups: ags_json,
           group_weighting_scheme: @context.group_weighting_scheme,
           show_total_grade_as_points: @context.settings[:show_total_grade_as_points],
           grading_scheme: grading_scheme,
           grading_period: grading_period,
           exclude_total: @exclude_total,
           student_outcome_gradebook_enabled: @context.feature_enabled?(:student_outcome_gradebook),
           student_id: @presenter.student_id)
  end

  def save_assignment_order
    if authorized_action(@context, @current_user, :read)
      whitelisted_orders = {
        'due_at' => :due_at, 'title' => :title,
        'module' => :module, 'assignment_group' => :assignment_group
      }
      assignment_order = whitelisted_orders.fetch(params.fetch(:assignment_order), :due_at)
      @current_user.preferences[:course_grades_assignment_order] ||= {}
      @current_user.preferences[:course_grades_assignment_order][@context.id] = assignment_order
      @current_user.save!
      redirect_to :back
    end
  end

  def light_weight_ags_json(assignment_groups, opts={})
    assignment_groups.map do |ag|
      visible_assignments = ag.visible_assignments(opts[:student] || @current_user).to_a

      if multiple_grading_periods? && @current_grading_period_id && !view_all_grading_periods?
        current_period = GradingPeriod.for(@context).find_by(id: @current_grading_period_id)
        visible_assignments = current_period.assignments_for_student(visible_assignments, opts[:student])
      end

      visible_assignments.map! do |a|
        {
          id: a.id,
          submission_types: a.submission_types_array,
          points_possible: a.points_possible,
          due_at: a.due_at,
          omit_from_final_grade: a.omit_from_final_grade?,
          muted: a.muted?
        }
      end

      {
        id: ag.id,
        rules: ag.rules_hash({stringify_json_ids: true}),
        group_weight: ag.group_weight,
        assignments: visible_assignments,
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
      @assignments = @context.assignments.active.where(:submission_types => 'attendance').to_a
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @at_least_one_due_at = @assignments.any?{|a| a.due_at }
      # Find which assignment group most attendance items belong to,
      # it'll be a better guess for default assignment group than the first
      # in the list...
      @default_group_id = @assignments.to_a.inject(Hash.new(0)){|h,a| h[a.assignment_group_id] += 1; h}.sort_by{|id, cnt| cnt }.reverse.first[0] rescue nil
    elsif @enrollment && @enrollment.grants_right?(@current_user, session, :read_grades)
      @assignments = @context.assignments.active.where(:submission_types => 'attendance').to_a
      @students = @context.students_visible_to(@current_user).order_by_sortable_name
      @submissions = @context.submissions.where(user_id: @enrollment.user_id).to_a
      @user = @enrollment.user
      render :student_attendance
      # render student_attendance, optional params[:assignment_id] to highlight and scroll to that particular assignment
    else
      flash[:notice] = t('notices.unauthorized', "You are not authorized to view attendance for this course")
      redirect_to named_context_url(@context, :context_url)
      # redirect
    end
  end

  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @last_exported_gradebook_csv = GradebookCsv.last_successful_export(course: @context, user: @current_user)
      set_current_grading_period if multiple_grading_periods?
      set_js_env
      @course_is_concluded = @context.completed?
      @post_grades_tools = post_grades_tools

      version = @current_user.preferred_gradebook_version
      if version == '2'
        render :gradebook and return
      elsif version == "gradezilla" && @context.root_account.feature_enabled?(:gradezilla)
        render :gradezilla and return
      elsif version == "srgb"
        render :screenreader and return
      else
        render :gradebook and return
      end
    end
  end

  def post_grades_tools
    tool_limit = @context.feature_enabled?(:post_grades) ? MAX_POST_GRADES_TOOLS - 1 : MAX_POST_GRADES_TOOLS
    external_tools = self.external_tools.map { |tool| external_tool_detail(tool) }

    tools = external_tools[0...tool_limit]
    tools.push(type: :post_grades) if @context.feature_enabled?(:post_grades)
    tools
  end

  def external_tool_detail(tool)
    post_grades_placement = tool[:placements][:post_grades]
    {
      data_url: post_grades_placement[:canvas_launch_url],
      name: tool[:name],
      type: :lti,
      data_width: post_grades_placement[:launch_width],
      data_height: post_grades_placement[:launch_height]
    }
  end

  def external_tools
    bookmarked_collection = Lti::AppLaunchCollator.bookmarked_collection(@context, [:post_grades])
    tools = bookmarked_collection.paginate(per_page: MAX_POST_GRADES_TOOLS + 1).to_a
    launch_definitions = Lti::AppLaunchCollator.launch_definitions(tools, [:post_grades])
    launch_definitions.each do |launch_definition|
      case launch_definition[:definition_type]
      when 'ContextExternalTool'
        url = external_tool_url_for_lti1(launch_definition)
      when 'Lti::MessageHandler'
        url = external_tool_url_for_lti2(launch_definition)
      end
      launch_definition[:placements][:post_grades][:canvas_launch_url] = url
    end
    launch_definitions
  end

  def external_tool_url_for_lti1(launch_definition)
    polymorphic_url(
      [@context, :external_tool],
      id: launch_definition[:definition_id],
      display: 'borderless',
      launch_type: 'post_grades',
    )
  end

  def external_tool_url_for_lti2(launch_definition)
    polymorphic_url(
      [@context, :basic_lti_launch_request],
      message_handler_id: launch_definition[:definition_id],
      display: 'borderless',
    )
  end

  def set_current_grading_period
    if params[:grading_period_id].present?
      @current_grading_period_id = params[:grading_period_id].to_i
    else
      return if view_all_grading_periods?
      current = GradingPeriod.current_period_for(@context)
      @current_grading_period_id = current ? current.id : 0
    end
  end

  def view_all_grading_periods?
    @current_grading_period_id == 0
  end

  def active_grading_periods
    @active_grading_periods ||= GradingPeriod.for(@context).sort_by(&:start_date)
  end

  def active_grading_periods_json
    @agp_json ||= GradingPeriod.periods_json(active_grading_periods, @current_user)
  end

  def latest_end_date_of_admin_created_grading_periods_in_the_past
    periods = active_grading_periods.select do |period|
      admin_created = period.account_group?
      admin_created && period.end_date.past?
    end
    periods.map(&:end_date).compact.sort.last
  end
  private :latest_end_date_of_admin_created_grading_periods_in_the_past

  def set_js_env
    @gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    per_page = Setting.get('api_max_per_page', '50').to_i
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(:teacher_notes=> true).first
    ag_includes = [:assignments, :assignment_visibility]
    chunk_size = if @context.assignments.published.count < Setting.get('gradebook2.assignments_threshold', '20').to_i
      Setting.get('gradebook2.submissions_chunk_size', '35').to_i
    else
      Setting.get('gradebook2.many_submissions_chunk_size', '10').to_i
    end
    js_env STUDENT_CONTEXT_CARDS_ENABLED: @domain_root_account.feature_enabled?(:student_context_cards)
    js_env :GRADEBOOK_OPTIONS => {
      :chunk_size => chunk_size,
      :assignment_groups_url => api_v1_course_assignment_groups_url(
        @context,
        include: ag_includes,
        override_assignment_dates: "false",
        exclude_assignment_submission_types: ['wiki_page']
      ),
      :sections_url => api_v1_course_sections_url(@context),
      :course_url => api_v1_course_url(@context),
      :effective_due_dates_url => api_v1_course_effective_due_dates_url(@context),
      :enrollments_url => custom_course_enrollments_api_url(per_page: per_page),
      :enrollments_with_concluded_url =>
        custom_course_enrollments_api_url(include_concluded: true, per_page: per_page),
      :enrollments_with_inactive_url =>
        custom_course_enrollments_api_url(include_inactive: true, per_page: per_page),
      :enrollments_with_concluded_and_inactive_url =>
        custom_course_enrollments_api_url(include_concluded: true, include_inactive: true, per_page: per_page),
      :students_url => custom_course_users_api_url(per_page: per_page),
      :students_with_concluded_enrollments_url =>
        custom_course_users_api_url(include_concluded: true, per_page: per_page),
      :students_with_inactive_enrollments_url =>
        custom_course_users_api_url(include_inactive: true, per_page: per_page),
      :students_with_concluded_and_inactive_enrollments_url =>
        custom_course_users_api_url(include_concluded: true, include_inactive: true, per_page: per_page),
      :submissions_url => api_v1_course_student_submissions_url(@context, :grouped => '1'),
      :outcome_links_url => api_v1_course_outcome_group_links_url(@context, :outcome_style => :full),
      :outcome_rollups_url => api_v1_course_outcome_rollups_url(@context, :per_page => 100),
      :change_grade_url => api_v1_course_assignment_submission_url(@context, ":assignment", ":submission", :include =>[:visibility]),
      :context_url => named_context_url(@context, :context_url),
      :download_assignment_submissions_url => named_context_url(@context, :context_assignment_submissions_url, "{{ assignment_id }}", :zip => 1),
      :re_upload_submissions_url => named_context_url(@context, :submissions_upload_context_gradebook_url, "{{ assignment_id }}"),
      :context_id => @context.id.to_s,
      :context_code => @context.asset_string,
      :context_sis_id => @context.sis_source_id,
      :group_weighting_scheme => @context.group_weighting_scheme,
      :grading_standard =>  @context.grading_standard_enabled? && (@context.grading_standard.try(:data) || GradingStandard.default_grading_standard),
      :course_is_concluded => @context.completed?,
      :course_name => @context.name,
      :gradebook_is_editable => @gradebook_is_editable,
      :context_allows_gradebook_uploads => @context.allows_gradebook_uploads?,
      :gradebook_import_url => new_course_gradebook_upload_path(@context),
      :setting_update_url => api_v1_course_settings_url(@context),
      :show_total_grade_as_points => @context.settings[:show_total_grade_as_points],
      :publish_to_sis_enabled => @context.allows_grade_publishing_by(@current_user) && @gradebook_is_editable,
      :publish_to_sis_url => context_url(@context, :context_details_url, :anchor => 'tab-grade-publishing'),
      :speed_grader_enabled => @context.allows_speed_grader?,
      :multiple_grading_periods_enabled => multiple_grading_periods?,
      :active_grading_periods => active_grading_periods_json,
      :latest_end_date_of_admin_created_grading_periods_in_the_past => latest_end_date_of_admin_created_grading_periods_in_the_past,
      :current_grading_period_id => @current_grading_period_id,
      :outcome_gradebook_enabled => @context.feature_enabled?(:outcome_gradebook),
      :custom_columns_url => api_v1_course_custom_gradebook_columns_url(@context),
      :custom_column_url => api_v1_course_custom_gradebook_column_url(@context, ":id"),
      :custom_column_data_url => api_v1_course_custom_gradebook_column_data_url(@context, ":id", per_page: per_page),
      :custom_column_datum_url => api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      :reorder_custom_columns_url => api_v1_custom_gradebook_columns_reorder_url(@context),
      :teacher_notes => teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      :change_gradebook_version_url => context_url(@context, :change_gradebook_version_context_gradebook_url, :version => 2),
      :export_gradebook_csv_url => course_gradebook_csv_url,
      :gradebook_csv_progress => @last_exported_gradebook_csv.try(:progress),
      :attachment_url => @last_exported_gradebook_csv.try(:attachment).try(:download_url),
      :attachment => @last_exported_gradebook_csv.try(:attachment),
      :sis_app_url => Setting.get('sis_app_url', nil),
      :sis_app_token => Setting.get('sis_app_token', nil),
      :list_students_by_sortable_name_enabled => @context.list_students_by_sortable_name?,
      :gradebook_column_size_settings => @current_user.preferences[:gradebook_column_size],
      :gradebook_column_size_settings_url => change_gradebook_column_size_course_gradebook_url,
      :gradebook_column_order_settings => @current_user.preferences[:gradebook_column_order].try(:[], @context.id),
      :gradebook_column_order_settings_url => save_gradebook_column_order_course_gradebook_url,
      :all_grading_periods_totals => @context.feature_enabled?(:all_grading_periods_totals),
      :sections => sections_json(@context.active_course_sections, @current_user, session),
      :settings_update_url => api_v1_course_gradebook_settings_update_url(@context),
      :settings => @current_user.preferences.fetch(:gradebook_settings, {}).fetch(@context.id, {}),
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

  # TODO: stop using this for speedgrader
  def update_submission
    if authorized_action(@context, @current_user, :manage_grades)
      if params[:submissions].blank? && params[:submission].blank?
        render nothing: true, status: 400
        return
      end

      submissions = if params[:submissions]
                      params[:submissions].map{|k, v| v} # apparently .values doesn't pass on the params
                    else
                      [params[:submission]]
                    end
      valid_user_ids = Set.new(@context.students_visible_to(@current_user, include: :inactive).pluck(:id))
      submissions.select! { |s| valid_user_ids.include? s[:user_id].to_i }
      users = @context.admin_visible_students.uniq.find(submissions.map { |s| s[:user_id] })
        .index_by(&:id)
      assignments = @context.assignments.active.find(submissions.map { |s|
        s[:assignment_id]
      }).index_by(&:id)

      request_error_status = nil
      @submissions = []
      submissions.compact.each do |submission|
        @assignment = assignments[submission[:assignment_id].to_i]
        @user = users[submission[:user_id].to_i]

        submission = submission.permit(:grade, :score, :excuse, :excused,
          :graded_anonymously, :provisional, :final,
          :comment, :media_comment_id)

        submission[:grader] = @current_user
        submission.delete(:provisional) unless @assignment.moderated_grading?
        if params[:attachments]
          attachments = []
          params[:attachments].keys.each do |idx|
            attachment = params[:attachments][idx].permit(Attachment.permitted_attributes)
            attachment[:user] = @current_user
            attachments << @assignment.attachments.create(attachment)
          end
          submission[:comment_attachments] = attachments
        end
        begin
          if [:grade, :score, :excuse, :excused].any? { |k| submission.key? k }
            # if it's a percentage graded assignment, we need to ensure there's a
            # percent sign on the end. eventually this will probably be done in
            # the javascript.
            if @assignment.grading_type == "percent" && submission[:grade] && submission[:grade] !~ /%\z/
              submission[:grade] = "#{submission[:grade]}%"
            end

            submission[:dont_overwrite_grade] = value_to_boolean(params[:dont_overwrite_grades])
            submission.delete(:final) if submission[:final] && !@context.grants_right?(@current_user, :moderate_grades)
            subs = @assignment.grade_student(@user, submission)
            if submission[:provisional]
              subs.each do |sub|
                sub.apply_provisional_grade_filter!(sub.provisional_grade(@current_user, final: submission[:final]))
              end
            end
            @submissions += subs
          end
          if [:comment, :media_comment_id, :comment_attachments].any? { |k| submission.key? k }
            submission[:commenter] = @current_user
            submission[:hidden] = @assignment.muted?

            subs = @assignment.update_submission(@user, submission)
            if submission[:provisional]
              subs.each do |sub|
                sub.apply_provisional_grade_filter!(sub.provisional_grade(@current_user, final: submission[:final]))
              end
            end
            @submissions += subs
          end
        rescue Assignment::GradeError => e
          logger.info "GRADES: grade_student failed because '#{e.message}'"
          request_error_status = e.status_code
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
            render :json => submissions_json, :status => :created, :location => course_gradebook_url(@assignment.context)
          }
          format.text {
            render :json => submissions_json, :status => :created, :location => course_gradebook_url(@assignment.context),
                   :as_text => true
          }
        else
          flash[:error] = t('errors.submission_failed', "Submission was unsuccessful: %{error}", :error => @error_message || t('errors.submission_failed_default', 'Submission Failed'))
          request_error_status ||= :bad_request

          format.html { render :show, course_id: @assignment.context.id }
          format.json { render json: { errors: { base: @error_message } }, status: request_error_status }
          format.text { render json: { errors: { base: @error_message } }, status: request_error_status }
        end
      end
    end
  end

  def submissions_json
    @submissions.map do |s|
      json = s.as_json(Submission.json_serialization_full_parameters)
      json['submission']['provisional_grade_id'] = s.provisional_grade_id if s.provisional_grade_id
      json
    end
  end

  def submissions_zip_upload
    return unless authorized_action(@context, @current_user, :manage_grades)
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
    if @assignment.unpublished?
      flash[:notice] = t(:speedgrader_enabled_only_for_published_content,
                         'SpeedGrader is enabled only for published content.')
      return redirect_to polymorphic_url([@context, @assignment])
    end

    if canvadoc_annotations_enabled_in_firefox? ||
        submisions_attachment_crocodocable_in_firefox?(@assignment.submissions)
        flash[:notice] = t("Warning: Crocodoc has limitations when used in Firefox. Comments will not always be saved.")
    end
    grading_role = if moderated_grading_enabled_and_no_grades_published
      if @context.grants_right?(@current_user, :moderate_grades)
        :moderator
      else
        :provisional_grader
      end
    else
      :grader
    end

    respond_to do |format|
      format.html do
        @headers = false
        @outer_frame = true
        log_asset_access([ "speed_grader", @context ], "grades", "other")
        env = {
          :CONTEXT_ACTION_SOURCE => :speed_grader,
          :settings_url => speed_grader_settings_course_gradebook_path,
          :force_anonymous_grading => force_anonymous_grading?(@assignment),
          :grading_role => grading_role,
          :grading_type => @assignment.grading_type,
          :lti_retrieve_url => retrieve_course_external_tools_url(
            @context.id, assignment_id: @assignment.id, display: 'borderless'
          ),
          :course_id => @context.id,
          :assignment_id => @assignment.id,
        }
        if [:moderator, :provisional_grader].include?(grading_role)
          env[:provisional_status_url] = api_v1_course_assignment_provisional_status_path(@context.id, @assignment.id)
        end
        if grading_role == :moderator
          env[:provisional_copy_url] = api_v1_copy_to_final_mark_path(@context.id, @assignment.id, "{{provisional_grade_id}}")
          env[:provisional_select_url] = api_v1_select_provisional_grade_path(@context.id, @assignment.id, "{{provisional_grade_id}}")
        end

        if @assignment.quiz
          env[:quiz_history_url] = course_quiz_history_path @context.id,
                                                            @assignment.quiz.id,
                                                            :user_id => "{{user_id}}"
        end
        append_sis_data(env)
        js_env(env)
        render
      end

      format.json do
        render json: Assignment::SpeedGrader.new(
          @assignment,
          @current_user,
          avatars: service_enabled?(:avatars),
          grading_role: grading_role
        ).json
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
  end

  def change_gradebook_column_size
    if authorized_action(@context, @current_user, :manage_grades)
      unless @current_user.preferences.key?(:gradebook_column_size)
        @current_user.preferences[:gradebook_column_size] = {}
      end

      @current_user.preferences[:gradebook_column_size][params[:column_id]] = params[:column_size]
      @current_user.save!
      render json: nil
    end
  end

  def save_gradebook_column_order
    if authorized_action(@context, @current_user, :manage_grades)
      unless @current_user.preferences.key?(:gradebook_column_order)
        @current_user.preferences[:gradebook_column_order] = {}
      end

      @current_user.preferences[:gradebook_column_order][@context.id] = params[:column_order].to_hash.with_indifferent_access
      @current_user.save!
      render json: nil
    end
  end

  def change_gradebook_version
    @current_user.preferences[:gradebook_version] = params[:version]
    @current_user.save!
    redirect_to polymorphic_url([@context, 'gradebook'])
  end

  def groups_as_assignments(groups=nil, options = {})
    groups ||= @context.assignment_groups.active

    percentage = lambda do |weight|
      I18n.n(weight, percentage: true)
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

  private

  def moderated_grading_enabled_and_no_grades_published
    @assignment.moderated_grading? && !@assignment.grades_published?
  end

  def exclude_total?(context)
    return true if context.hide_final_grades

    all_grading_periods_selected =
      multiple_grading_periods? && view_all_grading_periods?
    hide_all_grading_periods_totals = !context.feature_enabled?(:all_grading_periods_totals)
    all_grading_periods_selected && hide_all_grading_periods_totals
  end

  def submisions_attachment_crocodocable_in_firefox?(submissions)
    request.user_agent.to_s =~ /Firefox/ &&
    submissions.
      joins("left outer join #{submissions.connection.quote_table_name('canvadocs_submissions')} cs on cs.submission_id = submissions.id").
      joins("left outer join #{CrocodocDocument.quoted_table_name} on cs.crocodoc_document_id = crocodoc_documents.id").
      joins("left outer join #{Canvadoc.quoted_table_name} on cs.canvadoc_id = canvadocs.id").
      where("cs.crocodoc_document_id IS NOT null or cs.canvadoc_id IS NOT null").
      exists?
  end

  def canvadoc_annotations_enabled_in_firefox?
    request.user_agent.to_s =~ /Firefox/ &&
    Canvadocs.enabled? &&
    Canvadocs.annotations_supported? &&
    @assignment.submission_types.include?('online_upload')
  end

  def grade_summary_presenter
    options = presenter_options
    if options.key?(:grading_period_id)
      GradingPeriodGradeSummaryPresenter.new(@context, @current_user, params[:id], options)
    else
      GradeSummaryPresenter.new(@context, @current_user, params[:id], options)
    end
  end

  def presenter_options
    options = {}
    return options unless @context.present?

    if @current_grading_period_id.present? && !view_all_grading_periods? && multiple_grading_periods?
      options[:grading_period_id] = @current_grading_period_id
    end

    return options unless @current_user.present?

    order_preferences = @current_user.preferences[:course_grades_assignment_order]
    saved_order = order_preferences && order_preferences[@context.id]
    options[:assignment_order] = saved_order if saved_order.present?
    options
  end

  def custom_course_users_api_url(include_concluded: false, include_inactive: false, per_page:)
    state = %w[active invited]
    state << 'completed' if include_concluded
    state << 'inactive'  if include_inactive
    api_v1_course_users_url(
      @context,
      include: %i[avatar_url group_ids enrollments],
      enrollment_type: %w[student student_view],
      enrollment_state: state,
      per_page: per_page
    )
  end

  def custom_course_enrollments_api_url(include_concluded: false, include_inactive: false, per_page:)
    state = %w[active invited]
    state << 'completed' if include_concluded
    state << 'inactive'  if include_inactive
    api_v1_course_enrollments_url(
      @context,
      include: %i[avatar_url group_ids],
      type: %w[StudentEnrollment StudentViewEnrollment],
      state: state,
      per_page: per_page
    )
  end
end
