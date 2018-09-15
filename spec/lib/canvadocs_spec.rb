#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe Canvadocs do
  describe '.user_session_params' do
    let(:course) { Course.create! }
    let(:student) { User.create!(name: 'Severus Student', short_name: 'Sev, the Student') }
    let(:teacher) { User.create!(name: 'Giselle Grader', short_name: 'Gise, the Grader') }
    let(:assignment) { course.assignments.create!(title: 'an assignment') }
    let(:submission) { assignment.submission_for_student(student) }
    let(:attachment) do
      Attachment.create!(
        content_type: 'application/pdf',
        context: course,
        user: student,
        uploaded_data: stub_png_data,
        filename: 'file.png'
      )
    end

    let(:session_params) { Canvadocs.user_session_params(attachment, @current_user) }
    let(:user_filter) { session_params[:user_filter] }

    before(:each) do
      course.enroll_student(student).accept(true)
      course.enroll_teacher(teacher).accept(true)
      attachment.associate_with(submission)
      @current_user = student
    end

    describe 'parameters describing the current user' do
      it 'includes the short name of the current user with commas removed' do
        # This format for the name is in line with what we send in
        # the canvadocs default user options.
        expect(session_params[:user_name]).to eq 'Sev the Student'
      end

      it 'includes the real global ID of the current user' do
        expect(session_params[:user_id]).to eq student.global_id.to_s
      end

      context 'when a student is viewing' do
        it 'includes a user_role of "student"' do
          expect(session_params[:user_role]).to eq 'student'
        end

        it 'includes the anonymous ID of the student' do
          expect(session_params[:user_anonymous_id]).to eq submission.anonymous_id
        end
      end

      context 'when a grader is viewing' do
        before(:each) do
          @current_user = teacher
        end

        it 'includes a user_role that is based on the user enrollment type' do
          expect(session_params[:user_role]).to eq 'teacher'
        end

        it 'does not include an anonymous ID if the assignment is not moderated' do
          assignment.update!(moderated_grading: false)
          expect(session_params).not_to include(:user_anonymous_id)
        end

        context 'when the assignment is moderated' do
          before(:each) do
            assignment.update!(moderated_grading: true, final_grader: teacher, grader_count: 1)
          end

          it 'includes the anonymous ID of the grader when the grader has taken a slot' do
            assignment.moderation_graders.create!(user: teacher, anonymous_id: 'abcde', slot_taken: true)
            expect(session_params[:user_anonymous_id]).to eq 'abcde'
          end

          it 'includes the anonymous ID of the grader when the grader has not taken a slot' do
            assignment.moderation_graders.create!(user: teacher, anonymous_id: 'abcde', slot_taken: false)
            expect(session_params[:user_anonymous_id]).to eq 'abcde'
          end

          it 'does not include the anonymous ID if the grader does not have a moderation_grader record' do
            expect(session_params[:user_anonymous_id]).to be nil
          end
        end
      end
    end

    describe 'user filter' do
      let(:student_real_data) { {type: 'real', role: 'student', id: student.global_id.to_s, name: 'Sev the Student'} }
      let(:student_anonymous_data) { hash_including(type: 'anonymous', role: 'student', id: submission.anonymous_id) }
      let(:teacher_real_data) { {type: 'real', role: 'teacher', id: teacher.global_id.to_s, name: 'Gise the Grader'} }

      context 'for an unmoderated anonymized assignment' do
        before(:each) do
          assignment.update!(anonymous_grading: true, muted: true)
        end

        context 'when a student is viewing' do
          before(:each) do
            @current_user = student
          end

          it 'includes only the current user' do
            @current_user = student
            expect(user_filter).to include(student_real_data)
          end

          it 'requests that all returned annotations belong to users in the user_filter' do
            expect(session_params[:restrict_annotations_to_user_filter]).to be true
          end
        end

        context 'when a teacher is viewing' do
          before(:each) do
            @current_user = teacher
          end

          it 'includes anonymous information for the student' do
            expect(user_filter).to include(student_anonymous_data)
          end

          it 'does not request that all returned annotations belong to users in the user_filter' do
            expect(session_params[:restrict_annotations_to_user_filter]).to be false
          end
        end
      end

      context 'for an unmoderated non-anonymized assignment' do
        before(:each) do
          assignment.update!(anonymous_grading: false, muted: false)
        end

        context 'when a student is viewing' do
          before(:each) do
            @current_user = student
          end

          it 'omits the user filter entirely when a student is viewing' do
            expect(session_params).not_to include(:user_filter)
          end

          it 'omits the restrict_annotations_to_user_filter entirely' do
            expect(session_params).not_to have_key(:restrict_annotations_to_user_filter)
          end
        end

        context 'when a teacher is viewing' do
          before(:each) do
            @current_user = teacher
          end

          it 'omits the user filter entirely' do
            expect(session_params).not_to include(:user_filter)
          end

          it 'omits the restrict_annotations_to_user_filter entirely' do
            expect(session_params).not_to have_key(:restrict_annotations_to_user_filter)
          end
        end
      end

      context 'for a moderated assignment' do
        let(:final_grader) { teacher }
        let(:final_grader_real_data) do
          { type: 'real', role: 'teacher', id: teacher.global_id.to_s, name: 'Gise the Grader' }
        end

        let(:final_grader_anonymous_data) { hash_including(type: 'anonymous', role: 'teacher', id: 'qqqqq') }
        let(:provisional_grader_anonymous_data) { hash_including(type: 'anonymous', role: 'ta', id: 'wwwww') }
        let(:provisional_grader) { User.create!(name: 'Publius Provisional', short_name: 'Pub, the Prov') }
        let(:provisional_grader_real_data) do
          { type: 'real', role: 'ta', id: provisional_grader.global_id.to_s, name: 'Pub the Prov' }
        end

        before(:each) do
          assignment.update!(moderated_grading: true, final_grader: final_grader, grader_count: 1)
          assignment.moderation_graders.create!(user: final_grader, anonymous_id: 'qqqqq')
          course.enroll_ta(provisional_grader).accept(true)
          assignment.moderation_graders.create!(user: provisional_grader, anonymous_id: 'wwwww')
        end

        context 'when a student is viewing' do
          before(:each) do
            @current_user = student
          end

          it 'includes the student' do
            expect(user_filter).to include(student_real_data)
          end

          it 'excludes graders if grades are not published' do
            expect(user_filter).not_to include(hash_including(role: 'teacher'))
          end

          it 'includes the selected grader if grades are published' do
            submission.update!(grader: provisional_grader)
            attachment.associate_with(submission)
            assignment.update!(grades_published_at: Time.zone.now)
            expect(user_filter).to include(provisional_grader_real_data)
          end

          it 'excludes graders that were not selected if grades are published' do
            submission.update!(grader: provisional_grader)
            attachment.associate_with(submission)
            assignment.update!(grades_published_at: Time.zone.now)
            expect(user_filter).not_to include(final_grader_real_data)
          end

          it 'requests that all returned annotations belong to users in the user_filter' do
            expect(session_params[:restrict_annotations_to_user_filter]).to be true
          end
        end

        context 'when a provisional grader is viewing' do
          before(:each) do
            @current_user = provisional_grader
          end

          it 'includes real data for the current grader' do
            expect(user_filter).to include(provisional_grader_real_data)
          end

          it 'includes anonymous student data when anonymizing students' do
            assignment.update!(anonymous_grading: true, muted: true)
            expect(user_filter).to include(student_anonymous_data)
          end

          it 'returns an anonymous name for the student when anonymizing students' do
            assignment.update!(anonymous_grading: true, muted: true)
            student_entry = user_filter.find { |entry| entry[:role] == 'student' }
            expect(student_entry[:name]).to eq 'Student'
          end

          it 'includes real student data when not anonymizing students' do
            assignment.update!(anonymous_grading: false, muted: false)
            expect(user_filter).to include(student_real_data)
          end

          it 'includes real grader data when showing identities of other graders' do
            assignment.update!(grader_comments_visible_to_graders: true, graders_anonymous_to_graders: false)
            expect(user_filter).to include(final_grader_real_data)
          end

          it 'includes anonymous grader data when hiding identities of other graders' do
            assignment.update!(grader_comments_visible_to_graders: true, graders_anonymous_to_graders: true)
            expect(user_filter).to include(final_grader_anonymous_data)
          end

          it 'returns names in the format "Grader #" for graders whose identities are hidden' do
            assignment.update!(grader_comments_visible_to_graders: true, graders_anonymous_to_graders: true)
            final_grader_entry = user_filter.find { |entry| entry[:id] == 'qqqqq' }
            expect(final_grader_entry[:name]).to eq 'Grader 1'
          end

          it 'omits other graders when comments from other graders are hidden' do
            assignment.update!(grader_comments_visible_to_graders: false)
            user_filter_ids = user_filter.map { |entry| entry[:id] }
            expect(user_filter_ids).to match_array([student.global_id.to_s, provisional_grader.global_id.to_s])
          end

          it 'requests that all returned annotations belong to users in the user_filter' do
            expect(session_params[:restrict_annotations_to_user_filter]).to be true
          end
        end

        context 'when the final grader is viewing' do
          before(:each) do
            @current_user = final_grader
          end

          it 'includes real grader data when grader names are visible to the final grader' do
            assignment.update!(grader_names_visible_to_final_grader: true)
            expect(user_filter).to include(provisional_grader_real_data)
          end

          it 'includes anonymous grader data when grader names are not visible to the final grader' do
            assignment.update!(grader_names_visible_to_final_grader: false)
            expect(user_filter).to include(provisional_grader_anonymous_data)
          end

          it 'returns names in the format "Grader #" for graders not visible to the final grader' do
            assignment.update!(grader_names_visible_to_final_grader: false)
            final_grader_entry = user_filter.find { |entry| entry[:id] == 'wwwww' }
            expect(final_grader_entry[:name]).to eq 'Grader 2'
          end

          it 'always includes other graders when the final grader is viewing' do
            assignment.update!(grader_comments_visible_to_graders: false)
            user_filter_ids = user_filter.map { |entry| entry[:id] }
            expected_ids = [final_grader.global_id.to_s, provisional_grader.global_id.to_s, student.global_id.to_s]
            expect(user_filter_ids).to match_array(expected_ids)
          end

          it 'requests that all returned annotations belong to users in the user_filter' do
            expect(session_params[:restrict_annotations_to_user_filter]).to be true
          end
        end
      end
    end
  end
end
