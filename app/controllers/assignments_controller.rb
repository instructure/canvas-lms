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

# @API Assignments
class AssignmentsController < ApplicationController
  include Api::V1::Section
  include Api::V1::Assignment
  include Api::V1::AssignmentOverride
  include Api::V1::AssignmentGroup
  include Api::V1::GroupCategory
  include Api::V1::ModerationGrader
  include Api::V1::Outcome
  include Api::V1::ExternalTools
  include Api::V1::ContextModule
  include Api::V1::Rubric
  include Api::V1::RubricAssociation

  include KalturaHelper
  include ObserverEnrollmentsHelper
  include SyllabusHelper
  before_action :require_context

  include HorizonMode
  before_action :load_canvas_career, only: %i[index show syllabus]

  include K5Mode
  add_crumb(
    proc { t "#crumbs.assignments", "Assignments" },
    except: %i[destroy syllabus index new edit]
  ) { |c| c.send :course_assignments_path, c.instance_variable_get(:@context) }
  before_action(except: [:new, :edit]) { |c| c.active_tab = "assignments" }
  before_action(only: [:new, :edit]) { |c| setup_active_tab(c) }
  before_action :normalize_title_param, only: [:new, :edit]

  def index
    GuardRail.activate(:secondary) do
      return redirect_to(dashboard_url) if @context == @current_user

      if authorized_action(@context, @current_user, :read)
        return unless tab_enabled?(@context.class::TAB_ASSIGNMENTS)

        log_asset_access(["assignments", @context], "assignments", "other")

        add_crumb(t("#crumbs.assignments", "Assignments"), named_context_url(@context, :context_assignments_url))

        max_name_length_required_for_account = AssignmentUtil.name_length_required_for_account?(@context)
        max_name_length = AssignmentUtil.assignment_max_name_length(@context)
        sis_name = AssignmentUtil.post_to_sis_friendly_name(@context)
        due_date_required_for_account = AssignmentUtil.due_date_required_for_account?(@context)
        sis_integration_settings_enabled = AssignmentUtil.sis_integration_settings_enabled?(@context)

        # It'd be nice to do this as an after_create, but it's not that simple
        # because of course import/copy.
        @context.require_assignment_group

        set_js_assignment_data
        set_tutorial_js_env
        set_section_list_js_env
        grading_standard = @context.grading_standard_or_default
        assign_to_tags = @context.account.feature_enabled?(:assign_to_differentiation_tags) && @context.account.allow_assign_to_differentiation_tags?
        hash = {
          ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS: assign_to_tags,
          CAN_MANAGE_DIFFERENTIATION_TAGS: @context.grants_any_right?(@current_user, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS),
          WEIGHT_FINAL_GRADES: @context.apply_group_weights?,
          POST_TO_SIS_DEFAULT: @context.account.sis_default_grade_export[:value],
          SIS_INTEGRATION_SETTINGS_ENABLED: sis_integration_settings_enabled,
          SIS_NAME: sis_name,
          MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT: max_name_length_required_for_account,
          MAX_NAME_LENGTH: max_name_length,
          HAS_ASSIGNMENTS: @context.active_assignments.count > 0,
          QUIZ_LTI_ENABLED: quiz_lti_tool_enabled?,
          DUE_DATE_REQUIRED_FOR_ACCOUNT: due_date_required_for_account,
          MODERATED_GRADING_GRADER_LIMIT: Course::MODERATED_GRADING_GRADER_LIMIT,
          SHOW_SPEED_GRADER_LINK: @current_user.present? && context.allows_speed_grader? && context.grants_any_right?(@current_user, :manage_grades, :view_all_grades),
          FLAGS: {
            newquizzes_on_quiz_page: @context.root_account.feature_enabled?(:newquizzes_on_quiz_page),
            show_additional_speed_grader_link: Account.site_admin.feature_enabled?(:additional_speedgrader_links),
            new_quizzes_by_default: @context.feature_enabled?(:new_quizzes_by_default)
          },
          grading_scheme: grading_standard.data,
          points_based: grading_standard.points_based?,
          scaling_factor: grading_standard.scaling_factor
        }

        set_default_tool_env!(@context, hash)
        append_default_due_time_js_env(@context, hash)

        js_env(hash)

        respond_to do |format|
          format.html do
            @padless = true
            render :new_index
          end
        end
      end
    end
  end

  def render_a2_student_view?
    @current_user.present? && @assignment.a2_enabled? && !can_do(@context, @current_user, :read_as_admin) &&
      (!params.key?(:assignments_2) || value_to_boolean(params[:assignments_2]))
  end

  def a2_active_student_and_enrollment
    return [@current_user, @context_enrollment] unless @context_enrollment&.observer?

    # sets @selected_observed_user
    observed_users(@current_user, session, @context.id)

    active_enrollment = ObserverEnrollment.active_or_pending
                                          .where(course: @context,
                                                 user: @current_user,
                                                 associated_user: @selected_observed_user)
                                          .first

    [active_enrollment&.associated_user, active_enrollment]
  end

  def render_a2_student_view(student:)
    if @context.root_account.feature_enabled?(:instui_nav)
      add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
    end
    current_user_submission = @assignment.submissions.find_by(user: student)
    submission = if @context.feature_enabled?(:peer_reviews_for_a2)
                   if params[:reviewee_id].present? && !@assignment.anonymous_peer_reviews?
                     @assignment.submissions.find_by(user_id: params[:reviewee_id])
                   elsif params[:anonymous_asset_id].present?
                     @assignment.submissions.find_by(anonymous_id: params[:anonymous_asset_id])
                   else
                     current_user_submission
                   end
                 else
                   current_user_submission
                 end

    peer_review_mode_enabled = @context.feature_enabled?(:peer_reviews_for_a2) && (params[:reviewee_id].present? || params[:anonymous_asset_id].present?)
    peer_review_available = submission.present? && @assignment.submitted?(submission:) && current_user_submission.present? && @assignment.submitted?(submission: current_user_submission)
    grading_standard = @context.grading_standard_or_default
    js_env({
             a2_student_view: render_a2_student_view?,
             peer_review_mode_enabled: submission.present? && peer_review_mode_enabled,
             peer_review_available:,
             peer_display_name: @assignment.anonymous_peer_reviews? ? I18n.t("Anonymous student") : submission&.user&.name,
             originality_reports_for_a2_enabled: Account.site_admin.feature_enabled?(:originality_reports_for_a2),
             restrict_quantitative_data: @assignment.restrict_quantitative_data?(@current_user),
             grading_scheme: grading_standard.data,
             points_based: grading_standard.points_based?,
             scaling_factor: grading_standard.scaling_factor,
             enhanced_rubrics_enabled: @context.feature_enabled?(:enhanced_rubrics),
           })

    if peer_review_mode_enabled
      graphql_reviewer_submission_id = nil
      if current_user_submission
        graphql_reviewer_submission_id = CanvasSchema.id_from_object(
          current_user_submission,
          CanvasSchema.resolve_type(nil, current_user_submission, nil)[0],
          nil
        )
      end
      js_env({
               reviewee_id: @assignment.anonymous_peer_reviews? ? nil : params[:reviewee_id],
               anonymous_asset_id: params[:anonymous_asset_id],
               REVIEWER_SUBMISSION_ID: graphql_reviewer_submission_id
             })
    end

    graphql_submission_id = nil
    if submission
      graphql_submission_id = CanvasSchema.id_from_object(
        submission,
        CanvasSchema.resolve_type(nil, submission, nil)[0],
        nil
      )
    end

    assignment_prereqs = if @locked && @locked[:unlock_at]
                           @locked
                         elsif @locked && !@locked[:can_view]
                           context_module_sequence_items_by_asset_id(@assignment.id, "Assignment")
                         else
                           {}
                         end

    js_env({
             belongs_to_unpublished_module: @locked && !@locked[:can_view] && @locked.dig(:context_module, "workflow_state") == "unpublished"
           })

    mark_done_presenter = MarkDonePresenter.new(self, @context, params["module_item_id"], student, @assignment)
    if mark_done_presenter.has_requirement?
      js_env({
               CONTEXT_MODULE_ITEM: {
                 done: mark_done_presenter.checked?,
                 id: mark_done_presenter.item.id,
                 module_id: mark_done_presenter.module.id
               }
             })
    end

    if @assignment.turnitin_enabled? || @assignment.vericite_enabled? || @assignment.tool_settings_tool.present?
      similarity_pledge = {
        EULA_URL: tool_eula_url,
        COMMENTS: plagiarism_comments,
        PLEDGE_TEXT: pledge_text,
      }

      js_env({ SIMILARITY_PLEDGE: similarity_pledge })
    end

    js_env({
             ASSIGNMENT_ID: params[:id],
             CONFETTI_ENABLED: @domain_root_account&.feature_enabled?(:confetti_for_assignments),
             EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
             EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list],
             COURSE_ID: @context.id,
             ISOBSERVER: @context_enrollment&.observer?,
             ORIGINALITY_REPORTS_FOR_A2: Account.site_admin.feature_enabled?(:originality_reports_for_a2),
             PREREQS: assignment_prereqs,
             SUBMISSION_ID: graphql_submission_id
           })
    css_bundle :assignments_2_student
    js_bundle :assignments_show_student
    render html: "", layout: true
  end

  # Provide an easy entry point for A2 or other consumers to directly launch the LTI tool associated with
  # an assignment, while reusing the authorization and business logic of #show.
  # Hacky; relies on
  #   - content_tag_redirect reads `display` directly for rendering the LTI tool
  #   - assignments_2=false shortcircuits the A2 rendering in #show so that content_tag_redirect can be called
  def tool_launch
    @assignment = @context.assignments.find(params[:assignment_id])

    unless @assignment.submission_types == "external_tool" && @assignment.external_tool_tag
      flash[:error] = t "The assignment you requested is not associated with an LTI tool."
      return redirect_to named_context_url(@context, :context_assignments_url)
    end

    params[:display] = "borderless" # render the LTI launch full screen, without any Canvas chrome
    params[:assignments_2] = false # bypass A2 rendering to get to the call to content_tag_redirect
    show
  end

  def show
    unless request.format.html?
      return render body: "endpoint does not support #{request.format.symbol}", status: :bad_request
    end

    GuardRail.activate(:secondary) do
      @assignment ||= @context.assignments.find(params[:id])

      js_env({ ASSIGNMENT_POINTS_POSSIBLE: nil })

      if @assignment.deleted?
        flash[:notice] = t "notices.assignment_delete", "This assignment has been deleted"
        redirect_to named_context_url(@context, :context_assignments_url)
        return
      end

      if authorized_action(@assignment, @current_user, :read)
        if @current_user && @assignment && !@assignment.visible_to_user?(@current_user)
          flash[:error] = t "notices.assignment_not_available", "The assignment you requested is not available to your course section."
          redirect_to named_context_url(@context, :context_assignments_url)
          return
        end

        flash.now[:notice] = t("assignment_submit_success", "Assignment successfully submitted.") if params[:submitted]

        # override media comment context: in the show action, these will be submissions
        js_env media_comment_asset_string: @current_user.asset_string if @current_user

        @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @current_user)
        @assignment.ensure_assignment_group

        @locked = @assignment.locked_for?(@current_user, check_policies: true, deep_check_if_needed: true)
        @unlocked = !@locked || @assignment.grants_right?(@current_user, session, :update)

        if @assignment.external_tool? && Account.site_admin.feature_enabled?(:external_tools_for_a2) && @unlocked
          @tool = Lti::ToolFinder.from_assignment(@assignment)

          js_env({ LTI_TOOL: "true", LTI_TOOL_ID: @tool&.id, LTI_TOOL_SELECTION_WIDTH: @tool&.settings&.dig("selection_width"), LTI_TOOL_SELECTION_HEIGHT: @tool&.settings&.dig("selection_height") })
        end

        if @assignment.external_tool?
          js_env({ ASSIGNMENT_POINTS_POSSIBLE: @assignment.points_possible })
        end

        unless @assignment.new_record? || (@locked && !@locked[:can_view])
          GuardRail.activate(:primary) do
            @assignment.context_module_action(@current_user, :read)
          end
        end

        can_read_submissions = @assignment.grants_right?(@current_user, session, :read_own_submission) && @context.grants_right?(@current_user, session, :read_grades)
        if can_read_submissions
          @current_user_submission = @assignment.submissions.where(user_id: @current_user).first if @current_user
          @current_user_submission = nil if @current_user_submission &&
                                            !@current_user_submission.graded? &&
                                            !@current_user_submission.submission_type
          if @current_user_submission
            GuardRail.activate(:primary) do
              @current_user_submission.delay.context_module_action
            end
          end
        end

        log_asset_access(@assignment, "assignments", @assignment.assignment_group)
        asset_processor_eula_js_env

        if render_a2_student_view? && params[:display] != "borderless"
          js_env({ OBSERVER_OPTIONS: {
                   OBSERVED_USERS_LIST: observed_users(@current_user, session, @context.id),
                   CAN_ADD_OBSERVEE: @current_user
                                      .profile
                                      .tabs_available(@current_user, root_account: @domain_root_account)
                                      .any? { |t| t[:id] == UserProfile::TAB_OBSERVEES }
                 } })

          student_to_view, active_enrollment = a2_active_student_and_enrollment
          if student_to_view.present?
            js_env({
                     enrollment_state: active_enrollment&.state_based_on_date,
                     can_submit_assignment_from_section: @assignment.enrollment_active_for_assignment?(student_to_view),
                     stickers_enabled: @context.feature_enabled?(:submission_stickers)
                   })
            rce_js_env

            render_a2_student_view(student: student_to_view)
            return
          else
            # This should not be reachable but leaving in place until we remove the old view
            flash[:notice] = t "No student is being observed."
          end
        end

        assign_to_tags = @context.account.feature_enabled?(:assign_to_differentiation_tags) && @context.account.allow_assign_to_differentiation_tags?

        env = js_env({
                       COURSE_ID: @context.id,
                       ROOT_OUTCOME_GROUP: outcome_group_json(@context.root_outcome_group, @current_user, session),
                       HAS_GRADING_PERIODS: @context.grading_periods?,
                       VALID_DATE_RANGE: CourseDateRange.new(@context),
                       POST_TO_SIS: Assignment.sis_grade_export_enabled?(@context),
                       DUE_DATE_REQUIRED_FOR_ACCOUNT: AssignmentUtil.due_date_required_for_account?(@context),
                       ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS: assign_to_tags,
                       CAN_MANAGE_DIFFERENTIATION_TAGS: @context.grants_any_right?(@current_user, session, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS)
                     })
        set_section_list_js_env
        submission = @assignment.submissions.find_by(user: @current_user)
        if submission
          js_env({ SUBMISSION_ID: submission.id })
        end

        @first_annotation_submission = !submission&.has_submission? && @assignment.annotated_document?
        js_env({ FIRST_ANNOTATION_SUBMISSION: @first_annotation_submission })
        env[:SETTINGS][:filter_speed_grader_by_student_group] = filter_speed_grader_by_student_group?

        if env[:SETTINGS][:filter_speed_grader_by_student_group]
          can_view_tags = @context.grants_any_right?(
            @current_user,
            session,
            *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS
          )

          eligible_categories = can_view_tags ? @context.active_combined_group_and_differentiation_tag_categories : @context.group_categories.active
          eligible_categories = eligible_categories.where(id: @assignment.group_category) if @assignment.group_category.present?
          env[:group_categories] = group_categories_json(eligible_categories, @current_user, session, { include: ["groups"] })

          selected_group_id = @current_user&.get_preference(:gradebook_settings, @context.global_id)&.dig("filter_rows_by", "student_group_id")
          # If this is a group assignment and we had previously filtered by a
          # group that isn't part of this assignment's group set, behave as if
          # no group is selected.
          if selected_group_id.present? && Group.active.where(group_category_id: eligible_categories.pluck(:id), id: selected_group_id).exists?
            env[:selected_student_group_id] = selected_group_id
          end
        end

        @assignment_presenter = AssignmentPresenter.new(@assignment)
        if @assignment_presenter.can_view_speed_grader_link?(@current_user) && !@assignment.unpublished?
          env[:speed_grader_url] = context_url(@context, :speed_grader_context_gradebook_url, assignment_id: @assignment.id)
        end

        if @assignment.quiz?
          return redirect_to named_context_url(@context, :context_quiz_url, @assignment.quiz.id)
        elsif @assignment.discussion_topic? &&
              @assignment.discussion_topic.grants_right?(@current_user, session, :read)
          return redirect_to named_context_url(@context, :context_discussion_topic_url, @assignment.discussion_topic.id)
        elsif @context.conditional_release? && @assignment.wiki_page? &&
              @assignment.wiki_page.grants_right?(@current_user, session, :read)
          return redirect_to named_context_url(@context, :context_wiki_page_url, @assignment.wiki_page.id)
        elsif @assignment.submission_types == "external_tool" && @assignment.external_tool_tag && @unlocked
          permissions = {
            manage_rubrics: @context.grants_right?(@current_user, session, :manage_rubrics)
          }
          hash = {
            PERMISSIONS: permissions,
          }
          js_env(hash)
          enhanced_rubrics_assignments_js_env(@assignment) if Rubric.enhanced_rubrics_assignments_enabled?(@context)
          tag_type = params[:module_item_id].present? ? :modules : :assignments
          return content_tag_redirect(@context, @assignment.external_tool_tag, :context_url, tag_type)
        end

        add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
        @page_title = if @assignment.new_record?
                        t(:new_assignment, "New Assignment")
                      else
                        @assignment.title
                      end

        rce_js_env
        assignment_prereqs = {}
        if @locked && !@locked[:can_view]
          assignment_prereqs = context_module_sequence_items_by_asset_id(@assignment.id, "Assignment")
        end
        js_env({
                 ASSIGNMENT_ID: @assignment.id,
                 PREREQS: assignment_prereqs
               })

        if @context.feature_enabled?(:assignments_2_teacher) &&
           (!params.key?(:assignments_2) || value_to_boolean(params[:assignments_2])) &&
           can_do(@context, @current_user, :read_as_admin)
          css_bundle :assignments_2_teacher
          js_bundle :assignments_show_teacher_deprecated
          render html: "", layout: true
          return
        end

        if @context.root_account.feature_enabled?(:assignment_enhancements_teacher_view) &&
           can_do(@context, @current_user, :read_as_admin)
          css_bundle :assignment_enhancements_teacher_view
          js_bundle :assignments_show_teacher
          render html: "", layout: true
          return
        end

        # everything else here is only for the old assignment page and can be
        # deleted once the :assignments_2 feature flag is deleted
        @locked.delete(:lock_at) if @locked.is_a?(Hash) && @locked.key?(:unlock_at) # removed to allow proper translation on show page

        if can_read_submissions
          @assigned_assessments = @current_user_submission&.assigned_assessments&.select { |request| request.submission.grants_right?(@current_user, session, :read) } || []
        end

        @external_tools = if @assignment.submission_types.include?("online_upload") || @assignment.submission_types.include?("online_url")
                            Lti::ContextToolFinder.all_tools_for(@context, current_user: @current_user, placements: :homework_submission)
                          else
                            []
                          end

        context_rights = @context.rights_status(@current_user, session, :read_as_admin, :manage_assignments_edit)
        permissions = {
          context: context_rights,
          assignment: @assignment.rights_status(@current_user, session, :update, :submit),
          can_manage_groups: can_do(@context.groups.temp_record, @current_user, :create),
          manage_rubrics: @context.grants_right?(@current_user, session, :manage_rubrics)
        }

        @similarity_pledge = pledge_text

        hash = {
          EULA_URL: tool_eula_url,
          EXTERNAL_TOOLS: external_tools_json(@external_tools, @context, @current_user, session),
          PERMISSIONS: permissions,
          SIMILARITY_PLEDGE: @similarity_pledge,
          CONFETTI_ENABLED: @domain_root_account&.feature_enabled?(:confetti_for_assignments),
          EMOJIS_ENABLED: @context.feature_enabled?(:submission_comment_emojis),
          EMOJI_DENY_LIST: @context.root_account.settings[:emoji_deny_list],
          USER_ASSET_STRING: @current_user&.asset_string,
          OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION: @context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation),
        }

        append_default_due_time_js_env(@context, hash)
        js_env(hash)
        enhanced_rubrics_assignments_js_env(@assignment) if Rubric.enhanced_rubrics_assignments_enabled?(@context)

        set_master_course_js_env_data(@assignment, @context)
        conditional_release_js_env(@assignment, includes: :rule)

        @can_view_grades = @context.grants_right?(@current_user, session, :view_all_grades)
        @downloadable_submissions = downloadable_submissions?(@current_user, @context, @assignment)
        @can_grade = @assignment.grants_right?(@current_user, session, :grade)
        if @can_view_grades || @can_grade
          visible_student_ids = @context.apply_enrollment_visibility(@context.all_student_enrollments, @current_user).pluck(:user_id)
          @current_student_submissions = @assignment.submissions.where.not(submissions: { submission_type: nil }).where(user_id: visible_student_ids).to_a
        end

        @can_direct_share = @context.grants_right?(@current_user, session, :direct_share)
        @can_link_to_speed_grader = Account.site_admin.feature_enabled?(:additional_speedgrader_links) && @assignment.can_view_speed_grader?(@current_user)

        @assignment_menu_tools = external_tools_display_hashes(:assignment_menu)

        @mark_done = MarkDonePresenter.new(self, @context, params["module_item_id"], @current_user, @assignment)

        @show_locked_page = @locked && !@locked[:can_view]
        if @show_locked_page
          js_bundle :module_sequence_footer
        else
          css_bundle :assignments
          js_bundle :assignment_show
        end

        mastery_scales_js_env

        render locals: {
                 eula_url: tool_eula_url,
                 show_moderation_link: @assignment.moderated_grading? && @assignment.permits_moderation?(@current_user),
                 show_confetti: params[:confetti] == "true" && @domain_root_account&.feature_enabled?(:confetti_for_assignments)
               },
               stream: can_stream_template?
      end
    end
  end

  def show_moderate
    @assignment ||= @context.assignments.find(params[:assignment_id])

    raise ActiveRecord::RecordNotFound unless @assignment.moderated_grading? && @assignment.published?

    render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)

    add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
    add_crumb(t("Moderate"))

    css_bundle :assignment_grade_summary
    js_bundle :assignment_grade_summary
    js_env(show_moderate_env)

    @page_title = @assignment.title

    render html: "", layout: true
  end

  def downloadable_submissions?(current_user, context, assignment)
    types = %w[online_upload online_url online_text_entry]
    return false unless assignment.submission_types.split(",").intersect?(types) && current_user

    student_ids =
      if assignment.grade_as_group?
        assignment.representatives(user: current_user).map(&:id)
      else
        context.apply_enrollment_visibility(context.student_enrollments, current_user).pluck(:user_id)
      end
    student_ids.any? && assignment.submissions.where(user_id: student_ids, submission_type: types).exists?
  end

  def rubric
    @assignment = @context.assignments.active.find(params[:assignment_id])
    @root_outcome_group = outcome_group_json(@context.root_outcome_group, @current_user, session).to_json
    if authorized_action(@assignment, @current_user, :read)
      render partial: "shared/assignment_rubric_dialog"
    end
  end

  def assign_peer_reviews
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      cnt = params[:peer_review_count].to_i
      @assignment.peer_review_count = cnt if cnt > 0
      @assignment.intra_group_peer_reviews = params[:intra_group_peer_reviews].present?
      request = @assignment.assign_peer_reviews
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url, @assignment.id) }
        format.json { render json: request }
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
        format.json { render json: @request.as_json(methods: :asset_user_name) }
      end
    end
  end

  def remind_peer_review
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      @request = AssessmentRequest.where(id: params[:id]).first if params[:id].present?
      respond_to do |format|
        if @request.asset.assignment == @assignment && @request.send_reminder!
          format.json { render json: @request }
        else
          format.json { render json: { errors: { base: t("errors.reminder_failed", "Reminder failed") } }, status: :bad_request }
        end
        format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
      end
    end
  end

  def delete_peer_review
    @assignment = @context.assignments.active.find(params[:assignment_id])
    if authorized_action(@assignment, @current_user, :grade)
      @request = AssessmentRequest.where(id: params[:id]).first if params[:id].present?
      respond_to do |format|
        if @request.asset.assignment == @assignment && @request.destroy
          format.json { render json: @request }
        else
          format.json { render json: { errors: { base: t("errors.delete_reminder_failed", "Delete failed") } }, status: :bad_request }
        end
        format.html { redirect_to named_context_url(@context, :context_assignment_peer_reviews_url) }
      end
    end
  end

  def filter_by_assigned_assessment(submissions, search_term)
    cleaned_search_term = User.clean_name(search_term, /[\s,]+/)

    assessments = AssessmentRequest
                  .where(asset_id: submissions.map(&:id))
                  .for_active_users(@context)
                  .for_active_assessors(@context)
                  .preload(:assessor, :user)

    unique_assessors_set = Set.new
    assessments.each do |assessment|
      assessment_user = assessment.user
      cleaned_first_name_last = User.clean_name(assessment_user.name, /\s+/)
      cleaned_last_name_first = User.clean_name(assessment_user.sortable_name, /[\s,]+/)
      if cleaned_first_name_last.include?(cleaned_search_term) || cleaned_last_name_first.include?(cleaned_search_term)
        unique_assessors_set << assessment.assessor
      end
    end

    unique_assessors_set.to_a
  end

  def filter_by_all(student_list, submissions, search_term)
    filter_by_reviewer_list = filter_by_assessor(student_list, search_term)
    filter_by_assigned_assessment_list = filter_by_assigned_assessment(submissions, search_term)
    (filter_by_reviewer_list + filter_by_assigned_assessment_list).uniq
  end

  def filter_by_assessor(student_list, search_term)
    student_list.name_like(search_term, "peer_review")
  end

  def filter_by_selected_option(student_list, submissions, search_term, selected_option)
    case selected_option
    when "all"
      filter_by_all(student_list, submissions, search_term)
    when "student"
      filter_by_assigned_assessment(submissions, search_term)
    when "reviewer"
      filter_by_assessor(student_list, search_term)
    end
  end

  def peer_reviews
    @assignment = @context.assignments.active.find(params[:assignment_id])
    js_env({
             ASSIGNMENT_ID: @assignment.id,
             COURSE_ID: @context.id
           })
    if authorized_action(@assignment, @current_user, :grade)
      unless @assignment.has_peer_reviews?
        redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
        return
      end

      if @context.root_account.feature_enabled?(:instui_nav)
        add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
        add_crumb(t("Peer Reviews"))
      end

      visible_students = @context.students_visible_to(@current_user).not_fake_student
      visible_students_assigned_to_assignment = visible_students.joins(:submissions).where(submissions: { assignment: @assignment }).merge(Submission.active)
      @submissions = @assignment.submissions.include_assessment_requests
      @students_dropdown_list = visible_students_assigned_to_assignment.distinct.order_by_sortable_name
      @students = params[:search_term].present? ? filter_by_selected_option(@students_dropdown_list, @submissions, params[:search_term], params[:selected_option]) : @students_dropdown_list
      @students = @students.paginate(page: params[:page], per_page: 10)
    end
  end

  def syllabus
    rce_js_env
    add_crumb(
      if @context.elementary_enabled?
        t("Important Info")
      elsif @context.horizon_course?
        t("Overview")
      else
        t("#crumbs.syllabus", "Syllabus")
      end
    )
    can_see_admin_tools = @context.grants_any_right?(
      @current_user, session, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
    )
    @course_home_sub_navigation_tools = Lti::ContextToolFinder.new(
      @context,
      type: :course_home_sub_navigation,
      current_user: @current_user
    ).all_tools_sorted_array(exclude_admin_visibility: !can_see_admin_tools)

    if authorized_action(@context, @current_user, [:read, :read_syllabus])
      return unless tab_enabled?(@context.class::TAB_SYLLABUS)

      @groups = @context.assignment_groups.active.order(
        :position,
        AssignmentGroup.best_unicode_collation_key("name")
      ).to_a
      @syllabus_body = syllabus_user_content

      hash = {
        CONTEXT_ACTION_SOURCE: :syllabus,
      }
      append_sis_data(hash)
      js_env(hash)
      set_tutorial_js_env

      log_asset_access(["syllabus", @context], "syllabus", "other")
      respond_to(&:html)
    end
  end

  def toggle_mute
    return nil unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])

    @assignment = @context.assignments.active.find(params[:assignment_id])

    toggle_value = params[:status] == "true"
    return render_unauthorized_action if !toggle_value && !@assignment.grades_published?

    method = toggle_value ? :mute! : :unmute!
    @assignment.updating_user = @current_user

    respond_to do |format|
      if @assignment&.send(method)
        format.json { render json: @assignment.as_json(methods: :anonymize_students) }
      else
        format.json { render json: @assignment, status: :bad_request }
      end
    end
  end

  def create
    defaults = {}
    if params[:assignment] && params[:assignment][:post_to_sis].nil?
      defaults[:post_to_sis] = @context.account.sis_default_grade_export[:value]
    end
    defaults[:time_zone_edited] = Time.zone.name if params[:assignment]
    group = get_assignment_group(params[:assignment])
    @assignment ||= @context.assignments.build(strong_assignment_params.merge(defaults))

    if params[:assignment][:secure_params]
      secure_params = Canvas::Security.decode_jwt params[:assignment][:secure_params]
      @assignment.lti_context_id = secure_params[:lti_context_id]
    end

    @assignment.quiz_lti! if params.key?(:quiz_lti) || params[:assignment][:quiz_lti]

    @assignment.workflow_state = "unpublished"
    @assignment.updating_user = @current_user
    @assignment.content_being_saved_by(@current_user)
    @assignment.assignment_group = group if group
    # if no due_at was given, set it to 11:59 pm in the creator's time zone
    @assignment.infer_times
    if authorized_action(@assignment, @current_user, :create)
      SubmissionLifecycleManager.with_executing_user(@current_user) do
        respond_to do |format|
          if @assignment.save
            flash[:notice] = t "notices.created", "Assignment was successfully created."
            format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
            format.json { render json: @assignment.as_json(permissions: { user: @current_user, session: }), status: :created }
          else
            format.html { render :new }
            format.json { render json: @assignment.errors, status: :bad_request }
          end
        end
      end
    end
  end

  def new
    @assignment ||= @context.assignments.temp_record
    @assignment.workflow_state = "unpublished"
    add_crumb_on_new_quizzes(true)

    if params[:submission_types] == "discussion_topic"
      redirect_to new_polymorphic_url([@context, :discussion_topic], index_edit_params)
    elsif @context.conditional_release? && params[:submission_types] == "wiki_page"
      redirect_to new_polymorphic_url([@context, :wiki_page], index_edit_params)
    else
      @assignment.quiz_lti! if params.key?(:quiz_lti)
      edit
    end
  end

  def edit
    rce_js_env
    @assignment ||= @context.assignments.active.find(params[:id])
    add_crumb_on_new_quizzes(false)

    if @context.root_account.feature_enabled?(:assignment_edit_enhancements_teacher_view) &&
       authorized_action(@assignment, @current_user, @assignment.new_record? ? :create : :update)
      js_env({ ASSIGNMENT_EDIT_ENHANCEMENTS_TEACHER_VIEW: true, ASSIGNMENT_ID: params[:id], COURSE_ID: @context.id })
      css_bundle :assignment_enhancements_teacher_view
      render html: "", layout: true
      return
    end

    if authorized_action(@assignment, @current_user, @assignment.new_record? ? :create : :update)
      @assignment.title = params[:title] if params[:title]
      @assignment.due_at = params[:due_at] if params[:due_at]
      @assignment.points_possible = params[:points_possible] if params[:points_possible]
      @assignment.submission_types = params[:submission_types] if params[:submission_types]
      @assignment.assignment_group_id = params[:assignment_group_id] if params[:assignment_group_id]
      @assignment.ensure_assignment_group(false)

      if params.key?(:post_to_sis)
        @assignment.post_to_sis = value_to_boolean(params[:post_to_sis])
      elsif @assignment.new_record?
        @assignment.post_to_sis = @context.account.sis_default_grade_export[:value]
      end

      if @assignment.submission_types == "online_quiz" && @assignment.quiz
        return redirect_to edit_course_quiz_url(@context, @assignment.quiz, index_edit_params)
      elsif @assignment.submission_types == "discussion_topic" && @assignment.discussion_topic
        return redirect_to edit_polymorphic_url([@context, @assignment.discussion_topic], index_edit_params)
      elsif @context.conditional_release? &&
            @assignment.submission_types == "wiki_page" && @assignment.wiki_page
        return redirect_to edit_polymorphic_url([@context, @assignment.wiki_page], index_edit_params)
      end

      assignment_groups = @context.assignment_groups.active
      group_categories = @context.group_categories
                                 .reject { |c| c.student_organized? || c.non_collaborative? }
                                 .map { |c| { id: c.id, name: c.name } }

      # if assignment has student submissions and is attached to a deleted group category,
      # add that category to the ENV list so it can be shown on the edit page.
      if @assignment.group_category_deleted_with_submissions?
        locked_category = @assignment.group_category
        group_categories << { id: locked_category.id, name: locked_category.name }
      end

      json_for_assignment_groups = assignment_groups.map do |group|
        assignment_group_json(group, @current_user, session, [], { stringify_json_ids: true })
      end

      post_to_sis = Assignment.sis_grade_export_enabled?(@context)

      assign_to_tags = @context.account.feature_enabled?(:assign_to_differentiation_tags) && @context.account.allow_assign_to_differentiation_tags?

      hash = {
        ROOT_FOLDER_ID: Folder.root_folders(@context).first&.id,
        ROOT_OUTCOME_GROUP: outcome_group_json(@context.root_outcome_group, @current_user, session),
        ALLOW_ASSIGN_TO_DIFFERENTIATION_TAGS: assign_to_tags,
        CAN_MANAGE_DIFFERENTIATION_TAGS: @context.grants_any_right?(@current_user, session, *RoleOverride::GRANULAR_MANAGE_TAGS_PERMISSIONS),
        ASSIGNMENT_GROUPS: json_for_assignment_groups,
        ASSIGNMENT_INDEX_URL: polymorphic_url([@context, :assignments]),
        ASSIGNMENT_OVERRIDES: assignment_overrides_json(
          @assignment.overrides_for(@current_user, ensure_set_not_empty: true),
          @current_user,
          include_names: true
        ),
        AVAILABLE_MODERATORS: @assignment.available_moderators.map { |user| { name: user.name, id: user.id } },
        COURSE_ID: @context.id,
        GROUP_CATEGORIES: group_categories,
        HAS_GRADED_SUBMISSIONS: @assignment.graded_submissions_exist?,
        KALTURA_ENABLED: !!feature_enabled?(:kaltura),
        HAS_GRADING_PERIODS: @context.grading_periods?,
        MODERATED_GRADING_MAX_GRADER_COUNT: @assignment.moderated_grading_max_grader_count,
        PERMISSIONS: {
          can_manage_groups: can_do(@context.groups.temp_record, @current_user, :create),
          can_edit_grades: can_do(@context, @current_user, :manage_grades),
          manage_grading_schemes: can_do(@context, @current_user, :manage_grades),
          manage_rubrics: @context.grants_right?(@current_user, session, :manage_rubrics)
        },
        PLAGIARISM_DETECTION_PLATFORM: Lti::ToolProxy.capability_enabled_in_context?(
          @assignment.course,
          Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2
        ),
        POST_TO_SIS: post_to_sis,
        SIS_NAME: AssignmentUtil.post_to_sis_friendly_name(@context),
        VALID_DATE_RANGE: CourseDateRange.new(@context),
        NEW_QUIZZES_ASSIGNMENT_BUILD_BUTTON_ENABLED:
          Account.site_admin.feature_enabled?(:new_quizzes_assignment_build_button),
        HIDE_ZERO_POINT_QUIZZES_OPTION_ENABLED:
          Account.site_admin.feature_enabled?(:hide_zero_point_quizzes_option),
        GRADING_SCHEME_UPDATES_ENABLED:
          Account.site_admin.feature_enabled?(:grading_scheme_updates),
        ARCHIVED_GRADING_SCHEMES_ENABLED: Account.site_admin.feature_enabled?(:archived_grading_schemes),
        OUTCOMES_NEW_DECAYING_AVERAGE_CALCULATION:
          @context.root_account.feature_enabled?(:outcomes_new_decaying_average_calculation)
      }

      if @context.root_account.feature_enabled?(:instui_nav)
        if on_quizzes_page? && params.key?(:quiz_lti)
          add_crumb(t("Edit Quiz")) unless @assignment.new_record?
        else
          add_crumb(t("Edit Assignment")) unless @assignment.new_record?
        end
      else
        add_crumb(@assignment.title, polymorphic_url([@context, @assignment])) unless @assignment.new_record?
      end

      hash[:POST_TO_SIS_DEFAULT] = @context.account.sis_default_grade_export[:value] if post_to_sis && @assignment.new_record?
      hash[:ASSIGNMENT] = assignment_json(@assignment, @current_user, session, override_dates: false)
      hash[:ASSIGNMENT][:has_submitted_submissions] = @assignment.has_submitted_submissions?
      hash[:URL_ROOT] = polymorphic_url([:api_v1, @context, :assignments])
      hash[:CANCEL_TO] = set_cancel_to_url
      hash[:CAN_CANCEL_TO] = generate_cancel_to_urls
      hash[:CONTEXT_ID] = @context.id
      hash[:CONTEXT_ACTION_SOURCE] = :assignments
      hash[:MODERATED_GRADING_GRADER_LIMIT] = Course::MODERATED_GRADING_GRADER_LIMIT
      hash[:DUE_DATE_REQUIRED_FOR_ACCOUNT] = AssignmentUtil.due_date_required_for_account?(@context)
      hash[:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT] = AssignmentUtil.name_length_required_for_account?(@context)
      hash[:MAX_NAME_LENGTH] = try(:context).try(:account).try(:sis_assignment_name_length_input).try(:[], :value).to_i
      hash[:IS_MODULE_ITEM] = !@assignment.context_module_tags.empty?

      selected_tool = @assignment.tool_settings_tool
      hash[:SELECTED_CONFIG_TOOL_ID] = selected_tool ? selected_tool.id : nil
      hash[:SELECTED_CONFIG_TOOL_TYPE] = selected_tool ? selected_tool.class.to_s : nil
      hash[:REPORT_VISIBILITY_SETTING] = @assignment.turnitin_settings[:originality_report_visibility]
      hash[:SHOW_SPEED_GRADER_LINK] = Account.site_admin.feature_enabled?(:additional_speedgrader_links) && @assignment.published? && @assignment.can_view_speed_grader?(@current_user)

      if @context.grading_periods?
        hash[:active_grading_periods] = GradingPeriod.json_for(@context, @current_user)
      end

      set_default_tool_env!(@context, hash)
      append_default_due_time_js_env(@context, hash)

      hash[:ANONYMOUS_GRADING_ENABLED] = @context.feature_enabled?(:anonymous_marking)
      hash[:MODERATED_GRADING_ENABLED] = @context.feature_enabled?(:moderated_grading)
      hash[:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED] = @context.feature_enabled?(:anonymous_instructor_annotations)
      hash[:NEW_QUIZZES_ANONYMOUS_GRADING_ENABLED] = Account.site_admin.feature_enabled?(:anonymous_grading_with_new_quizzes)
      hash[:ASSET_PROCESSORS] = Lti::AssetProcessor.for_assignment_id(@assignment.id).info_for_display
      hash[:SUBMISSION_TYPE_SELECTION_TOOLS] = external_tools_display_hashes(
        :submission_type_selection,
        @context,
        %i[base_title external_url selection_width selection_height]
      )
      append_sis_data(hash)
      if context.is_a?(Course)
        hash[:allow_self_signup] = true # for group creation
        hash[:group_user_type] = "student"

        if Account.site_admin.feature_enabled?(:grading_scheme_updates)
          hash[:COURSE_DEFAULT_GRADING_SCHEME_ID] = context.grading_standard_id || context.default_grading_standard&.id
        end
      end

      if @assignment.annotatable_attachment_id.present?
        hash[:ANNOTATED_DOCUMENT] = {
          display_name: @assignment.annotatable_attachment.display_name,
          context_type: @assignment.annotatable_attachment.context_type,
          context_id: @assignment.annotatable_attachment.context_id,
          id: @assignment.annotatable_attachment.id
        }
      end

      hash[:USAGE_RIGHTS_REQUIRED] = @context.try(:usage_rights_required?)
      hash[:restrict_quantitative_data] = @context.is_a?(Course) ? @context.restrict_quantitative_data?(@current_user) : false

      if @assignment.quiz_lti? && @assignment.persisted? && Rubric.enhanced_rubrics_assignments_enabled?(@context)
        enhanced_rubrics_assignments_js_env(@assignment)
      end

      js_env(hash)
      conditional_release_js_env(@assignment)
      set_master_course_js_env_data(@assignment, @context)
      set_section_list_js_env
      render :edit
    end
  end

  def set_cancel_to_url
    if @assignment.quiz_lti? && @context.root_account.feature_enabled?(:newquizzes_on_quiz_page)
      return polymorphic_url([@context, :quizzes])
    end

    @assignment.new_record? ? polymorphic_url([@context, :assignments]) : polymorphic_url([@context, @assignment])
  end

  def generate_cancel_to_urls
    if @assignment.quiz_lti?
      quizzes_url = polymorphic_url([@context, :quizzes])
      assignments_url = polymorphic_url([@context, :assignments])
      modules_url = polymorphic_url([@context, :context_modules])
      gradebook_url = polymorphic_url([@context, :gradebook])
      return [quizzes_url, assignments_url, modules_url, gradebook_url]
    end
    [@assignment.new_record? ? polymorphic_url([@context, :assignments]) : polymorphic_url([@context, @assignment])]
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
    @assignment = api_find(@context.assignments.active, params[:id])
    if authorized_action(@assignment, @current_user, :delete)
      return render_unauthorized_action if editing_restricted?(@assignment)

      SubmissionLifecycleManager.with_executing_user(@current_user) do
        @assignment.destroy
      end

      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url)) }
        format.json { render json: assignment_json(@assignment, @current_user, session) }
      end
    end
  end

  # pulish a N.Q assignment from Quizzes Page
  def publish_quizzes
    if authorized_action(@context, @current_user, :manage_assignments_edit)
      @assignments = @context.assignments.active.where(id: params[:quizzes])
      @assignments.each(&:publish!)

      flash[:notice] = t("notices.quizzes_published",
                         { one: "1 quiz successfully published!",
                           other: "%{count} quizzes successfully published!" },
                         count: @assignments.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render json: {}, status: :ok }
      end
    end
  end

  # unpulish a N.Q assignment from Quizzes Page
  def unpublish_quizzes
    if authorized_action(@context, @current_user, :manage_assignments_edit)
      @assignments = @context.assignments.active.where(id: params[:quizzes], workflow_state: "published")
      @assignments.each(&:unpublish!)

      flash[:notice] = t("notices.quizzes_unpublished",
                         { one: "1 quiz successfully unpublished!",
                           other: "%{count} quizzes successfully unpublished!" },
                         count: @assignments.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render json: {}, status: :ok }
      end
    end
  end

  protected

  def set_default_tool_env!(context, hash)
    root_account_settings = context.root_account.settings
    if root_account_settings[:default_assignment_tool_url] && root_account_settings[:default_assignment_tool_name]
      hash[:DEFAULT_ASSIGNMENT_TOOL_URL] = root_account_settings[:default_assignment_tool_url]
      hash[:DEFAULT_ASSIGNMENT_TOOL_NAME] = root_account_settings[:default_assignment_tool_name]
      hash[:DEFAULT_ASSIGNMENT_TOOL_BUTTON_TEXT] = root_account_settings[:default_assignment_tool_button_text]
      hash[:DEFAULT_ASSIGNMENT_TOOL_INFO_MESSAGE] = root_account_settings[:default_assignment_tool_info_message]
    end
  end

  def show_moderate_env
    can_view_grader_identities = @assignment.can_view_other_grader_identities?(@current_user)

    if can_view_grader_identities
      current_grader_id = @current_user.id
      final_grader_id = @assignment.final_grader_id
    else
      # When the user cannot view other grader identities, the moderation page
      # will be loaded with grader data that has been anonymized. This includes
      # the current user's grader information. The relevant id must be provided
      # to the front end in this case.

      current_grader_id = @assignment.grader_ids_to_anonymous_ids[@current_user.id.to_s]
      final_grader_id = @assignment.grader_ids_to_anonymous_ids[@assignment.final_grader_id&.to_s]
    end

    {
      ASSIGNMENT: {
        course_id: @context.id,
        grades_published: @assignment.grades_published?,
        id: @assignment.id,
        muted: @assignment.muted?,
        title: @assignment.title
      },
      CURRENT_USER: {
        can_view_grader_identities:,
        can_view_student_identities: @assignment.can_view_student_names?(@current_user),
        grader_id: current_grader_id,
        id: @current_user.id
      },
      FINAL_GRADER: @assignment.final_grader && {
        grader_id: final_grader_id,
        id: @assignment.final_grader_id
      },
      GRADERS: moderation_graders_json(@assignment, @current_user, session),
    }
  end

  # LTI 2.0 EULA URL
  def tool_eula_url
    @assignment.tool_settings_tool.try(:tool_proxy)&.find_service(Assignment::LTI_EULA_SERVICE, "GET")&.endpoint
  end

  def strong_assignment_params
    params.require(:assignment)
          .permit(:title,
                  :name,
                  :description,
                  :due_at,
                  :points_possible,
                  :grading_type,
                  :submission_types,
                  :assignment_group,
                  :unlock_at,
                  :lock_at,
                  :group_category,
                  :group_category_id,
                  :peer_review_count,
                  :anonymous_peer_reviews,
                  :peer_reviews_due_at,
                  :peer_reviews_assign_at,
                  :grading_standard_id,
                  :peer_reviews,
                  :automatic_peer_reviews,
                  :grade_group_students_individually,
                  :notify_of_update,
                  :time_zone_edited,
                  :turnitin_enabled,
                  :vericite_enabled,
                  :context,
                  :position,
                  :external_tool_tag_attributes,
                  :freeze_on_copy,
                  :only_visible_to_overrides,
                  :post_to_sis,
                  :sis_assignment_id,
                  :integration_id,
                  :moderated_grading,
                  :omit_from_final_grade,
                  :hide_in_gradebook,
                  :intra_group_peer_reviews,
                  :important_dates,
                  allowed_extensions: strong_anything,
                  turnitin_settings: strong_anything,
                  integration_data: strong_anything)
  end

  def get_assignment_group(assignment_params)
    return unless assignment_params

    if (group_id = assignment_params[:assignment_group_id]).present?
      @context.assignment_groups.find(group_id)
    end
  end

  def normalize_title_param
    params[:title] ||= params[:name]
  end

  def index_edit_params
    params.permit(:title, :due_at, :points_possible, :assignment_group_id, :return_to)
  end

  def pledge_text
    closest_pledge = @assignment.course.account.closest_turnitin_pledge
    pledge = @context.turnitin_pledge.presence || closest_pledge if @assignment.turnitin_enabled?
    pledge ||= @context.vericite_pledge.presence || closest_pledge if @assignment.vericite_enabled?

    pledge || (@assignment.course.account.closest_turnitin_pledge if @assignment.tool_settings_tool.present?)
  end

  def plagiarism_comments
    if @assignment.turnitin_enabled?
      @context.all_turnitin_comments
    elsif @assignment.vericite_enabled?
      @context.vericite_comments
    end
  end

  def quiz_lti_tool_enabled?
    quiz_lti_tool = @context.quiz_lti_tool

    # The void url here is the default voided url as set by the beta refresh.
    # Rather than using the rails env (beta/test) to determine whether or not
    # the tool should be enabled, this URL was chosen because we sometimes
    # want the tool enabled in beta or test. NOTE: This is a stop-gap until
    # Quizzes.Next has a beta env.
    !@context.root_account.feature_enabled?(:newquizzes_on_quiz_page) &&
      @context.feature_enabled?(:quizzes_next) &&
      quiz_lti_tool.present? &&
      quiz_lti_tool.url != "http://void.url.inseng.net"
  end

  def filter_speed_grader_by_student_group?
    # Group assignments only need to filter if they show individual students
    return false if @assignment.group_category_id && !@assignment.grade_group_students_individually?

    @context.filter_speed_grader_by_student_group?
  end

  def add_crumb_on_new_quizzes(new_quiz)
    return if !new_quiz && @assignment.new_record?

    if on_quizzes_page? && params.key?(:quiz_lti)
      add_crumb(t("#crumbs.quizzes", "Quizzes"), course_quizzes_path(@context))
      add_crumb(t("Create Quiz")) if new_quiz && @context.root_account.feature_enabled?(:instui_nav)
    else
      add_crumb(t("#crumbs.assignments", "Assignments"), course_assignments_path(@context))
      add_crumb(t("Create New Assignment")) if new_quiz && @context.root_account.feature_enabled?(:instui_nav)
    end

    add_crumb(t("Create new")) if new_quiz && !@context.root_account.feature_enabled?(:instui_nav)
  end

  def setup_active_tab(controller)
    if on_quizzes_page? && params.key?(:quiz_lti)
      controller.active_tab = "quizzes"
      return
    end

    controller.active_tab = "assignments"
  end

  def on_quizzes_page?
    @context.root_account.feature_enabled?(:newquizzes_on_quiz_page) &&
      @context.feature_enabled?(:quizzes_next) && @context.quiz_lti_tool.present?
  end

  def set_section_list_js_env
    js_env SECTION_LIST: @context.course_sections.active.map { |section|
      {
        id: section.id,
        name: section.name,
        start_at: section.start_at,
        end_at: section.end_at,
        override_course_and_term_dates: section.restrict_enrollments_to_section_dates
      }
    }
  end

  # LTI 1.3 Asset Processor Eula Service
  def asset_processor_eula_js_env
    return unless @current_user
    return unless @context_enrollment&.student?

    js_env ASSET_PROCESSOR_EULA_LAUNCH_URLS: Lti::EulaUiService.eula_launch_urls(user: @current_user, assignment: @assignment)
  end
end
