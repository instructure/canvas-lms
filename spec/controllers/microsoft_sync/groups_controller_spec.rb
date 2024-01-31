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

require "microsoft_sync/membership_diff"

describe MicrosoftSync::GroupsController do
  let!(:group) { MicrosoftSync::Group.create!(course:, workflow_state:) }

  let(:course_id) { course.id }
  let(:feature) { :microsoft_group_enrollments_syncing }
  let(:params) { { course_id: } }
  let(:student) { course.student_enrollments.first.user }
  let(:teacher) { course.teacher_enrollments.first.user }
  let(:workflow_state) { :completed }
  let(:root_account) { course.root_account }
  let(:course) do
    course_with_student(active_all: true)
    @course
  end

  before do
    root_account.enable_feature! feature
    root_account.settings[:microsoft_sync_enabled] = true
    root_account.save!
  end

  shared_examples_for "endpoints that respond with 404 when records do not exist" do
    context "when the course does not exist" do
      before { course.destroy! }

      it { is_expected.to be_not_found }
    end

    context "when the course has no active microsoft group" do
      before { group.destroy! }

      it { is_expected.to be_not_found }
    end
  end

  shared_examples_for "endpoints that require a user" do
    context "when there is no user" do
      before { remove_user_session }

      it { is_expected.to redirect_to "/login" }
    end
  end

  shared_examples_for "endpoints that require permissions" do
    let(:user) { raise "set in examples" }

    context "when the user does not have the required permissions" do
      let(:unauthorized_user) { student }

      before { user_session(unauthorized_user) }

      it { is_expected.to be_unauthorized }
    end

    context "when the user has the update permission but not manage_students" do
      before do
        account_with_role_changes(role: teacher_role, role_changes: { manage_students: false })
        user_session(teacher)
      end

      it { is_expected.to_not be_unauthorized }
    end
  end

  shared_examples_for "endpoints that require a release flag to be on" do
    context "when the release flag is off" do
      before { root_account.disable_feature! feature }

      it { is_expected.to be_not_found }
    end
  end

  shared_examples_for "endpoints that return an existing group" do
    before { group.reload.update!(job_state: { step: "abc" }, last_error_report_id: 123) }

    specify { expect(subject.parsed_body).to_not include("job_state") }
    specify { expect(subject.parsed_body).to_not include("last_error_report_id") }

    context "when the user is a site admin" do
      before { user_session(site_admin) }

      let(:site_admin) { site_admin_user(user: user_with_pseudonym(account: Account.site_admin)) }

      specify { expect(subject.parsed_body).to_not include("job_state") }
      specify { expect(subject.parsed_body["last_error_report_id"]).to eq(123) }
    end

    it "deserializes and localizes the error" do
      serialized = MicrosoftSync::Errors.serialize(StandardError.new)
      group.update! last_error: serialized
      allow(MicrosoftSync::Errors).to receive(:deserialize_and_localize).and_call_original
      subject
      expect(MicrosoftSync::Errors).to have_received(:deserialize_and_localize).with(serialized)
    end
  end

  shared_examples_for "endpoints that require the integration to be available" do
    before do
      root_account.settings[:microsoft_sync_enabled] = false
      root_account.save!
    end

    it { is_expected.to be_bad_request }
  end

  describe "#sync" do
    subject { post :sync, params: }

    before { user_session(teacher) }

    it_behaves_like "endpoints that require a user"
    it_behaves_like "endpoints that require permissions"
    it_behaves_like "endpoints that require a release flag to be on"
    it_behaves_like "endpoints that return an existing group"
    it_behaves_like "endpoints that require the integration to be available"

    it { is_expected.to be_successful }

    it "schedules a sync" do
      expect_any_instance_of(MicrosoftSync::StateMachineJob).to receive(
        :run_later
      ).once
      subject
    end

    it 'updates the group state to "manually_scheduled"' do
      subject
      expect(group.reload.workflow_state).to eq "manually_scheduled"
    end

    context 'when the group is in a "running" state' do
      let(:workflow_state) { MicrosoftSync::Group::RUNNING_STATES.first }

      it { is_expected.to be_bad_request }

      it "responds with an error" do
        subject
        expect(json_parse["errors"]).to match_array [
          "A sync job is already running for the specified group"
        ]
      end
    end

    context "when the cool down period has not passed" do
      before { group.update!(last_manually_synced_at: Time.zone.now) }

      it { is_expected.to be_bad_request }

      it "responds with an error" do
        subject
        expect(json_parse["errors"]).to match_array [
          "Not enough time elapsed since last manual sync"
        ]
      end

      context "and the current user is a site admin" do
        before { user_session(site_admin) }

        let(:site_admin) { site_admin_user(user: user_with_pseudonym(account: Account.site_admin)) }

        it { is_expected.to be_successful }
      end

      context 'and the group is in a "ready state"' do
        let(:workflow_state) { :errored }

        it { is_expected.to be_successful }
      end
    end
  end

  describe "#create" do
    subject { post :create, params: }

    before { user_session(teacher) }

    it_behaves_like "endpoints that require a user"
    it_behaves_like "endpoints that require permissions"
    it_behaves_like "endpoints that require a release flag to be on"
    it_behaves_like "endpoints that require the integration to be available"

    context "when the course does not exist" do
      before { course.destroy! }

      it { is_expected.to be_not_found }
    end

    context "when a deleted group exists for the course" do
      subject do
        super()
        json_parse
      end

      before do
        group.update!(
          job_state: :membership_fetched,
          last_error: "something bad happened",
          workflow_state: "errored"
        )
        group.destroy!
      end

      it 'responds with "created"' do
        subject
        expect(response).to be_created
      end

      it "reactivates the existing group" do
        expect(subject["id"]).to eq group.id
      end

      it "clears the job state" do
        expect(subject["job_state"]).to be_blank
      end

      it "clears the last error" do
        expect(subject["last_error"]).to be_blank
      end

      it "resets the workflow state" do
        expect(subject["workflow_state"]).to eq "pending"
      end
    end

    context "when an active group already exists for the course" do
      it 'responds with "conflict"' do
        expect(subject.status).to eq 409
      end
    end

    context "when no group exists for the course" do
      subject do
        super()
        json_parse
      end

      before { group.destroy_permanently! }

      it 'responds with "created"' do
        subject
        expect(response).to have_http_status :created
      end

      it "creates a new group" do
        expect(subject).to match(
          JSON.parse(
            MicrosoftSync::Group.find(subject["id"]).to_json(
              include_root: false,
              except: %i[job_state last_error_report_id]
            )
          )
        )
      end

      context "when too many owners are enrolled in the course" do
        before { 3.times { teacher_in_course(course:, active_enrollment: true) } }

        before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS", 2) }

        it 'responds with "unprocessable_entity" and an error message' do
          subject
          expect(response.parsed_body["message"]).to match(
            /allows a maximum of 2 owners/
          )
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context "when too many members are enrolled in the course" do
        before { 3.times { student_in_course(course:, active_enrollment: true) } }

        before { stub_const("MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS", 2) }

        it 'responds with "unprocessable_entity" and an error message' do
          subject
          expect(response.parsed_body["message"]).to match(
            /allows a maximum of 2 members/
          )
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end
  end

  describe "#deleted" do
    subject { delete :destroy, params: }

    before { user_session(teacher) }

    it_behaves_like "endpoints that respond with 404 when records do not exist"
    it_behaves_like "endpoints that require a user"
    it_behaves_like "endpoints that require permissions"
    it_behaves_like "endpoints that require a release flag to be on"
    it_behaves_like "endpoints that require the integration to be available"

    it { is_expected.to be_no_content }

    it "destroys the group" do
      subject
      expect(group.reload).to be_deleted
    end
  end

  describe "#show" do
    subject { get :show, params: }

    before { user_session(teacher) }

    it_behaves_like "endpoints that respond with 404 when records do not exist"
    it_behaves_like "endpoints that require a user"
    it_behaves_like "endpoints that require permissions"
    it_behaves_like "endpoints that require a release flag to be on"
    it_behaves_like "endpoints that return an existing group"
    it_behaves_like "endpoints that require the integration to be available"

    it { is_expected.to be_successful }

    it "responds with the expected group" do
      subject
      expect(json_parse).to eq(
        JSON.parse(group.to_json(include_root: false, except: %i[job_state last_error_report_id]))
      )
    end

    describe "when there is debug info present on the entry" do
      let(:debug_info) { [{ "msg" => "Some fake debug info", "timestamp" => "2020-01-01T00:00:00Z" }] }

      before { group.update debug_info:, last_error_report: ErrorReport.create! }

      context "when the user is SiteAdmin" do
        before { user_session(site_admin) }

        let(:site_admin) { site_admin_user(user: user_with_pseudonym(account: Account.site_admin)) }

        it "includes the debugging info and error report id" do
          expect(subject).to be_successful
          expect(json_parse["debug_info"]).to eq(debug_info)
          expect(json_parse["last_error_report_id"]).to eq(group.last_error_report.id)
        end
      end

      context "when the user is not SiteAdmin" do
        it "does not include the debugging info or last error report id" do
          expect(subject).to be_successful
          expect(json_parse["debug_info"]).to be_nil
          expect(json_parse["last_error_report_id"]).to be_nil
        end
      end
    end
  end
end
