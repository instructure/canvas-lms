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

require_relative '../../spec_helper'

describe MicrosoftSync::Syncer do
  let(:syncer) { described_class.new(group) }
  let(:course) do
    course_model(name: 'sync test course')
  end
  let(:group) { MicrosoftSync::Group.create(course: course) }
  let(:graph_service) { double('GraphService') }
  let(:canvas_graph_service) { double('CanvasGraphService', graph_service: graph_service) }
  let(:tenant) { 'mytenant123' }

  def expect_next_step(result, next_step, memory_state=nil)
    expect(result).to be_a(MicrosoftSync::StateMachineJob::NextStep)
    expect { syncer.method(next_step.to_sym) }.to_not raise_error
    expect(result.next_step).to eq(next_step)
    expect(result.memory_state).to eq(memory_state)
  end

  def expect_retry(result, error_class:, delay_amount: nil, job_state_data: nil)
    expect(result).to be_a(MicrosoftSync::StateMachineJob::Retry)
    expect(result.error.class).to eq(error_class)
    expect(result.delay_amount).to eq(delay_amount)
    expect(result.delay_amount.to_i).to be < syncer.restart_job_after_inactivity.to_i
    expect(result.job_state_data).to eq(job_state_data)
  end

  def new_http_error(code)
    MicrosoftSync::Errors::HTTPInvalidStatus.for(
      response: double('response', code: code, body: ''),
      service: 'test',
      tenant: 'test'
    )
  end

  before do
    ra = course.root_account
    ra.settings[:microsoft_sync_tenant] = tenant
    ra.save!

    allow(MicrosoftSync::CanvasGraphService).to \
      receive(:new).with(tenant).and_return(canvas_graph_service)
  end

  describe '#initial_step' do
    subject { syncer.initial_step }

    it { is_expected.to eq(:step_ensure_class_group_exists) }
    it 'references an existing method' do
      expect { syncer.method(subject.to_sym) }.to_not raise_error
    end
  end

  describe '#max_retries' do
    subject { syncer.max_retries }

    it { is_expected.to eq(4) }
  end

  describe '#step_ensure_class_group_exists' do
    subject { syncer.step_ensure_class_group_exists(nil, nil) }

    before do
      allow(canvas_graph_service).to receive(:list_education_classes_for_course)
        .with(course).and_return(education_class_ids.map{|id| {'id' => id}})
    end

    shared_examples_for 'a group record which requires a new or updated MS group' do
      let(:education_class_ids) { [] }

      context 'when no remote MS group exists for the course' do
        # admin deleted the MS group we created, or a group never existed

        it 'creates a new MS group and goes to the "update group" step' do
          expect(canvas_graph_service).to \
            receive(:create_education_class).with(course).and_return('id' => 'newid')

          expect_next_step(subject, :step_update_group_with_course_data, 'newid')
        end
      end

      context "when there is a remote MS group but it doesn't match our ms_group_id in the DB" do
        let(:education_class_ids) { ['newid2'] }

        it 'goes to the "update group" step with the remote group ID' do
          expect(canvas_graph_service).to_not receive(:create_education_class)

          expect_next_step(subject, :step_update_group_with_course_data, 'newid2')
        end
      end

      context 'when there is more than one remote MS group for the course' do
        let(:education_class_ids) { [group.ms_group_id || 'someid', 'newid3'] }

        it 'raises an InvalidRemoteState error' do
          expect { subject }.to raise_error(
            MicrosoftSync::Errors::InvalidRemoteState,
            'Multiple Microsoft education classes exist for the course.'
          )
        end
      end

      context 'when the tenant is not set in the account settings' do
        let(:tenant) { nil }

        it 'raises a graceful cleanup error with a end-user-friendly name' do
          expect(MicrosoftSync::CanvasGraphService).to_not receive(:new)
          expect(syncer).to_not receive(:ensure_class_group_exists)
          begin
            subject
          rescue => e
          end
          expect(e).to be_a(described_class::TenantMissingOrSyncDisabled)
          expect(e).to be_a(MicrosoftSync::StateMachineJob::GracefulCancelErrorMixin)
        end
      end
    end

    context "when we don't have a ms_group_id" do
      it_behaves_like 'a group record which requires a new or updated MS group'
    end

    context 'when we have a ms_group_id' do
      before { group.update!(ms_group_id: 'oldid') }

      it_behaves_like 'a group record which requires a new or updated MS group'

      context 'when that group is the only remote MS group for the course' do
        let(:education_class_ids) { ['oldid'] }

        it 'does not modify or create any group' do
          expect(canvas_graph_service).to_not receive(:create_education_class)
          expect(canvas_graph_service).to_not receive(:update_group_with_course_data)
          expect { subject }.to_not change { group.reload.ms_group_id }
          expect_next_step(subject, :step_ensure_enrollments_user_mappings_filled)
        end
      end
    end
  end

  describe '#step_update_group_with_course_data' do
    shared_examples_for 'updating group with course data' do
      context 'on success' do
        it 'updates the LMS metadata, sets ms_group_id, and goes to the next step' do
          expect(canvas_graph_service).to \
            receive(:update_group_with_course_data).with('newid', course)

          expect { subject }.to change { group.reload.ms_group_id }.to('newid')
          expect_next_step(subject, :step_ensure_enrollments_user_mappings_filled)
        end
      end

      context 'on 404' do
        it 'retries with a delay' do
          expect(canvas_graph_service).to \
            receive(:update_group_with_course_data).with('newid', course)
            .and_raise(new_http_error(404))
          expect { subject }.to_not change { group.reload.ms_group_id }
          expect_retry(
            subject, error_class: MicrosoftSync::Errors::HTTPNotFound,
            delay_amount: 45.seconds, job_state_data: 'newid'
          )
        end
      end

      context 'on other failure' do
        it 'bubbles up the error' do
          expect(canvas_graph_service).to \
            receive(:update_group_with_course_data).with('newid', course)
            .and_raise(new_http_error(400))
          expect { subject }.to raise_error(MicrosoftSync::Errors::HTTPBadRequest)
        end
      end
    end

    context 'when run for the first time with a new_group_id' do
      subject { syncer.step_update_group_with_course_data('newid', nil) }

      it_behaves_like 'updating group with course data'
    end

    context 'when retrying' do
      subject do
        syncer.step_update_group_with_course_data(nil, 'newid')
      end

      it_behaves_like 'updating group with course data'
    end
  end

  describe '#step_ensure_enrollments_user_mappings_filled' do
    subject { syncer.step_ensure_enrollments_user_mappings_filled(nil, nil) }

    let(:batch_size) { 4 }

    let!(:students) do
      n_students_in_course(batch_size - 1, course: course)
    end

    let!(:teachers) do
      [teacher_in_course(course: course), teacher_in_course(course: course)].map(&:user)
    end

    let(:mappings) do
      MicrosoftSync::UserMapping.where(root_account_id: course.root_account_id)
    end

    before do
      stub_const('MicrosoftSync::CanvasGraphService::USERS_UPNS_TO_AADS_BATCH_SIZE', batch_size)

      students.each_with_index do |student, i|
        communication_channel(student, path_type: 'email', username: "student#{i}@example.com")
      end
      teachers.each_with_index do |teacher, i|
        communication_channel(teacher, path_type: 'email', username: "teacher#{i}@example.com")
      end

      allow(canvas_graph_service).to receive(:users_upns_to_aads) do |upns|
        raise "max batchsize stubbed at #{batch_size}" if upns.length > batch_size

        upns.map{|upn| [upn, upn.gsub(/@.*/, '-aad')]}.to_h # UPN "abc@def.com" -> AAD "abc-aad"
      end
    end

    it 'creates a mapping for each of the enrollments' do
      expect_next_step(subject, :step_generate_diff)
      expect(mappings.pluck(:user_id, :aad_id).sort).to eq(
        students.each_with_index.map{|student, n| [student.id, "student#{n}-aad"]}.sort +
        teachers.each_with_index.map{|teacher, n| [teacher.id, "teacher#{n}-aad"]}.sort
      )
    end

    it 'batches in sizes of CanvasGraphService::USERS_UPNS_TO_AADS_BATCH_SIZE' do
      expect(canvas_graph_service).to receive(:users_upns_to_aads).twice.and_return({})
      expect_next_step(subject, :step_generate_diff)
    end

    context "when Microsoft doesn't have AADs for the UPNs" do
      it "doesn't add any UserMappings" do
        expect(canvas_graph_service).to receive(:users_upns_to_aads).
          at_least(:once).and_return({})
        expect { subject }.to_not \
          change { MicrosoftSync::UserMapping.count }.from(0)
        expect_next_step(subject, :step_generate_diff)
      end
    end

    context 'when some users already have a mapping for that root account id' do
      before do
        MicrosoftSync::UserMapping.create!(
          user: students.first, root_account_id: course.root_account_id, aad_id: 'manualstudent1'
        )
        MicrosoftSync::UserMapping.create!(
          user: students.second, root_account_id: 0, aad_id: 'manualstudent2-wrong-rootaccount'
        )
      end

      it "doesn't lookup aads for those users" do
        upns_looked_up = []
        expect(canvas_graph_service).to receive(:users_upns_to_aads) do |upns|
          upns_looked_up += upns
          {}
        end
        expect_next_step(subject, :step_generate_diff)
        expect(upns_looked_up).to_not include("student0@example.com")
        expect(upns_looked_up).to include("student1@example.com")
      end
    end
  end

  describe '#step_generate_diff' do
    subject { syncer.step_generate_diff(nil, nil) }

    before do
      course.enrollments.to_a.each_with_index do |enrollment, i|
        MicrosoftSync::UserMapping.create!(
          user_id: enrollment.user_id, root_account_id: course.root_account_id, aad_id: i.to_s
        )
      end

      group.update!(ms_group_id: 'mygroup')
    end

    it 'gets members and owners and builds a diff' do
      expect(canvas_graph_service).to \
        receive(:get_group_users_aad_ids).with('mygroup').and_return(%w[m1 m2])
      expect(canvas_graph_service).to \
        receive(:get_group_users_aad_ids).with('mygroup', owners: true).and_return(%w[o1 o2])

      diff = double('MembershipDiff')
      expect(MicrosoftSync::MembershipDiff).to \
        receive(:new).with(%w[m1 m2], %w[o1 o2]).and_return(diff)
      members_and_enrollment_types = []
      expect(diff).to receive(:set_local_member) { |*args| members_and_enrollment_types << args }

      expect_next_step(subject, :step_execute_diff, diff)
      expect(members_and_enrollment_types).to eq([['0', 'TeacherEnrollment']])
    end
  end

  describe '#execute_diff' do
    subject { syncer.step_execute_diff(diff, nil) }

    let(:diff) { double('MembershipDiff') }

    before { group.update!(ms_group_id: 'mygroup') }

    it 'adds/removes users based on the diff' do
      expect(diff).to receive(:owners_to_remove).and_return(Set.new(%w[o1]))
      expect(diff).to receive(:members_to_remove).and_return(Set.new(%w[m1 m2]))
      expect(diff).to \
        receive(:additions_in_slices_of).
        with(MicrosoftSync::GraphService::GROUP_USERS_ADD_BATCH_SIZE).
        and_yield(owners: %w[o3], members: %w[o1 o2]).
        and_yield(members: %w[o3])

      expect(graph_service).to receive(:remove_group_member).once.with('mygroup', 'm1')
      expect(graph_service).to receive(:remove_group_member).once.with('mygroup', 'm2')
      expect(graph_service).to receive(:remove_group_owner).once.with('mygroup', 'o1')
      expect(graph_service).to \
        receive(:add_users_to_group).with('mygroup', owners: %w[o3], members: %w[o1 o2])
      expect(graph_service).to \
        receive(:add_users_to_group).with('mygroup', members: %w[o3])

      expect_next_step(subject, :step_ensure_team_exists)
    end
  end

  describe '#ensure_team_exists' do
    subject { syncer.step_ensure_team_exists(nil, nil) }

    before { group.update!(ms_group_id: 'mygroupid') }

    context 'when there are no teacher/ta/designer enrollments' do
      it "doesn't check for team existence or create a team" do
        course.enrollments.to_a.each do |e|
          e.destroy if e.type =~ /^Teacher|Ta|Designer/
        end
        expect(graph_service).to_not receive(:team_exists?)
        expect(graph_service).to_not receive(:create_team)
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end
    end

    context 'when the team already exists' do
      it "doesn't create a team" do
        expect(graph_service).to receive(:team_exists?).with('mygroupid').and_return(true)
        expect(graph_service).to_not receive(:create_team)
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end
    end

    context "when the team doesn't exist" do
      before do
        allow(graph_service).to receive(:team_exists?).with('mygroupid').and_return(false)
      end

      it 'creates the team' do
        expect(graph_service).to receive(:create_education_class_team).with('mygroupid')
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end

      context 'when the Microsoft API errors with "group has no owners"' do
        it "retries in 1 minute" do
          expect(graph_service).to receive(:create_education_class_team).with('mygroupid').
            and_raise(MicrosoftSync::Errors::GroupHasNoOwners)
          expect_retry(
            subject,
            error_class: MicrosoftSync::Errors::GroupHasNoOwners,
            delay_amount: 1.minute
          )
        end
      end

      context "when the Microsoft API errors with a 404 (e.g., group doesn't exist)" do
        it "retries in 1 minute" do
          expect(graph_service).to \
            receive(:create_education_class_team).with('mygroupid').and_raise(new_http_error(404))
          expect_retry(
            subject,
            error_class: MicrosoftSync::Errors::HTTPNotFound,
            delay_amount: 1.minute
          )
        end
      end

      context 'when the Microsoft API errors with some other error' do
        it "bubbles up the error" do
          expect(graph_service).to \
            receive(:create_education_class_team).with('mygroupid').
            and_raise(new_http_error(400))
          expect { subject }.to raise_error(MicrosoftSync::Errors::HTTPBadRequest)
        end
      end
    end
  end
end
