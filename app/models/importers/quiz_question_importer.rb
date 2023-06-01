# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Importers
  class QuizQuestionImporter < Importer
    self.item_class = Quizzes::QuizQuestion

    def self.import_from_migration(aq_hash, qq_hash, position, qq_ids, context, migration, quiz = nil, quiz_group = nil)
      unless aq_hash[:prepped_for_import]
        Importers::AssessmentQuestionImporter.prep_for_import(aq_hash, migration, :quiz_question)
      end

      hash = aq_hash.dup
      hash[:position] = position
      hash[:points_possible] = qq_hash[:points_possible] if qq_hash[:points_possible]
      hash[:points_possible] = 0 if hash[:points_possible].to_f < 0

      mig_id = qq_hash["quiz_question_migration_id"] || qq_hash["migration_id"]

      if (id = qq_ids[mig_id])
        data = { quiz_group_id: quiz_group&.id,
                 assessment_question_id: hash["assessment_question_id"],
                 question_data: hash,
                 created_at: Time.now.utc,
                 updated_at: Time.now.utc,
                 migration_id: mig_id,
                 position: }
        data.delete(:assessment_question_id) if hash["assessment_question_id"].nil? && migration.for_master_course_import? # don't undo an existing association
        Quizzes::QuizQuestion.where(id:).update_all(data)
      else
        root_account_id = quiz&.root_account_id || context&.root_account_id
        args = [
          quiz&.id,
          quiz_group&.id,
          hash["assessment_question_id"],
          hash.to_yaml,
          Time.now.utc,
          Time.now.utc,
          mig_id,
          position,
          root_account_id
        ]
        query = item_class.send(:sanitize_sql, [<<~SQL.squish, *args])
          INSERT INTO #{Quizzes::QuizQuestion.quoted_table_name} (quiz_id, quiz_group_id, assessment_question_id, question_data, created_at, updated_at, migration_id, position, root_account_id)
          VALUES (?,?,?,?,?,?,?,?,?)
        SQL
        GuardRail.activate(:primary) do
          qq_ids[mig_id] = item_class.connection.insert(query,
                                                        "#{item_class.name} Create",
                                                        item_class.primary_key,
                                                        nil,
                                                        item_class.sequence_name)
        end
      end
      hash
    end
  end
end
