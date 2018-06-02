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

module Api::V1::Assignment
  include Api::V1::Json
  include ApplicationHelper
  include Api::V1::ExternalTools::UrlHelpers
  include Api::V1::Locked
  include Api::V1::AssignmentOverride
  include SubmittablesGradingPeriodProtection
  include Api::V1::PlannerOverride

  API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS = {
    :only => %w(
      id
      position
      description
      points_possible
      grading_type
      created_at
      updated_at
      due_at
      final_grader_id
      grader_count
      lock_at
      unlock_at
      assignment_group_id
      peer_reviews
      anonymous_peer_reviews
      automatic_peer_reviews
      intra_group_peer_reviews
      post_to_sis
      grade_group_students_individually
      group_category_id
      grading_standard_id
      moderated_grading
      omit_from_final_grade
      anonymous_instructor_annotations
      anonymous_grading
    )
  }.freeze

  API_ASSIGNMENT_NEW_RECORD_FIELDS = {
    :only => %w(
      points_possible
      due_at
      assignment_group_id
      post_to_sis
    )
  }.freeze

  EDITABLE_ATTRS_IN_CLOSED_GRADING_PERIOD = %w[
    description
    submission_types
    peer_reviews
    peer_review_count
    anonymous_peer_reviews
    peer_reviews_due_at
    automatic_peer_reviews
    allowed_extensions
    due_at
    only_visible_to_overrides
    post_to_sis
    time_zone_edited
  ].freeze

  def assignments_json(assignments, user, session, opts = {})
    # check if all assignments being serialized belong to the same course
    contexts = assignments.map {|a| [a.context_id, a.context_type] }.uniq
    if contexts.length == 1
      # if so, calculate their effective due dates in one go, rather than individually
      opts[:exclude_response_fields] ||= []
      opts[:exclude_response_fields] << 'in_closed_grading_period'
      due_dates = EffectiveDueDates.for_course(assignments.first.context, assignments)
    end

    assignments.map do |assignment|
      json = assignment_json(assignment, user, session, opts)
      unless json.key? 'in_closed_grading_period'
        json['in_closed_grading_period'] = due_dates.in_closed_grading_period?(assignment)
      end
      json
    end
  end

  def assignment_json(assignment, user, session, opts = {})
    opts.reverse_merge!(
      include_discussion_topic: true,
      include_all_dates: false,
      override_dates: true,
      needs_grading_count_by_section: false,
      exclude_response_fields: [],
      include_planner_override: false
    )

    if opts[:override_dates] && !assignment.new_record?
      assignment = assignment.overridden_for(user)
    end

    fields = assignment.new_record? ? API_ASSIGNMENT_NEW_RECORD_FIELDS : API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS
    if opts[:exclude_response_fields].include?('description')
      fields_copy = fields[:only].dup
      fields_copy.delete("description")
      fields = {only: fields_copy}
    end

    hash = api_json(assignment, user, session, fields)
    hash['secure_params'] = assignment.secure_params if assignment.has_attribute?(:lti_context_id)
    hash['course_id'] = assignment.context_id
    hash['name'] = assignment.title
    hash['submission_types'] = assignment.submission_types_array
    hash['has_submitted_submissions'] = assignment.has_submitted_submissions?
    hash['due_date_required'] = assignment.due_date_required?
    hash['max_name_length'] = assignment.max_name_length

    unless opts[:exclude_response_fields].include?('in_closed_grading_period')
      hash['in_closed_grading_period'] = assignment.in_closed_grading_period?
    end

    hash['grades_published'] = assignment.grades_published? if opts[:include_grades_published]

    if !opts[:overrides].blank?
      hash['overrides'] = assignment_overrides_json(opts[:overrides], user)
    elsif opts[:include_overrides]
      hash['overrides'] = assignment_overrides_json(assignment.assignment_overrides.select(&:active?), user)
    end

    if !assignment.user_submitted.nil?
      hash['user_submitted'] = assignment.user_submitted
    end

    hash['omit_from_final_grade'] = assignment.omit_from_final_grade?

    if assignment.context && assignment.context.turnitin_enabled?
      hash['turnitin_enabled'] = assignment.turnitin_enabled
      hash['turnitin_settings'] = turnitin_settings_json(assignment)
    end

    if assignment.context && assignment.context.vericite_enabled?
      hash['vericite_enabled'] = assignment.vericite_enabled
      hash['vericite_settings'] = vericite_settings_json(assignment)
    end

    if PluginSetting.settings_for_plugin(:assignment_freezer)
      hash['freeze_on_copy'] = assignment.freeze_on_copy?
      hash['frozen'] = assignment.frozen_for_user?(user)
      hash['frozen_attributes'] = assignment.frozen_attributes_for_user(user)
    end

    hash['is_quiz_assignment'] = assignment.quiz? && assignment.quiz.assignment?
    hash['can_duplicate'] = assignment.can_duplicate?
    hash['original_assignment_id'] = assignment.duplicate_of&.id
    hash['original_assignment_name'] = assignment.duplicate_of&.name
    hash['workflow_state'] = assignment.workflow_state

    if assignment.quiz_lti?
      hash['is_quiz_lti_assignment'] = true
      hash['frozen_attributes'] ||= []
      hash['frozen_attributes'] << 'submission_types'
    end

    if assignment.external_tool? && assignment.external_tool_tag.present?
      hash['external_tool_tag_attributes'] = { 'url' => assignment.external_tool_tag.url }
    end

    return hash if assignment.new_record?

    # use already generated hash['description'] because it is filtered by
    # Assignment#filter_attributes_for_user when the assignment is locked
    unless opts[:exclude_response_fields].include?('description')
      hash['description'] = api_user_content(hash['description'],
                                             @context || assignment.context,
                                             user,
                                             opts[:preloaded_user_content_attachments] || {})
    end

    can_manage = assignment.context.grants_any_right?(user, :manage, :manage_grades, :manage_assignments)
    hash['muted'] = assignment.muted?
    hash['html_url'] = course_assignment_url(assignment.context_id, assignment)
    if can_manage
      hash['has_overrides'] = assignment.has_overrides?
    end

    if assignment.external_tool? && assignment.external_tool_tag.present?
      external_tool_tag = assignment.external_tool_tag
      hash['external_tool_tag_attributes'] = {
        'url' => external_tool_tag.url,
        'new_tab' => external_tool_tag.new_tab,
        'resource_link_id' => assignment.lti_resource_link_id
      }
      hash['url'] = sessionless_launch_url(@context,
                                           :launch_type => 'assessment',
                                           :assignment_id => assignment.id)
    end

    if assignment.automatic_peer_reviews? && assignment.peer_reviews?
      peer_review_params = assignment.slice(
        :peer_review_count,
        :peer_reviews_assign_at,
        :intra_group_peer_reviews
      )
      hash.merge!(peer_review_params)
    end

    include_needs_grading_count = opts[:exclude_response_fields].exclude?('needs_grading_count')
    if include_needs_grading_count && assignment.context.grants_right?(user, :manage_grades)
      query = Assignments::NeedsGradingCountQuery.new(assignment, user, opts[:needs_grading_course_proxy])
      if opts[:needs_grading_count_by_section]
        hash['needs_grading_count_by_section'] = query.count_by_section
      end
      hash['needs_grading_count'] = query.count
    end

    if assignment.context.grants_any_right?(user, :read_sis, :manage_sis)
      hash['integration_id'] = assignment.integration_id
      hash['integration_data'] = assignment.integration_data
    end

    if assignment.quiz
      hash['quiz_id'] = assignment.quiz.id
      hash['anonymous_submissions'] = !!(assignment.quiz.anonymous_submissions)
    end

    if assignment.allowed_extensions.present?
      hash['allowed_extensions'] = assignment.allowed_extensions
    end

    unless opts[:exclude_response_fields].include?('rubric')
      if assignment.rubric_association
        hash['use_rubric_for_grading'] = !!assignment.rubric_association.use_for_grading
        if assignment.rubric_association.rubric
          hash['free_form_criterion_comments'] = !!assignment.rubric_association.rubric.free_form_criterion_comments
        end
      end

      if assignment.rubric
        rubric = assignment.rubric
        hash['rubric'] = rubric.data.map do |row|
          row_hash = row.slice(:id, :points, :description, :long_description)
          row_hash["criterion_use_range"] = row[:criterion_use_range] || false
          row_hash["ratings"] = row[:ratings].map do |c|
            rating_hash = c.slice(:id, :points, :description, :long_description)
            rating_hash["long_description"] = c[:long_description] || ""
            rating_hash
          end
          if row[:learning_outcome_id] && outcome = LearningOutcome.where(id: row[:learning_outcome_id]).first
            row_hash["outcome_id"] = outcome.id
            row_hash["vendor_guid"] = outcome.vendor_guid
          end
          row_hash
        end
        hash['rubric_settings'] = {
          'id' => rubric.id,
          'title' => rubric.title,
          'points_possible' => rubric.points_possible,
          'free_form_criterion_comments' => !!rubric.free_form_criterion_comments
        }
      end
    end

    if opts[:include_discussion_topic] && assignment.discussion_topic
      extend Api::V1::DiscussionTopics
      hash['discussion_topic'] = discussion_topic_api_json(
        assignment.discussion_topic,
        assignment.discussion_topic.context,
        user,
        session,
        include_assignment: false, exclude_messages: opts[:exclude_response_fields].include?('description'))
    end

    if opts[:include_all_dates] && assignment.assignment_overrides
      override_count = assignment.assignment_overrides.loaded? ?
        assignment.assignment_overrides.select(&:active?).count : assignment.assignment_overrides.active.count
      if override_count < Setting.get('assignment_all_dates_too_many_threshold', '25').to_i
        hash['all_dates'] = assignment.dates_hash_visible_to(user)
      else
        hash['all_dates_count'] = override_count
      end
    end

    if opts[:include_module_ids]
      modulable = case assignment.submission_types
                  when 'online_quiz' then assignment.quiz
                  when 'discussion_topic' then assignment.discussion_topic
                  else assignment
                  end

      if modulable
        hash['module_ids'] = modulable.context_module_tags.map(&:context_module_id)
        hash['module_positions'] = modulable.context_module_tags.map(&:position)
      end
    end

    hash['published'] = assignment.published?
    if can_manage
      hash['unpublishable'] = assignment.can_unpublish?
    end

    hash['only_visible_to_overrides'] = value_to_boolean(assignment.only_visible_to_overrides)

    if opts[:include_visibility]
      hash['assignment_visibility'] = (opts[:assignment_visibilities] || assignment.students_with_visibility.pluck(:id).uniq).map(&:to_s)
    end

    if submission = opts[:submission]
      if submission.is_a?(Array)
        ActiveRecord::Associations::Preloader.new.preload(submission, :quiz_submission) if assignment.quiz?
        hash['submission'] = submission.map { |s| submission_json(s, assignment, user, session, params) }
      else
        hash['submission'] = submission_json(submission, assignment, user, session, params)
      end
    end

    if opts[:bucket]
      hash['bucket'] = opts[:bucket]
    end

    locked_json(hash, assignment, user, 'assignment')

    if assignment.context.present?
      hash['submissions_download_url'] = submissions_download_url(assignment.context, assignment)
    end

    if opts[:master_course_status]
      hash.merge!(assignment.master_course_api_restriction_data(opts[:master_course_status]))
    end

    if opts[:include_planner_override]
      override = assignment.planner_override_for(user)
      hash['planner_override'] = planner_override_json(override, user, session)
    end

    hash['anonymous_grading'] = value_to_boolean(assignment.anonymous_grading)

    hash
  end

  def turnitin_settings_json(assignment)
    settings = assignment.turnitin_settings.with_indifferent_access
    [:s_paper_check, :internet_check, :journal_check, :exclude_biblio, :exclude_quoted, :submit_papers_to].each do |key|
      settings[key] = value_to_boolean(settings[key])
    end

    ex_type = settings.delete(:exclude_type)
    settings[:exclude_small_matches_type] = case ex_type
      when '0'; nil
      when '1'; 'words'
      when '2'; 'percent'
    end

    ex_value = settings.delete(:exclude_value)
    settings[:exclude_small_matches_value] = ex_value.present? ? ex_value.to_i : nil

    settings.slice(*API_ALLOWED_TURNITIN_SETTINGS)
  end

  def vericite_settings_json(assignment)
    settings = assignment.vericite_settings.with_indifferent_access
    [:exclude_quoted, :exclude_self_plag, :store_in_index].each do |key|
      settings[key] = value_to_boolean(settings[key])
    end

    settings.slice(*API_ALLOWED_VERICITE_SETTINGS)
  end

  API_ALLOWED_ASSIGNMENT_INPUT_FIELDS = %w(
    name
    description
    position
    points_possible
    grader_count
    grading_type
    allowed_extensions
    due_at
    lock_at
    unlock_at
    assignment_group_id
    group_category_id
    peer_reviews
    anonymous_peer_reviews
    peer_reviews_assign_at
    peer_review_count
    automatic_peer_reviews
    intra_group_peer_reviews
    grade_group_students_individually
    turnitin_enabled
    vericite_enabled
    grading_standard_id
    freeze_on_copy
    notify_of_update
    integration_id
    omit_from_final_grade
    anonymous_instructor_annotations
  ).freeze

  API_ALLOWED_TURNITIN_SETTINGS = %w(
    originality_report_visibility
    s_paper_check
    internet_check
    journal_check
    exclude_biblio
    exclude_quoted
    exclude_small_matches_type
    exclude_small_matches_value
    submit_papers_to
  ).freeze

  API_ALLOWED_VERICITE_SETTINGS = %w(
    originality_report_visibility
    exclude_quoted
    exclude_self_plag
    store_in_index
  ).freeze

  def create_api_assignment(assignment, assignment_params, user, context = assignment.context)
    return :forbidden unless grading_periods_allow_submittable_create?(assignment, assignment_params)

    prepared_create = prepare_assignment_create_or_update(assignment, assignment_params, user, context)
    return false unless prepared_create[:valid]

    response = :created

    Assignment.suspend_due_date_caching do
      assignment.quiz_lti! if assignment_params.key?(:quiz_lti)

      response = if prepared_create[:overrides].present?
        create_api_assignment_with_overrides(prepared_create, user)
      else
        prepared_create[:assignment].save!
        :created
      end
    end

    DueDateCacher.recompute(prepared_create[:assignment], update_grades: true)
    response
  rescue ActiveRecord::RecordInvalid
    false
  rescue Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError => e
    assignment.errors.add('plagiarism_tool_subscription', e)
    false
  end

  def update_api_assignment(assignment, assignment_params, user, context = assignment.context)
    return :forbidden unless grading_periods_allow_submittable_update?(assignment, assignment_params)

    prepared_update = prepare_assignment_create_or_update(assignment, assignment_params, user, context)
    return false unless prepared_update[:valid]

    cached_due_dates_changed = prepared_update[:assignment].update_cached_due_dates?
    response = :ok

    Assignment.suspend_due_date_caching do
      response = if prepared_update[:overrides]
        update_api_assignment_with_overrides(prepared_update, user)
      else
        prepared_update[:assignment].save!
        :ok
      end
    end

    if @overrides_affected.to_i > 0 || cached_due_dates_changed
      DueDateCacher.recompute(prepared_update[:assignment], update_grades: true)
    end

    response
  rescue ActiveRecord::RecordInvalid
    false
  rescue Lti::AssignmentSubscriptionsHelper::AssignmentSubscriptionError => e
    assignment.errors.add('plagiarism_tool_subscription', e)
    false
  end

  API_ALLOWED_SUBMISSION_TYPES = [
    "online_quiz",
    "none",
    "on_paper",
    "discussion_topic",
    "external_tool",
    "online_upload",
    "online_text_entry",
    "online_url",
    "media_recording",
    "not_graded",
    "wiki_page",
    ""
  ].freeze

  def submission_types_valid?(assignment, assignment_params)
    return true if assignment_params['submission_types'].nil?
    assignment_params['submission_types'] = Array(assignment_params['submission_types'])

    if assignment_params['submission_types'].present? &&
      !assignment_params['submission_types'].all? do |s|
        return false if s == 'wiki_page' && !self.context.try(:feature_enabled?, :conditional_release)
        API_ALLOWED_SUBMISSION_TYPES.include?(s)
      end
        assignment.errors.add('assignment[submission_types]',
          I18n.t('assignments_api.invalid_submission_types',
            'Invalid submission types'))
        return false
    end
    true
  end

  # validate that date and times are iso8601
  def assignment_dates_valid?(assignment, assignment_params)
    errors = ['due_at', 'lock_at', 'unlock_at', 'peer_reviews_assign_at'].map do |v|
      if assignment_params[v].present? && assignment_params[v] !~ Api::ISO8601_REGEX
        assignment.errors.add("assignment[#{v}]",
                              I18n.t("assignments_api.invalid_date_time",
                                     'Invalid datetime for %{attribute}',
                                     attribute: v))
      end
    end

    errors.compact.empty?
  end

  def assignment_group_id_valid?(assignment, assignment_params)
    ag_id = assignment_params["assignment_group_id"].presence
    # if ag_id is a non-numeric string, ag_id.to_i will == 0
    if ag_id and ag_id.to_i <= 0
      assignment.errors.add('assignment[assignment_group_id]', I18n.t(:not_a_number, "must be a positive number"))
      false
    else
      true
    end
  end

  def assignment_final_grader_valid?(assignment, course)
    return true unless assignment.final_grader_id && assignment.final_grader_id_changed?

    final_grader = course.participating_instructors.find_by(id: assignment.final_grader_id)
    if final_grader.nil?
      assignment.errors.add('final_grader_id', I18n.t('course has no active instructors with this ID'))
      false
    elsif !course.grants_right?(final_grader, :select_final_grade)
      assignment.errors.add('final_grader_id', I18n.t('user does not have permission to select final grade'))
      false
    else
      true
    end
  end

  def assignment_editable_fields_valid?(assignment, user)
    return true if assignment.context.account_membership_allows(user)
    # if not in closed grading period editable fields are valid
    return true unless assignment.in_closed_grading_period?
    # if assignment was not and is still not gradeable fields are valid
    return true unless assignment.gradeable_was? || assignment.gradeable?

    impermissible_changes = assignment.changes.keys - EDITABLE_ATTRS_IN_CLOSED_GRADING_PERIOD
    # backend is title, frontend is name
    impermissible_changes << "name" if impermissible_changes.delete("title")
    return true unless impermissible_changes.present?

    impermissible_changes.each do |change|
      assignment.errors.add(change, I18n.t("cannot be changed because this assignment is due in a closed grading period"))
    end
    false
  end

  def update_from_params(assignment, assignment_params, user, context = assignment.context)
    update_params = assignment_params.permit(allowed_assignment_input_fields)

    if update_params.key?('peer_reviews_assign_at')
      update_params['peer_reviews_due_at'] = update_params['peer_reviews_assign_at']
      update_params.delete('peer_reviews_assign_at')
    end

    if update_params["submission_types"].is_a? Array
      update_params["submission_types"] = update_params["submission_types"].map do |type|
        # TODO: remove. this was temporary backward support for a hotfix
        type == "online_media_recording" ? "media_recording" : type
      end
      update_params["submission_types"] = update_params["submission_types"].join(',')
    end

    if update_params.key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      assignment.assignment_group = assignment.context.assignment_groups.where(id: ag_id).first
    end

    if update_params.key?("group_category_id") && !assignment.group_category_deleted_with_submissions?
      gc_id = update_params.delete("group_category_id").presence
      assignment.group_category = assignment.context.group_categories.where(id: gc_id).first
    end

    if update_params.key?("grading_standard_id")
      standard_id = update_params.delete("grading_standard_id")
      if standard_id.present?
        grading_standard = GradingStandard.for(context).where(id: standard_id).first
        assignment.grading_standard = grading_standard if grading_standard
      else
        assignment.grading_standard = nil
      end
    end

    if assignment_params.key? "muted"
      muted = value_to_boolean(assignment_params.delete("muted"))
      if muted
        assignment.mute!
      else
        assignment.unmute!
      end
    end

    if assignment.context.grants_right?(user, :manage_sis)
      data = update_params['integration_data']
      update_params['integration_data'] = JSON.parse(data) if data.is_a?(String)
    else
      update_params.delete('integration_id')
      update_params.delete('integration_data')
    end

    # do some fiddling with due_at for fancy midnight and add to update_params
    if update_params['due_at'].present? && update_params['due_at'] =~ Api::ISO8601_REGEX
      update_params['time_zone_edited'] = Time.zone.name
    end

    if !assignment.context.try(:turnitin_enabled?)
      update_params.delete("turnitin_enabled")
      update_params.delete("turnitin_settings")
    end

    if !assignment.context.try(:vericite_enabled?)
      update_params.delete("vericite_enabled")
      update_params.delete("vericite_settings")
    end

    # use Assignment#turnitin_settings= to normalize, but then assign back to
    # hash so that it is written with update_params
    if update_params.key?("turnitin_settings")
      assignment.turnitin_settings = turnitin_settings_hash(update_params)
    end

    # use Assignment#vericite_settings= to normalize, but then assign back to
    # hash so that it is written with update_params
    if update_params.key?("vericite_settings")
      assignment.vericite_settings = vericite_settings_hash(update_params)
    end

    # TODO: allow rubric creation

    if update_params.key?("description")
      update_params["description"] = process_incoming_html_content(update_params["description"])
    end

    if assignment_params.key? "published"
      published = value_to_boolean(assignment_params['published'])
      assignment.workflow_state = published ? 'published' : 'unpublished'
    end

    if assignment_params.key? "only_visible_to_overrides"
      assignment.only_visible_to_overrides = value_to_boolean(assignment_params['only_visible_to_overrides'])
    end

    post_to_sis = assignment_params.key?('post_to_sis') ? value_to_boolean(assignment_params['post_to_sis']) : nil
    if !post_to_sis.nil?
      assignment.post_to_sis = post_to_sis
    elsif assignment.new_record? && !Assignment.sis_grade_export_enabled?(context)
      # set the default setting if it is not included.
      assignment.post_to_sis = context.account.sis_default_grade_export[:value]
    end

    if assignment_params.key?('moderated_grading')
      assignment.moderated_grading = value_to_boolean(assignment_params['moderated_grading'])
    end

    grader_changes = final_grader_changes(assignment, context, assignment_params)
    assignment.final_grader_id = grader_changes.grader_id if grader_changes.grader_changed?

    if assignment_params.key?('anonymous_grading') && assignment.course.feature_enabled?(:anonymous_marking)
      assignment.anonymous_grading = value_to_boolean(assignment_params['anonymous_grading'])
    end

    if assignment_params.key?('duplicated_successfully')
      if value_to_boolean(assignment_params[:duplicated_successfully])
        assignment.finish_duplicating
      else
        assignment.fail_to_duplicate
      end
    end

    apply_report_visibility_options!(assignment_params, assignment)

    assignment.updating_user = user
    assignment.attributes = update_params
    assignment.infer_times

    assignment
  end

  def turnitin_settings_hash(assignment_params)
    turnitin_settings = assignment_params.delete("turnitin_settings").permit(*API_ALLOWED_TURNITIN_SETTINGS)
    turnitin_settings['exclude_type'] = case turnitin_settings['exclude_small_matches_type']
      when nil; '0'
      when 'words'; '1'
      when 'percent'; '2'
    end
    turnitin_settings['exclude_value'] = turnitin_settings['exclude_small_matches_value']
    turnitin_settings.to_unsafe_h
  end

  def vericite_settings_hash(assignment_params)
    vericite_settings = assignment_params.delete("vericite_settings").permit(*API_ALLOWED_VERICITE_SETTINGS)
    vericite_settings.to_unsafe_h
  end

  def submissions_hash(include_params, assignments, submissions_for_user=nil)
    return {} unless include_params.include?('submission')
    has_observed_users = include_params.include?("observed_users")

    subs_list = if submissions_for_user
      assignment_ids = assignments.map(&:id).to_set
      submissions_for_user.select{ |s|
        assignment_ids.include?(s.assignment_id)
      }
    else
      users = current_user_and_observed(include_observed: has_observed_users)
      @context.submissions.
        where(:assignment_id => assignments.map(&:id)).
        for_user(users)
    end

    if has_observed_users
      # assignment id -> array. even if <2 results for a given
      # assignment, we want to consistently return an array when
      # include[]=observed_users was supplied
      hash = Hash.new { |h,k| h[k] = [] }
      subs_list.each { |s| hash[s.assignment_id] << s }
    else
      # assignment id -> specific submission. never return an array when
      # include[]=observed_users was _not_ supplied
      hash = Hash[subs_list.map{|s| [s.assignment_id, s]}]
    end
    hash
  end

  # Returns an array containing the current user.  If
  # include_observed: true is passed also returns any observees if
  # the current user is an observer
  def current_user_and_observed(opts = { include_observed: false })
    user_and_observees = Array(@current_user)
    if opts[:include_observed] && @context_enrollment && @context_enrollment.observer?
      user_and_observees.concat(ObserverEnrollment.observed_students(@context, @current_user).keys)
    end
    user_and_observees
  end

  private

  def final_grader_changes(assignment, course, assignment_params)
    no_changes = OpenStruct.new(grader_changed?: false)
    return no_changes unless assignment.moderated_grading && assignment_params.key?('final_grader_id')
    return no_changes unless course.root_account.feature_enabled?(:anonymous_moderated_marking)

    final_grader_id = assignment_params.fetch("final_grader_id")
    return OpenStruct.new(grader_changed?: true, grader_id: nil) if final_grader_id.blank?

    OpenStruct.new(grader_changed?: true, grader_id: final_grader_id)
  end

  def apply_report_visibility_options!(assignment_params, assignment)
    if assignment_params[:report_visibility].present?
      settings = assignment.turnitin_settings
      settings[:originality_report_visibility] = assignment_params[:report_visibility]
      assignment.turnitin_settings = settings
    end
  end


  def prepare_assignment_create_or_update(assignment, assignment_params, user, context = assignment.context)
    raise "needs strong params" unless assignment_params.is_a?(ActionController::Parameters)

    unless assignment.new_record?
      old_assignment = assignment.clone
      old_assignment.id = assignment.id
    end

    if assignment_params[:secure_params] && assignment.new_record?
      secure_params = Canvas::Security.decode_jwt assignment_params[:secure_params]
      assignment.lti_context_id = secure_params[:lti_assignment_id]
    end

    apply_external_tool_settings(assignment, assignment_params)
    overrides = pull_overrides_from_params(assignment_params)
    invalid = { valid: false }
    return invalid unless update_parameters_valid?(assignment, assignment_params, overrides)

    updated_assignment = update_from_params(assignment, assignment_params, user, context)
    return invalid unless assignment_editable_fields_valid?(updated_assignment, user)
    return invalid unless assignment_final_grader_valid?(updated_assignment, context)

    {
      assignment: assignment,
      overrides: overrides,
      old_assignment: old_assignment,
      notify_of_update: assignment_params[:notify_of_update],
      valid: true
    }
  end

  def create_api_assignment_with_overrides(prepared_update, user)
    assignment = prepared_update[:assignment]
    overrides = prepared_update[:overrides]

    return :forbidden unless grading_periods_allow_assignment_overrides_batch_create?(assignment, overrides)

    assignment.transaction do
      assignment.validate_overrides_for_sis(overrides)
      assignment.save_without_broadcasting!
      batch_update_assignment_overrides(assignment, overrides, user)
    end

    assignment.do_notifications!(prepared_update[:old_assignment], prepared_update[:notify_of_update])
    return :created
  end

  def update_api_assignment_with_overrides(prepared_update, user)
    assignment = prepared_update[:assignment]
    overrides = prepared_update[:overrides]

    return :forbidden if overrides.any? && assignment.is_child_content? && (assignment.editing_restricted?(:due_dates) || assignment.editing_restricted?(:availability_dates))

    prepared_batch = prepare_assignment_overrides_for_batch_update(assignment, overrides, user)

    return :forbidden unless grading_periods_allow_assignment_overrides_batch_update?(assignment, prepared_batch)

    assignment.transaction do
      assignment.validate_overrides_for_sis(prepared_batch)
      assignment.save_without_broadcasting!
      perform_batch_update_assignment_overrides(assignment, prepared_batch)
    end

    assignment.do_notifications!(prepared_update[:old_assignment], prepared_update[:notify_of_update])
    :ok
  end

  def pull_overrides_from_params(assignment_params)
    overrides = deserialize_overrides(assignment_params[:assignment_overrides])
    overrides = [] if !overrides && assignment_params.key?(:assignment_overrides)
    assignment_params.delete(:assignment_overrides)
    overrides
  end

  def update_parameters_valid?(assignment, assignment_params, overrides)
    return false unless !overrides || overrides.is_a?(Array)
    return false unless assignment_group_id_valid?(assignment, assignment_params)
    return false unless assignment_dates_valid?(assignment, assignment_params)
    return false unless submission_types_valid?(assignment, assignment_params)
    true
  end

  def apply_external_tool_settings(assignment, assignment_params)
    if plagiarism_capable?(assignment_params)
      tool = assignment_configuration_tool(assignment_params)
      assignment.tool_settings_tool = tool
    end
  end

  def assignment_configuration_tool(assignment_params)
    tool_id = assignment_params['similarityDetectionTool'].split('_').last.to_i
    tool = nil
    if assignment_params['configuration_tool_type'] == 'ContextExternalTool'
      tool = ContextExternalTool.find_external_tool_by_id(tool_id, context)
    elsif assignment_params['configuration_tool_type'] == 'Lti::MessageHandler'
      mh = Lti::MessageHandler.find(tool_id)
      mh_context = mh.resource_handler.tool_proxy.context
      tool = mh if mh_context == @context || @context.account_chain.include?(mh_context)
    end
    tool
  end

  def plagiarism_capable?(assignment_params)
    assignment_params['submission_type'] == 'online' &&
      assignment_params['submission_types'].present? &&
      (assignment_params['submission_types'].include?('online_upload') ||
      assignment_params['submission_types'].include?('online_text_entry'))
  end

  def submissions_download_url(context, assignment)
    if assignment.quiz?
      course_quiz_quiz_submissions_url(context, assignment.quiz, zip: 1)
    else
      course_assignment_submissions_url(context, assignment, zip: 1)
    end
  end

  def allowed_assignment_input_fields
    API_ALLOWED_ASSIGNMENT_INPUT_FIELDS + [
      'turnitin_settings' => strong_anything,
      'vericite_settings' => strong_anything,
      'allowed_extensions' => strong_anything,
      'integration_data' => strong_anything,
      'external_tool_tag_attributes' => strong_anything,
      'submission_types' => strong_anything
    ]
  end
end
