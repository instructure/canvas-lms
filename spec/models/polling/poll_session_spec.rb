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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Polling::PollSession do
  before(:each) do
    course
    @course.root_account.disable_feature!(:draft_state)
    @section = @course.course_sections.create!(name: 'Section 2')
    teacher_in_course(course: @course, active_all: true)

    @poll = Polling::Poll.create!(user: @teacher, question: 'A Test Poll')
  end

  context "creating a poll session" do
    it "requires an associated poll" do
      lambda { Polling::PollSession.create!(course: @course, course_section: @section) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                                            /Poll can't be blank/)
    end

    it "requires an associated course" do
      lambda { Polling::PollSession.create!(poll: @poll, course_section: @section) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                                        /Course can't be blank/)
    end

    it "insures that the given course section belongs to the given course" do
      old_course = @course
      new_course = course

      section = new_course.course_sections.create!(name: "Alien Section")
      lambda { Polling::PollSession.create!(poll: @poll, course: old_course, course_section: section) }.should raise_error(ActiveRecord::RecordInvalid,
                                                                                                                           /That course section does not belong to the existing course/)
    end

    it "allows a session to be created without a section" do
      @session = Polling::PollSession.new(poll: @poll, course: @course)
      @session.save
      @session.should be_valid
    end

    it "doesn't allow public results to be displayed by default" do
      @session = Polling::PollSession.new(poll: @poll, course: @course, course_section: @section)
      @session.save
      @session.has_public_results.should be_false
    end

    it "saves successfully" do
      @session = Polling::PollSession.new(poll: @poll, course: @course, course_section: @section)
      @session.save
      @session.should be_valid
    end
  end

  describe ".available_for" do
    before(:each) do
      @course1 = course_model
      @course2 = course_model
      @teacher1 = teacher_in_course(course: @course1).user
      @teacher2 = teacher_in_course(course: @course2).user
      @student1 = student_in_course(course: @course1).user
      @student2 = student_in_course(course: @course2).user
      @unenrolled_student = user_model
      @poll1 = Polling::Poll.create!(user: @teacher1, question: 'A Test Poll')
      @poll2 = Polling::Poll.create!(user: @teacher2, question: 'Another Test Poll')
    end

      it "returns the poll sessions available for a user" do
        student1_sessions = []
        student2_sessions = []

        3.times do |n|
          student1_sessions << Polling::PollSession.create(poll: @poll1, course: @course1)
        end

        Polling::PollSession.available_for(@student1).size.should == 3
        Polling::PollSession.available_for(@student2).size.should == 0
        Polling::PollSession.available_for(@student1).should == student1_sessions

        2.times do |n|
          student2_sessions << Polling::PollSession.create(poll: @poll2, course: @course2)
        end

        Polling::PollSession.available_for(@student1).size.should == 3
        Polling::PollSession.available_for(@student2).size.should == 2
        Polling::PollSession.available_for(@student2).should == student2_sessions
    end
  end

end
