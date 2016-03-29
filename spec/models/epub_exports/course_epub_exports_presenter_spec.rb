#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe EpubExports::CourseEpubExportsPresenter do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @epub_export = @course.epub_exports.create(user: @student)
    @course_with_epub = @course
    course_with_user('StudentEnrollment', active_all: true, user: @student)
  end

  describe "#courses" do
    let_once(:presenter) do
      EpubExports::CourseEpubExportsPresenter.new(@student)
    end

    it "should set latest_epub_export for course with epub_export" do
      @course.enable_feature!(:epub_export)
      @course_with_epub.enable_feature!(:epub_export)
      courses = presenter.courses

      expect(courses.find do |course|
        course.id == @course_with_epub.id
      end.latest_epub_export).to eq @epub_export

      expect(courses.find do |course|
        course.id == @course.id
      end.latest_epub_export).to be_nil
    end

    it "should only include courses that have the feature enabled" do

      courses = presenter.courses

      expect(courses.find do |course|
        course.id == @course_with_epub.id
      end).to be_nil

    end
  end
end
