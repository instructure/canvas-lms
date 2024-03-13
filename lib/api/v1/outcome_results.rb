# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module Api::V1::OutcomeResults
  include Api::V1::Outcome
  include Outcomes::OutcomeFriendlyDescriptionResolver

  # Public: Serializes OutcomeResults
  #
  # results - The OutcomeResults to serialize
  #
  # Returns a hash that can be converted into json
  def outcome_results_json(results)
    {
      outcome_results: results.map { |r| outcome_result_json(r) }
    }
  end

  def outcome_result_json(result)
    hash = api_json(result, @current_user, session, {
                      methods: :submitted_or_assessed_at,
                      only: %w[id score mastery possible percent hide_points hidden]
                    })
    hash[:links] = {
      user: result.user.id.to_s,
      learning_outcome: result.learning_outcome_id.to_s,
      alignment: result.alignment.content.asset_string,
      assignment: result.assignment&.asset_string
    }
    hash
  end

  # Public: Serializes the rollups produced by Outcomes::ResultAnalytics.
  #
  # rollups - The rollups from Outcomes::ResultAnalytics to serialize
  #
  # Returns a hash that can be converted into json.
  def outcome_results_rollups_json(rollups)
    {
      rollups: serialize_user_rollups(rollups)
    }
  end

  # Public: Serializes outcomes in a hash that can be added to the linked hash.
  #
  # Returns a Hash containing serialized outcomes.
  def outcome_results_include_outcomes_json(outcomes, context, percents = {})
    alignment_asset_string_map = {}
    outcomes.each_slice(50).each do |outcomes_slice|
      ActiveRecord::Associations.preload(outcomes_slice, [:context])
      ContentTag.learning_outcome_alignments.not_deleted.where(learning_outcome_id: outcomes_slice)
                .pluck(:learning_outcome_id, :content_type, :content_id).each do |lo_id, content_type, content_id|
        (alignment_asset_string_map[lo_id] ||= []) << "#{content_type.underscore}_#{content_id}"
      end
    end
    assessed_outcomes = []
    outcomes.map(&:id).each_slice(100) do |outcome_ids|
      assessed_outcomes += LearningOutcomeResult.active.distinct.where(learning_outcome_id: outcome_ids).pluck(:learning_outcome_id)
    end
    friendly_descriptions = {}
    if context.root_account.feature_enabled?(:improved_outcomes_management) && Account.site_admin.feature_enabled?(:outcomes_friendly_description)
      account = @context.is_a?(Account) ? @context : @context.account
      course = @context.is_a?(Course) ? @context : nil

      friendly_descriptions_array = outcomes.map(&:id).each_slice(100).flat_map do |outcome_ids|
        resolve_friendly_descriptions(account, course, outcome_ids).map { |description| [description.learning_outcome_id.to_s, description.description] }
      end

      friendly_descriptions = friendly_descriptions_array.to_h
    end

    outcomes.map do |o|
      hash = outcome_json(
        o,
        @current_user,
        session,
        assessed_outcomes:,
        rating_percents: percents[o.id],
        context:,
        friendly_descriptions:
      )

      hash[:alignments] = alignment_asset_string_map[o.id]
      hash
    end
  end

  # Public: Serializes outcome groups in a hash that can be added to the linked hash.
  #
  # Returns a Hash containing serialized outcome groups.
  def outcome_results_include_outcome_groups_json(outcome_groups)
    outcome_groups.map { |g| outcome_group_json(g, @current_user, session) }
  end

  # Public: Serializes outcome links in a hash that can be added to the linked hash.
  #
  # Returns a Hash containing serialized outcome links.
  def outcome_results_include_outcome_links_json(outcome_links, context)
    outcome_links_json(outcome_links, @current_user, session, { context: })
  end

  # Public: Returns an Array of serialized Course objects for linked hash.
  def outcome_results_linked_courses_json(courses)
    courses.map { |course| { id: course.id.to_s, name: course.name } }
  end

  # Public: Returns an Array of serialized User objects for the linked hash.
  def outcome_results_linked_users_json(users)
    users.map do |u|
      hash = {
        id: u.id.to_s,
        name: u.name,
        display_name: u.short_name,
        sortable_name: u.sortable_name
      }
      hash[:avatar_url] = avatar_url_for_user(u) if service_enabled?(:avatars)
      hash
    end
  end

  # Public: Returns an Array of serialized Alignment objects for the linked hash.
  def outcome_results_include_alignments_json(alignments)
    alignments.map do |alignment|
      hash = { id: alignment.asset_string, name: alignment.title }
      html_url = polymorphic_url([alignment.context, alignment]) rescue nil
      hash[:html_url] = html_url if html_url
      hash
    end
  end

  def outcome_results_assignments_json(assignments)
    assignments.compact.map do |a|
      {
        id: a.asset_string,
        name: a.title,
        html_url: a.is_a?(LiveAssessments::Assessment) ? "" : polymorphic_url([a.context, a]),
        submission_types: a.try(:submission_types) || "magic_marker"
      }
    end
  end

  # Public: Serializes the aggregate rollup. Uses the specified context for the
  # id and name fields.
  def aggregate_outcome_results_rollups_json(rollups)
    {
      rollups: serialize_rollups(rollups, :course)
    }
  end

  # Internal: Returns an Array of serialized rollups.
  def serialize_rollups(rollups, context_key)
    rollups.map { |rollup| serialize_rollup(rollup, context_key) }
  end

  # Internal: Returns a suitable output hash for the rollup.
  def serialize_rollup(rollup, context_key)
    # both Course and User have a name method, so this works for both.
    {
      scores: serialize_rollup_scores(rollup.scores),
      links: { context_key => rollup.context.id.to_s }
    }
  end

  # Internal: Returns a suitable output hash for the user rollups, including
  # section information.
  def serialize_user_rollups(rollups)
    serialized_rollup_pairs = rollups.map do |rollup|
      [rollup, serialize_rollup(rollup, :user)]
    end
    duplicate_rollup_rows_for_sections(serialized_rollup_pairs)
  end

  # Internal: generates an array of duplicate serialized_rollups with distinct
  # section links for each section of the user's course. If @section is set (as
  # it is if section_id is sent as a parameter to the rollup api endpoint), only
  # that section is included
  def duplicate_rollup_rows_for_sections(serialized_rollup_pairs)
    # this is uglier than it should be to inject section ids. they really should
    # be in a 'links' section or something.
    # ideally, we would have some seperate mapping from users to course sections
    # it will also need to change if context is ever not a course
    # we're mostly assuming that there is one section enrollment per user. if a user
    # is in multiple sections, they will have multiple rollup results. pagination is
    # still by user, so the counts won't match up. again, this is a very rare thing
    section_func = if @section
                     ->(user) { [[@section.id, @context.all_student_enrollments.where(user_id: user.id, course_section_id: @section.id).first.workflow_state]] }
                   else
                     enrollments = @context.all_student_enrollments.where(user_id: serialized_rollup_pairs.map { |pair| pair.first.context.id }).to_a
                     ->(user) { enrollments.select { |e| e.user_id == user.id }.map { |e| [e&.course_section_id, e.workflow_state] } }
                   end

    serialized_rollup_pairs.flat_map do |rollup, serialized_rollup|
      section_func.call(rollup.context).map do |section_id, workflow_state|
        serialized_rollup.deep_merge(links: { section: section_id.to_s, status: workflow_state })
      end
    end
  end

  # Internal: Returns an Array of serialized rollup scores
  def serialize_rollup_scores(scores)
    scores.map { |score| serialize_rollup_score(score) }
  end

  # Internal: Returns a suitable output hash for the rollup score
  def serialize_rollup_score(score)
    {
      score: score.score,
      title: score.title,
      submitted_at: score.submitted_at,
      count: score.count,
      hide_points: score.hide_points,
      links: serialize_rollup_score_links(score)
    }
  end

  # Internal: returns hash for rollup score links
  def serialize_rollup_score_links(score)
    links = { outcome: score.outcome.id.to_s }
    if defined?(params) && params[:contributing_scores] == "true"
      links[:contributing_scores] = serialize_contributing_scores(score.outcome_results)
    end
    links
  end

  # Internal: returns an Array of serialized contributing scores
  def serialize_contributing_scores(contributing_scores)
    contributing_scores.map { |score| serialize_contributing_score(score) }
  end

  # Internal: returns hash for contributing score
  def serialize_contributing_score(score)
    {
      association_id: score.association_id,
      association_type: score.association_type,
      title: score.title,
      score: score.score
    }
  end

  def outcome_results_rollups_csv(current_user, _context, rollups, outcomes, outcome_paths)
    options = CSVWithI18n.csv_i18n_settings(current_user)
    CSVWithI18n.generate(**options) do |csv|
      row = []
      row << I18n.t(:student_name, "Student name")
      row << I18n.t(:student_id, "Student ID")
      row << I18n.t(:student_sis_id, "Student SIS ID")
      outcomes.each do |outcome|
        pathParts = outcome_paths.find { |x| x[:id] == outcome.id }[:parts]
        path = pathParts.pluck(:name).join(" > ")
        row << I18n.t(:outcome_path_result, "%{path} result", path:)
        row << I18n.t(:outcome_path_mastery_points, "%{path} mastery points", path:)
      end
      csv << row
      mastery_points = @context.root_account.feature_enabled?(:account_level_mastery_scales) && @context.resolved_outcome_proficiency&.mastery_points
      rollups.each do |rollup|
        row = [rollup.context.name, rollup.context.id]
        sis_user_id = @context.root_account.pseudonyms.active.where("sis_user_id IS NOT NULL AND user_id = ?", rollup.context.id).pick(:sis_user_id) || "N/A"
        row << sis_user_id
        outcomes.each do |outcome|
          score = rollup.scores.find { |x| x.outcome == outcome }
          row << (score ? score.score : nil)
          row << (mastery_points || outcome&.data&.dig(:rubric_criterion, :mastery_points))
        end
        csv << row
      end
    end
  end
end
