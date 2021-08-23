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

describe MicrosoftSync::SyncerSteps do
  let(:syncer_steps) { described_class.new(group) }
  let(:course) do
    course_model(name: 'sync test course')
  end
  let(:group) { MicrosoftSync::Group.create(course: course) }
  let(:graph_service_helpers) do
    instance_double(MicrosoftSync::GraphServiceHelpers,
                    graph_service: instance_double(MicrosoftSync::GraphService))
  end
  let(:graph_service) { graph_service_helpers.graph_service }
  let(:tenant) { 'mytenant123' }
  let(:sync_enabled) { true }
  let(:sync_type_statsd_tag) { 'full' }

  def expect_next_step(result, step, memory_state=nil)
    expect(result).to be_a(MicrosoftSync::StateMachineJob::NextStep)
    expect { syncer_steps.method(step.to_sym) }.to_not raise_error
    expect(result.step).to eq(step)
    expect(result.memory_state).to eq(memory_state)
  end

  def expect_delayed_next_step(result, step, delay_amount, job_state_data=nil)
    expect(result).to be_a(MicrosoftSync::StateMachineJob::DelayedNextStep)
    expect { syncer_steps.method(step.to_sym) }.to_not raise_error
    expect(result.step).to eq(step)
    expect(result.delay_amount).to eq(delay_amount)
    expect(result.job_state_data).to eq(job_state_data)
  end

  def expect_retry(result, error_class:, delay_amount: nil, job_state_data: nil, step: nil)
    expect(result).to be_a(MicrosoftSync::StateMachineJob::Retry)
    expect(result.error.class).to eq(error_class)
    expect(result.delay_amount).to eq(delay_amount)
    # Check that we haven't specified any delays too big for our max_delay
    [result.delay_amount].flatten.each do |delay|
      expect(delay.to_i).to be < syncer_steps.max_delay.to_i
    end
    expect(result.job_state_data).to eq(job_state_data)
    expect(result.step).to eq(step)
    if step
      expect { syncer_steps.method(step.to_sym) }.to_not raise_error
    end
  end

  def new_http_error(code, headers={})
    MicrosoftSync::Errors::HTTPInvalidStatus.for(
      response: double(
        'response', code: code, body: '', headers: HTTParty::Response::Headers.new(headers)
      ),
      service: 'test',
      tenant: 'test'
    )
  end

  before do
    ra = course.root_account
    ra.settings[:microsoft_sync_enabled] = sync_enabled
    ra.settings[:microsoft_sync_tenant] = tenant
    ra.settings[:microsoft_sync_login_attribute] = 'email'
    ra.settings[:microsoft_sync_remote_attribute] = 'mail'
    ra.save!

    allow(MicrosoftSync::GraphServiceHelpers).to \
      receive(:new).with(tenant, sync_type: sync_type_statsd_tag).and_return(graph_service_helpers)
  end

  describe '#max_retries' do
    subject { syncer_steps.max_retries }

    it { is_expected.to eq(3) }
  end

  describe '#after_failure' do
    it 'is defined' do
      # expand once we start using this (will be soon, when we stash
      # in-progress paginated results when getting group members)
      expect(syncer_steps.after_failure).to eq(nil)
    end
  end

  describe '#after_complete' do
    it 'sets last_synced_at on the group' do
      Timecop.freeze do
        expect { syncer_steps.after_complete }.to \
          change { group.reload.last_synced_at }.from(nil).to(Time.zone.now)
      end
    end
  end

  shared_examples_for 'a step that returns retry on intermittent error' do |options={}|
    # use actual graph service instead of double and intercept calls to "request":
    let(:graph_service_helpers) { MicrosoftSync::GraphServiceHelpers.new(tenant, {}) }
    let(:retry_args) { {delay_amount: [15, 60, 300]}.merge(options[:retry_args] || {}) }

    [EOFError, Errno::ECONNRESET, Timeout::Error].each do |error_class|
      context "when hitting the Microsoft API raises a #{error_class}" do
        it 'returns a Retry object' do
          expect(graph_service.http).to receive(:request).and_raise(error_class.new)
          expect_retry(subject, error_class: error_class, **retry_args)
        end
      end
    end

    context "when the Microsoft API returns a 500" do
      it 'returns a Retry object' do
        expect(graph_service.http).to receive(:request).and_raise(new_http_error(500))
        expect_retry(subject,
                     error_class: MicrosoftSync::Errors::HTTPInternalServerError, **retry_args)
      end
    end

    unless options[:except_404]
      context 'on 404' do
        it 'goes back to step_generate_diff with a delay' do
          expect(graph_service.http).to receive(:request).and_raise(new_http_error(404))
          expect_retry(subject,
                       error_class: MicrosoftSync::Errors::HTTPNotFound, **retry_args)
        end
      end
    end

    unless options[:except_throttled]
      context 'when the Microsoft API returns a 429 with a retry-after header' do
        it 'returns a Retry object with that retry-after time' do
          expect(graph_service.http).to receive(:request).and_raise(
            new_http_error(429, 'retry-after' => '3.14')
          )
          expect_retry(subject,
                       error_class: MicrosoftSync::Errors::HTTPTooManyRequests,
                       **retry_args.merge(delay_amount: 3.14))
        end
      end

      context 'when the Microsoft API returns a BatchRequestThrottled with a retry-after time' do
        it 'returns a Retry object with that retry-after time' do
          err = MicrosoftSync::GraphServiceHttp::BatchRequestThrottled.new('foo', [])
          expect(err).to receive(:retry_after_seconds).and_return(1.23)
          expect(graph_service.http).to receive(:request).and_raise(err)
          expect_retry(subject, error_class: err.class, **retry_args.merge(delay_amount: 1.23))
        end
      end

      context 'when the Microsoft API returns a 429 with no retry-after header' do
        it 'returns a Retry object with our default retry times' do
          expect(graph_service.http).to receive(:request).and_raise(new_http_error(429))
          expect_retry(subject,
                       error_class: MicrosoftSync::Errors::HTTPTooManyRequests, **retry_args)
        end
      end
    end
  end

  shared_examples_for 'max of members enrollment reached' do |max_members|
    it 'raises a graceful exit error informing the user' do
      klass = MicrosoftSync::SyncerSteps::MaxMemberEnrollmentsReached
      msg =
        "Microsoft 365 allows a maximum of #{(max_members || 25000).to_s(:delimited)} " \
        'members in a team.'
      expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
    end
  end

  shared_examples_for 'max of owners enrollment reached' do |max_owners|
    it 'raises a graceful exit error informing the user' do
      klass = MicrosoftSync::SyncerSteps::MaxOwnerEnrollmentsReached
      msg = "Microsoft 365 allows a maximum of #{max_owners || 100} owners in a team."
      expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
    end
  end

  describe '#step_initial' do
    it 'does a partial sync when initial_mem_state is :partial' do
      expect_next_step(syncer_steps.step_initial(:partial, nil), :step_partial_sync)
    end

    it 'does a partial sync when initial_mem_state is "partial"' do
      expect_next_step(syncer_steps.step_initial('partial', nil), :step_partial_sync)
    end

    it 'starts a full sync when when initial_mem_state is nil' do
      expect_next_step(syncer_steps.step_initial(nil, nil),
                       :step_full_sync_prerequisites)
    end
  end

  describe '#step_full_sync_prerequisites' do
    subject { syncer_steps.step_full_sync_prerequisites(nil, nil) }

    before do
      n_students_in_course(2, course: course)
      teacher_in_course(course: course)
      teacher_in_course(course: course)
    end

    context 'when the max enrollments in a course was not reached' do
      it 'schedule the next step `step_ensure_class_group_exists`' do
        expect_next_step(subject, :step_ensure_class_group_exists)
      end
    end

    context 'when max members enrollments was reached in a course' do
      before do
        stub_const('MicrosoftSync::SyncerSteps::MAX_ENROLLMENT_MEMBERS', 3)
      end

      it_should_behave_like 'max of members enrollment reached', 3
    end

    context 'when max owners enrollments was reached in a course' do
      before do
        stub_const('MicrosoftSync::SyncerSteps::MAX_ENROLLMENT_OWNERS', 1)
      end

      it_behaves_like 'max of owners enrollment reached', 1
    end

    it 'deletes the partial sync changes for the course' do
      expect(MicrosoftSync::PartialSyncChange).to \
        receive(:delete_all_replicated_to_secondary_for_course).with(course.id)
      subject
    end
  end

  describe '#step_ensure_class_group_exists' do
    subject { syncer_steps.step_ensure_class_group_exists(nil, nil) }

    before do
      allow(graph_service_helpers).to receive(:list_education_classes_for_course)
        .with(course).and_return(education_class_ids.map{|id| {'id' => id}})
    end

    shared_examples_for 'a group record which requires a new or updated MS group' do
      let(:education_class_ids) { [] }

      it_behaves_like 'a step that returns retry on intermittent error', except_404: true

      context 'when no remote MS group exists for the course' do
        # admin deleted the MS group we created, or a group never existed

        it 'creates a new MS group and goes to the "update group" step' do
          expect(graph_service_helpers).to \
            receive(:create_education_class).with(course).and_return('id' => 'newid')

          expect_delayed_next_step(
            subject, :step_update_group_with_course_data, 8.seconds, 'newid'
          )
        end
      end

      context "when there is a remote MS group but it doesn't match our ms_group_id in the DB" do
        let(:education_class_ids) { ['newid2'] }

        it 'goes to the "update group" step with the remote group ID' do
          expect(graph_service_helpers).to_not receive(:create_education_class)

          expect_delayed_next_step(
            subject, :step_update_group_with_course_data, 8.seconds, 'newid2'
          )
        end
      end

      context 'when there is more than one remote MS group for the course' do
        let(:education_class_ids) { [group.ms_group_id || 'someid', 'newid3'] }

        it 'raises a descriptive Graceful Cancel Error' do
          klass = described_class::MultipleEducationClasses
          msg = 'Multiple Microsoft education classes already exist for the course.'
          expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
        end
      end

      shared_examples_for 'missing the correct account settings' do
        it 'raises a graceful cleanup error with a end-user-friendly message' do
          expect(MicrosoftSync::GraphServiceHelpers).to_not receive(:new)
          expect(syncer_steps).to_not receive(:ensure_class_group_exists)
          klass = described_class::TenantMissingOrSyncDisabled
          msg =
            'Tenant missing or sync disabled. ' \
            'Check the Microsoft sync integration settings for the course and account.'
          expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
        end
      end

      context 'when the tenant is not set in the account settings' do
        let(:tenant) { nil }

        it_behaves_like 'missing the correct account settings'
      end

      context 'when the microsoft_sync_enabled is false in the account settings' do
        let(:sync_enabled) { false }

        it_behaves_like 'missing the correct account settings'
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
          expect(graph_service_helpers).to_not receive(:create_education_class)
          expect(graph_service_helpers).to_not receive(:update_group_with_course_data)
          expect { subject }.to_not change { group.reload.ms_group_id }
          expect_next_step(subject, :step_ensure_enrollments_user_mappings_filled)
        end
      end
    end
  end

  describe '#step_update_group_with_course_data' do
    subject do
      syncer_steps.step_update_group_with_course_data(nil, 'newid')
    end

    it_behaves_like 'a step that returns retry on intermittent error',
                    retry_args: {job_state_data: 'newid'}

    context 'on success' do
      it 'updates the LMS metadata, sets ms_group_id, and goes to the next step' do
        expect(graph_service_helpers).to \
          receive(:update_group_with_course_data).with('newid', course)

        expect { subject }.to change { group.reload.ms_group_id }.to('newid')
        expect_next_step(subject, :step_ensure_enrollments_user_mappings_filled)
      end
    end

    context 'on other failure' do
      it 'bubbles up the error' do
        expect(graph_service_helpers).to \
          receive(:update_group_with_course_data).with('newid', course)
          .and_raise(new_http_error(400))
        expect { subject }.to raise_error(MicrosoftSync::Errors::HTTPBadRequest)
      end
    end
  end

  describe '#step_ensure_enrollments_user_mappings_filled' do
    subject { syncer_steps.step_ensure_enrollments_user_mappings_filled(nil, nil) }

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
      stub_const('MicrosoftSync::GraphServiceHelpers::USERS_ULUVS_TO_AADS_BATCH_SIZE', batch_size)

      students.each_with_index do |student, i|
        communication_channel(student, path_type: 'email', username: "student#{i}@example.com", active_cc: true)
      end
      teachers.each_with_index do |teacher, i|
        communication_channel(teacher, path_type: 'email', username: "teacher#{i}@example.com", active_cc: true)
      end
    end

    it_behaves_like 'a step that returns retry on intermittent error'

    context "when Microsoft's API returns success" do
      before do
        allow(graph_service_helpers).to receive(:users_uluvs_to_aads) do |remote_attr, uluvs|
          raise "max batchsize stubbed at #{batch_size}" if uluvs.length > batch_size

          # ULUV "abc@def.com" -> AAD "abc-mail-aad"
          uluvs.map{|uluv| [uluv, uluv.gsub(/@.*/, "-#{remote_attr}-aad")]}.to_h
        end
      end

      it 'creates a mapping for each of the enrollments' do
        expect_next_step(subject, :step_generate_diff)
        expect(mappings.pluck(:user_id, :aad_id).sort).to eq(
          students.each_with_index.map{|student, n| [student.id, "student#{n}-mail-aad"]}.sort +
          teachers.each_with_index.map{|teacher, n| [teacher.id, "teacher#{n}-mail-aad"]}.sort
        )
      end

      it 'batches in sizes of GraphServiceHelpers::USERS_ULUVS_TO_AADS_BATCH_SIZE' do
        expect(graph_service_helpers).to receive(:users_uluvs_to_aads).twice.and_return({})
        expect_next_step(subject, :step_generate_diff)
      end

      context "when Microsoft doesn't have AADs for the ULUVs" do
        it "doesn't add any UserMappings" do
          expect(graph_service_helpers).to receive(:users_uluvs_to_aads)
            .at_least(:once).and_return({})
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
          uluvs_looked_up = []
          expect(graph_service_helpers).to receive(:users_uluvs_to_aads) do |_remote_attr, uluvs|
            uluvs_looked_up += uluvs
            {}
          end
          expect_next_step(subject, :step_generate_diff)
          expect(uluvs_looked_up).to_not include("student0@example.com")
          expect(uluvs_looked_up).to include("student1@example.com")
        end
      end

      context 'when the Account tenant changes while the job is running' do
        before do
          orig_root_account_method = syncer_steps.group.method(:root_account)

          allow(syncer_steps.group).to receive(:root_account) do
            result = orig_root_account_method.call
            # Change account settings right after we have used them.
            # This tests that we are using the same root_account for the GraphService tenant
            # as we are passing into UserMapping.bulk_insert_for_root_account
            acct = Account.find(result.id)
            acct.settings[:microsoft_sync_tenant] = "EXTRA" + acct.settings[:microsoft_sync_tenant]
            acct.save
            result
          end
        end

        it 'raises a UserMapping::AccountSettingsChanged error' do
          expect{subject}.to raise_error(MicrosoftSync::UserMapping::AccountSettingsChanged)
        end
      end

      context 'when the Account login attribute changes while the job is running' do
        before do
          orig_root_account_method = MicrosoftSync::UsersUluvsFinder.method(:new)

          allow(MicrosoftSync::UsersUluvsFinder).to receive(:new) do |user_ids, root_account|
            result = orig_root_account_method.call(user_ids, root_account)
            acct = Account.find(root_account.id)
            acct.settings[:microsoft_sync_login_attribute] = 'somethingelse'
            acct.save
            result
          end
        end

        it 'raises a UserMapping::AccountSettingsChanged error' do
          expect{subject}.to raise_error(MicrosoftSync::UserMapping::AccountSettingsChanged)
        end
      end
    end
  end

  describe '#step_generate_diff' do
    subject { syncer_steps.step_generate_diff(nil, nil) }

    it_behaves_like 'a step that returns retry on intermittent error'

    before do
      course.enrollments.to_a.each_with_index do |enrollment, i|
        MicrosoftSync::UserMapping.create!(
          user_id: enrollment.user_id, root_account_id: course.root_account_id, aad_id: i.to_s
        )
      end

      group.update!(ms_group_id: 'mygroup')
    end

    it 'gets members and owners and builds a diff' do
      expect(graph_service_helpers).to \
        receive(:get_group_users_aad_ids).with('mygroup').and_return(%w[m1 m2])
      expect(graph_service_helpers).to \
        receive(:get_group_users_aad_ids).with('mygroup', owners: true).and_return(%w[o1 o2])

      diff = instance_double(MicrosoftSync::MembershipDiff)
      expect(MicrosoftSync::MembershipDiff).to \
        receive(:new).with(%w[m1 m2], %w[o1 o2]).and_return(diff)
      members_and_enrollment_types = []
      expect(diff).to receive(:set_local_member) { |*args| members_and_enrollment_types << args }
      allow(diff).to receive(:local_owners) do
        members_and_enrollment_types.select do |me|
          MicrosoftSync::MembershipDiff::OWNER_ENROLLMENT_TYPES.include?(me.last)
        end.map(&:first)
      end

      expect_next_step(subject, :step_execute_diff, diff)
      expect(members_and_enrollment_types).to eq([['0', 'TeacherEnrollment']])
    end
  end

  shared_examples_for 'a step that executes a diff' do
    before do
      allow(diff).to \
        receive(:additions_in_slices_of)
        .with(MicrosoftSync::GraphService::GROUP_USERS_BATCH_SIZE)
        .and_yield(owners: %w[o3], members: %w[o1 o2])
        .and_yield(members: %w[o3])
      allow(diff).to \
        receive(:removals_in_slices_of)
        .with(MicrosoftSync::GraphService::GROUP_USERS_BATCH_SIZE)
        .and_yield(owners: %w[o1], members: %w[m1 m2])
        .and_yield(members: %w[m3])
    end

    it 'adds/removes users based on the diff' do
      expect(graph_service).to receive(:add_users_to_group_ignore_duplicates)
        .with('mygroup', owners: %w[o3], members: %w[o1 o2])
      expect(graph_service).to receive(:add_users_to_group_ignore_duplicates)
        .with('mygroup', members: %w[o3])
      expect(graph_service).to receive(:remove_group_users_ignore_missing)
        .with('mygroup', members: %w[m1 m2], owners: %w[o1])
      expect(graph_service).to receive(:remove_group_users_ignore_missing)
        .with('mygroup', members: %w[m3])

      subject
    end

    context 'when some users to be added already exist in the group' do
      it 'logs and increments statsd metrics' do
        expect(graph_service).to receive(:add_users_to_group_ignore_duplicates)
          .twice.and_return(members: %w[o3], owners: %w[o1 o2])
        allow(graph_service).to receive(:remove_group_users_ignore_missing)

        allow(Rails.logger).to receive(:warn)
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        allow(InstStatsd::Statsd).to receive(:count).and_call_original

        subject

        expect(Rails.logger).to have_received(:warn).twice
          .with(/Skipping redundant add for 3: .*(o3.*o2|o2.*o3)/)
        expect(InstStatsd::Statsd).to have_received(:increment).twice
          .with("microsoft_sync.syncer_steps.skipped_batches.add",
                tags: {sync_type: sync_type_statsd_tag})
        expect(InstStatsd::Statsd).to have_received(:count).twice
          .with("microsoft_sync.syncer_steps.skipped_total.add", 3,
                tags: {sync_type: sync_type_statsd_tag})
      end
    end

    context "when some users to be removed don't exist in the group" do
      it 'logs and increments statsd metrics' do
        allow(graph_service).to receive(:add_users_to_group_ignore_duplicates)
        expect(graph_service).to receive(:remove_group_users_ignore_missing)
          .twice.and_return(owners: %w[m2 m3])

        allow(Rails.logger).to receive(:warn)
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        allow(InstStatsd::Statsd).to receive(:count).and_call_original

        subject

        expect(Rails.logger).to have_received(:warn).twice
          .with(/Skipping redundant remove for 2: .*(m2.*m3|m3.*m2)/)
        expect(InstStatsd::Statsd).to have_received(:increment).twice
          .with("microsoft_sync.syncer_steps.skipped_batches.remove",
                tags: {sync_type: sync_type_statsd_tag})
        expect(InstStatsd::Statsd).to have_received(:count).twice
          .with("microsoft_sync.syncer_steps.skipped_total.remove", 2,
                tags: {sync_type: sync_type_statsd_tag})
      end
    end
  end

  describe '#step_execute_diff' do
    subject { syncer_steps.step_execute_diff(diff, nil) }

    let(:diff) do
      instance_double(
        MicrosoftSync::MembershipDiff, local_owners: Set.new(%w[o3]),
        max_enrollment_members_reached?: false, max_enrollment_owners_reached?: false,
        additions_in_slices_of: nil, removals_in_slices_of: nil
      )
    end

    before { group.update! ms_group_id: 'mygroup' }

    it_behaves_like 'a step that executes a diff' do
      it_behaves_like 'a step that returns retry on intermittent error',
                      retry_args: {step: :step_generate_diff}

      it 'goes to the step_check_team_exists on success' do
        allow(graph_service).to receive(:add_users_to_group_ignore_duplicates)
        allow(graph_service).to receive(:remove_group_users_ignore_missing)
        expect_next_step(subject, :step_check_team_exists)
      end
    end

    context 'when there are no local owners (course teacher enrollments)' do
      it 'raises a graceful exit error informing the user' do
        expect(diff).to receive(:local_owners).and_return Set.new
        klass = MicrosoftSync::Errors::MissingOwners
        msg = /no users corresponding to the instructors of the Canvas course could be found/
        expect { subject }.to raise_microsoft_sync_graceful_cancel_error(klass, msg)
      end
    end

    context 'when there are more than `MAX_ENROLLMENT_MEMBERS` enrollments in a course' do
      before do
        allow(diff).to receive(:max_enrollment_members_reached?).and_return true
      end

      it_behaves_like 'max of members enrollment reached'
    end

    context 'when there are more than `MAX_ENROLLMENT_OWNERS` owner enrollments in a course' do
      before do
        allow(diff).to receive(:max_enrollment_owners_reached?).and_return true
      end

      it_behaves_like 'max of owners enrollment reached'
    end
  end

  describe '#step_check_team_exists' do
    subject { syncer_steps.step_check_team_exists(nil, nil) }

    before { group.update!(ms_group_id: 'mygroupid') }

    it_behaves_like 'a step that returns retry on intermittent error', except_404: true

    context 'when there are no teacher/ta/designer enrollments' do
      it "doesn't check for team existence or create a team" do
        course.enrollments.to_a.each do |e|
          e.destroy if e.type =~ /^Teacher|Ta|Designer/
        end
        expect(graph_service).to_not receive(:team_exists?)
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end
    end

    context 'when the team already exists' do
      it "returns COMPLETE" do
        expect(graph_service).to receive(:team_exists?).with('mygroupid').and_return(true)
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end
    end

    context "when the team doesn't exist" do
      it "moves on to step_create_team after a delay" do
        expect(graph_service).to receive(:team_exists?).with('mygroupid').and_return(false)
        expect_delayed_next_step(subject, :step_create_team, 24.seconds)
      end
    end
  end

  describe '#step_create_team' do
    subject { syncer_steps.step_create_team(nil, nil) }

    before { group.update!(ms_group_id: 'mygroupid') }

    it_behaves_like 'a step that returns retry on intermittent error', except_404: true

    it 'creates the team' do
      expect(graph_service).to receive(:create_education_class_team).with('mygroupid')
      expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
    end

    context 'when the Microsoft API errors with "group has no owners"' do
      it "retries in (30, 90, 270 seconds)" do
        expect(graph_service).to receive(:create_education_class_team).with('mygroupid')
          .and_raise(MicrosoftSync::Errors::GroupHasNoOwners)
        expect_retry(
          subject,
          error_class: MicrosoftSync::Errors::GroupHasNoOwners,
          delay_amount: [30, 90, 270]
        )
      end
    end

    context "when the Microsoft API errors with a 404 (e.g., group doesn't exist)" do
      it "retries in (30, 90, 270 seconds)" do
        expect(graph_service).to \
          receive(:create_education_class_team).with('mygroupid').and_raise(new_http_error(404))
        expect_retry(
          subject,
          error_class: MicrosoftSync::Errors::HTTPNotFound,
          delay_amount: [30, 90, 270]
        )
      end
    end

    context 'when the Microsoft API errors with some other error' do
      it "bubbles up the error" do
        expect(graph_service).to \
          receive(:create_education_class_team).with('mygroupid')
          .and_raise(new_http_error(400))
        expect { subject }.to raise_error(MicrosoftSync::Errors::HTTPBadRequest)
      end
    end
  end

  describe '#step_partial_sync' do
    subject { syncer_steps.step_partial_sync(nil, nil) }
    let(:sync_type_statsd_tag) { 'partial' }

    before { group.update! ms_group_id: 'mygroup' }

    context 'when there is an ms_group_id but there are no PartialSyncChanges' do
      it 'returns COMPLETE' do
        expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
      end
    end

    context 'when there are changes to process' do
      let(:n_students) { 1 }
      let!(:students) { 1.upto(n_students).map{student_in_course(course: course).user} }
      let!(:teacher) { teacher_in_course(course: course).user }

      before do
        students.each_with_index do |student, index|
          communication_channel(student, path_type: "email", username: "s#{index}@example.com",
                                active_cc: true)
        end
        communication_channel(teacher, path_type: 'email', username: 't@example.com', active_cc: true)

        create_partial_sync_change 'member', students[0]
        create_partial_sync_change 'owner', teacher
      end

      def create_partial_sync_change(e_type, user, course_for_psc=nil)
        course_for_psc ||= course
        MicrosoftSync::PartialSyncChange.create!(
          course: course_for_psc, enrollment_type: e_type, user: user
        )
      end

      shared_examples_for 'a step that turns into a full sync job' do
        let(:sync_type_statsd_tag) { 'full' }

        it 'turns into a full sync job' do
          expect_next_step(subject, :step_full_sync_prerequisites)
        end

        it 'increments the statsd counter partial_into_full' do
          allow(InstStatsd::Statsd).to receive(:increment).and_call_original
          subject
          expect(InstStatsd::Statsd).to have_received(:increment)
            .with('microsoft_sync.syncer_steps.partial_into_full')
        end

        it 'leaves sync_type=full for statsd' do
          subject
          syncer_steps.send(:graph_service)
          expect(MicrosoftSync::GraphServiceHelpers).to \
            have_received(:new).with(anything, sync_type: 'full')
        end
      end

      context "when the group's ms_group_id is not set" do
        before { group.update! ms_group_id: nil }

        it_behaves_like 'a step that turns into a full sync job'
      end

      context 'when there are more than the max number of changes' do
        before do
          stub_const('MicrosoftSync::SyncerSteps::MAX_PARTIAL_SYNC_CHANGES',
                     MicrosoftSync::PartialSyncChange.count - 1)
        end

        it_behaves_like 'a step that turns into a full sync job'
      end

      context 'when executing a diff' do
        let(:n_students) { 3 }
        let(:diff) do
          instance_double(
            MicrosoftSync::PartialMembershipDiff,
            set_local_member: nil, set_member_mapping: nil,
            log_all_actions: nil, additions_in_slices_of: nil, removals_in_slices_of: nil
          )
        end

        before do
          # Including 2 above, creating these gives us 4 PSCs:
          create_partial_sync_change 'member', students[2]
          create_partial_sync_change 'owner', students[2]

          MicrosoftSync::UserMapping.create!(
            root_account: course.root_account, user: students[0], aad_id: 's0-old'
          )

          allow(graph_service_helpers).to receive(:users_uluvs_to_aads) do |remote_attr, uluvs|
            # ULUV "abc@def.com" -> AAD "abc-mail-aad"
            uluvs.map{|uluv| [uluv, uluv.gsub(/@.*/, "-#{remote_attr}-aad")]}.to_h
          end

          allow(MicrosoftSync::PartialMembershipDiff).to receive(:new).and_return(diff)
        end

        it "gets user mappings that don't exist for all PartialSyncChanges users" do
          subject
          # s0 already has a UserMapping. s1 doesn't have a PartialSyncChange.
          expect(graph_service_helpers).to have_received(:users_uluvs_to_aads)
            .with(anything, contain_exactly('s2@example.com', 't@example.com'))
        end

        it 'builds a partial membership diff' do
          subject
          expect(MicrosoftSync::PartialMembershipDiff).to have_received(:new).with(
            students[0].id => ['member'], students[2].id => ['member', 'owner'],
            teacher.id => ['owner']
          )
          expect(diff).to have_received(:set_local_member).with(students[0].id, 'StudentEnrollment')
          expect(diff).to have_received(:set_local_member).with(students[2].id, 'StudentEnrollment')
          expect(diff).to have_received(:set_local_member).with(teacher.id, 'TeacherEnrollment')
          expect(diff).to have_received(:set_member_mapping).with(students[0].id, 's0-old')
          expect(diff).to have_received(:set_member_mapping).with(students[2].id, 's2-mail-aad')
          expect(diff).to have_received(:set_member_mapping).with(teacher.id, 't-mail-aad')
        end

        it 'ignores inactive enrollments' do
          Enrollment.where(course: course, user: students[0]).update_all(workflow_state: 'deleted')
          subject
          expect(diff).to_not have_received(:set_local_member).with(students[0].id, 'StudentEnrollment')
          expect(diff).to have_received(:set_local_member).with(students[2].id, 'StudentEnrollment')
        end

        it 'ignores StudentViewEnrollment (fake) enrollments' do
          Enrollment.where(course: course, user: students[0]).update_all(type: 'StudentViewEnrollment')
          subject
          expect(diff).to_not have_received(:set_local_member).with(students[0].id, anything)
        end

        it_behaves_like 'a step that executes a diff' do
          # the latter it_behaves_like must be inside this one because 'a step
          # that executes a diff' makes the diff return actions. We need actions
          # to trigger requests that can cause an intermittent error

          it_behaves_like 'a step that returns retry on intermittent error',
                          except_throttled: true do
            context 'when a request is throttled' do
              before do
                allow(graph_service.http).to receive(:request)
                  .and_raise(new_http_error(429, 'retry-after' => '3.14'))
              end

              it 'turns into a full sync job with the delay given in the retry-after header' do
                expect_delayed_next_step(subject, :step_full_sync_prerequisites, 3.14)
                expect(graph_service.http).to have_received(:request)
              end

              it 'increments the statsd counter partial_into_full_throttled' do
                allow(InstStatsd::Statsd).to receive(:increment).and_call_original
                subject
                expect(InstStatsd::Statsd).to have_received(:increment)
                  .with('microsoft_sync.syncer_steps.partial_into_full_throttled')
              end
            end
          end
        end

        it 'deletes the partial sync changes' do
          expect { subject }.to change { MicrosoftSync::PartialSyncChange.count }.from(4).to(0)
        end

        it "doesn't delete partial sync changes which have been updated while the job is running" do
          last_psc = MicrosoftSync::PartialSyncChange.last
          expect(diff).to receive(:additions_in_slices_of) do
            last_psc.update!(updated_at: 2.seconds.from_now)
          end
          expect { subject }.to change { MicrosoftSync::PartialSyncChange.count }.from(4).to(1)
          expect(MicrosoftSync::PartialSyncChange.pluck(:id)).to eq([last_psc.id])
        end

        it 'returns COMPLETE' do
          expect(subject).to eq(MicrosoftSync::StateMachineJob::COMPLETE)
        end
      end
    end
  end

  describe '#max_delay' do
    it { expect(syncer_steps.max_delay).to eq 6.hours }
  end

  describe '::MAX_PARTIAL_SYNC_CHANGES' do
    it { expect(described_class::MAX_PARTIAL_SYNC_CHANGES).to eq 500 }
  end
end
