#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'spec_helper'

describe AnonymousOrModerationEvent do
  subject { AnonymousOrModerationEvent.new(params) }

  let(:params) do
    {
      user_id: user.id,
      assignment_id: assignment.id,
      event_type: :assignment_created,
      payload: { foo: :bar }
    }
  end
  let(:user) { instance_double('User', id: 1) }
  let(:assignment) { instance_double('Assignment', id: 1) }

  it { is_expected.to be_valid }

  describe 'relationships' do
    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:submission) }
    it { is_expected.to belong_to(:canvadoc) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:assignment_id) }
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(AnonymousOrModerationEvent::EVENT_TYPES) }
    it { is_expected.to validate_presence_of(:payload) }

    it { expect { AnonymousOrModerationEvent.new.validate }.not_to raise_error }

    context 'assignment_created events' do
      subject { AnonymousOrModerationEvent.new(params) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context 'assignment_updated events' do
      subject { AnonymousOrModerationEvent.new(params.merge(event_type: :assignment_updated)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context 'docviewer events' do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :docviewer_comment_created)) }

      it { is_expected.to validate_presence_of(:canvadoc_id) }
      it { is_expected.to validate_presence_of(:submission_id) }

      it 'requires the payload to have an annotation body' do
        event.validate
        expect(event.errors[:payload]).to include "annotation_body can't be blank"
      end
    end

    context '"grades_posted" events' do
      subject { AnonymousOrModerationEvent.new(params.merge(event_type: :grades_posted)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_absence_of(:submission_id) }
    end

    context '"provisional_grade_selected" events' do
      subject(:event) { AnonymousOrModerationEvent.new(params.merge(event_type: :provisional_grade_selected)) }

      it { is_expected.to validate_absence_of(:canvadoc_id) }
      it { is_expected.to validate_presence_of(:submission_id) }

      it 'requires the payload to have an id' do
        event.validate
        expect(event.errors[:payload]).to include "id can't be blank"
      end

      it 'requires the payload to have a student_id' do
        event.validate
        expect(event.errors[:payload]).to include "student_id can't be blank"
      end
    end
  end
end
