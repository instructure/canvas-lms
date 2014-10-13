#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../api_spec_helper')

describe Quizzes::QuizIpFiltersController, type: :request do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  before :once do
    course_with_teacher :active_all => true

    @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
    @quiz.save!
  end

  context 'index' do
    def get_index(raw = false, data = {})
      url = "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/ip_filters"
      params = { :controller => 'quizzes/quiz_ip_filters', :action => 'index',
                 :format => 'json', :course_id => @course.id.to_s,
                 :quiz_id => @quiz.id.to_s }

      if raw
        raw_api_call(:get, url, params, data)
      else
        api_call(:get, url, params, data)
      end
    end

    it 'should return an empty list' do
      json = get_index
      expect(json.has_key?('quiz_ip_filters')).to be_truthy
      expect(json['quiz_ip_filters'].size).to eq 0
    end

    it 'should list the active IP filter' do
      @quiz.ip_filter = '192.168.1.101'
      @quiz.save

      json = get_index
      expect(json['quiz_ip_filters'].size).to eq 1
    end

    it 'should list available IP filters' do
      @quiz.ip_filter = '192.168.1.101'
      @quiz.save

      @quiz.context.account.ip_filters = {
        'The Quiz IP Filters Spec Committee' => '192.168.1.101/24'
      }
      @quiz.context.account.save

      json = get_index
      expect(json['quiz_ip_filters'].size).to eq 2
    end

    it 'should restrict access to itself' do
      student_in_course

      json = get_index(true)
      assert_status(401)
    end

    context 'Pagination' do
      it 'should paginate' do
        account_filters = {}

        for i in 1..40 do
          account_filters["Filter #{i}"] = "192.168.1.#{i}"
        end

        @quiz.context.account.ip_filters = account_filters
        @quiz.context.account.save

        page1 = get_index false, { per_page: 25 }
        expect(page1['quiz_ip_filters'].size).to eq 25

        page1 = get_index false, { page: 2, per_page: 25 }
        expect(page1['quiz_ip_filters'].size).to eq 15
      end

      it 'should return an empty array with a cursor past the end' do
        page = get_index false, { page: 2 }
        expect(page['quiz_ip_filters']).to eq []
      end

      it 'should bail out on an invalid cursor' do
        get_index true, { page: 'invalid' }
        assert_status(404)
      end
    end

    context 'Rendering IP Filter objects' do
      it 'should render' do
        @quiz.ip_filter = '192.168.1.101'
        @quiz.save

        json = get_index
        expect(json.has_key?('quiz_ip_filters')).to be_truthy
        expect(json['quiz_ip_filters'][0]['name']).to eq 'Current Filter'
        expect(json['quiz_ip_filters'][0]['account']).to eq @quiz.title
        expect(json['quiz_ip_filters'][0]['filter']).to eq '192.168.1.101'
      end

      context 'JSON-API compliance' do
        it 'should render as JSON-API' do
          skip 'CNVS-8978: JSON-API compliance API spec helper'

          json = get_index
          assert_jsonapi_compliance(json, 'quiz_ip_filters')
        end
      end
    end
  end
end
