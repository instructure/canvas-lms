# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateFieldOnModelFromAssociation do
  context 'models' do
    it 'should populate the root_account_id on Attachment from AssessmentQuestion' do
      aq = assessment_question_bank_with_questions.assessment_questions.take
      a = attachment_model(context: aq, namespace: nil)
      a.update_columns(root_account_id: 0)
      expect(a.reload.root_account_id).to eq 0
      DataFixup::PopulateFieldOnModelFromAssociation.run(Attachment, :assessment_question, :root_account_id, old_value: 0)
      expect(a.reload.root_account_id).to eq aq.root_account_id
    end
  end
end
