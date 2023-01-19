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
  class ContentImporterHelper
    # do the id prepending right before import so we can only make an id unique if it's necessary
    def self.add_assessment_id_prepend(context, data, migration)
      id_prepender = migration.migration_settings[:id_prepender]
      if id_prepender && !migration.migration_settings[:overwrite_quizzes]
        existing_ids = existing_migration_ids(context)
        if data[:assessment_question_banks]
          Canvas::Migration::MigratorHelper.prepend_id_to_assessment_question_banks(data[:assessment_question_banks], id_prepender, existing_ids)
        end

        if data[:assessment_questions] && data[:assessment_questions][:assessment_questions]
          Canvas::Migration::MigratorHelper.prepend_id_to_questions(data[:assessment_questions][:assessment_questions], id_prepender, existing_ids)
        end

        if data[:assessments] && data[:assessments][:assessments]
          Canvas::Migration::MigratorHelper.prepend_id_to_assessments(data[:assessments][:assessments], id_prepender, existing_ids)
          if data[:modules]
            Canvas::Migration::MigratorHelper.prepend_id_to_linked_assessment_module_items(data[:modules], id_prepender, existing_ids)
          end
        end
      end
    end

    def self.existing_migration_ids(context)
      existing_ids = {}
      if context.respond_to?(:quizzes)
        existing_ids[:assessments] = context.quizzes
                                            .where.not(quizzes: { migration_id: nil }).pluck(:migration_id)
      end
      if context.respond_to?(:assessment_questions)
        existing_ids[:assessment_questions] = context.assessment_questions
                                                     .where.not(assessment_questions: { migration_id: nil }).pluck(:migration_id)
      end
      if context.respond_to?(:assessment_question_banks)
        existing_ids[:assessment_question_banks] = context.assessment_question_banks
                                                          .where.not(assessment_question_banks: { migration_id: nil }).pluck(:migration_id)
      end
      existing_ids
    end
  end
end
