# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::AddRcsAppHostToQuizLtiTools do
  describe ".run" do
    let(:lti) do
      ContextExternalTool.create!(
        {
          name: "Quizzes 2",
          tool_id: "Quizzes 2",
          context: Account.default,
          shared_secret: "a",
          consumer_key: "b",
          url: "http://example.com/launch"
        }
      )
    end

    context "when custom_fields is nil" do
      before do
        lti.custom_fields = nil
        lti.save!
      end

      it "adds the canvas_rcs_host custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsAppHostToQuizLtiTools.run
        expect(lti.reload.custom_fields).to eq({ "canvas_rcs_host" => "$com.instructure.RCS.app_host" })
      end
    end

    context "when custom_fields is an empty hash" do
      before do
        lti.custom_fields = {}
        lti.save!
      end

      it "adds the canvas_rcs_host custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsAppHostToQuizLtiTools.run
        expect(lti.reload.custom_fields).to eq({ "canvas_rcs_host" => "$com.instructure.RCS.app_host" })
      end
    end

    context "when custom_fields is not empty" do
      before do
        lti.custom_fields = { "key" => "value" }
        lti.save!
      end

      it "adds the canvas_rcs_host custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsAppHostToQuizLtiTools.run
        expect(lti.reload.custom_fields).to eq({ "canvas_rcs_host" => "$com.instructure.RCS.app_host", "key" => "value" })
      end
    end

    context "when canvas_rcs_host is present" do
      before do
        lti.custom_fields = { "key" => "value", "canvas_rcs_host" => "already set" }
        lti.save!
      end

      it "does not set the rcs_host custom field" do
        DataFixup::AddRcsAppHostToQuizLtiTools.run
        expect(lti.reload.custom_fields["canvas_rcs_host"]).to eq("already set")
      end
    end
  end
end
