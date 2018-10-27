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

require_relative '../spec_helper'

describe 'ToDoListPresenter' do
  context 'moderated assignments' do
    let(:course) { Course.create! }
    let(:student) { course_with_student(course: course, active_all: true).user }
    let(:grader) { course_with_teacher(course: course, active_all: true).user }
    let(:final_grader) { course_with_teacher(course: course, active_all: true).user }

    before :each do
      assignment = Assignment.create!(
        context: course,
        title: 'report',
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 2,
        final_grader: final_grader
      )
      assignment.submit_homework(student, body: 'biscuits')
      assignment.grade_student(student, grade: '1', grader: grader, provisional: true)
    end

    it 'returns moderated assignments that user is the final grader for' do
      presenter = ToDoListPresenter.new(nil, final_grader, nil)
      expect(presenter.needs_moderation.first.title).to eq 'report'
    end

    it 'does not return moderated assignments that user is not the final grader for' do
      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_moderation).to be_empty
    end
  end

  context 'grading assignments' do
    let(:course1) { Course.create! }
    let(:course2) { Course.create! }
    let(:student) { user_with_multiple_enrollments('StudentEnrollment') }
    let(:student2) { user_with_multiple_enrollments('StudentEnrollment') }
    let(:grader) { user_with_multiple_enrollments('TeacherEnrollment') }
    let(:final_grader) { user_with_multiple_enrollments('TeacherEnrollment') }


    def user_with_multiple_enrollments(enrollment_type)
      result = course_with_user(enrollment_type, course: course1, active_all: true).user
      course_with_user(enrollment_type, user: result, course: course2, active_all: true).user
    end

    before :each do
      Assignment.create!(
        context: course1,
        title: 'assignment1',
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 2,
        final_grader: final_grader
      ).submit_homework(student, body: 'biscuits!!! and potatoes')
      Assignment.create!(
        context: course2,
        title: 'assignment2',
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 2,
        final_grader: final_grader
      ).submit_homework(student, body: 'i really like potatoes')
    end

    it 'returns for assignments that need grading for a teacher that is a grader' do
      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_grading.map(&:title)).to contain_exactly('assignment1', 'assignment2')
    end

    it 'does not explode if the teacher is also a cross-shard site admin' do
      expect_any_instantiation_of(grader).to receive(:roles).and_return(['consortium_admin'])
      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_grading.map(&:title)).to contain_exactly('assignment1', 'assignment2')
    end

    it 'doesnt returns for assignments that need grading for a teacher that isnt a grader' do
      RoleOverride.create!(:context => course1.account,
                           :permission => 'manage_grades',
                           :role => teacher_role,
                           :enabled => false)

      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_grading.size).to eq(0)
    end

    it 'returns assignments from multiple types' do
      grading = Assignment.where(:title => 'assignment1').first
      grading.grade_student(student, grade: '1', grader: grader, provisional: true)

      presenter = ToDoListPresenter.new(nil, grader, nil)
      expect(presenter.needs_grading.map(&:title)).to contain_exactly('assignment2')

      presenter = ToDoListPresenter.new(nil, final_grader, nil)
      expect(presenter.needs_moderation.map(&:title)).to contain_exactly('assignment1')
    end
  end

  context "peer reviews" do
    let(:course1) { Course.create! }
    let(:reviewer) { course_with_user('StudentEnrollment', course: course1, active_all: true).user }
    let(:reviewee) { course_with_user('StudentEnrollment', course: course1, active_all: true).user }

    before :each do
      course1.offer!
      assignment = Assignment.create({
        context: course1,
        title: 'assignment3',
        submission_types: 'online_text_entry',
        due_at: 1.day.from_now,
        peer_reviews: true
      })
      assignment.publish
      assessment = assignment.assign_peer_review(reviewer, reviewee)
      assignment.submit_homework(reviewee, body: 'you say potato...')
    end

    it "does not blow up" do
      presenter = ToDoListPresenter.new(nil, reviewer, [course1])
      # basically checking that ToDoListPresenter.initialize didn't raise and error
      expect(presenter).not_to be_nil
    end
  end
end
