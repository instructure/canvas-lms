# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'spec_helper'

describe MicrosoftSync::Group do
  subject { described_class.create(course: course_model) }

  it { is_expected.to be_a(described_class) }
  it { is_expected.to be_valid }
  it { is_expected.to belong_to(:course).required }
  it { is_expected.to validate_presence_of(:course) }

  it 'defaults to workflow_state=pending' do
    expect(subject.workflow_state).to eq('pending')
  end

  it 'is soft deleted' do
    subject.destroy!
    expect(subject.reload).to be_deleted
  end

  describe 'not_deleted scope' do
    subject { described_class.not_deleted }

    before(:once) do
      %i[pending running errored completed deleted].each do |state|
        course_model.create_microsoft_sync_group(workflow_state: state)
      end
    end

    it 'includes pending groups' do
      expect(subject.where(workflow_state: 'pending')).not_to be_blank
    end

    it 'includes running groups' do
      expect(subject.where(workflow_state: 'running')).not_to be_blank
    end

    it 'includes errored groups' do
      expect(subject.where(workflow_state: 'errored')).not_to be_blank
    end

    it 'includes completed groups' do
      expect(subject.where(workflow_state: 'completed')).not_to be_blank
    end

    it 'does not include deleted groups' do
      expect(subject.where(workflow_state: 'deleted')).to be_blank
    end
  end

  describe '#restore!' do
    context 'with a deleted group' do
      subject do
        group = super()
        group.destroy!
        group.restore!
        group
      end

      it 'resets the job state' do
        expect(subject.job_state).to be_nil
      end

      it 'resets the last error' do
        expect(subject.last_error).to be_nil
      end

      it 'resets the workflow state' do
        expect(subject.workflow_state).to eq 'pending'
      end
    end

    context 'with an non-deleted group' do
      subject do
        group = super()
        group.update!(workflow_state: 'running')
        group.restore!
        group
      end

      it 'does nothing' do
        expect(subject.workflow_state).to eq 'running'
      end
    end
  end
end
