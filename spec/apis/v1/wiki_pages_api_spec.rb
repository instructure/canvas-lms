#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../api_spec_helper'
require_relative '../locked_spec'
require_relative '../../sharding_spec_helper'
require_relative '../../lti_spec_helper'

describe WikiPagesApiController, type: :request do
  include Api
  include Api::V1::Assignment
  include Api::V1::WikiPage
  include LtiSpecHelper

  describe "POST 'duplicate'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
      wiki_page_model({ :title => "Wiki Page" })
    end

    it "returns unauthorized if not a teacher" do
      api_call_as_user(@student, :post,
        "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
        { :controller => "wiki_pages_api",
          :action => "duplicate",
          :format => "json",
          :course_id => @course.id.to_s,
          :url => @page.url },
        {},
        {},
        { :expected_status => 401 })
    end

    it "can duplicate wiki non-assignment if teacher" do
      json = api_call_as_user(@teacher, :post,
        "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
        { :controller => "wiki_pages_api",
          :action => "duplicate",
          :format => "json",
          :course_id => @course.id.to_s,
          :url => @page.url },
        {},
        {},
        { :expected_status => 200 })
      expect(json["title"]).to eq "Wiki Page Copy"
    end

    it "can duplicate wiki assignment if teacher" do
      wiki_page_assignment_model({ :title => "Assignment Wiki" })
      json = api_call_as_user(@teacher, :post,
        "/api/v1/courses/#{@course.id}/pages/#{@page.url}/duplicate.json",
        { :controller => "wiki_pages_api",
          :action => "duplicate",
          :format => "json",
          :course_id => @course.id.to_s,
          :url => @page.url },
        {},
        {},
        { :expected_status => 200 })
      expect(json["title"]).to eq "Assignment Wiki Copy"
    end
  end
end
