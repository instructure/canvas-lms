# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CourseDateRange do
  before(:once) do
    @course = course_factory
  end

  it "should have a date and date_context for start and end" do
    range = CourseDateRange.new(@course)
    expect(range.start_at).to include(:date, :date_context)
    expect(range.end_at).to include(:date, :date_context)
  end

  it "should get term dates if restrict enrollments to course dates is false" do
    @course.enrollment_term.update(start_at: Time.now - 10.days, end_at: Time.now + 10.days)
    range = CourseDateRange.new(@course)
    expect(range.start_at[:date_context]).to eq("term")
    expect(range.end_at[:date_context]).to eq("term")
    expect(range.start_at[:date]).to eq(@course.enrollment_term.start_at)
    expect(range.end_at[:date]).to eq(@course.enrollment_term.end_at)
  end

  describe "with restrict enrollments to course dates active" do

    it "should set the range based on the course" do
      @course.update(start_at: Time.now - 5.days, conclude_at: Time.now + 5.days, restrict_enrollments_to_course_dates: true)
      range = CourseDateRange.new(@course)
      expect(range.start_at[:date_context]).to eq("course")
      expect(range.end_at[:date_context]).to eq("course")
      expect(range.start_at[:date]).to eq(@course.start_at)
      expect(range.end_at[:date]).to eq(@course.end_at)
    end

    it "should fall back to term date range if no range exists for the course" do
      @course.update(start_at: nil, conclude_at: nil)
      range = CourseDateRange.new(@course)
      expect(range.start_at[:date_context]).to eq("term")
      expect(range.end_at[:date_context]).to eq("term")
      expect(range.start_at[:date]).to eq(@course.enrollment_term.start_at)
      expect(range.end_at[:date]).to eq(@course.enrollment_term.end_at)
    end
  end
end
