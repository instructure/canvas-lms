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

require "spec_helper"

describe GroupMembershipsController do
  before :once do
    course_with_teacher(active_all: true)
    students = create_users_in_course(@course, 3, return_type: :record)
    @student1, @student2, @student3 = students
  end

  let(:group_category) { @course.group_categories.create!(name: "Test Category") }
  let(:group) { @course.groups.create!(name: "Test Group", group_category:) }
  let!(:membership1) { group.add_user(@student1) }
  let!(:membership2) { group.add_user(@student2) }
  let!(:membership3) { group.add_user(@student3) }

  describe "DELETE #destroy" do
    before do
      user_session(@teacher)
    end

    context "single membership deletion by membership_id" do
      it "deletes the membership and returns ok" do
        delete :destroy, params: { group_id: group.id, membership_id: membership1.id }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "ok" => true })
        expect(membership1.reload.workflow_state).to eq("deleted")
      end
    end

    context "single membership deletion by user_id" do
      it "deletes the membership and returns ok" do
        delete :destroy, params: { group_id: group.id, user_id: @student2.id }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq({ "ok" => true })
        expect(membership2.reload.workflow_state).to eq("deleted")
      end
    end

    context "unauthorized deletion" do
      before do
        user_session(@student1)
      end

      it "returns forbidden when user lacks permission" do
        delete :destroy, params: { group_id: group.id, membership_id: membership2.id }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #destroy_bulk" do
    before do
      user_session(@teacher)
    end

    context "successful bulk deletion" do
      it "deletes memberships for all provided user IDs and returns summary" do
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [@student1.id, @student2.id] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to match_array([@student1.id, @student2.id])
        expect(json["unauthorized_user_ids"]).to eq([])

        expect(membership1.reload.workflow_state).to eq("deleted")
        expect(membership2.reload.workflow_state).to eq("deleted")
        expect(membership3.reload.workflow_state).to eq("accepted") # unchanged
      end
    end

    context "bulk deletion with mixed authorization" do
      before do
        # Mock authorization to fail for student3"s membership
        allow_any_instance_of(GroupMembershipsController).to receive(:can_do).and_call_original
        allow_any_instance_of(GroupMembershipsController).to receive(:can_do)
          .with(membership3, @teacher, :delete).and_return(false)
      end

      it "deletes authorized memberships and reports unauthorized ones" do
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [@student1.id, @student2.id, @student3.id] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to match_array([@student1.id, @student2.id])
        expect(json["unauthorized_user_ids"]).to match_array([@student3.id])

        expect(membership1.reload.workflow_state).to eq("deleted")
        expect(membership2.reload.workflow_state).to eq("deleted")
        expect(membership3.reload.workflow_state).to eq("accepted") # unchanged due to authorization failure
      end
    end

    context "bulk deletion with no authorized memberships" do
      before do
        # Mock all authorizations to fail
        allow_any_instance_of(GroupMembershipsController).to receive(:can_do)
          .with(anything, @teacher, :delete).and_return(false)
      end

      it "reports all user IDs as unauthorized" do
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [@student1.id, @student2.id] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to eq([])
        expect(json["unauthorized_user_ids"]).to match_array([@student1.id, @student2.id])

        expect(membership1.reload.workflow_state).to eq("accepted") # unchanged
        expect(membership2.reload.workflow_state).to eq("accepted") # unchanged
      end
    end

    context "bulk deletion with empty user_ids array" do
      it "returns success with empty arrays" do
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to eq([])
        expect(json["unauthorized_user_ids"]).to eq([])
      end
    end

    context "bulk deletion with non-existent user IDs" do
      it "ignores non-existent memberships" do
        non_existent_user_id = 99_999
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [@student1.id, non_existent_user_id] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to match_array([@student1.id])
        expect(json["unauthorized_user_ids"]).to eq([])

        expect(membership1.reload.workflow_state).to eq("deleted")
      end
    end

    context "unauthorized user attempting bulk deletion" do
      before do
        user_session(@student1)
      end

      it "treats all memberships as unauthorized" do
        delete :destroy_bulk, params: { group_id: group.id, user_ids: [@student2.id, @student3.id] }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["message"]).to eq("Bulk delete completed")
        expect(json["deleted_user_ids"]).to eq([])
        expect(json["unauthorized_user_ids"]).to match_array([@student2.id, @student3.id])

        expect(membership2.reload.workflow_state).to eq("accepted") # unchanged
        expect(membership3.reload.workflow_state).to eq("accepted") # unchanged
      end
    end
  end
end
