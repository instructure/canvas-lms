# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include SubmissionCommentsHelper
  include KalturaHelper
  include Api::V1::AssignmentGroup
  include Api::V1::Group
  include Api::V1::GroupCategory
  include Api::V1::Submission
  include Api::V1::CustomGradebookColumn
  include Api::V1::Section
  include Api::V1::Rubric
  include Api::V1::RubricAssessment

  before_action :require_context
  before_action :require_user, only: %i[speed_grader speed_grader_settings grade_summary grading_rubrics update_final_grade_overrides]

  include K5Mode

  batch_jobs_in_actions only: :update_submission, batch: { priority: Delayed::LOW_PRIORITY }

  add_crumb(proc { t "#crumbs.grades", "Grades" }) { |c| c.send :named_context_url, c.instance_variable_get(:@context), :context_grades_url }
  before_action { |c| c.active_tab = "grades" }

  MAX_POST_GRADES_TOOLS = 10

  def grade_summary
    set_current_grading_period if grading_periods?
    @presenter = grade_summary_presenter
    student_enrollment = @presenter.student_enrollment
    # do this as the very first thing, if the current user is a
    # teacher in the course and they are not trying to view another
    # user's grades, redirect them to the gradebook
    if @presenter.user_needs_redirection?
      return redirect_to polymorphic_url([@context, :gradebook])
    end

    if !@presenter.student || !student_enrollment
      return render_unauthorized_action
    end

    return unless authorized_action(@context, @current_user, :read) &&
                  authorized_action(student_enrollment, @current_user, :read_grades)

    log_asset_access(["grades", @context], "grades", "other")

    js_env({
             course_id: @context.id,
             restrict_quantitative_data: @context.restrict_quantitative_data?(@current_user),
             student_grade_summary_upgrade: Account.site_admin.feature_enabled?(:student_grade_summary_upgrade),
             can_clear_badge_counts: Account.site_admin.grants_right?(@current_user, :manage_students),
             custom_grade_statuses: @context.custom_grade_statuses.as_json(include_root: false)
           })
    return render :grade_summary_list unless @presenter.student

    unless @context.root_account.feature_enabled?(:instui_nav)
      add_crumb(@presenter.student_name, named_context_url(@context,
                                                           :context_student_grades_url,
                                                           @presenter.student_id))
    end

    js_bundle :grade_summary, :rubric_assessment
    css_bundle :grade_summary

    load_grade_summary_data
    render stream: can_stream_template?
  end

  def load_grade_summary_data
    gp_id = nil
    if grading_periods?
      @grading_periods = active_grading_periods_json
      gp_id = @current_grading_period_id unless view_all_grading_periods?

      effective_due_dates =
        Submission.active
                  .where(user_id: @presenter.student_id, assignment_id: @context.assignments.active)
                  .select(:cached_due_date, :grading_period_id, :assignment_id, :user_id)
                  .each_with_object({}) do |submission, hsh|
          hsh[submission.assignment_id] = {
            submission.user_id => {
              due_at: submission.cached_due_date,
              grading_period_id: submission.grading_period_id,
            }
          }
        end
    end

    @exclude_total = exclude_total?(@context)

    GuardRail.activate(:secondary) do
      # run these queries on the secondary database for speed
      @presenter.assignments
      aggregate_assignments
      @presenter.submissions
      @presenter.assignment_stats
    end

    ActiveRecord::Associations.preload(@presenter.submissions, :visible_submission_comments)
    custom_gradebook_statuses_enabled = Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
    submissions_json = @presenter.submissions.map do |submission|
      json = {
        assignment_id: submission.assignment_id
      }
      if submission.user_can_read_grade?(@presenter.student)
        json.merge!({
                      excused: submission.excused?,
                      score: submission.score,
                      workflow_state: submission.workflow_state,
                    })
        json[:custom_grade_status_id] = submission.custom_grade_status_id if custom_gradebook_statuses_enabled
      end

      json[:submission_comments] = submission.visible_submission_comments.map do |comment|
        comment_map = {
          id: comment.id,
          attachments: comment.cached_attachments.map do |attachment|
            {
              id: attachment.id,
              display_name: attachment.display_name,
              mime_class: Attachment.mime_class(attachment.content_type),
              url: file_download_url(attachment.id)
            }.as_json
          end,
          attempt: comment.attempt,
          author_name: comment_author_name_for(comment),
          created_at: comment.created_at,
          edited_at: comment.edited_at,
          updated_at: comment.updated_at,
          comment: comment.comment,
          display_updated_at: datetime_string(comment.updated_at),
          is_read: comment.read?(@current_user) || (!@presenter.student_is_user? && !@presenter.user_an_observer_of_student?),
        }
        if comment.media_comment? && (media_object = SubmissionComment.serialize_media_comment(comment.media_comment_id))
          comment_map[:media_object] = media_object
        end
        comment_map
      end.as_json
      json[:assignment_url] = context_url(@context, :context_assignment_url, submission.assignment_id)

      json
    end

    grading_period = @grading_periods&.find { |period| period[:id] == gp_id }

    ags_json = light_weight_ags_json(@presenter.groups)
    root_account = @context.root_account

    js_hash = {
      submissions: submissions_json,
      assignment_groups: ags_json,
      assignment_sort_options: @presenter.sort_options,
      group_weighting_scheme: @context.group_weighting_scheme,
      show_total_grade_as_points: @context.show_total_grade_as_points?,
      grade_calc_ignore_unposted_anonymous_enabled: root_account.feature_enabled?(:grade_calc_ignore_unposted_anonymous),
      current_grading_period_id: @current_grading_period_id,
      current_assignment_sort_order: @presenter.assignment_order,
      grading_period_set: grading_period_group_json,
      grading_period:,
      grading_periods: @grading_periods,
      hide_final_grades: @context.hide_final_grades,
      courses_with_grades: courses_with_grades_json,
      effective_due_dates:,
      exclude_total: @exclude_total,
      gradebook_non_scoring_rubrics_enabled: root_account.feature_enabled?(:non_scoring_rubrics),
      rubric_assessments: rubric_assessments_json(@presenter.rubric_assessments, @current_user, session, style: "full"),
      rubrics: rubrics_json(@presenter.rubrics, @current_user, session, style: "full"),
      save_assignment_order_url: course_save_assignment_order_url(@context),
      student_outcome_gradebook_enabled: @context.feature_enabled?(:student_outcome_gradebook),
      student_id: @presenter.student_id,
      students: @presenter.students.as_json(include_root: false),
      outcome_proficiency:,
      outcome_service_results_to_canvas: outcome_service_results_to_canvas_enabled?
    }

    course_active_grading_standard = if @context.grading_standard_id.nil?
                                       if @context.restrict_quantitative_data?(@current_user)
                                         GradingSchemesJsonController.default_canvas_grading_standard(@context)
                                       else
                                         nil
                                       end
                                     elsif @context.grading_standard_id == 0
                                       GradingSchemesJsonController.default_canvas_grading_standard(@context)
                                     else
                                       standard = GradingStandard.for(@context).find_by(id: @context.grading_standard_id)
                                       if standard.nil?
                                         # course's grading standard was soft deleted. use canvas default scheme, since grading
                                         # schemes are enabled for the course (or else course would have a nil grading standard id)
                                         GradingSchemesJsonController.default_canvas_grading_standard(@context)
                                       else
                                         standard
                                       end
                                     end
    course_active_grading_scheme = if course_active_grading_standard
                                     GradingSchemesJsonController.base_grading_scheme_json(course_active_grading_standard, @current_user)
                                   else
                                     nil
                                   end
    js_hash[:course_active_grading_scheme] = course_active_grading_scheme

    # This really means "if the final grade override feature flag is enabled AND
    # the context in question has enabled the setting in the gradebook"
    if @context.allow_final_grade_override?
      total_score = if grading_periods? && !view_all_grading_periods?
                      @presenter.student_enrollment.find_score(grading_period_id: @current_grading_period_id)
                    else
                      @presenter.student_enrollment.find_score(course_score: true)
                    end

      js_hash[:effective_final_score] = total_score.effective_final_score if total_score&.overridden?
      js_hash[:final_override_custom_grade_status_id] = total_score.custom_grade_status_id if total_score&.custom_grade_status_id && Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
    end

    js_env(js_hash)
  end

  def save_assignment_order
    if authorized_action(@context, @current_user, :read)
      allowed_orders = {
        "due_at" => :due_at,
        "title" => :title,
        "module" => :module,
        "assignment_group" => :assignment_group
      }
      assignment_order = allowed_orders.fetch(params.fetch(:assignment_order), :due_at)
      @current_user.set_preference(:course_grades_assignment_order, @context.id, assignment_order)
      redirect_back(fallback_location: course_grades_url(@context))
    end
  end

  def light_weight_ags_json(assignment_groups)
    assignments_by_group = @presenter.assignments.each_with_object({}) do |assignment, assignments|
      # Pseudo-assignment objects with a "special_class" set are created for
      # assignment group totals, grading period totals, and course totals. We
      # only care about real assignments here, so we'll ignore those
      # pseudo-assignment objects.
      next if assignment.special_class

      assignments[assignment.assignment_group_id] ||= []
      assignments[assignment.assignment_group_id] << {
        id: assignment.id,
        submission_types: assignment.submission_types_array,
        points_possible: assignment.points_possible,
        due_at: assignment.due_at,
        omit_from_final_grade: assignment.omit_from_final_grade?,
        muted: assignment.muted?
      }
    end

    assignment_groups.map do |group|
      {
        id: group.id,
        rules: group.rules_hash({ stringify_json_ids: true }),
        group_weight: group.group_weight,
        assignments: assignments_by_group.fetch(group.id, [])
      }
    end
  end

  def grading_rubrics
    return unless authorized_action(@context, @current_user, [:read_rubrics, :manage_rubrics])

    @rubric_contexts = @context.rubric_contexts(@current_user)
    if params[:context_code]
      context = @rubric_contexts.detect { |r| r[:context_code] == params[:context_code] }
      @rubric_context = @context
      if context
        @rubric_context = Context.find_by_asset_string(params[:context_code])
      end
      @rubric_associations = @rubric_context.shard.activate { Context.sorted_rubrics(@rubric_context) }
      data = @rubric_associations.map do |ra|
        json = ra.as_json(methods: [:context_name], include: { rubric: { include_root: false } })
        # return shard-aware context codes
        json["rubric_association"]["context_code"] = ra.context.asset_string
        json["rubric_association"]["rubric"]["context_code"] = ra.rubric.context.asset_string
        json
      end
      render json: StringifyIds.recursively_stringify_ids(data)
    else
      render json: @rubric_contexts
    end
  end

  def show
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      log_asset_access(["grades", @context], "grades")

      # nomenclature of gradebook "versions":
      #   "gradebook" (default grid view)
      #     within the "gradebook" version there are two "views":
      #       "default"
      #       "learning_mastery"
      #   "individual" (also "srgb")
      #   "individual_enhanced"

      if requested_gradebook_view.present?
        if requested_gradebook_view != preferred_gradebook_view
          update_preferred_gradebook_view!(requested_gradebook_view)
        end
        redirect_to polymorphic_url([@context, :gradebook])
        return
      end

      individual_enhanced_enabled = @context.root_account.feature_enabled?(:individual_gradebook_enhancements)
      if gradebook_version == "individual_enhanced" && individual_enhanced_enabled
        show_enhanced_individual_gradebook
      elsif ["srgb", "individual"].include?(gradebook_version)
        show_individual_gradebook
      elsif preferred_gradebook_view == "learning_mastery" && outcome_gradebook_enabled?
        show_learning_mastery
      else
        show_default_gradebook
      end
    end
  end

  def show_default_gradebook
    set_current_grading_period if grading_periods?
    set_tutorial_js_env

    # Optimize initial data loading
    prefetch_xhr(user_ids_course_gradebook_url(@context), id: "user_ids")

    if grading_periods?
      prefetch_xhr(grading_period_assignments_course_gradebook_url(@context), id: "grading_period_assignments")
    end

    set_default_gradebook_env
    render "gradebooks/gradebook"
  end
  private :show_default_gradebook

  def show_individual_gradebook
    set_current_grading_period if grading_periods?
    set_tutorial_js_env

    set_individual_gradebook_env
    render "gradebooks/individual"
  end
  private :show_individual_gradebook

  def show_enhanced_individual_gradebook
    set_current_grading_period if grading_periods?
    set_enhanced_individual_gradebook_env
    deferred_js_bundle :enhanced_individual_gradebook
    @page_title = t("Gradebook: Individual View")
    render html: "".html_safe, layout: true
  end
  private :show_enhanced_individual_gradebook

  def show_learning_mastery
    InstStatsd::Statsd.increment("outcomes_page_views", tags: { type: "teacher_lmgb" })
    set_current_grading_period if grading_periods?
    set_tutorial_js_env

    set_learning_mastery_env
    render "gradebooks/learning_mastery"
  end
  private :show_learning_mastery

  def post_grades_ltis
    @post_grades_ltis ||= external_tools.map { |tool| external_tool_detail(tool) }
  end

  def external_tool_detail(tool)
    post_grades_placement = tool[:placements][:post_grades]
    {
      id: tool[:definition_id],
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
      when "ContextExternalTool"
        url = external_tool_url_for_lti1(launch_definition)
      when "Lti::MessageHandler"
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
      display: "borderless",
      launch_type: "post_grades"
    )
  end

  def external_tool_url_for_lti2(launch_definition)
    polymorphic_url(
      [@context, :basic_lti_launch_request],
      message_handler_id: launch_definition[:definition_id],
      display: "borderless"
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

  def grading_period_group
    return @grading_period_group if defined? @grading_period_group

    @grading_period_group = active_grading_periods.first&.grading_period_group
  end

  def active_grading_periods
    @active_grading_periods ||= GradingPeriod.for(@context).order(:start_date)
  end

  def grading_period_group_json
    return @grading_period_group_json if defined? @grading_period_group_json
    return @grading_period_group_json = nil unless grading_period_group.present?

    @grading_period_group_json = grading_period_group
                                 .as_json
                                 .fetch(:grading_period_group)
                                 .merge(grading_periods: active_grading_periods_json)
  end

  def active_grading_periods_json
    @agp_json ||= GradingPeriod.periods_json(active_grading_periods, @current_user)
  end

  def set_default_gradebook_env
    set_student_context_cards_js_env

    gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    per_page = Api::MAX_PER_PAGE
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(teacher_notes: true).first

    last_exported_gradebook_csv = GradebookCSV.last_successful_export(course: @context, user: @current_user)
    last_exported_attachment = last_exported_gradebook_csv.try(:attachment)

    if allow_apply_score_to_ungraded?
      last_score_to_ungraded = Progress.where(context: @context, tag: "apply_score_to_ungraded_assignments").order(created_at: :desc).first
      last_score_to_ungraded = nil if last_score_to_ungraded&.failed?
    end

    grading_standard = @context.grading_standard_or_default
    graded_late_submissions_exist = @context.submissions.graded.late.exists?
    visible_sections = @context.sections_visible_to(@current_user)
    root_account = @context.root_account

    custom_grade_statuses_enabled = Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
    standard_statuses = custom_grade_statuses_enabled ? root_account.standard_grade_statuses : []
    standard_status_hash = standard_statuses.pluck(:status_name, :color).to_h
    colors = standard_status_hash.merge!(gradebook_settings(:colors))

    custom_grade_statuses = custom_grade_statuses_enabled ? @context.custom_grade_statuses.as_json(include_root: false) : []

    gradebook_options = {
      active_grading_periods: active_grading_periods_json,
      allow_separate_first_last_names: @context.account.allow_gradebook_show_first_last_names? && Account.site_admin.feature_enabled?(:gradebook_show_first_last_names),
      allow_view_ungraded_as_zero: allow_view_ungraded_as_zero?,
      allow_apply_score_to_ungraded: allow_apply_score_to_ungraded?,
      attachment: last_exported_attachment,
      attachment_url: authenticated_download_url(last_exported_attachment),
      change_gradebook_version_url: context_url(@context, :change_gradebook_version_context_gradebook_url, version: 2),
      colors:,
      context_allows_gradebook_uploads: @context.allows_gradebook_uploads?,
      context_code: @context.asset_string,
      context_id: @context.id.to_s,
      context_sis_id: @context.sis_source_id,
      context_url: named_context_url(@context, :context_url),
      course_is_concluded: @context.completed?,
      course_name: @context.name,

      course_settings: {
        allow_final_grade_override: @context.allow_final_grade_override?,
        filter_speed_grader_by_student_group: @context.filter_speed_grader_by_student_group?
      },

      course_url: api_v1_course_url(@context),
      current_grading_period_id: @current_grading_period_id,
      custom_column_datum_url: api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      custom_grade_statuses:,
      custom_grade_statuses_enabled:,
      default_grading_standard: grading_standard.data,
      download_assignment_submissions_url: named_context_url(@context, :context_assignment_submissions_url, "{{ assignment_id }}", zip: 1),
      enhanced_gradebook_filters: @context.feature_enabled?(:enhanced_gradebook_filters),
      hide_zero_point_quizzes: Account.site_admin.feature_enabled?(:hide_zero_point_quizzes_option),
      enrollments_url: custom_course_enrollments_api_url(per_page:),
      enrollments_with_concluded_url: custom_course_enrollments_api_url(include_concluded: true, per_page:),
      export_gradebook_csv_url: course_gradebook_csv_url,
      final_grade_override_enabled: @context.feature_enabled?(:final_grades_override),
      gradebook_column_order_settings: @current_user.get_preference(:gradebook_column_order, @context.global_id),
      gradebook_column_order_settings_url: save_gradebook_column_order_course_gradebook_url,
      gradebook_column_size_settings: gradebook_column_size_preferences,
      gradebook_column_size_settings_url: change_gradebook_column_size_course_gradebook_url,
      gradebook_csv_progress: last_exported_gradebook_csv.try(:progress),
      gradebook_score_to_ungraded_progress: last_score_to_ungraded,
      gradebook_import_url: new_course_gradebook_upload_path(@context),
      gradebook_is_editable:,
      grade_calc_ignore_unposted_anonymous_enabled: root_account.feature_enabled?(:grade_calc_ignore_unposted_anonymous),
      graded_late_submissions_exist:,
      grading_period_set: grading_period_group_json,
      grading_schemes: GradingStandard.for(@context, include_archived: true).as_json(include_root: false),
      grading_standard: @context.grading_standard_enabled? && grading_standard.data,
      grading_standard_points_based: active_grading_standard_points_based(grading_standard),
      grading_standard_scaling_factor: active_grading_standard_scaling_factor(grading_standard),
      group_weighting_scheme: @context.group_weighting_scheme,
      has_modules: @context.has_modules?,
      individual_gradebook_enhancements: root_account.feature_enabled?(:individual_gradebook_enhancements),
      late_policy: @context.late_policy.as_json(include_root: false),
      login_handle_name: root_account.settings[:login_handle_name],
      message_attachment_upload_folder_id: @current_user.conversation_attachments_folder.id.to_s,
      multiselect_gradebook_filters_enabled: Account.site_admin.feature_enabled?(:multiselect_gradebook_filters),
      outcome_gradebook_enabled: outcome_gradebook_enabled?,
      performance_controls: gradebook_performance_controls,
      post_grades_feature: post_grades_feature?,
      post_grades_ltis:,
      post_manually: @context.post_manually?,
      proxy_submissions_allowed: Account.site_admin.feature_enabled?(:proxy_file_uploads) && @context.grants_right?(@current_user, session, :proxy_assignment_submission),
      publish_to_sis_enabled:
        !!@context.sis_source_id && @context.allows_grade_publishing_by(@current_user) && gradebook_is_editable,

      publish_to_sis_url: context_url(@context, :context_details_url, anchor: "tab-grade-publishing"),
      re_upload_submissions_url: named_context_url(@context, :submissions_upload_context_gradebook_url, "{{ assignment_id }}"),
      restrict_quantitative_data: @context.restrict_quantitative_data?(@current_user),
      reorder_custom_columns_url: api_v1_custom_gradebook_columns_reorder_url(@context),
      sections: sections_json(visible_sections, @current_user, session, [], allow_sis_ids: true),
      setting_update_url: api_v1_course_settings_url(@context),
      settings: gradebook_settings(@context.global_id),
      settings_update_url: api_v1_course_gradebook_settings_update_url(@context),
      show_message_students_with_observers_dialog: show_message_students_with_observers_dialog?,
      show_similarity_score: root_account.feature_enabled?(:new_gradebook_plagiarism_indicator),
      show_total_grade_as_points: @context.show_total_grade_as_points?,
      sis_app_token: Setting.get("sis_app_token", nil),
      sis_app_url: Setting.get("sis_app_url", nil),
      sis_name: root_account.settings[:sis_name],
      speed_grader_enabled: @context.allows_speed_grader?,
      student_groups: gradebook_group_categories_json,
      teacher_notes: teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      user_asset_string: @current_user&.asset_string,
      version: params.fetch(:version, nil),
      assignment_missing_shortcut: Account.site_admin.feature_enabled?(:assignment_missing_shortcut),
      grading_periods_filter_dates_enabled: Account.site_admin.feature_enabled?(:grading_periods_filter_dates),
    }

    js_env({
             EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
             EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list],
             GRADEBOOK_OPTIONS: gradebook_options
           })
  end

  def set_enhanced_individual_gradebook_env
    gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    grading_standard = @context.grading_standard_or_default
    last_exported_gradebook_csv = GradebookCSV.last_successful_export(course: @context, user: @current_user)
    last_exported_attachment = last_exported_gradebook_csv.try(:attachment)
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(teacher_notes: true).first
    per_page = Api::MAX_PER_PAGE
    gradebook_options = {
      active_grading_periods: active_grading_periods_json,
      attachment_url: authenticated_download_url(last_exported_attachment),
      change_grade_url: api_v1_course_assignment_submission_url(@context, ":assignment", ":submission", include: [:visibility]),
      course_settings: {
        allow_final_grade_override: @context.allow_final_grade_override?,
        filter_speed_grader_by_student_group: @context.filter_speed_grader_by_student_group?
      },
      context_id: @context.id.to_s,
      context_url: named_context_url(@context, :context_url),
      custom_column_data_url: api_v1_course_custom_gradebook_column_data_url(@context, ":id", per_page:),
      custom_column_datum_url: api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      custom_column_url: api_v1_course_custom_gradebook_column_url(@context, ":id"),
      custom_columns_url: api_v1_course_custom_gradebook_columns_url(@context),
      export_gradebook_csv_url: course_gradebook_csv_url,
      final_grade_override_enabled: @context.feature_enabled?(:final_grades_override),
      grade_calc_ignore_unposted_anonymous_enabled: @context.root_account.feature_enabled?(:grade_calc_ignore_unposted_anonymous),
      gradebook_csv_progress: last_exported_gradebook_csv.try(:progress),
      gradebook_is_editable:,
      grades_are_weighted: (grading_period_group_json && grading_period_group_json[:weighted]) || @context.group_weighting_scheme == "percent" || false,
      grading_period_set: grading_period_group_json,
      grading_schemes: GradingStandard.for(@context).as_json(include_root: false),
      grading_standard: @context.grading_standard_enabled? && grading_standard.data,
      grading_standard_points_based: active_grading_standard_points_based(grading_standard),
      grading_standard_scaling_factor: active_grading_standard_scaling_factor(grading_standard),
      group_weighting_scheme: @context.group_weighting_scheme,
      individual_gradebook_enhancements: true,
      outcome_gradebook_enabled: outcome_gradebook_enabled?,
      proxy_submissions_allowed: Account.site_admin.feature_enabled?(:proxy_file_uploads) && @context.grants_right?(@current_user, session, :proxy_assignment_submission),
      publish_to_sis_enabled:
        !!@context.sis_source_id && @context.allows_grade_publishing_by(@current_user) && gradebook_is_editable,
      publish_to_sis_url: context_url(@context, :context_details_url, anchor: "tab-grade-publishing"),
      reorder_custom_columns_url: api_v1_custom_gradebook_columns_reorder_url(@context),
      save_view_ungraded_as_zero_to_server: allow_view_ungraded_as_zero?,
      setting_update_url: api_v1_course_settings_url(@context),
      settings: gradebook_settings(@context.global_id),
      settings_update_url: api_v1_course_gradebook_settings_update_url(@context),
      show_total_grade_as_points: @context.show_total_grade_as_points?,
      teacher_notes: teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      message_attachment_upload_folder_id: @current_user.conversation_attachments_folder.id.to_s,
      download_assignment_submissions_url: named_context_url(@context, :context_assignment_submissions_url, ":assignment", zip: 1),
    }
    js_env({
             GRADEBOOK_OPTIONS: gradebook_options,
           })
  end

  def set_individual_gradebook_env
    set_student_context_cards_js_env

    gradebook_is_editable = @context.grants_right?(@current_user, session, :manage_grades)
    per_page = Api::MAX_PER_PAGE
    teacher_notes = @context.custom_gradebook_columns.not_deleted.where(teacher_notes: true).first
    ag_includes = %i[assignments assignment_visibility grades_published]

    last_exported_gradebook_csv = GradebookCSV.last_successful_export(course: @context, user: @current_user)
    last_exported_attachment = last_exported_gradebook_csv.try(:attachment)

    grading_standard = @context.grading_standard_or_default
    graded_late_submissions_exist = @context.submissions.graded.late.exists?
    visible_sections = @context.sections_visible_to(@current_user)
    root_account = @context.root_account

    gradebook_options = {
      active_grading_periods: active_grading_periods_json,
      api_max_per_page: per_page,

      assignment_groups_url: api_v1_course_assignment_groups_url(
        @context,
        include: ag_includes,
        override_assignment_dates: "false",
        exclude_assignment_submission_types: ["wiki_page"]
      ),

      attachment: last_exported_attachment,
      attachment_url: authenticated_download_url(last_exported_attachment),
      change_grade_url: api_v1_course_assignment_submission_url(@context, ":assignment", ":submission", include: [:visibility]),
      change_gradebook_version_url: context_url(@context, :change_gradebook_version_context_gradebook_url, version: 2),
      chunk_size: Setting.get("gradebook2.submissions_chunk_size", "10").to_i,
      colors: gradebook_settings(:colors),
      context_allows_gradebook_uploads: @context.allows_gradebook_uploads?,
      context_code: @context.asset_string,
      context_id: @context.id.to_s,
      context_modules_url: api_v1_course_context_modules_url(@context),
      context_sis_id: @context.sis_source_id,
      context_url: named_context_url(@context, :context_url),
      course_name: @context.name,

      course_settings: {
        allow_final_grade_override: @context.allow_final_grade_override?,
        filter_speed_grader_by_student_group: @context.filter_speed_grader_by_student_group?
      },

      course_url: api_v1_course_url(@context),
      current_grading_period_id: @current_grading_period_id,
      custom_column_data_url: api_v1_course_custom_gradebook_column_data_url(@context, ":id", per_page:),
      custom_column_datum_url: api_v1_course_custom_gradebook_column_datum_url(@context, ":id", ":user_id"),
      custom_column_url: api_v1_course_custom_gradebook_column_url(@context, ":id"),
      custom_columns_url: api_v1_course_custom_gradebook_columns_url(@context),
      default_grading_standard: grading_standard.data,
      download_assignment_submissions_url: named_context_url(@context, :context_assignment_submissions_url, "{{ assignment_id }}", zip: 1),
      enrollments_url: custom_course_enrollments_api_url(per_page:),
      enrollments_with_concluded_url: custom_course_enrollments_api_url(include_concluded: true, per_page:),
      export_gradebook_csv_url: course_gradebook_csv_url,
      final_grade_override_enabled: @context.feature_enabled?(:final_grades_override),
      gradebook_column_order_settings: @current_user.get_preference(:gradebook_column_order, @context.global_id),
      gradebook_column_order_settings_url: save_gradebook_column_order_course_gradebook_url,
      gradebook_column_size_settings: gradebook_column_size_preferences,
      gradebook_column_size_settings_url: change_gradebook_column_size_course_gradebook_url,
      gradebook_csv_progress: last_exported_gradebook_csv.try(:progress),
      gradebook_import_url: new_course_gradebook_upload_path(@context),
      gradebook_is_editable:,
      grade_calc_ignore_unposted_anonymous_enabled: root_account.feature_enabled?(:grade_calc_ignore_unposted_anonymous),
      graded_late_submissions_exist:,
      grading_period_set: grading_period_group_json,
      grading_schemes: GradingStandard.for(@context).as_json(include_root: false),
      grading_standard: @context.grading_standard_enabled? && grading_standard.data,
      grading_standard_points_based: active_grading_standard_points_based(grading_standard),
      grading_standard_scaling_factor: active_grading_standard_scaling_factor(grading_standard),
      group_weighting_scheme: @context.group_weighting_scheme,
      hide_zero_point_quizzes: Account.site_admin.feature_enabled?(:hide_zero_point_quizzes_option),
      late_policy: @context.late_policy.as_json(include_root: false),
      login_handle_name: root_account.settings[:login_handle_name],
      has_modules: @context.has_modules?,
      individual_gradebook_enhancements: root_account.feature_enabled?(:individual_gradebook_enhancements),
      message_attachment_upload_folder_id: @current_user.conversation_attachments_folder.id.to_s,
      outcome_gradebook_enabled: outcome_gradebook_enabled?,
      outcome_links_url: api_v1_course_outcome_group_links_url(@context, outcome_style: :full),
      outcome_rollups_url: api_v1_course_outcome_rollups_url(@context, per_page: 100),
      post_grades_feature: post_grades_feature?,
      post_manually: @context.post_manually?,
      proxy_submissions_allowed: Account.site_admin.feature_enabled?(:proxy_file_uploads) && @context.grants_right?(@current_user, session, :proxy_assignment_submission),
      publish_to_sis_enabled:
        !!@context.sis_source_id && @context.allows_grade_publishing_by(@current_user) && gradebook_is_editable,

      publish_to_sis_url: context_url(@context, :context_details_url, anchor: "tab-grade-publishing"),
      re_upload_submissions_url: named_context_url(@context, :submissions_upload_context_gradebook_url, "{{ assignment_id }}"),
      reorder_custom_columns_url: api_v1_custom_gradebook_columns_reorder_url(@context),
      save_view_ungraded_as_zero_to_server: allow_view_ungraded_as_zero?,
      sections: sections_json(visible_sections, @current_user, session, [], allow_sis_ids: true),
      sections_url: api_v1_course_sections_url(@context),
      setting_update_url: api_v1_course_settings_url(@context),
      settings: gradebook_settings(@context.global_id),
      settings_update_url: api_v1_course_gradebook_settings_update_url(@context),
      show_message_students_with_observers_dialog: show_message_students_with_observers_dialog?,
      show_similarity_score: root_account.feature_enabled?(:new_gradebook_plagiarism_indicator),
      show_total_grade_as_points: @context.show_total_grade_as_points?,
      sis_app_token: Setting.get("sis_app_token", nil),
      sis_app_url: Setting.get("sis_app_url", nil),
      sis_name: root_account.settings[:sis_name],
      speed_grader_enabled: @context.allows_speed_grader?,
      student_groups: gradebook_group_categories_json,
      submissions_url: api_v1_course_student_submissions_url(@context, grouped: "1"),
      teacher_notes: teacher_notes && custom_gradebook_column_json(teacher_notes, @current_user, session),
      user_asset_string: @current_user&.asset_string,
      version: params.fetch(:version, nil)
    }

    js_env({
             GRADEBOOK_OPTIONS: gradebook_options,
             outcome_service_results_to_canvas: outcome_service_results_to_canvas_enabled?,
           })
  end

  def set_learning_mastery_env
    set_student_context_cards_js_env
    root_account = @context.root_account
    visible_sections = if root_account.feature_enabled?(:limit_section_visibility_in_lmgb)
                         @context.sections_visible_to(@current_user)
                       else
                         @context.active_course_sections
                       end

    js_env({
             GRADEBOOK_OPTIONS: {
               context_id: @context.id.to_s,
               context_url: named_context_url(@context, :context_url),
               ACCOUNT_LEVEL_MASTERY_SCALES: root_account.feature_enabled?(:account_level_mastery_scales),
               OUTCOMES_FRIENDLY_DESCRIPTION: Account.site_admin.feature_enabled?(:outcomes_friendly_description),
               outcome_proficiency:,
               sections: sections_json(visible_sections, @current_user, session, [], allow_sis_ids: true),
               settings: gradebook_settings(@context.global_id),
               settings_update_url: api_v1_course_gradebook_settings_update_url(@context),
               IMPROVED_LMGB: root_account.feature_enabled?(:improved_lmgb),
               individual_gradebook_enhancements: root_account.feature_enabled?(:individual_gradebook_enhancements),
             },
             OUTCOME_AVERAGE_CALCULATION: root_account.feature_enabled?(:outcome_average_calculation),
             outcome_service_results_to_canvas: outcome_service_results_to_canvas_enabled?,
             OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION: root_account.feature_enabled?(:outcomes_new_decaying_average_calculation)
           })
  end

  def outcome_gradebook_enabled?
    @context.feature_enabled?(:outcome_gradebook)
  end

  def post_grades_feature?
    @context.feature_enabled?(:post_grades) &&
      @context.allows_grade_publishing_by(@current_user) &&
      can_do(@context, @current_user, :manage_grades)
  end

  def history
    if authorized_action(@context, @current_user, %i[manage_grades view_all_grades])
      crumbs.delete_if { |crumb| crumb[0] == "Grades" }
      add_crumb(t("Gradebook History"),
                context_url(@context, controller: :gradebooks, action: :history))
      @page_title = t("Gradebook History")
      @body_classes << "full-width padless-content"
      js_bundle :gradebook_history
      js_env(
        COURSE_URL: named_context_url(@context, :context_url),
        COURSE_IS_CONCLUDED: @context.is_a?(Course) && @context.completed?,
        OUTCOME_GRADEBOOK_ENABLED: outcome_gradebook_enabled?,
        OVERRIDE_GRADES_ENABLED: @context.try(:allow_final_grade_override?),
        individual_gradebook_enhancements: @context.root_account.feature_enabled?(:individual_gradebook_enhancements)
      )

      render html: "", layout: true
    end
  end

  def update_submission
    if authorized_action(@context, @current_user, :manage_grades)
      if params[:submissions].blank? && params[:submission].blank?
        render nothing: true, status: :bad_request
        return
      end

      submissions = if $canvas_rails == "7.1"
                      params[:submissions] ? params[:submissions].values : [params[:submission]]
                    elsif params[:submissions]
                      params[:submissions].values.map { |s| ActionController::Parameters.new(s) }
                    else
                      [params[:submission]]
                    end

      # decorate submissions with user_ids if not present
      submissions_without_user_ids = submissions.select { |s| s[:user_id].blank? }
      if submissions_without_user_ids.present?
        submissions = populate_user_ids(submissions_without_user_ids)
      end

      valid_user_ids = Set.new(@context.students_visible_to(@current_user, include: :inactive).pluck(:id))
      submissions.select! { |submission| valid_user_ids.include? submission[:user_id].to_i }

      user_ids = submissions.pluck(:user_id)
      assignment_ids = submissions.pluck(:assignment_id)
      users = @context.admin_visible_students.distinct.find(user_ids).index_by(&:id)
      assignments = @context.assignments.active.find(assignment_ids).index_by(&:id)
      # `submissions` is not a collection of ActiveRecord Submission objects,
      # so we pull the records here in order to check hide_grade_from_student?
      # on each submission below.
      submission_records = Submission.where(assignment_id: assignment_ids, user_id: user_ids)

      request_error_status = nil
      error = nil
      @submissions = []
      submissions.each do |submission|
        submission_record = submission_records.find { |sub| sub.user_id == submission[:user_id].to_i }
        @assignment = assignments[submission[:assignment_id].to_i]
        @user = users[submission[:user_id].to_i]

        submission = submission.permit(:grade,
                                       :score,
                                       :excuse,
                                       :excused,
                                       :graded_anonymously,
                                       :provisional,
                                       :final,
                                       :set_by_default_grade,
                                       :comment,
                                       :media_comment_id,
                                       :media_comment_type,
                                       :group_comment,
                                       :late_policy_status).to_unsafe_h
        is_default_grade_for_missing = value_to_boolean(submission.delete(:set_by_default_grade)) && submission_record.missing? && submission_record.late_policy_status.nil?

        submission[:grader] = @current_user unless is_default_grade_for_missing
        submission.delete(:provisional) unless @assignment.moderated_grading?
        if params[:attachments]
          submission[:comment_attachments] = params[:attachments].keys.map do |idx|
            attachment_json = params[:attachments][idx].permit(Attachment.permitted_attributes)
            attachment_json[:user] = @current_user
            attachment = @assignment.attachments.new(attachment_json.except(:uploaded_data))
            Attachments::Storage.store_for_attachment(attachment, attachment_json[:uploaded_data])
            attachment.save!
            attachment
          end
        end
        begin
          track_update_metrics(params, submission_record)
          dont_overwrite_grade = value_to_boolean(params[:dont_overwrite_grades])
          if %i[grade score excuse excused].any? { |k| submission.key? k }
            # if it's a percentage graded assignment, we need to ensure there's a
            # percent sign on the end. eventually this will probably be done in
            # the javascript.
            if @assignment.grading_type == "percent" && submission[:grade] && submission[:grade] !~ /%\z/
              submission[:grade] = "#{submission[:grade]}%"
            end

            submission[:dont_overwrite_grade] = dont_overwrite_grade
            submission.delete(:final) if submission[:final] && !@assignment.permits_moderation?(@current_user)
            if params.key?(:sub_assignment_tag) && @domain_root_account&.feature_enabled?(:discussion_checkpoints)
              submission[:sub_assignment_tag] = params.delete(:sub_assignment_tag)
            end
            subs = @assignment.grade_student(@user, submission.merge(skip_grader_check: is_default_grade_for_missing))
            apply_provisional_grade_filters!(submissions: subs, final: submission[:final]) if submission[:provisional]
            @submissions += subs
          end
          if %i[comment media_comment_id comment_attachments].any? { |k| submission.key? k }
            submission[:commenter] = @current_user
            submission[:hidden] = submission_record&.hide_grade_from_student?

            subs = @assignment.update_submission(@user, submission)
            apply_provisional_grade_filters!(submissions: subs, final: submission[:final]) if submission[:provisional]
            @submissions += subs
          end

          if submission.key?(:late_policy_status) && submission_record.present? && (!dont_overwrite_grade || (submission_record.grade.blank? && !submission_record.excused?))
            submission_record.update(late_policy_status: submission[:late_policy_status])
            if submission_record.saved_change_to_late_policy_status?
              @submissions << submission_record
            end
          end
        rescue Assignment::GradeError => e
          logger.info "GRADES: grade_student failed because '#{e.message}'"
          error = e
        end
      end
      @submissions = @submissions.reverse.uniq.reverse
      @submissions = nil if submissions.empty? # no valid submissions

      respond_to do |format|
        if @submissions && error.nil?
          flash[:notice] = t("notices.updated", "Assignment submission was successfully updated.")
          format.html { redirect_to course_gradebook_url(@assignment.context) }
          format.json do
            render(
              json: submissions_json(submissions: @submissions, assignments:),
              status: :created,
              location: course_gradebook_url(@assignment.context)
            )
          end
          format.text do
            render(
              json: submissions_json(submissions: @submissions, assignments:),
              status: :created,
              location: course_gradebook_url(@assignment.context),
              as_text: true
            )
          end
        else
          error_message = error&.to_s
          flash[:error] = t(
            "errors.submission_failed",
            "Submission was unsuccessful: %{error}",
            error: error_message || t("errors.submission_failed_default", "Submission Failed")
          )
          request_error_status = error&.status_code || :bad_request

          error_json = { base: error_message }
          error_json[:error_code] = error.error_code if error

          format.html { render :show, course_id: @assignment.context.id }
          format.json { render json: { errors: error_json }, status: request_error_status }
          format.text { render json: { errors: error_json }, status: request_error_status }
        end
      end
    end
  end

  def submissions_json(submissions:, assignments:)
    submissions.map do |submission|
      assignment = assignments[submission[:assignment_id].to_i]
      omitted_field = assignment.anonymize_students? ? :user_id : :anonymous_id
      json_params = Submission.json_serialization_full_parameters(methods: [:late, :missing]).merge(
        include: { submission_history: { methods: %i[late missing word_count], except: omitted_field } },
        except: [omitted_field, :submission_comments]
      )
      json = submission.as_json(json_params)

      json[:submission].tap do |submission_json|
        submission_json[:assignment_visible] = submission.assignment_visible_to_user?(submission.user)
        submission_json[:provisional_grade_id] = submission.provisional_grade_id if submission.provisional_grade_id
        submission_json[:submission_comments] = anonymous_moderated_submission_comments_json(
          assignment: submission.assignment,
          avatars: service_enabled?(:avatars),
          submissions:,
          submission_comments: submission.visible_submission_comments_for(@current_user),
          current_user: @current_user,
          course: @context
        ).map { |c| { submission_comment: c } }
      end
      json
    end
  end

  def submissions_zip_upload
    return unless authorized_action(@context, @current_user, :manage_grades)

    assignment = @context.assignments.active.find(params[:assignment_id])

    unless @context.allows_gradebook_uploads?
      flash[:error] = t("This course does not allow score uploads.")
      redirect_to named_context_url(@context, :context_assignment_url, assignment.id)
      return
    end

    unless valid_zip_upload_params?
      flash[:error] = t("Could not find file to upload.")
      redirect_to named_context_url(@context, :context_assignment_url, assignment.id)
      return
    end

    submission_zip_params = { uploaded_data: params[:submissions_zip] }
    assignment.generate_comments_from_files_later(submission_zip_params, @current_user, params[:attachment_id])

    redirect_to named_context_url(@context, :submissions_upload_context_gradebook_url, assignment.id)
  end

  def show_submissions_upload
    return unless authorized_action(@context, @current_user, :manage_grades)

    @assignment = @context.assignments.active.find(params[:assignment_id])

    unless @context.allows_gradebook_uploads?
      flash[:error] = t("This course does not allow score uploads.")
      redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
      return
    end

    @presenter = Submission::UploadPresenter.for(@context, @assignment)

    css_bundle :show_submissions_upload
    render :show_submissions_upload
  end

  def speed_grader
    unless @context.allows_speed_grader?
      flash[:notice] = t(:speed_grader_disabled, "SpeedGrader is disabled for this course")
      return redirect_to(course_gradebook_path(@context))
    end

    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    @assignment = @context.assignments.active.find(params[:assignment_id])

    if @assignment.unpublished?
      flash[:notice] = t(:speedgrader_enabled_only_for_published_content,
                         "SpeedGrader is enabled only for published content.")
      return redirect_to polymorphic_url([@context, @assignment])
    end

    if @assignment.moderated_grading? && !@assignment.user_is_moderation_grader?(@current_user)
      @assignment.create_moderation_grader(@current_user, occupy_slot: false)
    end

    @can_comment_on_submission = !@context.completed? && !@context_enrollment.try(:completed?)

    @can_reassign_submissions = @assignment.can_reassign?(@current_user)

    respond_to do |format|
      format.html do
        grading_role_for_user = grading_role(assignment: @assignment)
        rubric = @assignment&.rubric_association&.rubric
        @headers = false
        @outer_frame = true
        log_asset_access(["speed_grader", @context], "grades", "other")
        env = {
          SINGLE_NQ_SESSION_ENABLED: Account.site_admin.feature_enabled?(:single_new_quiz_session_in_speedgrader),
          NQ_GRADE_BY_QUESTION_ENABLED: Account.site_admin.feature_enabled?(:new_quizzes_grade_by_question_in_speedgrader),
          GRADE_BY_QUESTION: !!@current_user.preferences[:enable_speedgrader_grade_by_question],
          EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
          EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list],
          MANAGE_GRADES: @context.grants_right?(@current_user, session, :manage_grades),
          READ_AS_ADMIN: @context.grants_right?(@current_user, session, :read_as_admin),
          CONTEXT_ACTION_SOURCE: :speed_grader,
          can_view_audit_trail: @assignment.can_view_audit_trail?(@current_user),
          settings_url: speed_grader_settings_course_gradebook_path,
          force_anonymous_grading: force_anonymous_grading?(@assignment),
          anonymous_identities: @assignment.anonymous_grader_identities_by_anonymous_id,
          instructor_selectable_states: @assignment.instructor_selectable_states_by_provisional_grade_id,
          final_grader_id: @assignment.final_grader_id,
          grading_role: grading_role_for_user,
          grading_type: @assignment.grading_type,
          lti_retrieve_url: retrieve_course_external_tools_url(
            @context.id, assignment_id: @assignment.id, display: "borderless"
          ),
          course_id: @context.id,
          assignment_id: @assignment.id,
          custom_grade_statuses: Account.site_admin.feature_enabled?(:custom_gradebook_statuses) ? @context.custom_grade_statuses.as_json(include_root: false) : [],
          assignment_title: @assignment.title,
          rubric: rubric ? rubric_json(rubric, @current_user, session, style: "full") : nil,
          nonScoringRubrics: @domain_root_account.feature_enabled?(:non_scoring_rubrics),
          outcome_extra_credit_enabled: @context.feature_enabled?(:outcome_extra_credit), # for outcome-based rubrics
          outcome_proficiency:, # for outcome-based rubrics
          group_comments_per_attempt: @assignment.a2_enabled?,
          can_comment_on_submission: @can_comment_on_submission,
          show_help_menu_item: true,
          help_url: I18n.t(:"community.instructor_guide_speedgrader"),
          update_submission_grade_url: context_url(@context, :update_submission_context_gradebook_url),
          can_delete_attachments: @domain_root_account.grants_right?(@current_user, session, :become_user),
          media_comment_asset_string: @current_user.asset_string,
          late_policy: @context.late_policy&.as_json(include_root: false),
          assignment_missing_shortcut: Account.site_admin.feature_enabled?(:assignment_missing_shortcut),
        }
        if grading_role_for_user == :moderator
          env[:provisional_select_url] = api_v1_select_provisional_grade_path(@context.id, @assignment.id, "{{provisional_grade_id}}")
        end

        unless @assignment.grades_published? || @assignment.can_view_other_grader_identities?(@current_user)
          env[:current_anonymous_id] = @assignment.moderation_graders.find_by!(user_id: @current_user.id).anonymous_id
        end

        env[:selected_section_id] = gradebook_settings(@context.global_id)&.dig("filter_rows_by", "section_id")
        if @context.root_account.feature_enabled?(:new_gradebook_plagiarism_indicator)
          env[:new_gradebook_plagiarism_icons_enabled] = true
        end

        if @assignment.quiz
          env[:quiz_history_url] = course_quiz_history_path @context.id,
                                                            @assignment.quiz.id,
                                                            user_id: "{{user_id}}"
        end

        env[:filter_speed_grader_by_student_group_feature_enabled] =
          @context.root_account.feature_enabled?(:filter_speed_grader_by_student_group)

        env[:assignment_comment_library_feature_enabled] =
          @context.root_account.feature_enabled?(:assignment_comment_library)

        if @context.filter_speed_grader_by_student_group?
          env[:filter_speed_grader_by_student_group] = true

          requested_student_id = if @assignment.anonymize_students? && params[:anonymous_id].present?
                                   @assignment.submissions.find_by(anonymous_id: params[:anonymous_id])&.user_id
                                 elsif !@assignment.anonymize_students?
                                   params[:student_id]
                                 end

          group_selection = SpeedGrader::StudentGroupSelection.new(current_user: @current_user, course: @context)
          updated_group_info = group_selection.select_group(student_id: requested_student_id)

          if updated_group_info.group != group_selection.initial_group
            new_group_id = updated_group_info.group.present? ? updated_group_info.group.id.to_s : nil
            context_settings = gradebook_settings(context.global_id)
            context_settings.deep_merge!({
                                           "filter_rows_by" => {
                                             "student_group_id" => new_group_id
                                           }
                                         })
            @current_user.set_preference(:gradebook_settings, context.global_id, context_settings)
          end

          if updated_group_info.group.present?
            env[:selected_student_group] = group_json(updated_group_info.group, @current_user, session)
          end
          env[:student_group_reason_for_change] = updated_group_info.reason_for_change if updated_group_info.reason_for_change.present?
        end

        if @assignment.active_rubric_association?
          env[:update_rubric_assessment_url] = context_url(
            @context,
            :context_rubric_association_rubric_assessments_url,
            @assignment.rubric_association
          )
        end

        if Account.site_admin.feature_enabled?(:platform_service_speedgrader) && params[:platform_sg].present?

          @page_title = t("SpeedGrader")
          @body_classes << "full-width padless-content"

          remote_env(speedgrader: Services::PlatformServiceSpeedgrader.launch_url)

          js_env(env)
          deferred_js_bundle :platform_speedgrader

          render html: "".html_safe, layout: "bare"
        else
          append_sis_data(env)
          js_env(env)

          render :speed_grader, locals: {
            anonymize_students: @assignment.anonymize_students?
          }
        end
      end

      format.json do
        render json: SpeedGrader::Assignment.new(
          @assignment,
          @current_user,
          avatars: service_enabled?(:avatars),
          grading_role: grading_role(assignment: @assignment)
        ).json
      end
    end
  end

  def speed_grader_settings
    if params[:enable_speedgrader_grade_by_question]
      grade_by_question = value_to_boolean(params[:enable_speedgrader_grade_by_question])
      @current_user.preferences[:enable_speedgrader_grade_by_question] = grade_by_question
      @current_user.save!
    end

    if params[:selected_section_id]
      section_to_show = if params[:selected_section_id] == "all"
                          nil
                        elsif @context.active_course_sections.where(id: params[:selected_section_id]).exists?
                          params[:selected_section_id]
                        end

      context_settings = gradebook_settings(@context.global_id)
      context_settings.deep_merge!({
                                     "filter_rows_by" => {
                                       "section_id" => section_to_show
                                     }
                                   })
      # Showing a specific section should always display the "Sections" filter
      ensure_section_view_filter_enabled(context_settings) if section_to_show.present?
      @current_user.set_preference(:gradebook_settings, @context.global_id, context_settings)
    end

    head :ok
  end

  def blank_submission
    @headers = false
  end

  def change_gradebook_column_size
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      sub_key = @current_user.shared_gradebook_column?(params[:column_id]) ? "shared" : @context.global_id
      size_hash = @current_user.get_preference(:gradebook_column_size, sub_key) || {}
      size_hash[params[:column_id]] = params[:column_size]
      @current_user.set_preference(:gradebook_column_size, sub_key, size_hash)
      render json: nil
    end
  end

  def save_gradebook_column_order
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      @current_user.set_preference(:gradebook_column_order, @context.global_id, params[:column_order].to_unsafe_h)
      render json: nil
    end
  end

  def final_grade_overrides
    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    final_grade_overrides = ::Gradebook::FinalGradeOverrides.new(@context, @current_user)
    render json: { final_grade_overrides: final_grade_overrides.to_h }
  end

  # @API Bulk update final grade overrides
  #
  # Set multiple final grade override scores for a course. The course must have
  # final grade override enabled, and the caller must have permission to
  # manage grades. Additionally, the "Import Override Scores in Gradebook" feature
  # flag must be enabled.
  #
  # @argument grading_period_id [Integer]
  #   The grading period to apply the override scores to. If omitted, override
  #   scores will be applied to the total grades for the course.
  #
  # @argument override_scores[] [Required, Array]
  #   An array of hashes representing the new scores to assign.
  #
  # @argument override_scores[student_id] [Integer]
  #   The ID of the student to update.
  #
  # @argument override_scores[override_score] [Float]
  #   The new score to assign as a percentage.
  #
  # @example_request
  #
  # {
  #   "grading_period_id": "10",
  #   "override_scores": [
  #     {
  #       "student_id": "124",
  #       "override_score": "80.0"
  #     },
  #     {
  #       "student_id": "126",
  #       "override_score": "70.0"
  #     }
  #   ]
  # }
  #
  # @returns Progress
  def update_final_grade_overrides
    return unless authorized_action(@context, @current_user, :manage_grades)

    unless @context.allow_final_grade_override?
      render_unauthorized_action and return
    end

    if params[:grading_period_id]
      grading_period = GradingPeriod.for(@context).find_by(id: params[:grading_period_id])
      render json: { error: :invalid_grading_period }, status: :bad_request and return if grading_period.blank?
    end

    params.require(:override_scores)
    override_score_updates = params.permit(override_scores: %i[student_id override_score override_status_id]).to_h[:override_scores]

    progress = ::Gradebook::FinalGradeOverrides.queue_bulk_update(@context, @current_user, override_score_updates, grading_period)
    render json: progress_json(progress, @current_user, session)
  end

  # @API Apply score to ungraded submissions
  #
  # Perform a bulk scoring of ungraded submissions for a course, or mark
  # ungraded submissions as excused. The course's account must have the "Apply
  # Score to Ungraded" feature enabled, and the caller must have permission to
  # manage grades. By default, will apply scores to all ungraded submissions in
  # the course, but the scope may be restricted using the parameters below.
  #
  # @argument percent [Float]
  #   A percentage value between 0 and 100 representing the percent score to apply.
  #   Exactly one of this parameter or the "excused" parameter (with a true
  #   value) must be specified.
  #
  # @argument excused [Boolean]
  #   If true, mark ungraded submissions as excused. Exactly one of this
  #   parameter (with a true value) or the "percent" parameter must be
  #   specified.
  #
  # @argument mark_as_missing [Boolean]
  #   If true, mark all affected submissions as missing in addition to issuing a grade.
  #
  # @argument only_past_due [Boolean]
  #   If true, only operate on submissions whose due date has passed.
  #
  # @argument assignment_ids [Required, Array]
  #   An array of assignment ids to apply score to ungraded submissions.
  #
  # @argument student_ids [Required, Array]
  #   An array of student ids to apply score to ungraded submissions.
  #
  # @example_request
  #
  # {
  #   "percent": "50.0",
  #   "mark_as_missing": true,
  #   "only_past_due": true,
  #   "assignment_ids": ["1", "2", "3"],
  #   "student_ids": ["11", "22"]
  # }
  #
  # @returns Progress
  def apply_score_to_ungraded_submissions
    return unless authorized_action(@context, @current_user, :manage_grades)
    return render_unauthorized_action unless allow_apply_score_to_ungraded?

    excused = Canvas::Plugin.value_to_boolean(params[:excused])
    unless params[:percent].present? || excused
      return render json: { error: :no_score_or_excused_provided }, status: :bad_request
    end

    if params[:percent].present?
      return render json: { error: :cannot_both_score_and_excuse }, status: :bad_request if excused

      percent_value = params[:percent].to_f

      unless percent_value >= 0 && percent_value <= 100
        return render json: { error: :invalid_percent_value }, status: :bad_request
      end
    end

    options = ::Gradebook::ApplyScoreToUngradedSubmissions::Options.new(
      percent: percent_value,
      excused:,
      mark_as_missing: Canvas::Plugin.value_to_boolean(params[:mark_as_missing]),
      only_apply_to_past_due: Canvas::Plugin.value_to_boolean(params[:only_past_due])
    )

    return render json: { error: :no_student_ids_provided }, status: :bad_request if params[:student_ids].blank?
    return render json: { error: :no_assignment_ids_provided }, status: :bad_request if params[:assignment_ids].blank?

    options.assignment_ids = params[:assignment_ids]
    options.student_ids = params[:student_ids]

    progress = ::Gradebook::ApplyScoreToUngradedSubmissions.queue_apply_score(
      course: @context,
      grader: @current_user,
      options:
    )
    render json: progress_json(progress, @current_user, session)
  end

  def user_ids
    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    gradebook_user_ids = GradebookUserIds.new(@context, @current_user)
    render json: { user_ids: gradebook_user_ids.user_ids }
  end

  def grading_period_assignments
    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    grading_period_assignments = GradebookGradingPeriodAssignments.new(
      @context,
      course_settings: gradebook_settings(@context.global_id)
    )
    render json: { grading_period_assignments: grading_period_assignments.to_h }
  end

  def change_gradebook_version
    update_preferred_gradebook_view!("gradebook")
    @current_user.set_preference(:gradebook_version, params[:version])
    redirect_to polymorphic_url([@context, :gradebook])
  end

  private

  def active_grading_standard_scaling_factor(grading_standard)
    grading_standard.scaling_factor
  end

  def active_grading_standard_points_based(grading_standard)
    grading_standard.points_based
  end

  def gradebook_group_categories_json
    @context
      .group_categories
      .joins("LEFT JOIN #{Group.quoted_table_name} ON groups.group_category_id=group_categories.id AND groups.workflow_state <> 'deleted'")
      .group("group_categories.id", "group_categories.name")
      .pluck("group_categories.id", "group_categories.name", Arel.sql("json_agg(json_build_object('id', groups.id, 'name', groups.name))"))
      .map do |category_id, category_name, original_groups|
        groups = original_groups.select { |g| g["id"] }.map(&:with_indifferent_access)
        { id: category_id, name: category_name, groups: }.with_indifferent_access
      end
  end

  def valid_zip_upload_params?
    return true if params[:attachment_id].present?

    !!params[:submissions_zip] && !params[:submissions_zip].is_a?(String)
  end

  def outcome_proficiency
    if @context.root_account.feature_enabled?(:non_scoring_rubrics)
      if @context.root_account.feature_enabled?(:account_level_mastery_scales)
        @context.resolved_outcome_proficiency&.as_json
      else
        @context.account.resolved_outcome_proficiency&.as_json
      end
    end
  end

  def gradebook_version
    # params[:version] is a development-only convenience for engineers.
    # This param should never be used outside of development.
    if Rails.env.development? && params.include?(:version)
      params[:version]
    else
      @current_user.preferred_gradebook_version
    end
  end

  def requested_gradebook_view
    return nil if params[:view].blank?

    (params[:view] == "learning_mastery") ? "learning_mastery" : "gradebook"
  end

  def preferred_gradebook_view
    gradebook_settings(context.global_id)["gradebook_view"]
  end

  def update_preferred_gradebook_view!(gradebook_view)
    if ["learning_mastery", "default"].include?(gradebook_view)
      @current_user.set_preference(:gradebook_version, "gradebook")
    end
    context_settings = gradebook_settings(context.global_id)
    context_settings.deep_merge!({ "gradebook_view" => gradebook_view })
    @current_user.set_preference(:gradebook_settings, @context.global_id, context_settings)
  end

  def gradebook_performance_controls
    # Given that these are all consts, this should be removed in a separate refactoring
    {
      active_request_limit: 12,
      api_max_per_page: Api::MAX_PER_PAGE,
      assignment_groups_per_page: Api::MAX_PER_PAGE,
      context_modules_per_page: Api::MAX_PER_PAGE,
      custom_column_data_per_page: Api::MAX_PER_PAGE,
      custom_columns_per_page: Api::MAX_PER_PAGE,
      students_chunk_size: Api::MAX_PER_PAGE,
      submissions_chunk_size: 10,
      submissions_per_page: Api::MAX_PER_PAGE
    }
  end
  private :gradebook_performance_controls

  def percentage(weight)
    I18n.n(weight, percentage: true)
  end

  def points_possible(weight, options)
    return unless options[:weighting]
    return t("%{weight} of Final", weight: percentage(weight)) if options[:out_of_final]

    percentage(weight)
  end

  def aggregate_by_grading_period?
    view_all_grading_periods? && @context.weighted_grading_periods?
  end

  def aggregate_assignments
    if aggregate_by_grading_period?
      @presenter.periods_assignments = periods_as_assignments(@presenter.grading_periods,
                                                              out_of_final: true,
                                                              exclude_total: @exclude_total)
    else
      @presenter.groups_assignments = groups_as_assignments(@presenter.groups,
                                                            out_of_final: true,
                                                            exclude_total: @exclude_total)
    end
  end

  def groups_as_assignments(groups = nil, options = {})
    as_assignments(
      groups || @context.assignment_groups.active,
      options.merge!(weighting: @context.group_weighting_scheme == "percent")
    ) { |group| group_as_assignment(group, options) }
  end

  def periods_as_assignments(periods = nil, options = {})
    as_assignments(
      periods || @context.grading_periods.active,
      options.merge!(weighting: @context.weighted_grading_periods?)
    ) { |period| period_as_assignment(period, options) }
  end

  def as_assignments(objects = nil, options = {}, &block)
    fakes = []
    fakes.concat(objects.map(&block)) if objects && block
    fakes << total_as_assignment(options) unless options[:exclude_total]
    fakes
  end

  def group_as_assignment(group, options)
    OpenObject.build("assignment",
                     id: "group-#{group.id}",
                     rules: group.rules,
                     title: group.name,
                     points_possible: points_possible(group.group_weight, options),
                     hard_coded: true,
                     special_class: "group_total",
                     assignment_group_id: group.id,
                     group_weight: group.group_weight,
                     asset_string: "group_total_#{group.id}")
  end

  def period_as_assignment(period, options)
    OpenObject.build("assignment",
                     id: "period-#{period.id}",
                     rules: [],
                     title: period.title,
                     points_possible: points_possible(period.weight, options),
                     hard_coded: true,
                     special_class: "group_total",
                     assignment_group_id: period.id,
                     group_weight: period.weight,
                     asset_string: "period_total_#{period.id}")
  end

  def total_as_assignment(options = {})
    OpenObject.build("assignment",
                     id: "final-grade",
                     title: t("Total"),
                     points_possible: (options[:out_of_final] ? "" : percentage(100)),
                     hard_coded: true,
                     special_class: "final_grade",
                     asset_string: "final_grade_column")
  end

  def moderated_grading_enabled_and_no_grades_published?
    @assignment.moderated_grading? && !@assignment.grades_published?
  end

  def exclude_total?(context)
    return true if context.hide_final_grades
    return false unless grading_periods? && view_all_grading_periods?

    grading_period_group.present? && !grading_period_group.display_totals_for_all_grading_periods?
  end

  def grade_summary_presenter
    options = presenter_options
    if options.key?(:grading_period_id)
      GradingPeriodGradeSummaryPresenter.new(@context, @current_user, params[:id], **options)
    else
      GradeSummaryPresenter.new(@context, @current_user, params[:id], **options)
    end
  end

  def presenter_options
    options = {}
    return options unless @context.present?

    if @current_grading_period_id.present? && !view_all_grading_periods? && grading_periods?
      options[:grading_period_id] = @current_grading_period_id
    end

    return options unless @current_user.present?

    saved_order = @current_user.get_preference(:course_grades_assignment_order, @context.id)
    options[:assignment_order] = saved_order if saved_order.present?
    options
  end

  def custom_course_users_api_url(include_concluded: false, include_inactive: false, exclude_states: false, per_page:)
    state = %w[active invited]
    state << "completed" if include_concluded
    state << "inactive"  if include_inactive
    state = [] if exclude_states

    api_v1_course_users_url(
      @context,
      include: %i[avatar_url group_ids enrollments],
      enrollment_type: %w[student student_view],
      enrollment_state: state,
      per_page:
    )
  end

  def custom_course_enrollments_api_url(include_concluded: false, include_inactive: false, per_page:)
    state = %w[active invited]
    state << "completed" if include_concluded
    state << "inactive"  if include_inactive
    api_v1_course_enrollments_url(
      @context,
      include: %i[avatar_url group_ids],
      type: %w[StudentEnrollment StudentViewEnrollment],
      state:,
      per_page:
    )
  end

  def gradebook_settings(key)
    @current_user.get_preference(:gradebook_settings, key) || {}
  end

  def ensure_section_view_filter_enabled(context_settings)
    filter_settings = context_settings.fetch("selected_view_options_filters", [])
    return if filter_settings&.include?("sections")

    context_settings["selected_view_options_filters"] = filter_settings.append("sections")
  end

  def courses_with_grades_json
    courses = @presenter.courses_with_grades
    courses << @context if courses.empty?

    courses.map do |course|
      grading_period_set_id = GradingPeriodGroup.for_course(course)&.id

      {
        id: course.id,
        nickname: course.nickname_for(@current_user),
        url: context_url(course, :context_grades_url),
        grading_period_set_id: grading_period_set_id.try(:to_s)
      }
    end.as_json
  end

  def populate_user_ids(submissions)
    anonymous_ids = submissions.map { |submission| submission.fetch(:anonymous_id) }
    submission_ids_map = Submission.select(:user_id, :anonymous_id)
                                   .where(assignment: @context.assignments, anonymous_id: anonymous_ids)
                                   .index_by(&:anonymous_id)

    # merge back into submissions
    submissions.map do |submission|
      submission[:user_id] = submission_ids_map[submission.fetch(:anonymous_id)].user_id
      submission
    end
  end

  def apply_provisional_grade_filters!(submissions:, final:)
    preloaded_grades = ModeratedGrading::ProvisionalGrade.where(submission: submissions)
    grades_by_submission_id = preloaded_grades.group_by(&:submission_id)

    submissions.each do |submission|
      provisional_grade = submission.provisional_grade(
        @current_user,
        preloaded_grades: grades_by_submission_id,
        final:,
        default_to_null_grade: false
      )
      submission.apply_provisional_grade_filter!(provisional_grade) if provisional_grade
    end
  end

  def grading_role(assignment:)
    if moderated_grading_enabled_and_no_grades_published?
      if assignment.permits_moderation?(@current_user)
        :moderator
      else
        :provisional_grader
      end
    else
      :grader
    end
  end

  def gradebook_column_size_preferences
    @current_user.save if @current_user.changed?
    shared_settings = @current_user.get_preference(:gradebook_column_size, "shared") || {}
    course_settings = @current_user.get_preference(:gradebook_column_size, @context.global_id) || {}
    shared_settings.merge(course_settings)
  end

  def allow_view_ungraded_as_zero?
    @context.account.feature_enabled?(:view_ungraded_as_zero)
  end

  def allow_apply_score_to_ungraded?
    @context.account.feature_enabled?(:apply_score_to_ungraded)
  end

  def outcome_service_results_to_canvas_enabled?
    @context.feature_enabled?(:outcome_service_results_to_canvas)
  end

  def track_update_metrics(params, submission)
    if params.dig(:submission, :grade) && params["submission"]["grade"].to_s != submission.grade.to_s && params["originator"] == "speed_grader"
      InstStatsd::Statsd.increment("speedgrader.submission.posted_grade")
    end
  end
end
