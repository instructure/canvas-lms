# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe DataFixup::AddAnonymousGradingFieldToQuizLtiTools do
  describe ".run" do
    let!(:lti) do
      ContextExternalTool.create!(
        {
          name: "Quizzes 2",
          tool_id: "Quizzes 2",
          context: Account.default,
          shared_secret: "a",
          consumer_key: "b",
          url: "http://example.com/launch",
          custom_fields: { "key" => "value" }
        }
      )
    end

    it "adds the canvas_assignment_anonymous_grading custom field to Quiz LTI ContextExternalTool" do
      DataFixup::AddAnonymousGradingFieldToQuizLtiTools.run
      expect(lti.reload.custom_fields).to eq(
        {
          "canvas_assignment_anonymous_grading" => "$com.instructure.Assignment.anonymous_grading",
          "key" => "value"
        }
      )
    end
  end
end
