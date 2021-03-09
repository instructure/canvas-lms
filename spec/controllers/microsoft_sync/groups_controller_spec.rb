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
  let!(:group) { MicrosoftSync::Group.create!(course: course) }

  let(:teacher) { course.teacher_enrollments.first.user }
  let(:course_id) { course.id }
  let(:params) { {course_id: course_id} }
  let(:student) { course.student_enrollments.first.user }
  let(:course) do
    course_with_student(active_all: true)
    @course
  end

  shared_examples_for 'endpoints that respond with 404 when records do not exist' do
    context 'when the course does not exist' do
      before { course.destroy! }

      it { is_expected.to be_not_found }
    end

    context 'when the course has no active microsoft group' do
      before { group.destroy! }

      it { is_expected.to be_not_found }
    end
  end

  shared_examples_for 'endpoints that require a user' do
    context 'when there is no user' do
      before { remove_user_session }

      it { is_expected.to redirect_to '/login' }
    end
  end

  shared_examples_for 'endpoints that require permissions' do
    let(:user) { raise 'set in examples' }

    context 'when the user does not have the required permissions' do
      let(:unauthorized_user) { student }

      before { user_session(unauthorized_user) }

      it { is_expected.to be_unauthorized }
    end
  end

  describe '#deleted' do
    subject { delete :destroy, params: params }

    before { user_session(teacher) }

    it_behaves_like 'endpoints that respond with 404 when records do not exist'
    it_behaves_like 'endpoints that require a user'
    it_behaves_like 'endpoints that require permissions'

    it { is_expected.to be_no_content }

    it 'destroys the group' do
      subject
      expect(group.reload).to be_deleted
    end
  end

  describe '#show' do
    subject { get :show, params: params }

    before { user_session(teacher) }

    it_behaves_like 'endpoints that respond with 404 when records do not exist'
    it_behaves_like 'endpoints that require a user'
    it_behaves_like 'endpoints that require permissions'

    it { is_expected.to be_successful }

    it 'responds with the expected group' do
      subject
      expect(json_parse).to eq JSON.parse(group.to_json(include_root: false))
    end
  end
end
