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

describe Lti::AssetProcessorTiiMigrationsApiController do
  describe "GET #index" do
    let(:root_account) { account_model }
    let(:sub_account) { account_model(parent_account: root_account, root_account:) }
    let(:admin) { account_admin_user(account: root_account) }
    let!(:product_family) do
      Lti::ProductFamily.create!(
        vendor_code: "turnitin.com",
        product_code: "turnitin-lti",
        vendor_name: "TurnItIn",
        vendor_description: "TurnItIn LTI",
        website: "http://www.turnitin.com/",
        vendor_email: "support@turnitin.com",
        root_account:
      )
    end

    def create_tool_proxy(context:, product_family_override: nil, workflow_state: "active")
      pf = product_family_override || product_family
      tool_proxy = Lti::ToolProxy.create!(
        context:,
        guid: SecureRandom.uuid,
        shared_secret: "shared_secret",
        product_version: "1.0",
        lti_version: "LTI-2p0",
        product_family: pf,
        workflow_state:,
        raw_data: { enabled_capability: [] }
      )
      Lti::ToolProxyBinding.create!(context:, tool_proxy:, enabled: true) if workflow_state == "active"
      tool_proxy
    end

    def create_tii_assignment_lookup(assignment:, context_type:)
      AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool_type: "Lti::MessageHandler",
        tool_vendor_code: "turnitin.com",
        tool_product_code: "turnitin-lti",
        tool_resource_type_code: "resource",
        context_type:
      )
    end

    context "when user is root account admin" do
      before do
        user_session(admin)
      end

      context "when no accounts have TurnItIn tool proxies" do
        it "returns an empty array" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([])
        end
      end

      context "when accounts have TurnItIn tool proxies at account level" do
        let(:course) { course_model(account: sub_account) }
        let(:assignment) { assignment_model(course:) }

        before do
          create_tool_proxy(context: sub_account)
          create_tii_assignment_lookup(assignment:, context_type: "Account")
        end

        it "returns account data" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)

          data = response.parsed_body
          expect(data.length).to eq(1)

          sub_account_data = data.first
          expect(sub_account_data).to include(
            "account_name" => sub_account.name,
            "account_id" => sub_account.id
          )
        end
      end

      context "when accounts have TurnItIn tool proxies at course level" do
        let(:course) { course_model(account: sub_account) }
        let(:assignment) { assignment_model(course:) }

        before do
          create_tool_proxy(context: course)
          create_tii_assignment_lookup(assignment:, context_type: "Course")
        end

        it "returns account data for course's account" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)

          data = response.parsed_body
          expect(data.length).to eq(1)

          sub_account_data = data.first
          expect(sub_account_data).to include(
            "account_name" => sub_account.name,
            "account_id" => sub_account.id
          )
        end
      end

      context "when account has migration progress" do
        let(:progress) do
          Progress.create!(
            context: sub_account,
            tag: "lti_tii_ap_migration",
            workflow_state: "running",
            completion: 50,
            message: "Processing..."
          )
        end

        before do
          create_tool_proxy(context: sub_account)
          progress
        end

        it "includes migration progress in response" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)

          data = response.parsed_body
          sub_account_data = data.find { |d| d["account_id"] == sub_account.id }

          expect(sub_account_data["migration_progress"]).to include(
            "id" => progress.id,
            "workflow_state" => "running",
            "completion" => 50.0,
            "message" => "Processing..."
          )
        end

        it "returns the newest progress record when multiple exist" do
          old_progress = Progress.create!(
            context: sub_account,
            tag: "lti_tii_ap_migration",
            workflow_state: "completed",
            completion: 100,
            message: "Old migration completed",
            created_at: 2.days.ago
          )

          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)

          data = response.parsed_body
          sub_account_data = data.find { |d| d["account_id"] == sub_account.id }

          expect(sub_account_data["migration_progress"]).to include(
            "id" => progress.id,
            "workflow_state" => "running",
            "completion" => 50.0,
            "message" => "Processing..."
          )
          expect(sub_account_data["migration_progress"]["id"]).not_to eq(old_progress.id)
        end
      end

      context "when tool proxy workflow_state is not active" do
        before do
          create_tool_proxy(context: sub_account, workflow_state: "deleted")
        end

        it "does not include accounts with deleted tool proxies" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([])
        end
      end

      context "when tool proxy is for a different vendor" do
        before do
          other_product_family = Lti::ProductFamily.create!(
            vendor_code: "other_vendor.com",
            product_code: "other-product",
            vendor_name: "Other Vendor",
            vendor_description: "Other Product",
            website: "http://www.other.com/",
            vendor_email: "support@other.com",
            root_account:
          )
          create_tool_proxy(context: sub_account, product_family_override: other_product_family)
        end

        it "does not include accounts with non-TurnItIn tool proxies" do
          get :index, params: { account_id: root_account.id }
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([])
        end
      end
    end

    context "when user does not have manage_lti_registrations permission" do
      before { user_session(student_in_course(account: root_account).user) }

      it "returns forbidden" do
        get :index, params: { account_id: root_account.id }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get :index, params: { account_id: root_account.id }
        expect(response).to redirect_to(login_url)
      end
    end

    context "when requesting from a sub-account" do
      before do
        user_session(admin)
      end

      it "returns not found" do
        get :index, params: { account_id: sub_account.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST #create" do
    let(:root_account) { account_model }
    let(:sub_account) { account_model(parent_account: root_account, root_account:) }
    let(:admin) { account_admin_user(account: root_account) }

    before do
      root_account.enable_feature!(:lti_asset_processor_tii_migration)
    end

    context "when user is root account admin" do
      before do
        user_session(admin)
      end

      it "creates a progress and enqueues a job" do
        expect do
          post :create, params: { account_id: sub_account.id, email: "test@example.com" }
        end.to change(Progress, :count).by(1).and change(Delayed::Job, :count).by(1)

        expect(response).to have_http_status(:ok)

        data = response.parsed_body
        expect(data).to include("id", "workflow_state", "completion")
        expect(data["workflow_state"]).to eq("queued")

        progress = Progress.find(data["id"])
        expect(progress.context).to eq(sub_account)
        expect(progress.tag).to eq("lti_tii_ap_migration")
        expect(progress.user).to eq(admin)
      end

      it "creates a progress for root account" do
        expect do
          post :create, params: { account_id: root_account.id, email: "test@example.com" }
        end.to change(Progress, :count).by(1)

        expect(response).to have_http_status(:ok)

        progress = Progress.find(response.parsed_body["id"])
        expect(progress.context).to eq(root_account)
      end

      it "returns not found for non-existent account" do
        post :create, params: { account_id: 0, email: "test@example.com" }
        expect(response).to have_http_status(:not_found)
      end

      it "enqueues job with strand parameter" do
        post :create, params: { account_id: sub_account.id, email: "test@example.com" }

        expect(response).to have_http_status(:ok)

        job = Delayed::Job.last
        expect(job.strand).to eq("tii_migration_account_#{sub_account.global_id}")
      end

      context "when there is already a pending migration" do
        it "returns existing queued progress instead of creating a new one" do
          existing_progress = Progress.create!(
            context: sub_account,
            tag: "lti_tii_ap_migration",
            workflow_state: "queued",
            user: admin
          )

          expect do
            post :create, params: { account_id: sub_account.id, email: "test@example.com" }
          end.not_to change(Progress, :count)

          expect(response).to have_http_status(:ok)
          data = response.parsed_body
          expect(data["id"]).to eq(existing_progress.id)
        end

        it "creates new progress when existing one is completed" do
          Progress.create!(
            context: sub_account,
            tag: "lti_tii_ap_migration",
            workflow_state: "completed",
            user: admin
          )

          expect do
            post :create, params: { account_id: sub_account.id, email: "test@example.com" }
          end.to change(Progress, :count).by(1)

          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when user does not have manage_lti_registrations permission" do
      before { user_session(student_in_course(account: root_account).user) }

      it "returns forbidden" do
        post :create, params: { account_id: sub_account.id, email: "test@example.com" }, format: :json
        expect(response).to be_forbidden
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        post :create, params: { account_id: sub_account.id, email: "test@example.com" }
        expect(response).to redirect_to(login_url)
      end
    end
  end
end
