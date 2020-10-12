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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe SIS::Models::Enrollment do

  describe '#initialize' do
    let(:params) do
      {
        course_id: '1',
        section_id: '2',
        role: 'StudentEnrollment',
        notify: 'true'
      }
    end
    let(:subject) { described_class.new(**params) }

    it 'sets nil defaults to all params' do
      expect(subject.user_integration_id).to be_nil
      expect(subject.associated_user_id).to be_nil
      expect(subject.status).to be_nil
      expect(subject.limit_section_privileges).to be_nil
    end

    it 'assigns args if provided' do
      expect(subject.notify).to eq 'true'
      expect(subject.course_id).to eq '1'
      expect(subject.section_id).to eq '2'
      expect(subject.role).to eq 'StudentEnrollment'
    end
  end

  describe '#valid_context?' do
    it 'detects an invalid context' do
      expect(subject).to_not be_valid_context
    end

    it 'has a valid context if there is a course_id' do
      subject.course_id = 10
      expect(subject).to be_valid_context
    end

    it 'has a valid context if there is a section_id' do
      subject.section_id = 9
      expect(subject).to be_valid_context
    end
  end

  describe '#valid_user?' do
    it 'detects an invalid user' do
      expect(subject).to_not be_valid_user
    end

    it 'has a valid context if there is a user_id' do
      subject.user_id = 10
      expect(subject).to be_valid_user
    end

    it 'has a valid context if there is a user_integration_id' do
      subject.user_integration_id = 9
      expect(subject).to be_valid_user
    end
  end

  describe '#valid_status?' do
    it 'detects an empty status' do
      expect(subject).to_not be_valid_status
    end

    it 'detects a bad status' do
      subject.status = 'fake'
      expect(subject).to_not be_valid_status
    end

    it 'accepts the active status' do
      subject.status = 'active'
      expect(subject).to be_valid_status
    end

    it 'accepts the deleted status' do
      subject.status = 'deleted'
      expect(subject).to be_valid_status
    end

    it 'accepts the completed status' do
      subject.status = 'completed'
      expect(subject).to be_valid_status
    end

    it 'accepts the inactive status' do
      subject.status = 'inactive'
      expect(subject).to be_valid_status
    end
  end

  describe '#row_info' do
    it 'provides row info for available attributes' do
      subject.notify = 'true'
      expect(subject.row_info).to include(':notify=>"true"')
    end
  end
end
