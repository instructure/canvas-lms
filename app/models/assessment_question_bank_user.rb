#
# Copyright (C) 2011 Instructure, Inc.
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

class AssessmentQuestionBankUser < ActiveRecord::Base
  include Workflow
  attr_accessible :assessment_question_bank, :user
  belongs_to :assessment_question_bank
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [:id, :assessment_question_bank_id, :user_id, :permissions, :workflow_state, :deleted_at, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:assessment_question_bank, :user]
  validates_presence_of :assessment_question_bank_id, :user_id, :workflow_state
  
  workflow do
    state :active
    state :invited
    state :deleted
  end
end
