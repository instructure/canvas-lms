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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper')
require_dependency "lti/ims/results_controller"

describe Lti::Ims::ResultsController do
  let_once(:course) { course_factory(active_course: true) }
  let_once(:assignment) { assignment_model context: course}
  let_once(:result) { lti_result_model assignment: assignment }
  let(:json) { JSON.parse(response.body) }

  shared_examples 'mime_type check' do
    it 'does not return ims mime_type' do
      expect(response.headers['Content-Type']).not_to include described_class::MIME_TYPE
    end
  end

  shared_examples 'unauthorized' do
    it_behaves_like 'mime_type check'

    xit 'returns 401 unauthorized' do
      expect(response).to have_http_status :unauthorized
    end
  end

  shared_examples 'response check' do
    let(:action) { raise 'Override in spec'}
    let(:course_id) { assignment.context.id }
    let(:params_overrides) { {} }

    before do
      get action, params: { course_id: course_id, line_item_id: result.lti_line_item_id }.merge(params_overrides)
    end

    it 'returns correct mime_type' do
      expect(response.headers['Content-Type']).to include described_class::MIME_TYPE
    end

    it 'returns 200 success' do
      expect(response).to have_http_status :ok
    end

    context 'with unknown course' do
      let(:course_id) { Course.maximum(:id) + 1 }

      it_behaves_like 'mime_type check'

      it 'returns 404 not found' do
        expect(response).to have_http_status :not_found
      end
    end

    xcontext 'with course not in scope of tool' do
      let(:course_id) { course_model.id }

      it_behaves_like 'unauthorized'
    end

    xcontext 'with capabilities not in scope of tool' do
      # TODO: update scopes in before block

      it_behaves_like 'unauthorized'
    end
  end

  describe '#index' do
    it_behaves_like 'response check' do
      let(:action) { :index }
    end

    before_once do
      8.times { lti_result_model line_item: result.line_item, assignment: assignment }
    end

    it 'returns a collection of results' do
      get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id }
      expect(json.size).to eq 9
    end

    it 'formats the results correctly' do
      get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id }
      expect { Lti::Result.find(json.first['id'].split('/').last.to_i) }.not_to raise_error
    end

    context 'with user_id in params' do
      it 'returns a single result' do
        get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: result.user_id }
        expect(json.size).to eq 1
      end

      it 'returns the user result' do
        get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: result.user_id }
        expect(json.first['userId'].to_i).to eq result.user_id
      end

      context 'with non-existent user' do
        it 'returns an empty array' do
          get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: User.maximum(:id) + 1 }
          expect(json).to be_empty
        end
      end

      context 'with no result for user' do
        it 'returns an empty array' do
          usr = create_users_in_course(course, 1, return_type: :record).first
          get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: usr.id }
          expect(json).to be_empty
        end
      end

      context 'with user not in course' do
        it 'returns empty array' do
          usr = student_in_course(course: course, active_all: true).user
          get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: usr.id }
          expect(json).to be_empty
        end
      end

      context 'with user not a student' do
        it 'returns empty array' do
          usr = ta_in_course(course: course, active_all: true).user
          get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, user_id: usr.id }
          expect(json).to be_empty
        end
      end
    end

    context 'with limit in params' do
      it 'honors the limit' do
        get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, limit: 2 }
        expect(json.size).to eq 2
      end

      it 'provides the pagination headers' do
        get :index, params: { course_id: course.id, line_item_id: result.lti_line_item_id, limit: 2 }
        expect(response.headers['Link']).to include 'rel="next"'
      end
    end
  end

  describe '#show' do
    it_behaves_like 'response check' do
      let(:action) { :show }
      let(:params_overrides) { { id: result.id } }
    end

    it 'returns the result' do
      get :show, params: { course_id: course.id, line_item_id: result.lti_line_item_id, id: result.id }
      expect(response).to have_http_status :ok
    end

    it 'formats the result correctly' do
      get :show, params: { course_id: course.id, line_item_id: result.lti_line_item_id, id: result.id }
      rslt = Lti::Result.find(json['id'].split('/').last.to_i)
      expect(rslt).to eq result
    end

    context 'when result requested not in line_item' do
      it 'returns a 404' do
        li = line_item_model assignment: assignment
        get :show, params: { course_id: course.id, line_item_id: li.id, id: result.id }

        expect(response).to have_http_status :not_found
      end
    end

    context 'when result does not exist' do
      it 'returns a 404' do
        get :show, params: { course_id: course.id, line_item_id: result.lti_line_item_id, id: result.id + 1 }
        expect(response).to have_http_status :not_found
      end
    end
  end
end
