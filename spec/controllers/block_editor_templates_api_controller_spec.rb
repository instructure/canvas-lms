# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe BlockEditorTemplatesApiController do
  let_once(:account) { Account.default }
  let_once(:course1) { course_factory(active_all: true, account:) }
  let_once(:course2) { course_factory(active_all: true, account:) }
  let_once(:teacher) do
    user_factory(active_all: true).tap do |t|
      course1.enroll_teacher(t, enrollment_state: "active")
      course2.enroll_teacher(t, enrollment_state: "active")
    end
  end
  let_once(:template_in_course1) do
    BlockEditorTemplate.create!(
      context: course1,
      name: "Course 1 Template",
      node_tree: '{"ROOT":{}}',
      editor_version: "0.2",
      template_type: "page",
      workflow_state: "unpublished"
    )
  end
  let_once(:template_in_course2) do
    BlockEditorTemplate.create!(
      context: course2,
      name: "Course 2 Template",
      node_tree: '{"ROOT":{}}',
      editor_version: "0.2",
      template_type: "page",
      workflow_state: "unpublished"
    )
  end

  before do
    user_session(teacher)
    allow(controller).to receive(:template_editor?).and_return(true)
  end

  describe "PUT #update" do
    it "allows updating a template in the same course" do
      put :update, params: { course_id: course1.id, id: template_in_course1.id, name: "Updated Name" }, format: :json
      expect(response).to be_successful
      expect(template_in_course1.reload.name).to eq("Updated Name")
    end

    it "rejects updating a template from a different course" do
      put :update, params: { course_id: course1.id, id: template_in_course2.id, name: "Hacked" }, format: :json
      expect(response).to be_not_found
      expect(template_in_course2.reload.name).to eq("Course 2 Template")
    end
  end

  describe "POST #publish" do
    it "allows publishing a template in the same course" do
      post :publish, params: { course_id: course1.id, id: template_in_course1.id }, format: :json
      expect(response).to be_successful
      expect(template_in_course1.reload.workflow_state).to eq("active")
    end

    it "rejects publishing a template from a different course" do
      post :publish, params: { course_id: course1.id, id: template_in_course2.id }, format: :json
      expect(response).to be_not_found
      expect(template_in_course2.reload.workflow_state).to eq("unpublished")
    end
  end

  describe "DELETE #destroy" do
    it "allows deleting a template in the same course" do
      delete :destroy, params: { course_id: course1.id, id: template_in_course1.id }, format: :json
      expect(response).to be_successful
    end

    it "rejects deleting a template from a different course" do
      delete :destroy, params: { course_id: course1.id, id: template_in_course2.id }, format: :json
      expect(response).to be_not_found
      expect(BlockEditorTemplate.find(template_in_course2.id)).to be_present
    end
  end
end
