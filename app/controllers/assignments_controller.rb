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

  include KalturaHelper
  include SyllabusHelper
  before_action :require_context
  add_crumb(
    proc { t '#crumbs.assignments', "Assignments" },
    except: [:destroy, :syllabus, :index, :new, :edit]
  ) { |c| c.send :course_assignments_path, c.instance_variable_get("@context") }
  before_action(except: [:new, :edit]) { |c| c.active_tab = "assignments" }
  before_action(only: [:new, :edit]) { |c| setup_active_tab(c) }
  before_action :normalize_title_param, :only => [:new, :edit]

  def index
    GuardRail.activate(:secondary) do
      return redirect_to(dashboard_url) if @context == @current_user

      if authorized_action(@context, @current_user, :read)
        return unless tab_enabled?(@context.class::TAB_ASSIGNMENTS)
        log_asset_access([ "assignments", @context ], 'assignments', 'other')

        add_crumb(t('#crumbs.assignments', "Assignments"), named_context_url(@context, :context_assignments_url))

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
        set_section_list_js_env if @domain_root_account.feature_enabled?(:assignment_bulk_edit)
        hash = {
          WEIGHT_FINAL_GRADES: @context.apply_group_weights?,
          POST_TO_SIS_DEFAULT: @context.account.sis_default_grade_export[:value],
          SIS_INTEGRATION_SETTINGS_ENABLED: sis_integration_settings_enabled,
          SIS_NAME: sis_name,
          MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT: max_name_length_required_for_account,
          MAX_NAME_LENGTH: max_name_length,
          HAS_ASSIGNMENTS: @context.active_assignments.count > 0,
          QUIZ_LTI_ENABLED: quiz_lti_tool_enabled?,
          DUE_DATE_REQUIRED_FOR_ACCOUNT: due_date_required_for_account,
          FLAGS: {
            newquizzes_on_quiz_page: @context.root_account.feature_enabled?(:newquizzes_on_quiz_page)
          }
        }

        set_default_tool_env!(@context, hash)

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
    @assignment.a2_enabled? && !can_do(@context, @current_user, :read_as_admin) &&
      (!params.key?(:assignments_2) || value_to_boolean(params[:assignments_2]))
  end

  def render_a2_student_view
    submission = @assignment.submissions.find_by(user: @current_user)
    graphql_submisison_id = nil
    if submission
      graphql_submisison_id = CanvasSchema.id_from_object(
        submission,
        CanvasSchema.resolve_type(submission, nil),
        nil
      )
    end

    assignment_prereqs =
      if @locked && !@locked[:can_view]
        context_module_sequence_items_by_asset_id(@assignment.id, "Assignment")
      else
        {}
      end

    js_env({
      ASSIGNMENT_ID: params[:id],
      COURSE_ID: @context.id,
      PREREQS: assignment_prereqs,
      SUBMISSION_ID: graphql_submisison_id
    })
    css_bundle :assignments_2_student
    js_bundle :assignments_2_show_student
    render html: '', layout: true
  end

  def show
    GuardRail.activate(:secondary) do
      @assignment ||= @context.assignments.find(params[:id])

      if @assignment.deleted?
        flash[:notice] = t 'notices.assignment_delete', "This assignment has been deleted"
        redirect_to named_context_url(@context, :context_assignments_url)
        return
      end

      if authorized_action(@assignment, @current_user, :read)
        if @current_user && @assignment && !@assignment.visible_to_user?(@current_user)
          flash[:error] = t 'notices.assignment_not_available', "The assignment you requested is not available to your course section."
          redirect_to named_context_url(@context, :context_assignments_url)
          return
        end

        @assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @current_user)
        @assignment.ensure_assignment_group

        @locked = @assignment.locked_for?(@current_user, :check_policies => true, :deep_check_if_needed => true)
        @unlocked = !@locked || @assignment.grants_right?(@current_user, session, :update)

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

        if render_a2_student_view?
          rce_js_env
          render_a2_student_view
          return
        end

        env = js_env({COURSE_ID: @context.id})
        env[:SETTINGS][:filter_speed_grader_by_student_group] = filter_speed_grader_by_student_group?

        if env[:SETTINGS][:filter_speed_grader_by_student_group]
          eligible_categories = @context.group_categories.active
          eligible_categories = eligible_categories.where(id: @assignment.group_category) if @assignment.group_category.present?
          env[:group_categories] = group_categories_json(eligible_categories, @current_user, session, {include: ['groups']})

          selected_group_id = @current_user.get_preference(:gradebook_settings, @context.global_id)&.dig('filter_rows_by', 'student_group_id')
          # If this is a group assignment and we had previously filtered by a
          # group that isn't part of this assignment's group set, behave as if
          # no group is selected.
          if selected_group_id.present? && Group.active.exists?(group_category_id: eligible_categories.pluck(:id), id: selected_group_id)
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
        elsif @context.feature_enabled?(:conditional_release) && @assignment.wiki_page? &&
          @assignment.wiki_page.grants_right?(@current_user, session, :read)
          return redirect_to named_context_url(@context, :context_wiki_page_url, @assignment.wiki_page.id)
        elsif @assignment.submission_types == 'external_tool' && @assignment.external_tool_tag && @unlocked
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

        if @context.feature_enabled?(:assignments_2_teacher) && (!params.key?(:assignments_2) || value_to_boolean(params[:assignments_2]))
          if can_do(@context, @current_user, :read_as_admin)
            css_bundle :assignments_2_teacher
            js_bundle :assignments_2_show_teacher
            render html: '', layout: true
            return
          end
        end

        # everything else here is only for the old assignment page and can be
        # deleted once the :assignments_2 feature flag is deleted
        @locked.delete(:lock_at) if @locked.is_a?(Hash) && @locked.key?(:unlock_at) # removed to allow proper translation on show page

        if can_read_submissions
          @assigned_assessments = @current_user_submission&.assigned_assessments&.select { |request| request.submission.grants_right?(@current_user, session, :read) } || []
        end

        if @assignment.submission_types.include?("online_upload") || @assignment.submission_types.include?("online_url")
          @external_tools = ContextExternalTool.all_tools_for(@context, :user => @current_user, :placements => :homework_submission)
        else
          @external_tools = []
        end

        permissions = {
          context: @context.rights_status(@current_user, session, :read_as_admin, :manage_assignments),
          assignment: @assignment.rights_status(@current_user, session, :update, :submit),
        }

        @similarity_pledge = pledge_text

        js_env({
          EULA_URL: tool_eula_url,
          EXTERNAL_TOOLS: external_tools_json(@external_tools, @context, @current_user, session),
          PERMISSIONS: permissions,
          ROOT_OUTCOME_GROUP: outcome_group_json(@context.root_outcome_group, @current_user, session),
          SIMILARITY_PLEDGE: @similarity_pledge,
          CONFETTI_ENABLED: @domain_root_account&.feature_enabled?(:confetti_for_assignments),
          USER_ASSET_STRING: @current_user&.asset_string,
        })

        set_master_course_js_env_data(@assignment, @context)
        conditional_release_js_env(@assignment, includes: :rule)

        @can_view_grades = @context.grants_right?(@current_user, session, :view_all_grades)
        @downloadable_submissions = downloadable_submissions?(@current_user, @context, @assignment)
        @can_grade = @assignment.grants_right?(@current_user, session, :grade)
        if @can_view_grades || @can_grade
          visible_student_ids = @context.apply_enrollment_visibility(@context.all_student_enrollments, @current_user).pluck(:user_id)
          @current_student_submissions = @assignment.submissions.where("submissions.submission_type IS NOT NULL").where(:user_id => visible_student_ids).to_a
        end

        # this will set @user_has_google_drive
        user_has_google_drive

        @can_direct_share = @context.root_account.feature_enabled?(:direct_share) && @context.grants_right?(@current_user, session, :read_as_admin)
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
        }, stream: can_stream_template?
      end
    end
  end

  def show_moderate
    @assignment ||= @context.assignments.find(params[:assignment_id])

    raise ActiveRecord::RecordNotFound unless @assignment.moderated_grading? && @assignment.published?

    render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)

    add_crumb(@assignment.title, polymorphic_url([@context, @assignment]))
    add_crumb(t('Moderate'))

    css_bundle :assignment_grade_summary
    js_bundle :assignment_grade_summary
    js_env(show_moderate_env)
    set_student_context_cards_js_env

    @page_title = @assignment.title

    render html: "", layout: true
  end

  def downloadable_submissions?(current_user, context, assignment)
    types = ["online_upload", "online_url", "online_text_entry"]
    return unless (assignment.submission_types.split(",") & types).any? && current_user

    student_ids =
      if assignment.grade_as_group?
        assignment.representatives(user: current_user).map(&:id)
      else
        context.apply_enrollment_visibility(context.student_enrollments, current_user).pluck(:user_id)
      end
    student_ids.any? && assignment.submissions.where(user_id: student_ids, submission_type: types).exists?
  end

  def list_google_docs
    assignment ||= @context.assignments.find(params[:id])
    # prevent masquerading users from accessing google docs
    if assignment.allow_google_docs_submission? && @real_current_user.blank?
      docs = {}
      begin
        docs = google_drive_connection.list_with_extension_filter(assignment.allowed_extensions)
      rescue GoogleDrive::NoTokenError, Google::APIClient::AuthorizationError => e
        Canvas::Errors.capture_exception(:oauth, e, :warn)
      rescue ArgumentError => e
        Canvas::Errors.capture_exception(:oauth, e)
      rescue => e
        Canvas::Errors.capture_exception(:oauth, e)
        raise e
      end
      respond_to do |format|
        format.json { render json: docs.to_hash }
      end
    else
      error_object = {errors:
        {base: t('errors.google_docs_masquerade_rejected', "Unable to connect to Google Docs as a masqueraded user.")}
      }
      respond_to do |format|
        format.json { render json: error_object, status: :bad_request }
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
      @assignment.intra_group_peer_reviews = params[:intra_group_peer_reviews].present?
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
      @request = AssessmentRequest.where(id: params[:id]).first if params[:id].present?
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
      @request = AssessmentRequest.where(id: params[:id]).first if params[:id].present?
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

      @students = student_scope.not_fake_student.distinct.order_by_sortable_name
      @submissions = @assignment.submissions.include_assessment_requests
    end
  end

  def syllabus
    rce_js_env
    add_crumb t '#crumbs.syllabus', "Syllabus"
    active_tab = "Syllabus"
    if authorized_action(@context, @current_user, [:read, :read_syllabus])
      return unless tab_enabled?(@context.class::TAB_SYLLABUS)
      @groups = @context.assignment_groups.active.order(
        :position,
        AssignmentGroup.best_unicode_collation_key('name')
      ).to_a
      @syllabus_body = syllabus_user_content

      hash = {
        CONTEXT_ACTION_SOURCE: :syllabus,
      }
      append_sis_data(hash)
      js_env(hash)
      set_tutorial_js_env

      log_asset_access([ "syllabus", @context ], "syllabus", 'other')
      respond_to do |format|
        format.html
      end
    end
  end

  def toggle_mute
    return nil unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
    @assignment = @context.assignments.active.find(params[:assignment_id])

    toggle_value = params[:status] == 'true'
    return render_unauthorized_action if !toggle_value && !@assignment.grades_published?

    method = toggle_value ? :mute! : :unmute!
    @assignment.updating_user = @current_user

    respond_to do |format|
      if @assignment && @assignment.send(method)
        format.json { render json: @assignment.as_json(methods: :anonymize_students) }
      else
        format.json { render :json => @assignment, :status => :bad_request }
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

    @assignment.quiz_lti! if params.key?(:quiz_lti)

    @assignment.workflow_state = "unpublished"
    @assignment.updating_user = @current_user
    @assignment.content_being_saved_by(@current_user)
    @assignment.assignment_group = group if group
    # if no due_at was given, set it to 11:59 pm in the creator's time zone
    @assignment.infer_times
    if authorized_action(@assignment, @current_user, :create)
      DueDateCacher.with_executing_user(@current_user) do
        respond_to do |format|
          if @assignment.save
            flash[:notice] = t 'notices.created', "Assignment was successfully created."
            format.html { redirect_to named_context_url(@context, :context_assignment_url, @assignment.id) }
            format.json { render :json => @assignment.as_json(:permissions => {:user => @current_user, :session => session}), :status => :created}
          else
            format.html { render :new }
            format.json { render :json => @assignment.errors, :status => :bad_request }
          end
        end
      end
    end
  end

  def new
    @assignment ||= @context.assignments.temp_record
    @assignment.workflow_state = 'unpublished'
    add_crumb_on_new_quizzes(true)

    if params[:submission_types] == 'discussion_topic'
      redirect_to new_polymorphic_url([@context, :discussion_topic], index_edit_params)
    elsif @context.feature_enabled?(:conditional_release) && params[:submission_types] == 'wiki_page'
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

      if @assignment.submission_types == 'online_quiz' && @assignment.quiz
        return redirect_to edit_course_quiz_url(@context, @assignment.quiz, index_edit_params)
      elsif @assignment.submission_types == 'discussion_topic' && @assignment.discussion_topic
        return redirect_to edit_polymorphic_url([@context, @assignment.discussion_topic], index_edit_params)
      elsif @context.feature_enabled?(:conditional_release) &&
        @assignment.submission_types == 'wiki_page' && @assignment.wiki_page
        return redirect_to edit_polymorphic_url([@context, @assignment.wiki_page], index_edit_params)
      end

      assignment_groups = @context.assignment_groups.active
      group_categories = @context.group_categories.
        select { |c| !c.student_organized? }.
        map { |c| { :id => c.id, :name => c.name } }

      # if assignment has student submissions and is attached to a deleted group category,
      # add that category to the ENV list so it can be shown on the edit page.
      if @assignment.group_category_deleted_with_submissions?
        locked_category = @assignment.group_category
        group_categories << { :id => locked_category.id, :name => locked_category.name }
      end

      json_for_assignment_groups = assignment_groups.map do |group|
        assignment_group_json(group, @current_user, session, [], {stringify_json_ids: true})
      end

      post_to_sis = Assignment.sis_grade_export_enabled?(@context)
      hash = {
        ROOT_OUTCOME_GROUP: outcome_group_json(@context.root_outcome_group, @current_user, session),
        ASSIGNMENT_GROUPS: json_for_assignment_groups,
        ASSIGNMENT_INDEX_URL: polymorphic_url([@context, :assignments]),
        ASSIGNMENT_OVERRIDES: assignment_overrides_json(
          @assignment.overrides_for(@current_user, ensure_set_not_empty: true),
          @current_user
        ),
        AVAILABLE_MODERATORS: @assignment.available_moderators.map { |user| { name: user.name, id: user.id } },
        COURSE_ID: @context.id,
        GROUP_CATEGORIES: group_categories,
        HAS_GRADED_SUBMISSIONS: @assignment.graded_submissions_exist?,
        KALTURA_ENABLED: !!feature_enabled?(:kaltura),
        HAS_GRADING_PERIODS: @context.grading_periods?,
        MODERATED_GRADING_MAX_GRADER_COUNT: @assignment.moderated_grading_max_grader_count,
        PLAGIARISM_DETECTION_PLATFORM: Lti::ToolProxy.capability_enabled_in_context?(
          @assignment.course,
          Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2
        ),
        POST_TO_SIS: post_to_sis,
        SIS_NAME: AssignmentUtil.post_to_sis_friendly_name(@context),
        VALID_DATE_RANGE: CourseDateRange.new(@context)
      }

      add_crumb(@assignment.title, polymorphic_url([@context, @assignment])) unless @assignment.new_record?
      hash[:POST_TO_SIS_DEFAULT] = @context.account.sis_default_grade_export[:value] if post_to_sis && @assignment.new_record?
      hash[:ASSIGNMENT] = assignment_json(@assignment, @current_user, session, override_dates: false)
      hash[:ASSIGNMENT][:has_submitted_submissions] = @assignment.has_submitted_submissions?
      hash[:URL_ROOT] = polymorphic_url([:api_v1, @context, :assignments])
      hash[:CANCEL_TO] = set_cancel_to_url
      hash[:CONTEXT_ID] = @context.id
      hash[:CONTEXT_ACTION_SOURCE] = :assignments
      hash[:DUE_DATE_REQUIRED_FOR_ACCOUNT] = AssignmentUtil.due_date_required_for_account?(@context)
      hash[:MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT] = AssignmentUtil.name_length_required_for_account?(@context)
      hash[:MAX_NAME_LENGTH] = self.try(:context).try(:account).try(:sis_assignment_name_length_input).try(:[], :value).to_i

      selected_tool = @assignment.tool_settings_tool
      hash[:SELECTED_CONFIG_TOOL_ID] = selected_tool ? selected_tool.id : nil
      hash[:SELECTED_CONFIG_TOOL_TYPE] = selected_tool ? selected_tool.class.to_s : nil
      hash[:REPORT_VISIBILITY_SETTING] = @assignment.turnitin_settings[:originality_report_visibility]

      if @context.grading_periods?
        hash[:active_grading_periods] = GradingPeriod.json_for(@context, @current_user)
      end

      set_default_tool_env!(@context, hash)

      hash[:ANONYMOUS_GRADING_ENABLED] = @context.feature_enabled?(:anonymous_marking)
      hash[:MODERATED_GRADING_ENABLED] = @context.feature_enabled?(:moderated_grading)
      hash[:ANONYMOUS_INSTRUCTOR_ANNOTATIONS_ENABLED] = @context.feature_enabled?(:anonymous_instructor_annotations)

      hash[:SUBMISSION_TYPE_SELECTION_TOOLS] =
        @domain_root_account&.feature_enabled?(:submission_type_tool_placement) ?
        external_tools_display_hashes(:submission_type_selection, @context,
          [:base_title, :external_url, :selection_width, :selection_height]) : []

      append_sis_data(hash)
      if context.is_a?(Course)
        hash[:allow_self_signup] = true # for group creation
        hash[:group_user_type] = 'student'
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

      DueDateCacher.with_executing_user(@current_user) do
        @assignment.destroy
      end

      respond_to do |format|
        format.html { redirect_to(named_context_url(@context, :context_assignments_url)) }
        format.json { render :json => assignment_json(@assignment, @current_user, session) }
      end
    end
  end

  # pulish a N.Q assignment from Quizzes Page
  def publish_quizzes
    if authorized_action(@context, @current_user, :manage_assignments)
      @assignments = @context.assignments.active.where(id: params[:quizzes])
      @assignments.each(&:publish!)

      flash[:notice] = t('notices.quizzes_published',
                         { :one => "1 quiz successfully published!",
                           :other => "%{count} quizzes successfully published!" },
                         :count => @assignments.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render :json => {}, :status => :ok }
      end
    end
  end

  # unpulish a N.Q assignment from Quizzes Page
  def unpublish_quizzes
    if authorized_action(@context, @current_user, :manage_assignments)
      @assignments = @context.assignments.active.where(id: params[:quizzes], workflow_state: 'published')
      @assignments.each(&:unpublish!)

      flash[:notice] = t('notices.quizzes_unpublished',
                         { :one => "1 quiz successfully unpublished!",
                           :other => "%{count} quizzes successfully unpublished!" },
                         :count => @assignments.length)

      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_quizzes_url) }
        format.json { render :json => {}, :status => :ok }
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
        can_view_grader_identities: can_view_grader_identities,
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

  def tool_eula_url
    @assignment.tool_settings_tool.try(:tool_proxy)&.find_service(Assignment::LTI_EULA_SERVICE, 'GET')&.endpoint
  end

  def strong_assignment_params
    params.require(:assignment).
      permit(:title, :name, :description, :due_at, :points_possible,
        :grading_type, :submission_types, :assignment_group, :unlock_at, :lock_at,
        :group_category, :group_category_id, :peer_review_count, :anonymous_peer_reviews,
        :peer_reviews_due_at, :peer_reviews_assign_at, :grading_standard_id,
        :peer_reviews, :automatic_peer_reviews, :grade_group_students_individually,
        :notify_of_update, :time_zone_edited, :turnitin_enabled, :vericite_enabled,
        :context, :position, :external_tool_tag_attributes, :freeze_on_copy,
        :only_visible_to_overrides, :post_to_sis, :sis_assignment_id, :integration_id, :moderated_grading,
        :omit_from_final_grade, :intra_group_peer_reviews,
        :allowed_extensions => strong_anything,
        :turnitin_settings => strong_anything,
        :integration_data => strong_anything)
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
      quiz_lti_tool.url != 'http://void.url.inseng.net'
  end

  def filter_speed_grader_by_student_group?
    # Group assignments only need to filter if they show individual students
    return false if @assignment.group_category? && !@assignment.grade_group_students_individually?

    @context.filter_speed_grader_by_student_group?
  end

  def add_crumb_on_new_quizzes(new_quiz)
    return if !new_quiz && @assignment.new_record?

    if on_quizzes_page? && params.key?(:quiz_lti)
      add_crumb(t('#crumbs.quizzes', "Quizzes"), course_quizzes_path(@context))
    else
      add_crumb(t('#crumbs.assignments', "Assignments"), course_assignments_path(@context))
    end

    add_crumb(t('Create new')) if new_quiz
  end

  def setup_active_tab(controller)
    if on_quizzes_page? && params.key?(:quiz_lti)
      controller.active_tab = "quizzes"
      return
    end

    controller.active_tab = "assignments"
  end

  def on_quizzes_page?
    @context.root_account.feature_enabled?(:newquizzes_on_quiz_page) && \
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
end
