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

describe DataFixup::AddRcsServiceJwtToQuizLtiTools do
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
        lti.update(custom_fields: nil)
      end

      it "adds the canvas_rcs_service_jwt custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsServiceJwtToQuizLtiTools.run
        expect(lti.reload.custom_fields).to eq({ "canvas_rcs_service_jwt" => "$com.instructure.RCS.service_jwt" })
      end
    end

    context "when custom_fields is an empty hash" do
      before do
        lti.update(custom_fields: {})
      end

      it "adds the canvas_rcs_service_jwt custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsServiceJwtToQuizLtiTools.run
        expect(lti.reload.custom_fields).to eq({ "canvas_rcs_service_jwt" => "$com.instructure.RCS.service_jwt" })
      end
    end

    context "when custom_fields is not empty" do
      before do
        lti.update(custom_fields: { "key" => "value" })
      end

      it "adds the canvas_rcs_service_jwt custom field to Quiz LTI ContextExternalTool" do
        DataFixup::AddRcsServiceJwtToQuizLtiTools.run
        expect(lti.reload.custom_fields).to include({ "canvas_rcs_service_jwt" => "$com.instructure.RCS.service_jwt" })
      end

      it "keeps the other existing custom fields" do
        DataFixup::AddRcsServiceJwtToQuizLtiTools.run
        expect(lti.reload.custom_fields).to include({ "key" => "value" })
      end
    end

    context "when canvas_rcs_service_jwt is present" do
      before do
        lti.update(custom_fields: { "key" => "value", "canvas_rcs_service_jwt" => "already set" })
      end

      it "does not set the canvas_rcs_service_jwt custom field" do
        DataFixup::AddRcsServiceJwtToQuizLtiTools.run
        expect(lti.reload.custom_fields["canvas_rcs_service_jwt"]).to eq("already set")
      end
    end
  end
end
