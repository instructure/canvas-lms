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
  class AssessmentQuestionBankImporter < Importer
    self.item_class = AssessmentQuestionBank

    # extract and compile the assessment question bank data from inside the individual questions
    def self.preprocess_migration_data(data)
      return if data[:assessment_question_banks]

      questions = (data[:assessment_questions] && data[:assessment_questions][:assessment_questions]) || []

      banks = []
      questions.each do |q|
        q.delete(:question_bank_name) if q[:question_bank_name].blank?

        if (id = q.delete(:question_bank_id))
          q[:question_bank_migration_id] ||= id
        end

        if q[:question_bank_migration_id] && (bank = banks.detect { |b| b[:migration_id] == q[:question_bank_migration_id] })
          bank[:count] += 1
          bank[:title] ||= q[:question_bank_name]
          q[:question_bank_name] ||= bank[:title]
          bank[:migration_id] ||= CC::CCHelper.create_key(bank[:title], "assessment_question_bank") if bank[:title]
        elsif !q[:question_bank_migration_id] && q[:question_bank_name] && (bank = banks.detect { |b| b[:title] == q[:question_bank_name] })
          # should not be reaching this point on standard canvas imports
          bank[:count] += 1
          q[:question_bank_migration_id] = bank[:migration_id]
        else
          bank = { count: 1 }
          bank[:title] = q[:question_bank_name] if q[:question_bank_name]
          bank[:migration_id] = q[:question_bank_migration_id] if q[:question_bank_migration_id]
          bank[:migration_id] ||= CC::CCHelper.create_key(bank[:title], "assessment_question_bank") if bank[:title]
          bank[:for_quiz] = true if q[:is_quiz_question_bank]
          q[:question_bank_migration_id] ||= bank[:migration_id]
          banks << bank
        end
      end

      data[:assessment_question_banks] = banks
    end
  end
end
