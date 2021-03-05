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

require 'spec_helper'

describe MicrosoftSync::GroupsController, type: :controller do
  describe '#show' do
    subject { get :show, params: params }

    let!(:group) { MicrosoftSync::Group.create!(course: course) }

    let(:authorized_user) { course.teacher_enrollments.first.user }
    let(:course_id) { course.id }
    let(:params) { {course_id: course_id} }
    let(:unauthorized_user) { course.student_enrollments.first.user }
    let(:course) do
      course_with_student(active_all: true)
      @course
    end

    before { user_session(authorized_user) }

    it { is_expected.to be_successful }

    it 'responds with the expected group' do
      subject
      expect(json_parse).to eq JSON.parse(group.to_json(include_root: false))
    end

    context 'when the course has no microsoft group' do
      before { group.destroy! }

      it { is_expected.to be_not_found }
    end

    context 'when there is no user session' do
      before { remove_user_session }

      it { is_expected.to redirect_to '/login' }
    end

    context 'when the user does not have the required permissions' do
      before { user_session(unauthorized_user) }

      it { is_expected.to be_unauthorized }
    end

    context 'when the specified course does not exist' do
      before { course.destroy! }

      it { is_expected.to be_not_found }
    end
  end
end
