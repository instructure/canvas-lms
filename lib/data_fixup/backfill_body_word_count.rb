# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
class DataFixup::BackfillBodyWordCount
  DATAFIX_CUTOFF = Time.utc(2024)

  def self.run
    GuardRail.activate(:secondary) do
      submissions_to_backfill.find_ids_in_ranges(batch_size: 1_000) do |min_id, max_id|
        ids = submissions_to_backfill.where(id: min_id..max_id).pluck(:id)

        GuardRail.activate(:primary) do
          delay_if_production(
            priority: Delayed::LOWER_PRIORITY,
            n_strand: "Datafix:BackfillBodyWordCount:ProcessSubmissions#{Shard.current.database_server.id}"
          ).process_submissions(ids)
        end
      end
    end
  end

  def self.submissions_to_backfill
    Submission
      .active
      .where.not(body: nil)
      .where.not(submission_type: "online_quiz")
      .where(body_word_count: nil, updated_at: DATAFIX_CUTOFF..)
  end

  def self.process_submissions(ids)
    GuardRail.activate(:secondary) do
      Submission.where(id: ids).find_each do |submission|
        process_versions(submission)
        body_word_count = submission.calc_body_word_count
        GuardRail.activate(:primary) { submission.update_columns(body_word_count:) }
      end
    end
  end

  def self.process_versions(submission)
    submission.versions.where(created_at: DATAFIX_CUTOFF..).find_each do |version|
      version_submission = version.model
      return if version_submission.body.nil?
      return if version_submission.body_word_count.present?
      return if version_submission.submission_type == "online_quiz"

      version_submission.body_word_count = version_submission.calc_body_word_count
      yaml = version_submission.attributes.to_yaml
      GuardRail.activate(:primary) { version.update_columns(yaml:) }
    end
  end
end
