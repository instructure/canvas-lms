#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

  API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS = {
    :only => %w(
      id
      position
      description
      points_possible
      grading_type
      due_at
      lock_at
      unlock_at
      assignment_group_id
      peer_reviews
      automatic_peer_reviews
      grade_group_students_individually
      group_category_id
      grading_standard_id
    )
  }

  API_ASSIGNMENT_NEW_RECORD_FIELDS = {
    :only => %w(
      points_possible
      due_at
      assignment_group_id
    )
  }

  def assignments_json(assignments, user, session, opts = {})
    assignments.map{ |assignment| assignment_json(assignment, user, session, opts) }
  end

  def assignment_json(assignment, user, session, opts = {})
    opts.reverse_merge!(
      include_discussion_topic: true,
      include_all_dates: false,
      override_dates: true
    )

    if opts[:override_dates] && !assignment.new_record?
      assignment = assignment.overridden_for(user)
    end
    fields = assignment.new_record? ? API_ASSIGNMENT_NEW_RECORD_FIELDS : API_ALLOWED_ASSIGNMENT_OUTPUT_FIELDS
    hash = api_json(assignment, user, session, fields)
    hash['course_id'] = assignment.context_id
    hash['name'] = assignment.title
    hash['submission_types'] = assignment.submission_types_array

    if assignment.context && assignment.context.turnitin_enabled?
      hash['turnitin_enabled'] = assignment.turnitin_enabled
      hash['turnitin_settings'] = turnitin_settings_json(assignment)
    end

    if PluginSetting.settings_for_plugin(:assignment_freezer)
      hash['freeze_on_copy'] = assignment.freeze_on_copy?
      hash['frozen'] = assignment.frozen_for_user?(user)
      hash['frozen_attributes'] = assignment.frozen_attributes_for_user(user)
    end

    return hash if assignment.new_record?

    # use already generated hash['description'] because it is filtered by
    # Assignment#filter_attributes_for_user when the assignment is locked
    hash['description'] = api_user_content(hash['description'],
                                           @context || assignment.context,
                                           user,
                                           opts[:preloaded_user_content_attachments] || {})
    hash['muted'] = assignment.muted?
    hash['html_url'] = course_assignment_url(assignment.context_id, assignment)

    if assignment.external_tool? && assignment.external_tool_tag.present?
      external_tool_tag = assignment.external_tool_tag
      hash['external_tool_tag_attributes'] = {
        'url' => external_tool_tag.url,
        'new_tab' => external_tool_tag.new_tab,
        'resource_link_id' => ContextExternalTool.opaque_identifier_for(external_tool_tag, assignment.shard)
      }
      hash['url'] = sessionless_launch_url(@context,
                                           :launch_type => 'assessment',
                                           :assignment_id => assignment.id)
    end

    if assignment.automatic_peer_reviews? && assignment.peer_reviews?
      hash['peer_review_count'] = assignment.peer_review_count
      hash['peer_reviews_assign_at'] = assignment.peer_reviews_assign_at
    end

    if assignment.grants_right?(user, :grade)
      hash['needs_grading_count'] = assignment.needs_grading_count_for_user user
    end

    if assignment.quiz
      hash['quiz_id'] = assignment.quiz.id
      hash['anonymous_submissions'] = !!(assignment.quiz.anonymous_submissions)
    end

    if assignment.allowed_extensions.present?
      hash['allowed_extensions'] = assignment.allowed_extensions
    end

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
        row_hash["ratings"] = row[:ratings].map do |c|
          c.slice(:id, :points, :description)
        end
        if row[:learning_outcome_id] && outcome = LearningOutcome.find_by_id(row[:learning_outcome_id])
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

    if opts[:include_discussion_topic] && assignment.discussion_topic
      extend Api::V1::DiscussionTopics
      hash['discussion_topic'] = discussion_topic_api_json(
        assignment.discussion_topic,
        assignment.discussion_topic.context,
        user,
        session,
        include_assignment: false)
    end

    if opts[:include_all_dates] && assignment.assignment_overrides
      hash['all_dates'] = assignment.dates_hash_visible_to(user)
    end

    if opts[:include_module_ids]
      thing_in_module = case assignment.submission_types
                        when "online_quiz" then assignment.quiz
                        when "discussion_topic" then assignment.discussion_topic
                        else assignment
                        end
      module_ids = thing_in_module.context_module_tags.map &:context_module_id
      hash['module_ids'] = module_ids
    end

    if assignment.context.feature_enabled?(:draft_state)
      hash['published'] = ! assignment.unpublished?
      hash['unpublishable'] = assignment.can_unpublish?
    end

    if assignment.context.feature_enabled?(:differentiated_assignments)
      hash['only_visible_to_overrides'] = value_to_boolean(assignment.only_visible_to_overrides)
    end

    if submission = opts[:submission]
      hash['submission'] = submission_json(submission,assignment,user,session)
    end

    locked_json(hash, assignment, user, 'assignment')

    hash
  end

  def turnitin_settings_json(assignment)
    settings = assignment.turnitin_settings.with_indifferent_access
    [:s_paper_check, :internet_check, :journal_check, :exclude_biblio, :exclude_quoted].each do |key|
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

  API_ALLOWED_ASSIGNMENT_INPUT_FIELDS = %w(
    name
    description
    position
    points_possible
    grading_type
    submission_types
    allowed_extensions
    due_at
    lock_at
    unlock_at
    assignment_group_id
    group_category_id
    peer_reviews
    peer_reviews_assign_at
    peer_review_count
    automatic_peer_reviews
    external_tool_tag_attributes
    grade_group_students_individually
    turnitin_enabled
    turnitin_settings
    grading_standard_id
    freeze_on_copy
    notify_of_update
  )

  API_ALLOWED_TURNITIN_SETTINGS = %w(
    originality_report_visibility
    s_paper_check
    internet_check
    journal_check
    exclude_biblio
    exclude_quoted
    exclude_small_matches_type
    exclude_small_matches_value
  )

  def update_api_assignment(assignment, assignment_params)
    return nil unless assignment_params.is_a?(Hash)

    old_assignment = assignment.new_record? ? nil : assignment.clone
    old_assignment.id = assignment.id if old_assignment.present?

    overrides = deserialize_overrides(assignment_params.delete(:assignment_overrides))
    return if overrides && !overrides.is_a?(Array)

    return false unless valid_assignment_group_id?(assignment, assignment_params)

    assignment = update_from_params(assignment, assignment_params)

    if overrides
      assignment.transaction do
        assignment.save_without_broadcasting!
        batch_update_assignment_overrides(assignment, overrides)
      end
      assignment.do_notifications!(old_assignment, assignment_params[:notify_of_update])
    else
      assignment.save!
    end

    return true
  rescue ActiveRecord::RecordInvalid
    return false
  end

  def valid_assignment_group_id?(assignment, assignment_params)
    ag_id = assignment_params["assignment_group_id"].presence
    # if ag_id is a non-numeric string, ag_id.to_i will == 0
    if ag_id and ag_id.to_i <= 0
      assignment.errors.add('assignment[assignment_group_id]', I18n.t(:not_a_number, "must be a positive number"))
      false
    else
      true
    end
  end

  def update_from_params(assignment, assignment_params)
    update_params = assignment_params.slice(*API_ALLOWED_ASSIGNMENT_INPUT_FIELDS)

    if update_params.has_key?('peer_reviews_assign_at')
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

    if update_params.has_key?("assignment_group_id")
      ag_id = update_params.delete("assignment_group_id").presence
      assignment.assignment_group = assignment.context.assignment_groups.find_by_id(ag_id)
    end

    if update_params.has_key?("group_category_id")
      gc_id = update_params.delete("group_category_id").presence
      assignment.group_category = assignment.context.group_categories.find_by_id(gc_id)
    end

    #TODO: validate grading_standard_id (it's permissions are currently useless)

    if assignment_params.key? "muted"
      assignment.muted = value_to_boolean(assignment_params.delete("muted"))
    end

    exception_message = ["invalid due_at",
                         "assignment_params: #{assignment_params}",
                         "user: #{@current_user.attributes}",
                         "account: #{assignment.context.root_account.attributes}",
                         "course: #{assignment.context.attributes}",
                         "assignment: #{assignment.attributes}"].join(",\n")

    # do some fiddling with due_at for fancy midnight and add to update_params
    # validate that date and times are iso8601 otherwise ignore them, but still
    # allow clearing them when set to nil
    if update_params['due_at'].present? && update_params['due_at'] !~ Api::ISO8601_REGEX
      Api.invalid_time_stamp_error('due_at', exception_message)
      # todo stop logging and delete invalid dates
      # update_params.delete(:due_at)
    elsif update_params.has_key?('due_at')
      update_params['time_zone_edited'] = Time.zone.name
    end

    if update_params['lock_at'].present? && update_params['lock_at'] !~ Api::ISO8601_REGEX
      Api.invalid_time_stamp_error('lock_at', exception_message)
      # todo stop logging and delete invalid dates
      # update_params.delete(:lock_at)
    end

    if update_params['unlock_at'].present? && update_params['unlock_at'] !~ Api::ISO8601_REGEX
      Api.invalid_time_stamp_error('unlock_at', exception_message)
      # todo stop logging and delete invalid dates
      # update_params.delete(:unlock_at)
    end

    if update_params['peer_reviews_due_at'].present? && update_params['peer_reviews_due_at'] !~ Api::ISO8601_REGEX
      Api.invalid_time_stamp_error('peer_reviews_due_at', exception_message)
      # todo stop logging and delete invalid dates
      # update_params.delete(:peer_reviews_due_at)
    end

    if !assignment.context.try(:turnitin_enabled?)
      update_params.delete("turnitin_enabled")
      update_params.delete("turnitin_settings")
    end

    # use Assignment#turnitin_settings= to normalize, but then assign back to
    # hash so that it is written with update_params
    if update_params.has_key?("turnitin_settings")
      turnitin_settings = update_params.delete("turnitin_settings").slice(*API_ALLOWED_TURNITIN_SETTINGS)
      turnitin_settings['exclude_type'] = case turnitin_settings['exclude_small_matches_type']
        when nil; '0'
        when 'words'; '1'
        when 'percent'; '2'
      end
      turnitin_settings['exclude_value'] = turnitin_settings['exclude_small_matches_value']
      assignment.turnitin_settings = turnitin_settings
    end

    # TODO: allow rubric creation

    if update_params.has_key?("description")
      update_params["description"] = process_incoming_html_content(update_params["description"])
    end

    if assignment.context.feature_enabled?(:draft_state)
      if assignment_params.has_key? "published"
        published = value_to_boolean(assignment_params['published'])
        assignment.workflow_state = published ? 'published' : 'unpublished'
      end
    end

    if assignment.context.feature_enabled?(:differentiated_assignments)
      if assignment_params.has_key? "only_visible_to_overrides"
        assignment.only_visible_to_overrides = value_to_boolean(assignment_params['only_visible_to_overrides'])
      end
    end

    assignment.updating_user = @current_user
    assignment.attributes = update_params
    assignment.infer_times

    assignment
  end
end
