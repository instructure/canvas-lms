#
# Copyright (C) 2013 Instructure, Inc.
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

require 'csv'

module Api::V1::OutcomeResults
  include Api::V1::Outcome

  # Public: Serializes OutcomeResults
  #
  # results - The OutcomeResults to serialize
  #
  # Returns a hash that can be converted into json
  def outcome_results_json(results)
    {
      outcome_results: results.map{|r| outcome_result_json(r)}
    }
  end

  def outcome_result_json(result)
    hash = api_json(result, @current_user, session, only: %w(id score))
    hash[:links] = {
      user: result.user.id.to_s,
      learning_outcome: result.learning_outcome_id.to_s,
      alignment: result.alignment.content.asset_string
    }
    Api.recursively_stringify_json_ids(hash)
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
  def outcome_results_include_outcomes_json(outcomes)
    outcomes.map do |o|
      hash = outcome_json(o, @current_user, session)
      hash.merge!(alignments: o.alignments.map(&:content_asset_string))
      Api.recursively_stringify_json_ids(hash)
    end
  end

  # Public: Serializes outcome groups in a hash that can be added to the linked hash.
  #
  # Returns a Hash containing serialized outcome groups.
  def outcome_results_include_outcome_groups_json(outcome_groups)
    outcome_groups.map { |g| Api.recursively_stringify_json_ids(outcome_group_json(g, @current_user, session)) }
  end

  # Public: Serializes outcome links in a hash that can be added to the linked hash.
  #
  # Returns a Hash containing serialized outcome links.
  def outcome_results_include_outcome_links_json(outcome_links)
    outcome_links.map { |l| Api.recursively_stringify_json_ids(outcome_link_json(l, @current_user, session)) }
  end

  # Public: Returns an Array of serialized Course objects for linked hash.
  def outcome_results_linked_courses_json(courses)
    courses.map { |course| {id: course.id.to_s, name: course.name} }
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
      hash[:avatar_url] = avatar_url_for_user(u, blank_fallback) if service_enabled?(:avatars)
      hash
    end
  end

  # Public: Returns an Array of serialized Alignment objects for the linked hash.
  def outcome_results_include_alignments_json(alignments)
    alignments.map do |alignment|
      hash = {id: alignment.asset_string, name: alignment.title}
      html_url = polymorphic_url([alignment.context, alignment]) rescue nil
      hash[:html_url] = html_url if html_url
      hash
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
      links: {context_key => rollup.context.id.to_s}
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
    section_ids_func = if @section
                         ->(user) { [@section.id] }
                       else
                         enrollments = @context.student_enrollments.active.where(:user_id => serialized_rollup_pairs.map{|pair| pair[0].context.id}).to_a
                         ->(user) { enrollments.select{|e| e.user_id == user.id}.map(&:course_section_id) }
                       end

    serialized_rollup_pairs.map do |rollup, serialized_rollup|
      section_ids_func.call(rollup.context).map do |section_id|
        serialized_rollup.deep_merge(links: {section: section_id.to_s})
      end
    end.flatten(1)
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
      links: {outcome: score.outcome.id.to_s},
    }
  end

  def outcome_results_rollups_csv(rollups, outcomes, outcome_paths)
    CSV.generate do |csv|
      row = []
      row << I18n.t(:student_name, 'Student name')
      row << I18n.t(:student_id, 'Student ID')
      outcomes.each do |outcome|
        pathParts = outcome_paths.find{|x| x[:id] == outcome.id}[:parts]
        path = pathParts.map{|x| x[:name]}.join(' > ')
        row << I18n.t(:outcome_path_result, "%{path} result", :path => path)
        row << I18n.t(:outcome_path_mastery_points, "%{path} mastery points", :path => path)
      end
      csv << row
      rollups.each do |rollup|
        row = [rollup.context.name, rollup.context.id]
        outcomes.each do |outcome|
          score = rollup.scores.find{|x| x.outcome == outcome}
          criterion = outcome.data && outcome.data[:rubric_criterion]
          row << (score ? score.score : nil)
          row << (criterion ? criterion[:mastery_points] : nil)
        end
        csv << row
      end
    end
  end
end
