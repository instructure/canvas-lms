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
  let(:course) { course_model(name: 'sync test course') }
  let(:group) { MicrosoftSync::Group.create(course: course) }
  let(:canvas_graph_service) { double('CanvasGraphService') }
  let(:tenant) { 'mytenant123' }

  before do
    ra = course.root_account
    ra.settings[:microsoft_sync_tenant] = tenant
    ra.save!

    allow(MicrosoftSync::CanvasGraphService).to \
      receive(:new).with(tenant).and_return(canvas_graph_service)
  end

  describe '#sync!' do
    context 'when the tenant is not set in the account settings' do
      let(:tenant) { nil }

      it 'does nothing' do
        expect(MicrosoftSync::CanvasGraphService).to_not receive(:new)
        expect(syncer).to_not receive(:ensure_class_group_exists)
        syncer.sync!
      end
    end

    context 'if the group has been deleted' do
      it 'does nothing' do
        group.destroy!
        expect(MicrosoftSync::CanvasGraphService).to_not receive(:new)
        syncer.sync!
      end
    end

    context 'when there is an error' do
      it 'sets workflow_state to errored and last_error and lets the error bubble up' do
        err = StandardError.new('foo')
        expect(syncer).to receive(:ensure_class_group_exists).and_raise(err)
        expect { syncer.sync! }.to raise_error(err)
        expect(group.reload.workflow_state).to eq('errored')
        expect(group.last_error).to eq(MicrosoftSync::Errors.user_facing_message(err))
      end
    end

    it 'calls each step and sets workflow_state to completed' do
      expect(syncer).to receive(:ensure_class_group_exists)
      expect(syncer).to receive(:ensure_enrollments_user_mappings_filled)
      expect { syncer.sync! }.to \
        change { group.reload.workflow_state }.from('pending').to('completed')
    end
  end

  describe '#ensure_class_group_exists' do
    before do
      allow(canvas_graph_service).to receive(:list_education_classes_for_course).
        with(course).and_return(education_class_ids.map{|id| {'id' => id}})

      # TODO: we may remove the sleep, or end up keeping/changing it (in which
      # case we should add some expectations around it). See the code.
      allow(syncer).to receive(:sleep).with(2)
    end

    shared_examples_for 'a group record which requires a new or updated MS group' do
      context 'when no remote MS group exists for the course' do
        # admin deleted the MS group we created, or a group never existed
        let(:education_class_ids) { [] }

        it 'creates a new MS group, updates the LMS metadata, and sets ms_group_id' do
          expect(canvas_graph_service).to \
            receive(:create_education_class).with(course).and_return('id' => 'newid')
          expect(canvas_graph_service).to \
            receive(:update_group_with_course_data).with('newid', course)
          expect { syncer.ensure_class_group_exists }.to \
            change { group.reload.ms_group_id }.to('newid')
        end
      end

      context 'when no remote MS group with our ms_group_id exists for the course' do
        let(:education_class_ids) { ['newid2'] }

        it 'updates that MS group with the LMS metadata and sets ms_group_id on the model' do
          expect(canvas_graph_service).to_not receive(:create_education_class)
          expect(canvas_graph_service).to \
            receive(:update_group_with_course_data).with('newid2', course)
          expect { syncer.ensure_class_group_exists }.to \
            change { group.reload.ms_group_id }.to('newid2')
        end
      end

      context 'when there is more than one remote MS group for the course' do
        let(:education_class_ids) { [group.ms_group_id || 'someid', 'newid3'] }

        it 'raises an InvalidRemoteState error' do
          expect { syncer.ensure_class_group_exists }.to raise_error(
            MicrosoftSync::Errors::InvalidRemoteState,
            'Multiple Microsoft education classes exist for the course.'
          )
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
          expect { syncer.ensure_class_group_exists }.to_not change { group.reload.ms_group_id }
        end
      end
    end
  end

  describe '#ensure_enrollments_user_mappings_filled' do
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
      syncer.ensure_enrollments_user_mappings_filled
      expect(mappings.pluck(:user_id, :aad_id).sort).to eq(
        students.each_with_index.map{|student, n| [student.id, "student#{n}-aad"]}.sort +
        teachers.each_with_index.map{|teacher, n| [teacher.id, "teacher#{n}-aad"]}.sort
      )
    end

    it 'batches in sizes of CanvasGraphService::USERS_UPNS_TO_AADS_BATCH_SIZE' do
      expect(canvas_graph_service).to receive(:users_upns_to_aads).twice.and_return({})
      syncer.ensure_enrollments_user_mappings_filled
    end

    context "when Microsoft doesn't have AADs for the UPNs" do
      it "doesn't add any UserMappings" do
        expect(canvas_graph_service).to receive(:users_upns_to_aads).
          at_least(:once).and_return({})
        expect { syncer.ensure_enrollments_user_mappings_filled }.to_not \
          change { MicrosoftSync::UserMapping.count }.from(0)
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
        syncer.ensure_enrollments_user_mappings_filled
        expect(upns_looked_up).to_not include("student0@example.com")
        expect(upns_looked_up).to include("student1@example.com")
      end
    end
  end
end
