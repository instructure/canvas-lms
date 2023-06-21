# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../qti_helper"
if Qti.migration_executable
  describe "Converting a cengage QTI" do
    it "gets the question bank name and id" do
      qti_data = file_as_string(cengage_question_dir, "question_with_bank.xml")
      hash = Qti::AssessmentItemConverter.create_instructure_question(qti_data:)
      expect(hash[:question_bank_name]).to eq "Practice Test Chapter 2"
      expect(hash[:question_bank_id]).to eq "res00013"
    end

    it "points a group to a question bank" do
      manifest_node = get_manifest_node("group_to_bank", quiz_type: "examination")
      a = Qti::AssessmentTestConverter.new(manifest_node, cengage_question_dir)
      a.create_instructure_quiz
      group = a.quiz[:questions].first
      expect(group[:pick_count]).to eq 20
      expect(group[:question_bank_migration_id]).to eq "res00013"
    end
  end
end
