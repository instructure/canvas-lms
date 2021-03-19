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

  let(:course_id) { course.id }
  let(:feature_context) { course.root_account }
  let(:feature) { :microsoft_group_enrollments_syncing }
  let(:params) { { course_id: course_id } }
  let(:student) { course.student_enrollments.first.user }
  let(:teacher) { course.teacher_enrollments.first.user }
  let(:course) do
    course_with_student(active_all: true)
    @course
  end

  before { feature_context.enable_feature! feature }

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

  shared_examples_for 'endpoints that require a release flag to be on' do
    context 'when the release flag is off' do
      before { feature_context.disable_feature! feature }

      it { is_expected.to be_not_found }
    end
  end

  describe '#create' do
    subject { post :create, params: params }

    before { user_session(teacher) }

    it_behaves_like 'endpoints that require a user'
    it_behaves_like 'endpoints that require permissions'
    it_behaves_like 'endpoints that require a release flag to be on'

    context 'when the course does not exist' do
      before { course.destroy! }

      it { is_expected.to be_not_found }
    end

    context 'when a deleted group exists for the course' do
      subject do
        super()
        json_parse
      end

      before do
        group.update!(
          job_state: :membership_fetched,
          last_error: 'something bad happened',
          workflow_state: 'errored'
        )
        group.destroy!
      end

      it 'responds with "created"' do
        subject
        expect(response).to be_created
      end

      it 'reactivates the existing group' do
        expect(subject['id']).to eq group.id
      end

      it 'clears the job state' do
        expect(subject['job_state']).to be_blank
      end

      it 'clears the last error' do
        expect(subject['last_error']).to be_blank
      end

      it 'resets the workflow state' do
        expect(subject['workflow_state']).to eq 'pending'
      end
    end

    context 'when an active group already exists for the course' do
      it 'responds with "conflict"' do
        expect(subject.status).to eq 409
      end
    end

    context 'when no group exists for the course' do
      subject do
        super()
        json_parse
      end

      before { group.destroy_permanently! }

      it 'responds with "created"' do
        subject
        expect(response.status).to eq 201
      end

      it 'creates a new group' do
        expect(subject).to match(
          JSON.parse(
            MicrosoftSync::Group.find(subject['id']).to_json(
              include_root: false
            )
          )
        )
      end
    end
  end

  describe '#deleted' do
    subject { delete :destroy, params: params }

    before { user_session(teacher) }

    it_behaves_like 'endpoints that respond with 404 when records do not exist'
    it_behaves_like 'endpoints that require a user'
    it_behaves_like 'endpoints that require permissions'
    it_behaves_like 'endpoints that require a release flag to be on'

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
    it_behaves_like 'endpoints that require a release flag to be on'

    it { is_expected.to be_successful }

    it 'responds with the expected group' do
      subject
      expect(json_parse).to eq JSON.parse(group.to_json(include_root: false))
    end
  end
end
