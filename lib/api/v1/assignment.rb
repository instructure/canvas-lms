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

module Api::V1::Assignment
  include Api::V1::Json
  include ApplicationHelper
  include Api::V1::ExternalTools::UrlHelpers
  include Api::V1::Locked
  include Api::V1::AssignmentOverride
  include SubmittablesGradingPeriodProtection
  include Api::V1::PlannerOverride

  ALL_DATES_LIMIT = 25

  PRELOADS = %i[external_tool_tag
                duplicate_of
                rubric
                rubric_association].freeze

  API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS = {
    only: %w[
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
      graders_anonymous_to_graders
      grader_comments_visible_to_graders
      grader_names_visible_to_final_grader
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
      hide_in_gradebook
      omit_from_final_grade
      anonymous_instructor_annotations
      anonymous_grading
      allowed_attempts
      annotatable_attachment_id
    ]
  }.freeze

  API_ASSIGNMENT_NEW_RECORD_FIELDS = {
    only: %w[
      graders_anonymous_to_graders
      grader_comments_visible_to_graders
      grader_names_visible_to_final_grader
      points_possible
      due_at
      assignment_group_id
      post_to_sis
      annotatable_attachment_id
    ]
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
    graders_anonymous_to_graders
    grader_comments_visible_to_graders
    grader_names_visible_to_final_grader
  ].freeze

  def assignments_json(assignments, user, session, opts = {})
    # check if all assignments being serialized belong to the same course
    contexts = assignments.map { |a| [a.context_id, a.context_type] }.uniq
    if contexts.length == 1
      # if so, calculate their effective due dates in one go, rather than individually
      opts[:exclude_response_fields] ||= []
      opts[:exclude_response_fields] << "in_closed_grading_period"
      due_dates = EffectiveDueDates.for_course(assignments.first.context, assignments)
    end

    assignments.map do |assignment|
      json = assignment_json(assignment, user, session, opts)
      unless json.key? "in_closed_grading_period"
        json["in_closed_grading_period"] = due_dates.in_closed_grading_period?(assignment)
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
      include_planner_override: false,
      include_can_edit: false,
      include_webhook_info: false,
      include_assessment_requests: false
    )

    if opts[:override_dates] && !assignment.new_record?
      assignment = assignment.overridden_for(user)
    end

    fields = assignment.new_record? ? API_ASSIGNMENT_NEW_RECORD_FIELDS : API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS
    if opts[:exclude_response_fields].include?("description")
      fields_copy = fields[:only].dup
      fields_copy.delete("description")
      fields = { only: fields_copy }
    end

    hash = api_json(assignment, user, session, fields)

    description = api_user_content(hash["description"],
                                   @context || assignment.context,
                                   user,
                                   opts[:preloaded_user_content_attachments] || {})

    hash["secure_params"] = assignment.secure_params(include_description: description.present?) if assignment.has_attribute?(:lti_context_id)
    hash["lti_context_id"] = assignment.lti_context_id if assignment.has_attribute?(:lti_context_id)
    hash["course_id"] = assignment.context_id
    hash["name"] = assignment.title
    hash["submission_types"] = assignment.submission_types_array
    hash["has_submitted_submissions"] = assignment.has_submitted_submissions?
    hash["due_date_required"] = assignment.due_date_required?
    hash["max_name_length"] = assignment.max_name_length
    hash["allowed_attempts"] = -1 if assignment.allowed_attempts.nil?
    paced_course = assignment.course.account.feature_enabled?(:course_paces) && Course.find_by(id: assignment.context_id)&.enable_course_paces?
    hash["in_paced_course"] = paced_course if paced_course

    unless opts[:exclude_response_fields].include?("in_closed_grading_period")
      hash["in_closed_grading_period"] = assignment.in_closed_grading_period?
    end

    hash["grades_published"] = assignment.grades_published? if opts[:include_grades_published]
    hash["graded_submissions_exist"] = assignment.graded_submissions_exist?

    if opts[:include_checkpoints] && assignment.root_account.feature_enabled?(:discussion_checkpoints)
      hash["has_sub_assignments"] = assignment.has_sub_assignments?
      hash["checkpoints"] = assignment.sub_assignments.map { |sub_assignment| Checkpoint.new(sub_assignment, user).as_json }
    end

    if opts[:overrides].present?
      hash["overrides"] = assignment_overrides_json(opts[:overrides], user)
    elsif opts[:include_overrides]
      hash["overrides"] = assignment_overrides_json(assignment.assignment_overrides.select(&:active?), user)
    end

    unless assignment.user_submitted.nil?
      hash["user_submitted"] = assignment.user_submitted
    end

    hash["omit_from_final_grade"] = assignment.omit_from_final_grade?

    hash["hide_in_gradebook"] = assignment.hide_in_gradebook?

    if assignment.context&.turnitin_enabled?
      hash["turnitin_enabled"] = assignment.turnitin_enabled
      hash["turnitin_settings"] = turnitin_settings_json(assignment)
    end

    if assignment.context&.vericite_enabled?
      hash["vericite_enabled"] = assignment.vericite_enabled
      hash["vericite_settings"] = vericite_settings_json(assignment)
    end

    if PluginSetting.settings_for_plugin(:assignment_freezer)
      hash["freeze_on_copy"] = assignment.freeze_on_copy?
      hash["frozen"] = assignment.frozen_for_user?(user)
      hash["frozen_attributes"] = assignment.frozen_attributes_for_user(user)
    end

    hash["is_quiz_assignment"] = assignment.quiz? && assignment.quiz.assignment?
    hash["can_duplicate"] = assignment.can_duplicate?
    hash["original_course_id"] = assignment.duplicate_of&.course&.id
    hash["original_assignment_id"] = assignment.duplicate_of&.id
    hash["original_lti_resource_link_id"] = assignment.duplicate_of&.lti_resource_link_id
    hash["original_assignment_name"] = assignment.duplicate_of&.name
    hash["original_quiz_id"] = assignment.migrate_from_id
    hash["workflow_state"] = assignment.workflow_state
    hash["important_dates"] = assignment.important_dates

    if assignment.quiz_lti?
      hash["is_quiz_lti_assignment"] = true
      hash["frozen_attributes"] ||= []
      hash["frozen_attributes"] << "submission_types"
    end

    if assignment.external_tool? && assignment.external_tool_tag.present?
      hash["external_tool_tag_attributes"] = { "url" => assignment.external_tool_tag.url }
    end

    return hash if assignment.new_record?

    # use already generated hash['description'] because it is filtered by
    # Assignment#filter_attributes_for_user when the assignment is locked
    unless opts[:exclude_response_fields].include?("description")
      hash["description"] = description
    end

    can_manage = assignment.context.grants_any_right?(user, :manage, :manage_grades, :manage_assignments, :manage_assignments_edit)
    hash["muted"] = assignment.muted?
    hash["html_url"] = course_assignment_url(assignment.context_id, assignment)
    if can_manage
      hash["has_overrides"] = assignment.has_overrides?
    end

    if assignment.external_tool? && assignment.external_tool_tag.present?
      external_tool_tag = assignment.external_tool_tag
      tool_attributes = {
        "url" => external_tool_tag.url,
        "new_tab" => external_tool_tag.new_tab,
        "resource_link_id" => assignment.lti_resource_link_id,
        "external_data" => external_tool_tag.external_data
      }
      tool_attributes.merge!(external_tool_tag.attributes.slice("content_type", "content_id")) if external_tool_tag.content_id
      tool_attributes["custom_params"] = assignment.primary_resource_link&.custom
      hash["external_tool_tag_attributes"] = tool_attributes
      hash["url"] = sessionless_launch_url(@context,
                                           launch_type: "assessment",
                                           assignment_id: assignment.id)
    end

    # the webhook_info is for internal use only and is not intended to be used with
    # multiple assignments, it will create difficult to fix n+1s
    if opts[:include_webhook_info]
      hash["webhook_info"] = assignment.assignment_configuration_tool_lookups[0]&.webhook_info
    end

    if assignment.automatic_peer_reviews? && assignment.peer_reviews?
      peer_review_params = assignment.slice(
        :peer_review_count,
        :peer_reviews_assign_at,
        :intra_group_peer_reviews
      )
      hash.merge!(peer_review_params)
    end

    include_needs_grading_count = opts[:exclude_response_fields].exclude?("needs_grading_count")
    if include_needs_grading_count && assignment.context.grants_right?(user, :manage_grades)
      query = Assignments::NeedsGradingCountQuery.new(assignment, user, opts[:needs_grading_course_proxy])
      if opts[:needs_grading_count_by_section]
        hash["needs_grading_count_by_section"] = query.count_by_section
      end
      hash["needs_grading_count"] = query.count
    end

    if assignment.context.grants_any_right?(user, :read_sis, :manage_sis)
      hash["sis_assignment_id"] = assignment.sis_source_id
      hash["integration_id"] = assignment.integration_id
      hash["integration_data"] = assignment.integration_data
    end

    if assignment.quiz?
      hash["quiz_id"] = assignment.quiz.id
      hash["anonymous_submissions"] = !!assignment.quiz.anonymous_submissions
    end

    if assignment.allowed_extensions.present?
      hash["allowed_extensions"] = assignment.allowed_extensions
    end

    if opts[:include_assessment_requests]
      if user.assigned_assessments.any?
        submission = assignment.submission_for_student(user)
        assessment_requests = user.assigned_assessments.where(assessor_asset: submission).preload(:asset, assessor_asset: :assignment)
        hash["assessment_requests"] = assessment_requests.map { |assessment_request| assessment_request_json(assessment_request, anonymous_peer_reviews: assignment.anonymous_peer_reviews?) }
      else
        hash["assessment_requests"] = []
      end
    end

    unless opts[:exclude_response_fields].include?("rubric")
      if assignment.active_rubric_association?
        hash["use_rubric_for_grading"] = !!assignment.rubric_association.use_for_grading
        if assignment.rubric_association.rubric
          hash["free_form_criterion_comments"] = !!assignment.rubric_association.rubric.free_form_criterion_comments
        end
      end

      if assignment.active_rubric_association?
        rubric = assignment.rubric
        hash["rubric"] = rubric.data.map do |row|
          row_hash = row.slice(:id, :points, :description, :long_description, :ignore_for_scoring)
          row_hash["criterion_use_range"] = row[:criterion_use_range] || false
          row_hash["ratings"] = row[:ratings].map do |c|
            rating_hash = c.slice(:id, :points, :description, :long_description)
            rating_hash["long_description"] = c[:long_description] || ""
            rating_hash
          end
          if row[:learning_outcome_id] &&
             (outcome = LearningOutcome.where(id: row[:learning_outcome_id]).first)
            row_hash["outcome_id"] = outcome.id
            row_hash["vendor_guid"] = outcome.vendor_guid
          end
          row_hash
        end
        hash["rubric_settings"] = {
          "id" => rubric.id,
          "title" => rubric.title,
          "points_possible" => rubric.points_possible,
          "free_form_criterion_comments" => !!rubric.free_form_criterion_comments,
          "hide_score_total" => !!assignment.rubric_association.hide_score_total,
          "hide_points" => !!assignment.rubric_association.hide_points
        }
      end
    end

    if opts[:include_discussion_topic] && assignment.discussion_topic?
      extend Api::V1::DiscussionTopics
      hash["discussion_topic"] = discussion_topic_api_json(
        assignment.discussion_topic,
        assignment.discussion_topic.context,
        user,
        session,
        include_assignment: false,
        exclude_messages: opts[:exclude_response_fields].include?("description")
      )
    end

    if opts[:include_all_dates] && assignment.assignment_overrides
      override_count = if assignment.assignment_overrides.loaded?
                         assignment.assignment_overrides.count(&:active?)
                       else
                         assignment.assignment_overrides.active.count
                       end
      if override_count < ALL_DATES_LIMIT
        hash["all_dates"] = assignment.dates_hash_visible_to(user)
      else
        hash["all_dates_count"] = override_count
      end
    end

    if opts[:include_can_edit]
      can_edit_assignment = assignment.user_can_update?(user, session)
      hash["can_edit"] = can_edit_assignment
      hash["all_dates"]&.each do |date_hash|
        in_closed_grading_period = date_in_closed_grading_period?(date_hash["due_at"])
        date_hash["in_closed_grading_period"] = in_closed_grading_period
        date_hash["can_edit"] = can_edit_assignment && (!in_closed_grading_period || !constrained_by_grading_periods?)
      end
    end

    if opts[:include_module_ids]
      modulable = case assignment.submission_types
                  when "online_quiz" then assignment.quiz
                  when "discussion_topic" then assignment.discussion_topic
                  else assignment
                  end

      if modulable
        hash["module_ids"] = modulable.context_module_tags.map(&:context_module_id)
        hash["module_positions"] = modulable.context_module_tags.map(&:position)
      end
    end

    hash["published"] = assignment.published?
    if can_manage
      hash["unpublishable"] = assignment.can_unpublish?
    end

    hash["only_visible_to_overrides"] = value_to_boolean(assignment.only_visible_to_overrides)
    hash["visible_to_everyone"] = assignment.visible_to_everyone

    if opts[:include_visibility]
      hash["assignment_visibility"] = (opts[:assignment_visibilities] || assignment.students_with_visibility.pluck(:id).uniq).map(&:to_s)
    end

    if (submission = opts[:submission])
      should_show_statistics = opts[:include_score_statistics] && assignment.can_view_score_statistics?(user)

      if submission.is_a?(Array)
        ActiveRecord::Associations.preload(submission, :quiz_submission) if assignment.quiz?
        hash["submission"] = submission.map { |s| submission_json(s, assignment, user, session, assignment.context, params[:include], params) }
        should_show_statistics &&= submission.any? do |s|
          s.assignment = assignment # Avoid extra query in submission.hide_grade_from_student? to get assignment
          s.eligible_for_showing_score_statistics?
        end
      else
        hash["submission"] = submission_json(submission, assignment, user, session, assignment.context, params[:include], params)
        submission.assignment = assignment # Avoid extra query in submission.hide_grade_from_student? to get assignment
        should_show_statistics &&= submission.eligible_for_showing_score_statistics?
      end

      if should_show_statistics && (stats = assignment&.score_statistic)
        hash["score_statistics"] = {
          "min" => stats.minimum.to_f.round(1),
          "max" => stats.maximum.to_f.round(1),
          "mean" => stats.mean.to_f.round(1)
        }
        if stats.median.nil?
          # We must be serving an old score statistics, go update in the background to ensure it exists next time
          ScoreStatisticsGenerator.update_score_statistics_in_singleton(@context)
        elsif Account.site_admin.feature_enabled?(:enhanced_grade_statistics)
          hash["score_statistics"]["upper_q"] = stats.upper_q.to_f.round(1)
          hash["score_statistics"]["median"] = stats.median.to_f.round(1)
          hash["score_statistics"]["lower_q"] = stats.lower_q.to_f.round(1)
        end
      end
    end

    if opts[:bucket]
      hash["bucket"] = opts[:bucket]
    end

    locked_json(hash, assignment, user, "assignment")

    if assignment.context.present?
      hash["submissions_download_url"] = submissions_download_url(assignment.context, assignment)
    end

    if opts[:master_course_status]
      hash.merge!(assignment.master_course_api_restriction_data(opts[:master_course_status]))
    end

    if opts[:include_planner_override]
      override = assignment.planner_override_for(user)
      hash["planner_override"] = planner_override_json(override, user, session)
    end

    hash["post_manually"] = assignment.post_manually?
    hash["anonymous_grading"] = value_to_boolean(assignment.anonymous_grading)
    hash["anonymize_students"] = assignment.anonymize_students?

    hash["require_lockdown_browser"] = assignment.settings&.dig("lockdown_browser", "require_lockdown_browser") || false

    if opts[:include_can_submit] && !assignment.quiz? && !submission.is_a?(Array)
      hash["can_submit"] = assignment.expects_submission? &&
                           !assignment.locked_for?(user) &&
                           assignment.rights_status(user, :submit)[:submit] &&
                           (submission.nil? || submission.attempts_left.nil? || submission.attempts_left > 0)
    end

    if opts[:include_ab_guid]
      hash["ab_guid"] = assignment.ab_guid.presence || assignment.ab_guid_through_rubric
    end

    hash["restrict_quantitative_data"] = assignment.restrict_quantitative_data?(user, true) || false

    if opts[:migrated_urls_content_migration_id]
      hash["migrated_urls_content_migration_id"] = opts[:migrated_urls_content_migration_id]
    end

    hash
  end

  def turnitin_settings_json(assignment)
    settings = assignment.turnitin_settings.with_indifferent_access
    %i[s_paper_check internet_check journal_check exclude_biblio exclude_quoted submit_papers_to].each do |key|
      settings[key] = value_to_boolean(settings[key])
    end

    ex_type = settings.delete(:exclude_type)
    settings[:exclude_small_matches_type] = case ex_type
                                            when "0" then nil
                                            when "1" then "words"
                                            when "2" then "percent"
                                            end

    ex_value = settings.delete(:exclude_value)
    settings[:exclude_small_matches_value] = ex_value.present? ? ex_value.to_i : nil

    settings.slice(*API_ALLOWED_TURNITIN_SETTINGS)
  end

  def vericite_settings_json(assignment)
    settings = assignment.vericite_settings.with_indifferent_access
    %i[exclude_quoted exclude_self_plag store_in_index].each do |key|
      settings[key] = value_to_boolean(settings[key])
    end

    settings.slice(*API_ALLOWED_VERICITE_SETTINGS)
  end

  API_ALLOWED_ASSIGNMENT_INPUT_FIELDS = %w[
    name
    description
    position
    points_possible
    graders_anonymous_to_graders
    grader_comments_visible_to_graders
    grader_names_visible_to_final_grader
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
    sis_assignment_id
    integration_id
    hide_in_gradebook
    omit_from_final_grade
    anonymous_instructor_annotations
    allowed_attempts
    important_dates
  ].freeze

  API_ALLOWED_TURNITIN_SETTINGS = %w[
    originality_report_visibility
    s_paper_check
    internet_check
    journal_check
    exclude_biblio
    exclude_quoted
    exclude_small_matches_type
    exclude_small_matches_value
    submit_papers_to
  ].freeze

  API_ALLOWED_VERICITE_SETTINGS = %w[
    originality_report_visibility
    exclude_quoted
    exclude_self_plag
    store_in_index
  ].freeze

  def create_api_assignment(assignment, assignment_params, user, context = assignment.context, calculate_grades: nil)
    return :forbidden unless grading_periods_allow_submittable_create?(assignment, assignment_params)

    prepared_create = prepare_assignment_create_or_update(assignment, assignment_params, user, context)
    return false unless prepared_create[:valid]

    response = :created

    Assignment.suspend_due_date_caching do
      assignment.quiz_lti! if assignment_params.key?(:quiz_lti) || assignment&.quiz_lti?

      response = if prepared_create[:overrides].present?
                   create_api_assignment_with_overrides(prepared_create, user)
                 else
                   prepared_create[:assignment].save!
                   :created
                 end
    end

    calc_grades = calculate_grades ? value_to_boolean(calculate_grades) : true
    SubmissionLifecycleManager.recompute(prepared_create[:assignment], update_grades: calc_grades, executing_user: user)
    response
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_api_assignment(assignment, assignment_params, user, context = assignment.context, opts = {})
    return :forbidden unless grading_periods_allow_submittable_update?(assignment, assignment_params)

    # Trying to change the "everyone" due date when the assignment is restricted to a specific section
    # creates an "everyone else" section
    prepared_update = prepare_assignment_create_or_update(assignment, assignment_params, user, context)
    return false unless prepared_update[:valid]

    if !(assignment_params["due_at"]).nil? && assignment["only_visible_to_overrides"]
      assignment["only_visible_to_overrides"] = false
    end

    cached_due_dates_changed = prepared_update[:assignment].update_cached_due_dates?
    response = :ok

    Assignment.suspend_due_date_caching do
      response = if prepared_update[:overrides]
                   update_api_assignment_with_overrides(prepared_update, user)
                 else
                   if assignment_params["force_updated_at"] && !prepared_update[:assignment].changed?
                     prepared_update[:assignment].touch
                   else
                     prepared_update[:assignment].save!
                   end
                   :ok
                 end
    end

    if @overrides_affected.to_i > 0 || cached_due_dates_changed
      assignment.clear_cache_key(:availability)
      assignment.quiz.clear_cache_key(:availability) if assignment.quiz?
      SubmissionLifecycleManager.recompute(prepared_update[:assignment], update_grades: true, executing_user: user)
    end

    # At present, when an assignment linked to a LTI tool is copied, there is no way for canvas
    # to know what resouces the LTI tool needs copied as well. New Quizzes has a problem
    # when an assignment linked to a New Quiz is copied, none of the content referenced in the RCE
    # html is moved to the destination course. This code block gives New Quizzes the ability
    # to let canvas know what additional assets need to be copied.
    # Note: this is intended to be a short term solution to resolve an ongoing production issue.
    url = assignment_params["migrated_urls_report_url"]
    if url.present?
      res = CanvasHttp.get(url)
      data = JSON.parse(res.body)

      unless data.empty?
        copy_values = {}
        source_course = nil

        migration_type = "course_copy_importer"
        plugin = Canvas::Plugin.find(migration_type)
        content_migration = context.content_migrations.build(
          user:,
          context:,
          migration_type:,
          initiated_source: :new_quizzes
        )

        data.each_key do |key|
          import_object = Context.find_asset_by_url(key)

          next unless import_object.respond_to?(:context) && import_object.context.is_a?(Course)

          if import_object.is_a?(WikiPage)
            copy_values[:wiki_pages] ||= []
            copy_values[:wiki_pages] << import_object
            source_course ||= import_object.context
          elsif import_object.is_a?(Attachment)
            copy_values[:attachments] ||= []
            copy_values[:attachments] << import_object
            source_course ||= import_object.context
          end
        end

        return response if source_course.nil?

        content_migration.source_course = source_course
        use_global_identifiers = content_migration.use_global_identifiers?

        copy_values.transform_values! do |import_objects|
          import_objects.map do |import_object|
            CC::CCHelper.create_key(import_object, global: use_global_identifiers)
          end
        end

        content_migration.update_migration_settings({
                                                      import_quizzes_next: false,
                                                      source_course_id: source_course.id
                                                    })
        content_migration.workflow_state = "created"
        content_migration.migration_settings[:import_immediately] = false
        content_migration.save

        copy_options = ContentMigration.process_copy_params(copy_values, global_identifiers: use_global_identifiers)
        content_migration.migration_settings[:migration_ids_to_import] ||= {}
        content_migration.migration_settings[:migration_ids_to_import][:copy] = copy_options
        content_migration.copy_options = copy_options
        content_migration.save

        content_migration.shard.activate do
          content_migration.queue_migration(plugin)
        end

        opts[:migrated_urls_content_migration_id] = content_migration.global_id
      end
    end

    response
  rescue ActiveRecord::RecordInvalid => e
    assignment.errors.add("invalid_record", e)
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
    "student_annotation",
    ""
  ].freeze

  def submission_types_valid?(assignment, assignment_params)
    return true if assignment_params["submission_types"].nil?

    assignment_params["submission_types"] = Array(assignment_params["submission_types"])

    if assignment_params["submission_types"].present? &&
       !assignment_params["submission_types"].all? do |s|
         return false if s == "wiki_page" && !context.try(:conditional_release?)

         API_ALLOWED_SUBMISSION_TYPES.include?(s) || (s == "default_external_tool" && assignment.unpublished?)
       end
      assignment.errors.add("assignment[submission_types]",
                            I18n.t("assignments_api.invalid_submission_types",
                                   "Invalid submission types"))
      return false
    end
    true
  end

  # validate that date and times are iso8601
  def assignment_dates_valid?(assignment, assignment_params)
    errors = %w[due_at lock_at unlock_at peer_reviews_assign_at].map do |v|
      next unless assignment_params[v].present? && assignment_params[v] !~ Api::ISO8601_REGEX

      assignment.errors.add("assignment[#{v}]",
                            I18n.t("assignments_api.invalid_date_time",
                                   "Invalid datetime for %{attribute}",
                                   attribute: v))
    end

    errors.compact.empty?
  end

  def assignment_group_id_valid?(assignment, assignment_params)
    ag_id = assignment_params["assignment_group_id"].presence
    # if ag_id is a non-numeric string, ag_id.to_i will == 0
    if ag_id && ag_id.to_i <= 0
      assignment.errors.add("assignment[assignment_group_id]", I18n.t(:not_a_number, "must be a positive number"))
      false
    else
      true
    end
  end

  def assignment_final_grader_valid?(assignment, course)
    return true unless assignment.final_grader_id && assignment.final_grader_id_changed?

    final_grader = course.participating_instructors.find_by(id: assignment.final_grader_id)
    if final_grader.nil?
      assignment.errors.add("final_grader_id", I18n.t("course has no active instructors with this ID"))
      false
    elsif !course.grants_right?(final_grader, :select_final_grade)
      assignment.errors.add("final_grader_id", I18n.t("user does not have permission to select final grade"))
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
    update_params = assignment_params.permit(allowed_assignment_input_fields(assignment))

    if update_params.key?("peer_reviews_assign_at")
      update_params["peer_reviews_due_at"] = update_params["peer_reviews_assign_at"]
      update_params.delete("peer_reviews_assign_at")
    end

    if update_params.key?("anonymous_peer_reviews") &&
       Canvas::Plugin.value_to_boolean(update_params["anonymous_peer_reviews"]) != assignment.anonymous_peer_reviews
      ::AssessmentRequest.where(asset: assignment.submissions).update_all(updated_at: Time.now.utc)
    end

    if update_params["submission_types"].is_a? Array
      update_params["submission_types"] = update_params["submission_types"].map do |type|
        # TODO: remove. this was temporary backward support for a hotfix
        (type == "online_media_recording") ? "media_recording" : type
      end
      update_params["submission_types"] = update_params["submission_types"].join(",")
    end

    update_params["submission_types"] ||= "not_graded" if update_params["grading_type"] == "not_graded"

    if update_params.key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      assignment.assignment_group = assignment.context.assignment_groups.where(id: ag_id).first
    end

    if update_params.key?("ab_guid")
      assignment.ab_guid.clear
      ab_guids = update_params.delete("ab_guid").presence
      Array(ab_guids).each do |guid|
        assignment.ab_guid << guid if guid.present?
      end
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

    if assignment.context.grants_right?(user, :manage_sis)
      if update_params.key?("sis_assignment_id") && update_params["sis_assignment_id"].blank?
        update_params["sis_assignment_id"] = nil
      end

      data = update_params["integration_data"]
      update_params["integration_data"] = JSON.parse(data) if data.is_a?(String)
    else
      update_params.delete("sis_assignment_id")
      update_params.delete("integration_id")
      update_params.delete("integration_data")
    end

    # do some fiddling with due_at for fancy midnight and add to update_params
    if update_params["due_at"].present? && update_params["due_at"] =~ Api::ISO8601_REGEX
      update_params["time_zone_edited"] = Time.zone.name
    end

    unless assignment.context.try(:turnitin_enabled?)
      update_params.delete("turnitin_enabled")
      update_params.delete("turnitin_settings")
    end

    unless assignment.context.try(:vericite_enabled?)
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
      published = value_to_boolean(assignment_params["published"])
      assignment.workflow_state = published ? "published" : "unpublished"
    end

    if assignment_params.key? "only_visible_to_overrides"
      assignment.only_visible_to_overrides = value_to_boolean(assignment_params["only_visible_to_overrides"])
    end

    post_to_sis = assignment_params.key?("post_to_sis") ? value_to_boolean(assignment_params["post_to_sis"]) : nil
    if !post_to_sis.nil?
      assignment.post_to_sis = post_to_sis
    elsif assignment.new_record? && !Assignment.sis_grade_export_enabled?(context)
      # set the default setting if it is not included.
      assignment.post_to_sis = context.account.sis_default_grade_export[:value]
    end

    if assignment_params.key?("moderated_grading")
      assignment.moderated_grading = value_to_boolean(assignment_params["moderated_grading"])
    end

    grader_changes = final_grader_changes(assignment, assignment_params)
    assignment.final_grader_id = grader_changes.grader_id if grader_changes.grader_changed?

    if assignment_params.key?("anonymous_grading") && assignment.course.feature_enabled?(:anonymous_marking)
      assignment.anonymous_grading = value_to_boolean(assignment_params["anonymous_grading"])
    end

    if assignment_params.key?("duplicated_successfully")
      if value_to_boolean(assignment_params[:duplicated_successfully])
        assignment.finish_duplicating
      else
        assignment.fail_to_duplicate
      end
    end

    if assignment_params.key?("alignment_cloned_successfully") && assignment.root_account.feature_enabled?(:course_copy_alignments)
      if value_to_boolean(assignment_params[:alignment_cloned_successfully])
        assignment.finish_alignment_cloning
      else
        assignment.fail_to_clone_alignment
      end
    end

    if assignment_params.key?("migrated_successfully")
      if value_to_boolean(assignment_params[:migrated_successfully])
        assignment.finish_migrating
      else
        assignment.fail_to_migrate
      end
    end

    if assignment_params.key?("cc_imported_successfully")
      if value_to_boolean(assignment_params[:cc_imported_successfully])
        assignment.finish_importing
      else
        assignment.fail_to_import
      end
    end

    if update_params.key?(:submission_types)
      if update_params[:submission_types].include?("student_annotation")
        if assignment_params.key?(:annotatable_attachment_id)
          attachment = Attachment.find(assignment_params.delete(:annotatable_attachment_id))
          assignment.annotatable_attachment = attachment.copy_to_student_annotation_documents_folder(assignment.course)
        end
      else
        assignment.annotatable_attachment_id = nil
      end
    end

    if update_lockdown_browser?(assignment_params)
      update_lockdown_browser_settings(assignment, assignment_params)
    end

    if update_params["allowed_attempts"].to_i == -1 && assignment.allowed_attempts.nil?
      # if allowed_attempts is nil, the api json will replace it with -1 for some reason
      # so if it's included in the json to update, we should just ignore it
      update_params.delete("allowed_attempts")
    end

    if update_params.key?("important_dates")
      update_params["important_dates"] = value_to_boolean(update_params["important_dates"])
    end

    apply_report_visibility_options!(assignment_params, assignment)

    assignment.updating_user = user
    assignment.attributes = update_params
    assignment.infer_times

    assignment
  end

  def turnitin_settings_hash(assignment_params)
    turnitin_settings = assignment_params.delete("turnitin_settings").permit(*API_ALLOWED_TURNITIN_SETTINGS)
    turnitin_settings["exclude_type"] = case turnitin_settings["exclude_small_matches_type"]
                                        when nil then "0"
                                        when "words" then "1"
                                        when "percent" then "2"
                                        end
    turnitin_settings["exclude_value"] = turnitin_settings["exclude_small_matches_value"]
    turnitin_settings.to_unsafe_h
  end

  def vericite_settings_hash(assignment_params)
    vericite_settings = assignment_params.delete("vericite_settings").permit(*API_ALLOWED_VERICITE_SETTINGS)
    vericite_settings.to_unsafe_h
  end

  def submissions_hash(include_params, assignments)
    return {} unless include_params.include?("submission")

    has_observed_users = include_params.include?("observed_users")
    users = current_user_and_observed(include_observed: has_observed_users)
    subs_list = @context.submissions
                        .where(assignment_id: assignments.map(&:id))
                        .for_user(users)

    if has_observed_users
      # assignment id -> array. even if <2 results for a given
      # assignment, we want to consistently return an array when
      # include[]=observed_users was supplied
      hash = Hash.new { |h, k| h[k] = [] }
      subs_list.each { |s| hash[s.assignment_id] << s }
    else
      # assignment id -> specific submission. never return an array when
      # include[]=observed_users was _not_ supplied
      hash = subs_list.index_by(&:assignment_id)
    end
    hash
  end

  # Returns an array containing the current user.  If
  # include_observed: true is passed also returns any observees if
  # the current user is an observer
  def current_user_and_observed(opts = { include_observed: false })
    user_and_observees = Array(@current_user)
    if opts[:include_observed] && (@context_enrollment&.observer? || @current_user.enrollments.of_observer_type.active.where(course: @context).exists?)
      user_and_observees.concat(ObserverEnrollment.observed_students(@context, @current_user).keys)
    end
    user_and_observees
  end

  private

  def final_grader_changes(assignment, assignment_params)
    no_changes = OpenStruct.new(grader_changed?: false)
    return no_changes unless assignment.moderated_grading && assignment_params.key?("final_grader_id")

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

    if assignment_params[:points_possible].blank? &&
       (assignment.new_record? || assignment_params.key?(:points_possible)) # only change if they're deliberately updating to blank
      assignment_params[:points_possible] = 0
    end

    unless assignment.new_record?
      assignment.restore_attributes
      old_assignment = assignment.clone
      old_assignment.id = assignment.id
    end

    invalid = { valid: false }

    if assignment_params[:secure_params] && assignment.new_record?
      secure_params = Canvas::Security.decode_jwt assignment_params[:secure_params]
      if Assignment.find_by(lti_context_id: secure_params[:lti_assignment_id])
        assignment.errors.add("assignment[lti_context_id]", I18n.t("lti_context_id should be unique"), attribute: "lti_context_id")
        return invalid
      end
      assignment.lti_context_id = secure_params[:lti_assignment_id]
    end

    apply_external_tool_settings(assignment, assignment_params)
    overrides = pull_overrides_from_params(assignment_params)

    if assignment_params[:allowed_extensions].present? && assignment_params[:allowed_extensions].length > Assignment.maximum_string_length
      assignment.errors.add("assignment[allowed_extensions]", I18n.t("Value too long, allowed length is %{length}", length: Assignment.maximum_string_length))
      return invalid
    end

    return invalid unless update_parameters_valid?(assignment, assignment_params, user, overrides)

    updated_assignment = update_from_params(assignment, assignment_params, user, context)
    return invalid unless assignment_editable_fields_valid?(updated_assignment, user)
    return invalid unless assignment_final_grader_valid?(updated_assignment, context)

    external_tool_tag_attributes = assignment_params[:external_tool_tag_attributes]
    if external_tool_tag_attributes&.include?(:custom_params)
      custom_params = external_tool_tag_attributes[:custom_params]
      unless custom_params_valid?(custom_params)
        assignment.errors.add(:custom_params, :invalid, message: I18n.t("Invalid custom parameters. Please ensure they match the LTI 1.3 specification."))
        return invalid
      end
      assignment.lti_resource_link_custom_params = custom_params.presence&.to_unsafe_h || {}
    end

    if external_tool_tag_attributes&.include?(:url)
      assignment.lti_resource_link_url = external_tool_tag_attributes[:url]
    end

    if assignment.external_tool?
      assignment.peer_reviews = false
    end

    line_item = assignment_params.dig(:external_tool_tag_attributes, :line_item)
    if line_item.respond_to?(:dig)
      assignment.line_item_resource_id = line_item[:resourceId]
      assignment.line_item_tag = line_item[:tag]
    end

    {
      assignment:,
      overrides:,
      old_assignment:,
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
    :created
  end

  def update_api_assignment_with_overrides(prepared_update, user)
    assignment = prepared_update[:assignment]
    overrides = prepared_update[:overrides]

    return :forbidden if overrides.any? && assignment.is_child_content? && (assignment.editing_restricted?(:due_dates) || assignment.editing_restricted?(:availability_dates))

    prepared_batch = prepare_assignment_overrides_for_batch_update(assignment, overrides, user)

    return :forbidden unless grading_periods_allow_assignment_overrides_batch_update?(assignment, prepared_batch)

    assignment.transaction do
      assignment.validate_overrides_for_sis(prepared_batch)

      # validate_assignment_overrides runs as a save callback, but if the group
      # category is changing, remove overrides for old groups first so we don't
      # fail validation
      assignment.validate_assignment_overrides if assignment.will_save_change_to_group_category_id?
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

  def custom_params_valid?(custom_params)
    custom_params.blank? ||
      (custom_params.respond_to?(:to_unsafe_h) && Lti::DeepLinkingUtil.valid_custom_params?(custom_params.to_unsafe_h))
  end

  def update_parameters_valid?(assignment, assignment_params, user, overrides)
    return false unless !overrides || overrides.is_a?(Array)
    return false unless assignment_group_id_valid?(assignment, assignment_params)
    return false unless assignment_dates_valid?(assignment, assignment_params)
    return false unless submission_types_valid?(assignment, assignment_params)

    if assignment_params[:submission_types]&.include?("student_annotation")
      return false unless assignment_params.key?(:annotatable_attachment_id)

      attachment = Attachment.find_by(id: assignment_params[:annotatable_attachment_id])
      return false unless attachment&.grants_right?(user, :read)
    end

    true
  end

  def apply_external_tool_settings(assignment, assignment_params)
    if plagiarism_capable?(assignment_params)
      tool = assignment_configuration_tool(assignment_params)
      assignment.tool_settings_tool = tool
    elsif assignment.persisted? && clear_tool_settings_tools?(assignment, assignment_params)
      # Destroy subscriptions and tool associations
      assignment.delay_if_production.clear_tool_settings_tools
    end
  end

  def assignment_configuration_tool(assignment_params)
    tool_id = assignment_params["similarityDetectionTool"].split("_").last.to_i
    tool = nil
    case assignment_params["configuration_tool_type"]
    when "ContextExternalTool"
      tool = ContextExternalTool.find_external_tool_by_id(tool_id, context)
    when "Lti::MessageHandler"
      mh = Lti::MessageHandler.find(tool_id)
      mh_context = mh.resource_handler.tool_proxy.context
      tool = mh if mh_context == @context || @context.account_chain.include?(mh_context)
    end
    tool
  end

  def clear_tool_settings_tools?(assignment, assignment_params)
    assignment.assignment_configuration_tool_lookups.present? &&
      assignment_params["submission_types"].present? &&
      (
        assignment.submission_types.split(",").none? { |t| assignment_params["submission_types"].include?(t) } ||
        assignment_params["submission_types"].blank?
      )
  end

  def plagiarism_capable?(assignment_params)
    assignment_params["submission_type"] == "online" &&
      assignment_params["submission_types"].present? &&
      (assignment_params["submission_types"].include?("online_upload") ||
      assignment_params["submission_types"].include?("online_text_entry"))
  end

  def submissions_download_url(context, assignment)
    if assignment.quiz?
      course_quiz_quiz_submissions_url(context, assignment.quiz, zip: 1)
    else
      course_assignment_submissions_url(context, assignment, zip: 1)
    end
  end

  def allowed_assignment_input_fields(assignment)
    should_update_submission_types =
      !assignment.submission_types&.include?("online_quiz") ||
      assignment.submissions.having_submission.empty?

    API_ALLOWED_ASSIGNMENT_INPUT_FIELDS + [
      { "turnitin_settings" => strong_anything },
      { "vericite_settings" => strong_anything },
      { "allowed_extensions" => strong_anything },
      { "integration_data" => strong_anything },
      { "external_tool_tag_attributes" => strong_anything },
      ({ "submission_types" => strong_anything } if should_update_submission_types),
      { "ab_guid" => strong_anything },
    ].compact
  end

  def update_lockdown_browser?(assignment_params)
    %i[
      require_lockdown_browser
      require_lockdown_browser_for_results
      require_lockdown_browser_monitor
      lockdown_browser_monitor_data
      access_code
    ].any? { |key| assignment_params.key?(key) }
  end

  def update_lockdown_browser_settings(assignment, assignment_params)
    settings = assignment.settings || {}
    ldb_settings = settings["lockdown_browser"] || {}

    if assignment_params.key?("require_lockdown_browser")
      ldb_settings[:require_lockdown_browser] = value_to_boolean(assignment_params[:require_lockdown_browser])
    end

    if assignment_params.key?("require_lockdown_browser_for_results")
      ldb_settings[:require_lockdown_browser_for_results] = value_to_boolean(assignment_params[:require_lockdown_browser_for_results])
    end

    if assignment_params.key?("require_lockdown_browser_monitor")
      ldb_settings[:require_lockdown_browser_monitor] = value_to_boolean(assignment_params[:require_lockdown_browser_monitor])
    end

    if assignment_params.key?("lockdown_browser_monitor_data")
      ldb_settings[:lockdown_browser_monitor_data] = assignment_params[:lockdown_browser_monitor_data]
    end

    if assignment_params.key?("access_code")
      ldb_settings[:access_code] = assignment_params[:access_code]
    end

    settings[:lockdown_browser] = ldb_settings
    assignment.settings = settings
  end

  def assessment_request_json(assessment_request, anonymous_peer_reviews: false)
    fields = %i[workflow_state]
    api_json(assessment_request, @current_user, session, only: fields).tap do |json|
      if anonymous_peer_reviews
        json[:anonymous_id] = assessment_request.asset.anonymous_id
      else
        json[:user_id] = assessment_request.user.id
        json[:user_name] = assessment_request.user.name
      end
      json[:available] = assessment_request.available?
    end
  end
end
