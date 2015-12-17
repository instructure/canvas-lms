#
# Copyright (C) 2015 Instructure, Inc.
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

require_relative '../spec_helper'

describe GradingStandardsController do
  before(:once) do
    course_with_teacher(active_all: true)
  end

  describe "POST 'create'" do
    let(:default_grading_standard) do
      [ ["A", 0.94], ["A-", 0.9], ["B+", 0.87], ["B", 0.84],
        ["B-", 0.8], ["C+", 0.77], ["C", 0.74], ["C-", 0.7],
        ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0] ]
    end

    let!(:teacher_session) { user_session(@teacher) }
    let(:json_response) { json_parse['grading_standard']['data'] }

    it "responds with a 200 with a valid user, course id, and json format" do
      post 'create', course_id: @course.id, format: 'json'
      expect(response).to be_ok
    end

    it "uses the default grading standard if no standard data is provided" do
      post 'create', course_id: @course.id, format: 'json'
      expect(json_response).to eq(default_grading_standard)
    end

    it "allows the user to send in a :data param to set the standard" do
      standard = {
        title: 'New Grading Standard!',
        data: [['A', 0.61], ['F', 0.00]]
      }
      post 'create', course_id: @course.id, grading_standard: standard, format: 'json'
      expect(json_response).to eq(standard[:data])
    end

    it "allows the user to send in a :standard_data param to set the standard" do
      standard = {
        title: 'New Grading Standard!',
        standard_data: {
          scheme_1: {name: 'A',value: 61},
          scheme_2: {name: 'F',value: 0}
        }
      }
      post 'create', course_id: @course.id, grading_standard: standard, format: 'json'
      expected_response_data = [['A', 0.61], ['F', 0.00]]
      expect(json_response).to eq(expected_response_data)
    end
  end
end
