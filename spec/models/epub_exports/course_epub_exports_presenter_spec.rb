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
    @course_without_epub = course_with_user('StudentEnrollment',
      active_all: true, user: @student
    ).course
    @course_as_obsever = course_with_user('ObserverEnrollment',
      active_all: true,
      user: @student
    ).course
    @course_as_ta = course_with_user('TaEnrollment',
      active_all: true,
      user: @student
    ).course
  end

  describe "#courses" do
    subject(:courses) do
      EpubExports::CourseEpubExportsPresenter.new(@student).courses
    end

    context 'when feature is enabled' do
      before do
        [@course_with_epub, @course_without_epub, @course_as_obsever, @course_as_ta].map {|course| course.enable_feature!(:epub_export) }
      end

      it "sets latest_epub_export for course with epub_export" do
        expect(courses.find do |course|
          course.id == @course_with_epub.id
        end.latest_epub_export).to eq @epub_export
      end

      it 'does not set latest_epub_export for course without epub_export' do
        expect(courses.find do |course|
          course.id == @course_without_epub.id
        end.latest_epub_export).to be_nil
      end

      it 'does not include web zip exports' do
        @course_with_epub.web_zip_exports.create!(user: @student)
        expect(courses.find do |course|
          course.id == @course_with_epub.id
        end.latest_epub_export).to eq @epub_export
      end

      it 'does not include course for which user is an observer' do
        expect(courses).not_to include(@course_as_observer)
      end

      it 'includes courses for which the user is a ta' do
        expect(courses).to include(@course_as_ta)
      end
    end

    it "should only include courses that have the feature enabled" do
      expect(courses.find do |course|
        course.id == @course_with_epub.id
      end).to be_nil
    end
  end
end
