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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')
require_dependency "alerts/user_note"

module Alerts
  describe UserNote do

    # course_with_teacher(:active_all => 1)
    # @teacher = @user
    # @user = nil
    # student_in_course(:active_all => 1)
    # UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }

    describe '#should_not_receive_message?' do

      before :once do
        course_with_teacher(:active_all => 1)
        root_account = @course.root_account
        root_account.enable_user_notes = true
        root_account.save!
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
      end

      it 'should validate the length of title' do
        @long_string = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                        qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                        qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                        qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                        qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'
        expect(lambda {::UserNote.create!(creator: @teacher, user: @user, title: @long_string) { |un| un.created_at = Time.now - 30.days }}).
          to raise_error("Validation failed: Title is too long (maximum is 255 characters)")
      end

      it 'returns true when the course root account has user notes disabled' do
        root_account = @course.root_account
        root_account.enable_user_notes = false
        root_account.save!

        ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }

        user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
        expect(user_note_alert.should_not_receive_message?(@student.id, 29)).to eq true
      end

      it 'returns true when the student has received a note less than threshold days ago' do
        ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }

        user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
        expect(user_note_alert.should_not_receive_message?(@student.id, 31)).to eq true
      end

      it 'returns false when the student has not received a note less than threshold days ago' do
        ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }

        user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
        expect(user_note_alert.should_not_receive_message?(@student.id, 29)).to eq false
      end

      it 'handles multiple user notes' do
        ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 30.days }
        ::UserNote.create!(:creator => @teacher, :user => @user) { |un| un.created_at = Time.now - 10.days }

        user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
        expect(user_note_alert.should_not_receive_message?(@student.id, 29)).to eq true
      end

      it 'handles notes from multiple students' do
        student_1 = @student
        course_with_student({course: @course})
        student_2 = @student

        ::UserNote.create!(:creator => @teacher, :user => student_1) { |un| un.created_at = Time.now - 30.days }
        ::UserNote.create!(:creator => @teacher, :user => student_2) { |un| un.created_at = Time.now - 10.days }

        ungraded_timespan = Alerts::UserNote.new(@course, [student_1.id, student_2.id], [@teacher.id])
        expect(ungraded_timespan.should_not_receive_message?(student_1.id, 2)).to eq false
      end


      context 'when the student has not received any notes' do
        context 'when there is a course start_at' do
          it 'returns true when threshold days from course start are exceeded' do
            @course.start_at = Time.now - 2.days
            @course.save!

            user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
            expect(user_note_alert.should_not_receive_message?(@student.id, 3)).to eq true
          end

          it 'returns false when threshold days from course start are not exceeded' do
            @course.start_at = Time.now - 7.days
            @course.save!

            user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
            expect(user_note_alert.should_not_receive_message?(@student.id, 3)).to eq false
          end

        end

        context 'when there is no course start_at' do
          it 'returns true when threshold days from course created at are exceeded' do
            @course.created_at = Time.now - 2.days
            @course.start_at = nil
            @course.save!

            user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
            expect(user_note_alert.should_not_receive_message?(@student.id, 3)).to eq true
          end

          it 'returns false when threshold days from course created at are not exceeded' do
            @course.created_at = Time.now - 7.days
            @course.start_at = nil
            @course.save!

            user_note_alert = Alerts::UserNote.new(@course, [@student.id], [@teacher.id])
            expect(user_note_alert.should_not_receive_message?(@student.id, 3)).to eq false
          end
        end
      end

    end
  end
end
