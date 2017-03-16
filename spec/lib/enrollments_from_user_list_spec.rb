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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe EnrollmentsFromUserList do
  before(:each) do
    course_model(:reusable => true)
    @el = UserList.new(list_to_parse)
    account = Account.default
    account.settings = { :open_registration => true }
    account.save!
  end

  context "initialized object" do

    it "should initialize with a course id" do
      expect{EnrollmentsFromUserList.new }.to raise_error(ArgumentError, /^wrong number of arguments/)
      e = EnrollmentsFromUserList.new(@course)
      expect(e.course).to eql(@course)
    end

    it "should process with an user list" do
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.all? {|e| expect(e).to be_is_a(StudentEnrollment)}
    end

    it "should process repeat addresses without creating new users" do
      @el = UserList.new(list_to_parse_with_repeats)
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      expect(enrollments.length).to eql(3)
    end

    it "should respect the section option when a user is already enrolled in another section" do
      othersection = @course.course_sections.create! name: 'othersection'
      @teacher.pseudonyms.create! unique_id: 'teacher@example.com'
      @el = UserList.new('teacher@example.com')
      enrollments = EnrollmentsFromUserList.process(@el, @course, course_section_id: othersection.to_param, enrollment_type: 'TeacherEnrollment')
      expect(enrollments.map(&:course_section_id)).to eq([othersection.id])
      expect(@teacher.teacher_enrollments.where(course_id: @course).pluck(:course_section_id)).to match_array([@course.default_section.id, othersection.id])
    end

  end

  context "EnrollmentsFromUserList.process" do
    it "should be able to process from the class" do
      enrollments = EnrollmentsFromUserList.process(@el, @course)
      enrollments.all? {|e| expect(e).to be_is_a(StudentEnrollment)}
    end

    it "touches only users whose enrollments were updated" do
      Timecop.freeze(1.hour.ago) do
        @david_sr = user_with_pseudonym(:username => 'david_richards@example.com')
        @david_jr = user_with_pseudonym(:username => 'david_richards_jr@example.com')
        @course.enroll_student(@david_jr)
      end
      EnrollmentsFromUserList.process(UserList.new(list_to_parse), @course)
      cutoff = 30.minutes.ago
      expect(@david_sr.reload.updated_at).to be > cutoff
      expect(@david_jr.reload.updated_at).to be < cutoff
    end
  end

end


def list_to_parse
  %{david@example.com, "Richards, David" <david_richards@example.com>, David Richards <david_richards_jr@example.com>}
end

def list_to_parse_with_repeats
  %{david@example.com, "Richards, David" <david_richards@example.com>, David Richards <david_richards_jr@example.com>, david_richards_jr@example.com, DAVID@example.com}
end
