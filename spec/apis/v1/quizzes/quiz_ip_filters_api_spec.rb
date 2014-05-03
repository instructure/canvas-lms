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
  before :each do
    course_with_teacher_logged_in :active_all => true

    @quiz = Quizzes::Quiz.create!(:title => 'quiz', :context => @course)
    @quiz.save!
  end

  context 'index' do
    def get_index(raw = false, data = {})
      helper = method(raw ? :raw_api_call : :api_call)
      helper.call(:get,
        "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/ip_filters",
        { :controller => 'quizzes/quiz_ip_filters', :action => 'index', :format => 'json',
          :course_id => @course.id.to_s,
          :quiz_id => @quiz.id.to_s
        }, data)
    end

    it 'should return an empty list' do
      json = get_index
      json.has_key?('quiz_ip_filters').should be_true
      json['quiz_ip_filters'].size.should == 0
    end

    it 'should list the active IP filter' do
      @quiz.ip_filter = '192.168.1.101'
      @quiz.save

      json = get_index
      json['quiz_ip_filters'].size.should == 1
    end

    it 'should list available IP filters' do
      @quiz.ip_filter = '192.168.1.101'
      @quiz.save

      @quiz.context.account.ip_filters = {
        'The Quiz IP Filters Spec Committee' => '192.168.1.101/24'
      }
      @quiz.context.account.save

      json = get_index
      json['quiz_ip_filters'].size.should == 2
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
        page1['quiz_ip_filters'].size.should == 25

        page1 = get_index false, { page: 2, per_page: 25 }
        page1['quiz_ip_filters'].size.should == 15
      end

      it 'should return an empty array with a cursor past the end' do
        page = get_index false, { page: 2 }
        page['quiz_ip_filters'].should == []
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
        json.has_key?('quiz_ip_filters').should be_true
        json['quiz_ip_filters'][0]['name'].should == 'Current Filter'
        json['quiz_ip_filters'][0]['account'].should == @quiz.title
        json['quiz_ip_filters'][0]['filter'].should == '192.168.1.101'
      end

      context 'JSON-API compliance' do
        it 'should render as JSON-API' do
          pending 'CNVS-8978: JSON-API compliance API spec helper'

          json = get_index
          assert_jsonapi_compliance(json, 'quiz_ip_filters')
        end
      end
    end
  end
end
