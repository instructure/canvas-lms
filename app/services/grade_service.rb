# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class GradeService
  def initialize(assignment:, essay:, rubric:, root_account_uuid:, current_user:)
    @assignment = assignment.to_s
    @essay = essay.to_s
    @rubric = rubric
    @root_account_uuid = root_account_uuid
    @current_user = current_user
    @rubric_prompt_format = self.class.normalize_rubric_for_prompt(@rubric)
  end

  def call
    @essay = sanitize_essay(@essay)
    validate_essay_length(@essay)

    if rubric_matches_default_template?
      raise "Rubric criteria not descriptive enough"
    end

    cedar_rubric = build_cedar_rubric(@rubric)

    begin
      grading_results = CedarClient.grade_essay(
        description: @assignment,
        essay: @essay,
        rubric: cedar_rubric,
        feature_slug: "grading-assistance",
        root_account_uuid: @root_account_uuid,
        current_user: @current_user
      )

      map_grade_essay_results_to_canvas(grading_results, @rubric)
    rescue InstructureMiscPlugin::Extensions::CedarClient::CedarClientError => e
      raise CedarAi::Errors::GraderError, e.message
    rescue => e
      raise CedarAi::Errors::GraderError, "Invalid response from gradeEssay: #{e.message}"
    end
  end

  def self.normalize_rubric_for_prompt(rubric_data)
    rubric_data.each_with_object({}) do |criterion, acc|
      key = criterion[:description]
      acc[key] = {
        "Criteria" => (criterion[:ratings] || []).map do |rating|
          {
            "Description" => rating[:long_description],
            "Points" => rating[:points]
          }
        end,
        "MaximumPoints" => criterion[:points]
      }
    end
  end

  private

  def build_cedar_rubric(rubric_data)
    rubric_data.map do |criterion|
      {
        name: criterion[:description],
        criteria: (criterion[:ratings] || []).map do |rating|
          {
            points: rating[:points],
            description: rating[:long_description]
          }
        end
      }
    end
  end

  def map_grade_essay_results_to_canvas(grading_results, rubric_data)
    grading_results.filter_map do |result|
      rubric_category = result.rubric_category

      criterion_data = rubric_data.find { |c| c[:description] == rubric_category }
      next unless criterion_data

      matched_rating = (criterion_data[:ratings] || []).find do |r|
        TextNormalizerHelper.normalize(r[:long_description]) ==
          TextNormalizerHelper.normalize(result.criterion)
      end
      next unless matched_rating

      {
        "id" => criterion_data[:id],
        "description" => rubric_category,
        "rating" => {
          "id" => matched_rating[:id],
          "description" => result.criterion,
          "rating" => matched_rating[:points],
          "reasoning" => result.reasoning
        },
        # NEW: inline guidance from gradeEssay
        "comments" => result.guidance
      }
    end
  end

  def sanitize_essay(text)
    # First decode any HTML entities
    text = CGI.unescapeHTML(text)
    text = ActionView::Base.full_sanitizer.sanitize(text)

    # Remove any remaining HTML tags and their content
    text = text.gsub(%r{<[^>]*>.*?</[^>]*>}, "")                          # Remove content between other opening and closing tags
               .gsub(/<[^>]*>/, "")                                       # Remove any remaining opening tags
               .gsub(%r{</[^>]*>}, "")                                    # Remove any remaining closing tags

    # Remove any content between \&lt; and \&gt; (including the entities themselves)
    text = text.gsub(%r{\\&lt;[^&]*\\&gt;.*?\\&lt;/[^&]*\\&gt;}, "")      # Remove content between encoded opening and closing tags
               .gsub(/\\&lt;[^&]*\\&gt;/, "")                             # Remove any remaining encoded opening tags
               .gsub(%r{\\&lt;/[^&]*\\&gt;}, "")                          # Remove any remaining encoded closing tags

    raise "No essay submission found after removing text between <>" if text.blank?

    # Remove lines starting with more than 3 # characters
    text = text.split("\n").reject { |line| line.strip.start_with?("####") }.join("\n")

    # Clean up any resulting double spaces and trim
    text.gsub(/\s+/, " ").strip
  end

  def validate_essay_length(text)
    raise "Submission must be at least 5 words long" if text.split.size < 5
  end

  def rubric_matches_default_template?
    predefined_criteria_templates = [
      ["Exit Ticket Prompt", "Preparation", "Time", "Participation"],
      ["Peer Review"],
      ["Description of criterion"]
    ]

    submitted_criteria = @rubric.pluck(:description)

    predefined_criteria_templates.each do |template_criteria|
      criteria_not_in_submission = submitted_criteria - template_criteria
      return true if criteria_not_in_submission.empty?
    end

    false
  end
end
