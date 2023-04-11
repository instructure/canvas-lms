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

module SisGradePassbackCommon
  def getpseudonym(user_sis_id)
    pseudo = Pseudonym.where(sis_user_id: user_sis_id).first
    expect(pseudo).not_to be_nil
    pseudo
  end

  def getuser(user_sis_id)
    user = getpseudonym(user_sis_id).user
    expect(user).not_to be_nil
    user
  end

  def getsection(section_sis_id)
    section = CourseSection.where(sis_source_id: section_sis_id).first
    expect(section).not_to be_nil
    section
  end

  def getenroll(user_sis_id, section_sis_id)
    e = Enrollment.where(user_id: getuser(user_sis_id).id, course_section_id: getsection(section_sis_id).id).first
    expect(e).not_to be_nil
    e
  end

  def grade_passback_setup(wait_for_success)
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status",
      "T1,Teacher1,,T,1,t1@example.com,active",
      "S1,Student1,,S,1,s1@example.com,active",
      "S2,Student2,,S,2,s2@example.com,active",
      "S3,Student3,,S,3,s3@example.com,active",
      "S4,Student4,,S,4,s4@example.com,active",
      "S5,Student5,,S,5,s5@example.com,active",
      "S6,Student6,,S,6,s6@example.com,active"
    )
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "C1,C1,C1,,,active"
    )
    @course = Course.where(sis_source_id: "C1").first
    @course.assignment_groups.create(name: "Assignments")
    @teacher = getuser("T1")
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S1,C1,S1,active,,",
      "S2,C1,S2,active,,",
      "S3,C1,S3,active,,",
      "S4,C1,S4,active,,"
    )
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status",
      ",T1,teacher,S1,active",
      ",S1,student,S1,active",
      ",S2,student,S2,active",
      ",S3,student,S2,active",
      ",S4,student,S1,active",
      ",S5,student,S3,active",
      ",S6,student,S4,active"
    )
    a1 = @course.assignments.create!(title: "A1", points_possible: 10)
    a2 = @course.assignments.create!(title: "A2", points_possible: 10)

    a1.grade_student(getuser("S1"), { grade: "6", grader: @teacher })
    a1.grade_student(getuser("S2"), { grade: "6", grader: @teacher })
    a1.grade_student(getuser("S3"), { grade: "7", grader: @teacher })
    a1.grade_student(getuser("S5"), { grade: "7", grader: @teacher })
    a1.grade_student(getuser("S6"), { grade: "8", grader: @teacher })
    a2.grade_student(getuser("S1"), { grade: "8", grader: @teacher })
    a2.grade_student(getuser("S2"), { grade: "9", grader: @teacher })
    a2.grade_student(getuser("S3"), { grade: "9", grader: @teacher })
    a2.grade_student(getuser("S5"), { grade: "10", grader: @teacher })
    a2.grade_student(getuser("S6"), { grade: "10", grader: @teacher })

    @stud5, @stud6, @sec4 = nil, nil, nil
    Pseudonym.where(sis_user_id: "S5").first.tap do |p|
      @stud5 = p
      p.sis_user_id = nil
      p.save
    end

    Pseudonym.where(sis_user_id: "S6").first.tap do |p|
      @stud6 = p
      p.sis_user_id = nil
      p.save
    end

    getsection("S4").tap do |s|
      @sec4 = s
      s.sis_source_id = nil
      s.save
    end

    @course.grading_standard_enabled = true
    @course.save!
    GradeCalculator.recompute_final_score(%w[S1 S2 S3 S4].map { |x| getuser(x).id }, @course.id)
    @course.reload

    @plugin = Canvas::Plugin.find!("grade_export")
    @ps = PluginSetting.new(name: @plugin.id, settings: @plugin.default_settings)
    @ps.posted_settings = @plugin.default_settings.merge({
                                                           format_type: "instructure_csv",
                                                           wait_for_success: wait_for_success ? "yes" : "no",
                                                           publish_endpoint: "http://localhost/endpoint"
                                                         })
    @ps.save!

    @course.offer!
    user_session(@teacher)

    @course.grading_standard_id = 0
    @course.save!

    get "/courses/#{@course.id}/settings"
    f("#tab-grade-publishing-link").click
    wait_for_ajaximations

    expect(f("#publish_grades_messages").text).to eq "Unpublished - 6"
    driver.execute_script "window.confirm = function(msg) { return true; }"

    csv = <<~CSV
      publisher_id,publisher_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score,grade
      #{@teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70,C-
      #{@teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75,C
      #{@teacher.id},T1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80,B-
      #{@teacher.id},T1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0,F
      #{@teacher.id},T1,#{getsection("S3").id},S3,#{@stud5.id},,#{Enrollment.where(user_id: @stud5.user.id, course_section_id: getsection("S3").first.id).id},active,85,B
      #{@teacher.id},T1,#{@sec4.id},,#{@stud6.id},,#{Enrollment.where(user_id: @stud6.user.id, course_section_id: @sec4.id).first.id},active,90,A-
    CSV
    expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
    f("#publish_grades_link").click
    wait_for_ajaximations
    expect(f("#publish_grades_messages").text).to eq(wait_for_success ? "Publishing - 6" : "Published - 6")
  end
end
