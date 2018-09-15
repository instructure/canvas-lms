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

require_relative '../../common'
require_relative '../pages/moderate_page'
require_relative '../pages/speedgrader_page'

describe 'Audit Trail' do
  include_context 'in-process server selenium tests'

  before(:once) do
    skip('Unskip with GRADE-1075')
    @account = Account.default
    role1 = @account.roles.create!(name: "Auditor", base_role_type: "TeacherEnrollment")
    @account.role_overrides.create!(role: role1, permission: :view_audit_trail, enabled: true)

    # a course with 3 teachers, 1 auditor
    @teacher1 = course_with_teacher(name: 'Teacher Boss1', active_user: true, active_enrollment: true).user
    @teacher2 = course_with_teacher(course: @course, name: 'Teacher Boss2', active_user: true, active_enrollment: true).user
    @teacher3 = course_with_teacher(course: @course, name: 'Teacher Boss3', active_user: true, active_enrollment: true).user
    @auditor = course_with_user('TeacherEnrollment', course: @course, role: role1, name: "Auditor Person", active_course: true, active_enrollment: true).user

    # enroll two students
    @student1 = course_with_student(course: @course, name: 'First Student', active_user: true, active_enrollment: true).user
    @student2 = course_with_student(course: @course, name: 'Second Student', active_user: true, active_enrollment: true).user

    # create moderated assignment with teacher3 as final grader
    @assignment = @course.assignments.create!(
      title: 'moderated assignment',
      grader_count: 2,
      final_grader_id: @teacher3.id,
      submission_types: 'online_text_entry',
      grading_type: 'points',
      points_possible: 10,
      moderated_grading: true
    )

    @assignment.grade_student(@student1, grade: 10, grader: @teacher1, provisional: true)
    @assignment.grade_student(@student2, grade: 8, grader: @teacher1, provisional: true)
    @assignment.grade_student(@student1, grade: 6, grader: @teacher2, provisional: true)
    @assignment.grade_student(@student2, grade: 5, grader: @teacher2, provisional: true)

    submissions = @assignment.find_or_create_submissions([@student1, @student2])

    submissions.each do |submission|
      submission.add_comment(author: @teacher1, comment: 'Just a comment by teacher1', provisional: true)
      submission.add_comment(author: @teacher2, comment: 'Just a comment by teacher2', provisional: true)
    end
  end

  before :each do
    skip('Unskip with GRADE-1075')
    user_session(@teacher3)

    ModeratePage.visit(@course.id, @assignment.id)
    ModeratePage.select_provisional_grade_for_student_by_position(@student1, 1)
    ModeratePage.select_provisional_grade_for_student_by_position(@student2, 2)

    # post the grades
    ModeratePage.click_post_grades_button
    driver.switch_to.alert.accept
    wait_for_ajaximations
    # wait for element to exist, means page has loaded
    ModeratePage.grades_posted_button
    # unmute using Display to Students button
    ModeratePage.click_display_to_students_button
    driver.switch_to.alert.accept
    wait_for_ajaximations
    # wait for element to exist, means page has loaded
    ModeratePage.grades_visible_to_students_button

    # change sesison to auditor
    user_session(@auditor)
    Speedgrader.visit(@course.id, @assignment.id)

  end

  it 'shows entry for submission comments', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    #verify that the submission comments created above show in audit trail
    Speedgrader.click_audit_link
    wait_for_ajaximations
    expect(Speedgrader.audit_entries).to include_text("Just a comment by teacher1")
  end

  it 'shows entry for submission comments deleted', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    Speedgrader.delete_comment[0].click
    accept_alert
    wait_for_ajaximations
    # delete a comment, verify there is an entry
    expect(Speedgrader.audit_entries).to include_text("Remove comment")
  end

  it 'shows entry for grades posted', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    # verify there is an entry for when the grades were posted
    expect(Speedgrader.audit_entries).to include_text("Posted Grade")
  end

  it 'show entry for grades displayed to students', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    # verify there is an entry for when unmuted
    expect(Speedgrader.audit_entries).to include_text("Unmuted assignment")
  end

  it 'shows entry for editing anonymous grading', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    @assignment.update!(anonymous_grading: true)
    # make some edits to the assignment, verify in audit trail
    # (final grader, comment visibility, # of graders, muted on/off, anonymous on/off, etc.)
    expect(Speedgrader.audit_entries).to include_text("Anonymouse turned on")
  end

  it 'shows entry for editing graders anon to graders', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    @assignment.update!(graders_anonymous_to_graders: true)
    # make some edits to the assignment, verify in audit trail
    # (final grader, comment visibility, # of graders, muted on/off, anonymous on/off, etc.)
    expect(Speedgrader.audit_entries).to include_text("Graders anonymous to graders turned on")
  end

  it 'shows entry for editing grader names visible to final grader', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    @assignment.update!(grader_names_visible_to_final_grader: false)
    # make some edits to the assignment, verify in audit trail
    # (final grader, comment visibility, # of graders, muted on/off, anonymous on/off, etc.)
    expect(Speedgrader.audit_entries).to include_text("Grader names visible to final grader turned off")
  end

  it 'shows entry for editing grader comments visible', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    @assignment.update!(grader_comments_visible_to_graders: false)
    # make some edits to the assignment, verify in audit trail
    # (final grader, comment visibility, # of graders, muted on/off, anonymous on/off, etc.)
    expect(Speedgrader.audit_entries).to include_text("Grader comments visisble to graders turned off")
  end

  it 'shows entry for editing grader count', priority: "1", test_id: 3513995 do
    skip('Unskip with GRADE-1075')
    @assignment.update!(grader_count: 3)
    # make some edits to the assignment, verify in audit trail
    # (final grader, comment visibility, # of graders, muted on/off, anonymous on/off, etc.)
    expect(Speedgrader.audit_entries).to include_text("Grader count updated to 3")
  end
end
