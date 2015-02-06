#
# Copyright (C) 2011-14 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe GradingStandardsApiController, type: :request do
  context "account admin" do
    describe 'grading standards creation' do
      before :once do
        @account = Account.default
        account_admin_user
        @resource_path = "/api/v1/accounts/#{@account.id}/grading_standards"
        @resource_params = { :controller => 'grading_standards_api', :action => 'create', :format => 'json', :account_id => @account.id.to_s }
      end

      it "should create account level grading standards" do
        post_params = {"title"=>"account grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"70"}]}
        json = api_call(:post, @resource_path, @resource_params, post_params)
        grading_standard = GradingStandard.find(json['id'])
        expect(json['title']).to eq 'account grading standard'
        expect(json['context_id']).to eq @account.id
        expect(json['context_type']).to eq 'Account'
        data = json['grading_scheme']
        expect(data.count).to eq 3
        expect(data[0]).to eq({'name'=>'A', 'value'=>0.9})
        expect(data[1]).to eq({'name'=>'B', 'value'=>0.8})
        expect(data[2]).to eq({'name'=>'C', 'value'=>0.7})
      end

      it "should create course level grading standards" do
        course = course(name: 'grading standard course')
        @resource_path = "/api/v1/courses/#{course.id}/grading_standards"
        @resource_params = { :controller => 'grading_standards_api', :action => 'create', :format => 'json', :course_id => course.id.to_s }
        post_params = {"title"=>"course grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"70"}]}
        json = api_call(:post, @resource_path, @resource_params, post_params)
        grading_standard = GradingStandard.find(json['id'])
        expect(json['title']).to eq 'course grading standard'
        expect(json['context_id']).to eq course.id
        expect(json['context_type']).to eq 'Course'
        data = json['grading_scheme']
        expect(data.count).to eq 3
        expect(data[0]).to eq({'name'=>'A', 'value'=>0.9})
        expect(data[1]).to eq({'name'=>'B', 'value'=>0.8})
        expect(data[2]).to eq({'name'=>'C', 'value'=>0.7})
      end

      it "should return error if no grading scheme provided" do
        post_params = {"title"=>"account grading standard"}
        json = api_call(:post, @resource_path, @resource_params, post_params, {}, {expected_status: 400})
        expect(json).to eq({"errors"=>{"data"=>[{"attribute"=>"data", "type"=>"blank", "message"=>"blank"}]}})
      end

      it "should return error if grading scheme contains negative values" do
        post_params = {"title"=>"course grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"-90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"70"}]}
        json = api_call(:post, @resource_path, @resource_params, post_params, {}, {expected_status: 400})
        expect(json).to eq({"errors"=>{"data"=>[{"attribute"=>"data", "type"=>"grading scheme values cannot be negative", "message"=>"grading scheme values cannot be negative"}]}})
      end

      it "should return error if grading scheme contains duplicate values" do
        post_params = {"title"=>"course grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"90"}]}
        json = api_call(:post, @resource_path, @resource_params, post_params, {}, {expected_status: 400})
        expect(json).to eq({"errors"=>{"data"=>[{"attribute"=>"data", "type"=>"grading scheme cannot contain duplicate values", "message"=>"grading scheme cannot contain duplicate values"}]}})
      end
    end
  end

  context "teacher" do
    before :once do
      @account = Account.default
      @resource_path = "/api/v1/accounts/#{@account.id}/grading_standards"
      @resource_params = { :controller => 'grading_standards_api', :action => 'create', :format => 'json', :account_id => @account.id.to_s }
      @course = course(name: 'grading standard course')
      user
      enrollment = @course.enroll_teacher(@user)
      enrollment.accept!
    end

    it "should not be able to create account level grading standards" do
      post_params = {"title"=>"account grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"70"}]}
      api_call(:post, @resource_path, @resource_params, post_params,{}, {:expected_status => 401})
    end

    it "should not be able to create course level grading standards" do
      course = course(name: 'grading standard course')
      @resource_path = "/api/v1/courses/#{course.id}/grading_standards"
      @resource_params = { :controller => 'grading_standards_api', :action => 'create', :format => 'json', :course_id => course.id.to_s }
      post_params = {"title"=>"course grading standard", "grading_scheme_entry"=>[{"name"=>"A", "value"=>"90"}, {"name"=>"B", "value"=>"80"}, {"name"=>"C", "value"=>"70"}]}
      api_call(:post, @resource_path, @resource_params, post_params,{}, {:expected_status => 401})
    end
  end


end
