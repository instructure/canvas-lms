#
# Copyright (C) 2016 - present Instructure, Inc.
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

class FixMoreDeprecatedPolymorphicNames < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    tables = {
      attachments: {
        context_type: 'QuizStatistics'
      },
      cloned_items: {
        original_item_type: 'Quiz'
      },
      delayed_messages: {
        context_type: 'QuizSubmission'
      },
      delayed_notifications: {
        asset_type: 'QuizSubmission'
      },
      learning_outcome_question_results: {
        associated_asset_type: 'Quiz'
      },
      learning_outcome_result: {
        association_type: 'Quiz',
        associated_asset_type: 'Quiz',
        artifact_type: 'QuizSubmission'
      },
      messages: {
        context_type: ['QuizSubmission', 'QuizRegradeRun'],
        asset_context_type: ['QuizSubmission', 'QuizRegradeRun']
      },
      progress: {
        context_type: 'QuizStatistics'
      }
    }

    LearningOutcomeResult.where(association_type: 'Quiz').
        where("EXISTS (SELECT 1 FROM #{LearningOutcomeResult.quoted_table_name} lor2 WHERE
                       lor2.association_type='Quizzes::Quiz' AND
                       learning_outcome_results.user_id=lor2.user_id AND
                       learning_outcome_results.content_tag_id=lor2.content_tag_id AND
                       learning_outcome_results.association_id=lor2.association_id AND
                       learning_outcome_results.associated_asset_id=lor2.associated_asset_id AND
                       learning_outcome_results.associated_asset_type=lor2.associated_asset_type)").
        delete_all

    tables.each do |(table, columns)|
      klass = table.to_s.classify.constantize
      klass.find_ids_in_ranges(batch_size: 10000) do |min_id, max_id|
        columns.each do |(column, types)|
          Array(types).each do |type|
            klass.where(id: min_id..max_id, column => type).
              update_all(column => "Quizzes::#{type}")
          end
        end
      end
    end
  end
end
