# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Api::V1::Course do
  include Api::V1::Course

  def feeds_calendar_url(feed_code)
    "feed_calendar_url(#{feed_code.inspect})"
  end

  describe "#course_settings_json" do
    before :once do
      @course = Course.create!
    end

    it "returns course settings hash" do
      grading_standard = grading_standard_for(@course)
      @course.grading_standard = grading_standard
      @course.save
      course_settings = course_settings_json(@course)
      expect(course_settings[:allow_student_discussion_topics]).to be true
      expect(course_settings[:allow_student_forum_attachments]).to be true
      expect(course_settings[:allow_student_discussion_editing]).to be true
      expect(course_settings[:grading_standard_enabled]).to be true
      expect(course_settings[:grading_standard_id]).to eq grading_standard.id
    end

    it "includes filter_speed_grader_by_student_group in the settings hash" do
      course_settings = course_settings_json(@course)
      expect(course_settings).to have_key :filter_speed_grader_by_student_group
    end

    it "includes conditional_release value in the settings hash" do
      course_settings = course_settings_json(@course)
      expect(course_settings).to have_key :conditional_release
    end
  end

  describe "#course_json" do
    it "works for a logged-out user" do
      course_factory
      hash = course_json(@course, nil, nil, [], nil)
      expect(hash["id"]).to be_present
    end

    it "includes course locale" do
      course_factory
      @course.locale = "tlh"
      @course.save
      hash = course_json(@course, nil, nil, [], nil)
      expect(hash["locale"]).to eql @course.locale
    end

    describe "course_image" do
      before :once do
        course_factory
        @course.image_url = "http://image.jpeg"
        @course.save
      end

      it "is included when requested" do
        hash = course_json(@course, nil, nil, ["course_image"], nil)
        expect(hash["image_download_url"]).to eql "http://image.jpeg"
      end

      it "is not included if the course_image include is not present" do
        hash = course_json(@course, nil, nil, [], nil)
        expect(hash["image_download_url"]).not_to be_present
      end
    end

    describe "banner_image" do
      before :once do
        course_factory
        @course.banner_image_url = "http://image2.jpeg"
        @course.save
      end

      it "is included when requested" do
        hash = course_json(@course, nil, nil, ["banner_image"], nil)
        expect(hash["banner_image_download_url"]).to eql "http://image2.jpeg"
      end

      it "is not included if the course_image include is not present" do
        hash = course_json(@course, nil, nil, [], nil)
        expect(hash["banner_image_download_url"]).not_to be_present
      end
    end
  end
end
