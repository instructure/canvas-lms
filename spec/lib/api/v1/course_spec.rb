#
# Copyright (C) 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Api::V1::Course do
  include Api::V1::Course

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  describe "#course_settings_json" do
  	it "should return course settings hash" do
  		course_factory
  		grading_standard = grading_standard_for(@course)
  		@course.grading_standard = grading_standard
  		@course.save
  		course_settings = course_settings_json(@course)
  		expect(course_settings[:allow_student_discussion_topics]).to eq true
  		expect(course_settings[:allow_student_forum_attachments]).to eq false
  		expect(course_settings[:allow_student_discussion_editing]).to eq true
  		expect(course_settings[:grading_standard_enabled]).to eq true
  		expect(course_settings[:grading_standard_id]).to eq grading_standard.id
  	end
  end

  describe "#course_json" do
    it "should work for a logged-out user" do
      course_factory
      hash = course_json(@course, nil, nil, [], nil)
      expect(hash['id']).to be_present
    end
  end
end
