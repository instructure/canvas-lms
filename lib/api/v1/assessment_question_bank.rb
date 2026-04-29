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

module Api::V1::AssessmentQuestionBank
  include Api::V1::Json

  API_ALLOWED_QUESTION_BANK_OUTPUT_FIELDS = {
    only: %w[
      id
      context_id
      context_type
      title
      workflow_state
      created_at
      updated_at
    ]
  }.freeze

  def question_bank_json(bank, user, session, options = {})
    api_json(bank, user, session, API_ALLOWED_QUESTION_BANK_OUTPUT_FIELDS).tap do |json|
      json[:assessment_question_count] = bank.assessment_question_count if options[:include_question_count]
      json[:context_code] = bank.context_code
    end
  end

  def question_banks_json(banks, user, session, options = {})
    banks.map { |bank| question_bank_json(bank, user, session, options) }
  end
end
