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

require 'spec_helper'
require 'lti2_spec_helper'

describe Assignment::SpeedGrader do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "some user")
  end

  context "create and publish a course with 2 students" do
    let_once(:student_A) do
      course_with_student(course: @course, user_name: "Student A")
      @student
    end
    let_once(:student_B) do
      course_with_student(course: @course, user_name: "Student B")
      @student
    end
    let_once(:teacher) do
      course_with_teacher(course: @course, user_name: "an teacher")
      @teacher
    end

    context "add students to the group" do
      let(:category) { @course.group_categories.create! name: "Assignment Groups" }
      let(:assignment) do
        @course.assignments.create!(
          group_category_id: category.id,
          grade_group_students_individually: false,
          submission_types: %w(text_entry)
        )
      end
      let(:homework_params) do
        {
          submission_type: 'online_text_entry',
          body: 'blah',
          comment: 'a group comment during submission from student A',
          group_comment: true
        }.freeze
      end
      let(:comment_two_to_group_params) do
        {
          comment: 'a group comment from student A',
          user_id:  student_A.id,
          group_comment: true
        }.freeze
      end
      let(:comment_three_to_group_params) do
        {
          comment: 'a group comment from student B',
          user_id:  student_B.id,
          group_comment: true
        }.freeze
      end
      let(:comment_four_private_params) do
        {
          comment: 'a private comment from student A',
          user_id:  student_A.id,
        }.freeze
      end
      let(:comment_five_private_params) do
        {
          comment: 'a private comment from student B',
          user_id:  student_B.id,
        }.freeze
      end
      let(:comment_six_to_group_params) do
        {
          comment: 'a group comment from teacher',
          user_id:  teacher.id,
          group_comment: true
        }.freeze
      end
      let(:comment_seven_private_params) do
        {
          comment: 'a private comment from teacher',
          user_id:  teacher.id,
        }.freeze
      end

      before do
        group = category.groups.create!(name: 'a group', context: @course)
        group.add_user(student_A)
        group.add_user(student_B)
        assignment.submit_homework(student_A, homework_params.dup)
        assignment.update_submission(student_A, comment_two_to_group_params.dup)
        assignment.update_submission(student_A, comment_three_to_group_params.dup)
        assignment.update_submission(student_A, comment_four_private_params.dup)
        assignment.update_submission(student_A, comment_five_private_params.dup)
        assignment.update_submission(student_A, comment_six_to_group_params.dup)
        assignment.update_submission(student_A, comment_seven_private_params.dup)
      end

      it "only shows group comments" do
        json = Assignment::SpeedGrader.new(assignment, teacher).json
        student_a_submission = json.fetch(:submissions).select { |s| s[:user_id] == student_A.id.to_s }.first
        comments = student_a_submission.fetch(:submission_comments).map do |comment|
          comment.slice(:author_id, :comment)
        end
        expect(comments).to include({
          "author_id" => student_A.id.to_s,
          "comment" => homework_params.fetch(:comment)
        },{
          "author_id" => comment_two_to_group_params.fetch(:user_id).to_s,
          "comment" => comment_two_to_group_params.fetch(:comment)
        },{
          "author_id" => comment_three_to_group_params.fetch(:user_id).to_s,
          "comment" => comment_three_to_group_params.fetch(:comment)
        },{
          "author_id" => comment_six_to_group_params.fetch(:user_id).to_s,
          "comment" => comment_six_to_group_params.fetch(:comment)
        })
        expect(comments).not_to include({
          "author_id" => comment_four_private_params.fetch(:user_id).to_s,
          "comment" => comment_four_private_params.fetch(:comment)
        },{
          "author_id" => comment_five_private_params.fetch(:user_id).to_s,
          "comment" => comment_five_private_params.fetch(:comment)
        },{
          "author_id" => comment_seven_private_params.fetch(:user_id).to_s,
          "comment" => comment_seven_private_params.fetch(:comment)
      })
      end
    end
  end

  it "includes comments' created_at" do
    setup_assignment_with_homework
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(:comment => 'comment')
    json = Assignment::SpeedGrader.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments].first[:created_at].to_i).to eql @comment.created_at.to_i
  end

  it "excludes provisional comments" do
    setup_assignment_with_homework
    @assignment.moderated_grading = true
    @assignment.grader_count = 2
    @assignment.save!
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(comment: 'comment', author: @teacher, provisional: true)
    json = Assignment::SpeedGrader.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments]).to be_empty
  end

  context "students and active course sections" do
    before(:once) do
      @course = course_factory(active_course: true)
      @teacher, @student1, @student2 = (1..3).map{User.create}
      @assignment = Assignment.create!(title: "title", context: @course, only_visible_to_overrides: true)
      @course.enroll_teacher(@teacher)
      @course.enroll_student(@student2, :enrollment_state => 'active')
      @section1 = @course.course_sections.create!(name: "test section 1")
      @section2 = @course.course_sections.create!(name: "test section 2")
      student_in_section(@section1, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section1})
    end

    it "includes only students and sections with overrides for differentiated assignments" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json[:context][:students].map{|s| s[:id]}).to include(@student1.id.to_s)
      expect(json[:context][:students].map{|s| s[:id]}).not_to include(@student2.id.to_s)
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}).to include(@section1.id.to_s)
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}).not_to include(@section2.id.to_s)
    end

    it "sorts student view students last" do
      test_student = @course.student_view_student
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json[:context][:students].last[:id]).to eq(test_student.id.to_s)
    end

    it "includes all students when is only_visible_to_overrides false" do
      @assignment.only_visible_to_overrides = false
      @assignment.save!
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json[:context][:students].map{|s| s[:id]}).to include(@student1.id.to_s)
      expect(json[:context][:students].map{|s| s[:id]}).to include(@student2.id.to_s)
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}).to include(@section1.id.to_s)
      expect(json[:context][:active_course_sections].map{|cs| cs[:id]}).to include(@section2.id.to_s)
    end
  end

  context "with submissions" do
    let!(:now) { Time.zone.now }

    before do
      section_1 = @course.course_sections.create!(name: 'Section one')
      section_2 = @course.course_sections.create!(name: 'Section two')

      @assignment = @course.assignments.create!(title: 'Overridden assignment', due_at: 5.days.ago(now))

      @student_1 = user_with_pseudonym(active_all: true, username: 'student1@example.com')
      @student_2 = user_with_pseudonym(active_all: true, username: 'student2@example.com')

      @course.enroll_student(@student_1, :section => section_1).accept!
      @course.enroll_student(@student_2, :section => section_2).accept!

      o1 = @assignment.assignment_overrides.build
      o1.due_at = 2.days.ago(now)
      o1.due_at_overridden = true
      o1.set = section_1
      o1.save!

      o2 = @assignment.assignment_overrides.build
      o2.due_at = 2.days.from_now(now)
      o2.due_at_overridden = true
      o2.set = section_2
      o2.save!

      @assignment.submit_homework(@student_1, submission_type: 'online_text_entry', body: 'blah')
      @assignment.submit_homework(@student_2, submission_type: 'online_text_entry', body: 'blah')
    end

    it "returns submission lateness" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        if submission[:workflow_state] == "submitted"
          expect(submission[:late]).to eq user.submissions.first.late?
        end
      end
    end

    it 'returns grading_period_id on submissions' do
      group = @course.root_account.grading_period_groups.create!
      group.enrollment_terms << @course.enrollment_term
      period = group.grading_periods.create!(
        title: 'A Grading Period',
        start_date: now - 2.months,
        end_date: now + 2.months
      )
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      submission = json[:submissions].first
      expect(submission.fetch('grading_period_id')).to eq period.id.to_s
    end

    it "creates a non-annotatable DocViewer session for Discussion attachments" do
      course = student_in_course(active_all: true).course
      assignment = assignment_model(course: course)
      assignment.anonymous_grading = true
      topic = course.discussion_topics.create!(assignment: assignment)
      attachment = attachment_model(
        context: @student,
        uploaded_data: stub_png_data,
        filename: "homework.png"
      )
      entry = topic.reply_from(user: @student, text: "entry")
      entry.attachment = attachment
      entry.save!
      topic.ensure_submission(@student)

      expect(Canvadocs).to receive(:enabled?).twice.and_return(true)
      expect(Canvadocs).to receive(:config).and_return({ a: 1 })
      expect(Canvadoc).to receive(:mime_types).and_return("image/png")

      json = Assignment::SpeedGrader.new(assignment, @teacher).json
      sub = json[:submissions].first[:submission_history].first[:submission]
      canvadoc_url = sub[:versioned_attachments].first.dig(:attachment, :canvadoc_url)
      expect(canvadoc_url.include?("enable_annotations%22:false")).to eq true
    end

    it "creates DocViewer session anonymous instructor annotations if assignment has it set" do
      course = student_in_course(active_all: true).course
      assignment = assignment_model(course: course)
      attachment = attachment_model(
        context: @student,
        uploaded_data: stub_png_data,
        filename: "homework.png"
      )
      assignment.anonymous_instructor_annotations = true
      topic = course.discussion_topics.create!(assignment: assignment)
      entry = topic.reply_from(user: @student, text: "entry")
      entry.attachment = attachment
      entry.save!
      topic.ensure_submission(@student)

      expect(Canvadocs).to receive(:enabled?).twice.and_return(true)
      expect(Canvadocs).to receive(:config).and_return({ a: 1 })
      expect(Canvadoc).to receive(:mime_types).and_return("image/png")

      json = Assignment::SpeedGrader.new(assignment, @teacher).json
      sub = json[:submissions].first[:submission_history].first[:submission]
      canvadoc_url = sub[:versioned_attachments].first.fetch(:attachment).fetch(:canvadoc_url)

      expect(canvadoc_url.include?("anonymous_instructor_annotations%22:true")).to eq true
    end

    it "passes enrollment type to DocViewer" do
      course = student_in_course(active_all: true).course
      assignment = assignment_model(course: course)
      attachment = attachment_model(
        context: @student,
        uploaded_data: stub_png_data,
        filename: "homework.png"
      )
      topic = course.discussion_topics.create!(assignment: assignment)
      entry = topic.reply_from(user: @student, text: "entry")
      entry.attachment = attachment
      entry.save!
      topic.ensure_submission(@student)

      expect(Canvadocs).to receive(:enabled?).twice.and_return(true)
      expect(Canvadocs).to receive(:config).and_return({ a: 1 })
      expect(Canvadoc).to receive(:mime_types).and_return("image/png")

      json = Assignment::SpeedGrader.new(assignment, @teacher).json
      sub = json[:submissions].first[:submission_history].first[:submission]
      canvadoc_url = sub[:versioned_attachments].first.fetch(:attachment).fetch(:canvadoc_url)

      expect(canvadoc_url.include?("enrollment_type%22:%22teacher%22")).to eq true
    end

    it "includes submission missing status in each submission history version" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        next unless user
        submission[:submission_history].each_with_index do |version, idx|
          expect(version[:submission][:missing]).to eq user.submissions.first.submission_history[idx].missing?
        end
      end
    end

    it "includes submission late status in each submission history version" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        next unless user
        submission[:submission_history].each_with_index do |version, idx|
          expect(version[:submission][:late]).to eq user.submissions.first.submission_history[idx].late?
        end
      end
    end

    it "includes submission entered_score and entered_grade in each submission history version" do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        next unless user
        submission[:submission_history].each_with_index do |version, idx|
          submission_version = user.submissions.first.submission_history[idx]
          expect(version[:submission][:entered_score]).to eq submission_version.entered_score
          expect(version[:submission][:entered_grade]).to eq submission_version.entered_grade
        end
      end
    end
  end

  it "includes inline view pingback url for files" do
    assignment = @course.assignments.create! :submission_types => ['online_upload']
    attachment = @student.attachments.create! :uploaded_data => dummy_io, :filename => 'doc.doc', :display_name => 'doc.doc', :context => @student
    assignment.submit_homework @student, :submission_type => :online_upload, :attachments => [attachment]
    json = Assignment::SpeedGrader.new(assignment, @teacher).json
    attachment_json = json['submissions'][0]['submission_history'][0]['submission']['versioned_attachments'][0]['attachment']
    expect(attachment_json['view_inline_ping_url']).to match %r{/users/#{@student.id}/files/#{attachment.id}/inline_view\z}
  end

  it "includes lti launch url in submission history" do
    setup_assignment_without_submission
    @assignment.submit_homework(@user, :submission_type => 'basic_lti_launch', :url => 'http://www.example.com')
    json = Assignment::SpeedGrader.new(@assignment, @teacher).json
    url_json = json['submissions'][0]['submission_history'][0]['submission']['external_tool_url']
    expect(url_json).to eql('http://www.example.com')
  end

  context "course is soft concluded" do
    before :once do
      course_with_teacher(active_all: true)
      @student1 = User.create!
      @student2 = User.create!
      @course.enroll_student(@student1, enrollment_state: 'active')
      @course.enroll_student(@student2, enrollment_state: 'active')
      assignment_model(course: @course)
      @teacher.preferences[:gradebook_settings] = {}
      @teacher.preferences[:gradebook_settings][@course.id] = {
        'show_concluded_enrollments' => 'false'
      }
    end

    it 'does not include concluded students when user preference is to not include' do
      Enrollment.find_by(user: @student1).conclude
      @course.update_attributes!(conclude_at: 1.day.ago, start_at: 2.days.ago)
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json[:context][:students].count).to be 1
    end

    it 'includes concluded when user preference is to include' do
      @teacher.preferences[:gradebook_settings][@course.id]['show_concluded_enrollments'] = 'true'
      Enrollment.find_by(user: @student1).conclude
      @course.update_attributes!(conclude_at: 1.day.ago, start_at: 2.days.ago)
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json[:context][:students].count).to be 2
    end
  end

  context "group assignments" do
    before :once do
      course_with_teacher(active_all: true)
      @gc = @course.group_categories.create! name: "Assignment Groups"
      @groups = [1, 2].map { |i| @gc.groups.create! name: "Group #{i}", context: @course }
      students = create_users_in_course(@course, 6, return_type: :record)
      students.each_with_index { |s, i| @groups[i % @groups.size].add_user(s) }
      @assignment = @course.assignments.create!(
        group_category_id: @gc.id,
        grade_group_students_individually: false,
        submission_types: %w(text_entry)
      )
    end

    it "is not in group mode for non-group assignments" do
      setup_assignment_with_homework
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json["GROUP_GRADING_MODE"]).not_to be_truthy
    end

    it "sorts student view students last" do
      test_student = @course.student_view_student
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      expect(json[:context][:students].last[:id]).to eq(test_student.id.to_s)
    end

    it 'returns "groups" instead of students' do
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json
      @groups.each do |group|
        j = json["context"]["students"].find { |g| g["name"] == group.name }
        expect(group.users.map { |u| u.id.to_s }).to include j["id"]
      end
      expect(json["GROUP_GRADING_MODE"]).to be_truthy
    end

    it 'chooses the student with turnitin data to represent' do
      turnitin_submissions = @groups.map do |group|
        rep = group.users.sample
        turnitin_submission = @assignment.grade_student(rep, grade: 10, grader: @teacher)[0]
        turnitin_submission.update_attribute :turnitin_data, {blah: 1}
        turnitin_submission
      end

      @assignment.update_attribute :turnitin_enabled, true
      json = Assignment::SpeedGrader.new(@assignment, @teacher).json

      expect(json["submissions"].map do |s|
        s["id"]
      end.sort).to eq turnitin_submissions.map { |t| t.id.to_s }.sort
    end

    it 'prefers people with submissions' do
      g1, = @groups
      @assignment.grade_student(g1.users.first, score: 10, grader: @teacher)
      g1rep = g1.users.sample
      s = @assignment.submission_for_student(g1rep)
      s.update_attribute :submission_type, 'online_upload'
      expect(@assignment.representatives(@teacher)).to include g1rep
    end

    it "prefers people who aren't excused when submission exists" do
      g1, = @groups
      g1rep, *others = g1.users.to_a.shuffle
      @assignment.submit_homework(g1rep, {
        submission_type: 'online_text_entry',
        body: 'hi'
      })
      others.each do |u|
        @assignment.grade_student(u, excuse: true, grader: @teacher)
      end
      expect(@assignment.representatives(@teacher)).to include g1rep
    end

    it "includes users who aren't in a group" do
      student_in_course active_all: true
      expect(@assignment.representatives(@teacher).last).to eq @student
    end

    it "doesn't include deleted groups" do
      student_in_course active_all: true
      deleted_group = @gc.groups.create! name: "DELETE ME", context: @course
      deleted_group.add_user(@student)
      rep_names = @assignment.representatives(@teacher).map(&:name)
      expect(rep_names).to include "DELETE ME"

      deleted_group.destroy
      rep_names = @assignment.representatives(@teacher).map(&:name)
      expect(rep_names).not_to include "DELETE ME"
    end

    it 'prefers active users over other workflow states' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments[0].deactivate
      enrollments[1].conclude

      reps = @assignment.representatives(@teacher, includes: %i[inactive completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[2].user_id)
    end

    it 'prefers inactive users when no active users are present' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments[0].conclude
      enrollments[1].deactivate
      enrollments[2].conclude

      reps = @assignment.representatives(@teacher, includes: %i[inactive completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[1].user_id)
    end

    it 'includes concluded students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:conclude)

      reps = @assignment.representatives(@teacher, includes: [:completed])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[0].user_id)
    end

    it 'does not include concluded students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:conclude)

      reps = @assignment.representatives(@teacher, includes: [])
      user = reps.select { |u| u.name == group.name }.first
      expect(user).to be_nil
    end

    it 'includes inactive students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:deactivate)

      reps = @assignment.representatives(@teacher, includes: [:inactive])
      user = reps.select { |u| u.name == group.name }.first
      expect(user.id).to eql(enrollments[0].user_id)
    end

    it 'does not include inactive students when included' do
      group = @groups.first
      enrollments = group.all_real_student_enrollments
      enrollments.each(&:deactivate)

      reps = @assignment.representatives(@teacher, includes: [])
      user = reps.select { |u| u.name == group.name }.first
      expect(user).to be_nil
    end
  end

  context "quizzes" do
    it "works for quizzes without quiz_submissions" do
      quiz = @course.quizzes.create! :title => "Final",
                                     :quiz_type => "assignment"
      quiz.did_edit
      quiz.offer

      assignment = quiz.assignment
      assignment.grade_student(@student, grade: 1, grader: @teacher)
      json = Assignment::SpeedGrader.new(assignment, @teacher).json
      expect(json[:submissions]).to be_all do |s|
        s.key? 'submission_history'
      end
    end

    context "with quiz_submissions" do
      before :once do
        quiz_with_graded_submission [], :course => @course, :user => @student
      end

      it "doesn't include quiz_submissions when there are too many attempts" do
        Setting.set('too_many_quiz_submission_versions', 3)
        3.times do
          @quiz_submission.versions.create!
        end
        json = Assignment::SpeedGrader.new(@quiz.assignment, @teacher).json
        json[:submissions].all? { |s| expect(s["submission_history"].size).to eq 1 }
      end

      it "returns quiz lateness correctly" do
        @quiz.time_limit = 10
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].first[:submission]['late']).to be_falsey

        @quiz.due_at = 1.day.ago
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].first[:submission]['late']).to be_truthy
      end

      it "returns quiz lateness correctly with overrides" do
        o = @quiz.assignment_overrides.build
        o.due_at = 1.day.ago
        o.due_at_overridden = true
        o.set = @course.default_section
        o.save!

        @assignment.reload
        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].first[:submission]['late']).to be_truthy
      end

      it "returns quiz history for records before and after namespace change" do
        @quiz.save!

        json = Assignment::SpeedGrader.new(@assignment, @teacher).json
        expect(json[:submissions].first['submission_history'].size).to eq 1

        Version.where("versionable_type = 'QuizSubmission'").update_all("versionable_type = 'Quizzes::QuizSubmission'")
        json = Assignment::SpeedGrader.new(@assignment.reload, @teacher).json
        expect(json[:submissions].first['submission_history'].size).to eq 1
      end
    end
  end

  describe "grader comment visibility" do
    let_once(:course) { course_with_teacher(active_all: true, name: "Teacher").course }
    let_once(:teacher) { @teacher }
    let_once(:ta) do
      course_with_ta(course: course, active_all: true)
      @ta
    end
    let_once(:moderator) do
      course_with_teacher(course: course, active_all: true)
      @teacher
    end

    let_once(:section) { course.course_sections.create!(name: "Section 1") }
    let_once(:student) { user_with_pseudonym(active_all: true, username: "student1@example.com") }

    let_once(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        final_grader_id: moderator.id,
        grader_count: 2,
        moderated_grading: true,
        submission_types: ['online_text_entry'],
        title: "Example Assignment"
      )
    end
    let_once(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
    end

    let_once(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry") }

    let(:teacher_pg) { submission.provisional_grade(teacher) }
    let(:ta_pg) { submission.provisional_grade(ta) }

    let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }
    let(:submission_json) { json['submissions'][0] }

    before :once do
      course.enroll_student(student, section: section).accept!
      assignment.update_submission(student, comment: 'comment by student', commenter: student)

      assignment.moderation_graders.create!(user: teacher, anonymous_id: 'teach')
      assignment.moderation_graders.create!(user: ta, anonymous_id: 'atata')

      submission.add_comment(author: moderator, comment: 'comment by moderator', provisional: false)

      submission.add_comment(author: teacher, comment: 'comment by teacher', provisional: false)
      submission.add_comment(author: teacher, comment: 'provisional comment by teacher', provisional: true)
      teacher_pg.update_attribute(:score, 2)

      rubric_association.assess(
        artifact: teacher_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'teacher comment',
            points: 2
          }
        },
        assessor: teacher,
        user: student
      )

      selection = assignment.moderated_grading_selections.find_by!(student: student)
      selection.provisional_grade = teacher_pg
      selection.save!

      submission.add_comment(author: ta, comment: 'comment by ta', provisional: false)
      submission.add_comment(author: ta, comment: 'provisional comment by ta', provisional: true)
      ta_pg.update_attribute(:score, 3)

      rubric_association.assess(
        artifact: ta_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'ta comment',
            points: 3
          }
        },
        assessor: ta,
        user: student
      )
    end

    before :each do
      submission.anonymous_id = 'aaaaa'
      submission.save!

      allow(assignment).to receive(:can_view_student_names?).and_return(true)
      allow(assignment).to receive(:can_view_other_grader_identities?).and_return(false)
    end

    context "when the user is the final grader" do
      let(:json) { Assignment::SpeedGrader.new(assignment, moderator, avatars: true, grading_role: :moderator).json }

      before(:each) do
        allow(assignment).to receive(:can_view_other_grader_comments?).with(moderator).and_return(true)
      end

      it "includes submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes submission comments from students" do
        student_comment = submission.submission_comments.find_by!(author: student)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        moderator_comment = submission.submission_comments.find_by!(author: moderator, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(moderator_comment.id.to_s)
      end

      it "includes provisional grade submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta, provisional_grade_id: nil)
        provisional_comments = submission_json['provisional_grades'].map {|grade| grade['submission_comments']}.flatten
        comment_ids = provisional_comments.map {|comment| comment['id']}
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes rubric assessment comments from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments']}
        expect(comments).to include('ta comment')
      end

      it "includes rubric assessment comments html from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments_html']}
        expect(comments).to include('ta comment')
      end
    end

    context "when the user is not the final grader and can view other grader comments" do
      let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }

      before(:each) do
        allow(assignment).to receive(:can_view_other_grader_comments?).with(teacher).and_return(true)
      end

      it "includes submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes submission comments from the final grader" do
        moderator_comment = submission.submission_comments.find_by!(author: moderator, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(moderator_comment.id.to_s)
      end

      it "includes submission comments from students" do
        student_comment = submission.submission_comments.find_by!(author: student)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        teacher_comment = submission.submission_comments.find_by!(author: teacher, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(teacher_comment.id.to_s)
      end

      it "includes provisional grade submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta, provisional_grade_id: nil)
        provisional_comments = submission_json['provisional_grades'].map {|grade| grade['submission_comments']}.flatten
        comment_ids = provisional_comments.map {|comment| comment['id']}
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes provisional grade submission comments from the final grader" do
        moderator_comment = submission.submission_comments.find_by!(author: moderator, provisional_grade_id: nil)
        provisional_comments = submission_json['provisional_grades'].map {|grade| grade['submission_comments']}.flatten
        comment_ids = provisional_comments.map {|comment| comment['id']}
        expect(comment_ids).to include(moderator_comment.id.to_s)
      end

      it "includes rubric assessment comments from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments']}
        expect(comments).to include('ta comment')
      end

      it "includes rubric assessment comments html from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments_html']}
        expect(comments).to include('ta comment')
      end
    end

    context "when the user is not the final grader and cannot view other grader comments" do
      let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }

      before(:each) do
        allow(assignment).to receive(:can_view_other_grader_comments?).with(teacher).and_return(false)
      end

      it "excludes submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).not_to include(ta_comment.id.to_s)
      end

      it "excludes submission comments from the final grader" do
        moderator_comment = submission.submission_comments.find_by!(author: moderator, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).not_to include(moderator_comment.id.to_s)
      end

      it "includes submission comments from students" do
        student_comment = submission.submission_comments.find_by!(author: student)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        teacher_comment = submission.submission_comments.find_by!(author: teacher, provisional_grade_id: nil)
        comment_ids = submission_json['submission_comments'].map {|comment| comment['id']}
        expect(comment_ids).to include(teacher_comment.id.to_s)
      end

      it "excludes provisional grade submission comments from other graders" do
        ta_comment = submission.submission_comments.find_by!(author: ta, provisional_grade_id: nil)
        provisional_comments = submission_json['provisional_grades'].map {|grade| grade['submission_comments']}.flatten
        comment_ids = provisional_comments.map {|comment| comment['id']}
        expect(comment_ids).not_to include(ta_comment.id.to_s)
      end

      it "excludes provisional grade submission comments from the final grader" do
        moderator_comment = submission.submission_comments.find_by!(author: moderator, provisional_grade_id: nil)
        provisional_comments = submission_json['provisional_grades'].map {|grade| grade['submission_comments']}.flatten
        comment_ids = provisional_comments.map {|comment| comment['id']}
        expect(comment_ids).not_to include(moderator_comment.id.to_s)
      end

      it "excludes rubric assessment comments from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments']}
        expect(comments).not_to include('ta comment')
      end

      it "excludes rubric assessment comments html from other graders" do
        rubric_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessment_data = rubric_assessments.map {|assessment| assessment['data']}.flatten
        comments = assessment_data.map {|datum| datum['comments_html']}
        expect(comments).not_to include('ta comment')
      end
    end
  end

  describe "when moderated grading is enabled" do
    before(:once) do
      course_with_ta(:course => @course, :active_all => true)
      @assignment = assignment_model(
        course: @course,
        submission_types: 'online_text_entry',
        moderated_grading: true,
        grader_count: 2
      )
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)

      @submission = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'ahem')
      @assignment.update_submission(@student, :comment => 'real comment', :score => 1, :commenter => @student)

      @submission.add_comment(:author => @teacher, :comment => 'provisional comment', :provisional => true)
      @teacher_pg = @submission.provisional_grade(@teacher)
      @teacher_pg.update_attribute(:score, 2)
      @association.assess(
        :user => @student, :assessor => @teacher, :artifact => @teacher_pg,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 2,
            :comments => 'a comment',
          }
        }
      )

      selection = @assignment.moderated_grading_selections.find_by!(student: @student)
      selection.update!(provisional_grade: @teacher_pg)

      @submission.add_comment(:author => @ta, :comment => 'other provisional comment', :provisional => true)
      @ta_pg = @submission.provisional_grade(@ta)
      @ta_pg.update_attribute(:score, 3)
      @association.assess(
        :user => @student, :assessor => @ta, :artifact => @ta_pg,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 3,
            :comments => 'a comment',
          }
        }
      )

      @other_student = user_factory(active_all: true)
      student_in_course(:course => @course, :user => @other_student, :active_all => true)
    end

    def find_real_submission(json)
      json['submissions'].find { |s| s['workflow_state'] != 'unsubmitted' }
    end

    it "returns all three comments" do
      course_with_ta :course => @course, :active_all => true
      json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      comments = find_real_submission(json)['submission_comments'].map { |comment| comment['comment'] }
      expect(comments).to match_array ['real comment', 'provisional comment', 'other provisional comment']
    end

    describe "for provisional grader" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      end

      it 'has a submission with score' do
        s = find_real_submission(@json)
        expect(s['score']).to eq @ta_pg.score
      end

      it "includes all provisional grades" do
        submission = find_real_submission(@json)
        scorer_ids = submission['provisional_grades'].map {|pg| pg.fetch('scorer_id')}
        expect(scorer_ids).to contain_exactly(@teacher_pg.scorer_id.to_s, @ta_pg.scorer_id.to_s)
      end

      it "has all three comments" do
        comments = find_real_submission(@json)['submission_comments'].map { |comment| comment['comment'] }
        expect(comments).to match_array ['real comment', 'provisional comment', 'other provisional comment']
      end

      it "only includes the grader's provisional rubric assessments" do
        ras = @json['context']['students'][0]['rubric_assessments']
        expect(ras.count).to eq 1
        expect(ras[0]['assessor_id']).to eq @ta.id.to_s
      end
    end

    describe "for moderator" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @teacher, :grading_role => :moderator).json
      end

      it "has all three comments" do
        s = find_real_submission(@json)
        expect(s['score']).to eq 2
        comments = s['submission_comments'].map { |comment| comment['comment'] }
        expect(comments).to match_array ['real comment', 'provisional comment', 'other provisional comment']
      end

      it "includes the moderator's provisional rubric assessments" do
        ras = @json['context']['students'][0]['rubric_assessments']
        expect(ras.count).to eq 1
        expect(ras[0]['assessor_id']).to eq @teacher.id.to_s
      end

      it "lists all provisional grades" do
        pgs = find_real_submission(@json)['provisional_grades']
        expect(pgs.size).to eq 2
        expect(pgs.map { |pg| [pg['score'], pg['scorer_id'], pg['submission_comments'].map{|c| c['comment']}.sort] }).to match_array(
          [
            [2.0, @teacher.id.to_s, ["provisional comment", "real comment"]],
            [3.0, @ta.id.to_s, ["other provisional comment", "real comment"]]
          ]
        )
      end

      it "includes all the other provisional rubric assessments in their respective grades" do
        ta_pras = find_real_submission(@json)['provisional_grades'][1]['rubric_assessments']
        expect(ta_pras.count).to eq 1
        expect(ta_pras[0]['assessor_id']).to eq @ta.id.to_s
      end

      it "includes whether the provisional grade is selected" do
        s = find_real_submission(@json)
        expect(s['provisional_grades'][0]['selected']).to be_truthy
        expect(s['provisional_grades'][1]['selected']).to be_falsey
      end
    end
  end

  context "when an assignment is anonymous" do
    before(:once) do
      course_with_teacher

      @active_student = @course.enroll_student(User.create!, enrollment_state: 'active').user
      @course.enroll_student(User.create!, enrollment_state: 'inactive')
      @course.enroll_student(User.create!, enrollment_state: 'completed')
      @course.enroll_student(User.create!, enrollment_state: 'completed')
    end

    let(:assignment) { @course.assignments.create!(title: 'anonymous', anonymous_grading: true) }
    let(:speed_grader_json) { Assignment::SpeedGrader.new(assignment, @teacher).json }
    let(:students) { speed_grader_json[:context][:students] }

    it "returns only active students if assignment is muted" do
      active_student_submission = assignment.submission_for_student(@active_student)

      returned_ids = students.map { |student| student['anonymous_id'] }
      expect(returned_ids).to match_array [active_student_submission.anonymous_id]
    end

    it "returns students in accord with user gradebook preferences if assignment is not muted" do
      @teacher.preferences[:gradebook_settings] = {}
      @teacher.preferences[:gradebook_settings][@course.id] = {
        'show_concluded_enrollments' => 'true',
        'show_inactive_enrollments' => 'true'
      }
      assignment.unmute!

      expect(students.length).to eq 4
    end
  end

  context "OriginalityReport" do
    include_context 'lti2_spec_helper'

    let_once(:test_course) do
      test_course = course_factory(active_course: true)
      test_course.enroll_teacher(test_teacher, enrollment_state: 'active')
      test_course.enroll_student(test_student, enrollment_state: 'active')
      test_course
    end

    let_once(:test_teacher) { User.create }
    let_once(:test_student) { User.create }

    let(:assignment) { Assignment.create!(title: "title", context: test_course) }
    let(:attachment) do
      attachment = test_student.attachments.new :filename => "homework.doc"
      attachment.content_type = "foo/bar"
      attachment.size = 10
      attachment.save!
      attachment
    end

    it 'includes the OriginalityReport in the json' do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})
      OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission)
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      tii_data = json['submissions'].first['submission_history'].first['submission']['turnitin_data']
      expect(tii_data[attachment.asset_string]['state']).to eq 'acceptable'
    end

    it "includes 'has_originality_report' in the json for text entry submissions" do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})
      OriginalityReport.create!(originality_score: '1', submission: submission)
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      has_report = json['submissions'].first['submission_history'].first['submission']['has_originality_report']
      expect(has_report).to be_truthy
    end

    it "includes 'has_originality_report' in the json for group assignments" do
      user_two = test_student.dup
      user_two.update_attributes!(lti_context_id: SecureRandom.uuid)
      assignment.course.enroll_student(user_two)

      group = group_model(context: assignment.course)
      group.update_attributes!(users: [user_two, test_student])

      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      assignment.submit_homework(user_two, submission_type: 'online_upload', attachments: [attachment])

      assignment.submissions.each do |s|
        s.update_attributes!(group: group, turnitin_data: {blah: 1})
      end

      report = OriginalityReport.create!(originality_score: '1', submission: submission, attachment: attachment)
      report.copy_to_group_submissions!

      json = Assignment::SpeedGrader.new(assignment, test_teacher).json

      has_report = json['submissions'].map{ |s| s['submission_history'].first['submission']['has_originality_report'] }
      expect(has_report).to match_array [true, true]
    end

    it "includes 'has_originality_report' in the json" do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})
      OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission)
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      has_report = json['submissions'].first['submission_history'].first['submission']['has_originality_report']
      expect(has_report).to be_truthy
    end

    it 'includes "has_plagiarism_tool" if the assignment has a plagiarism tool' do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})

      AssignmentConfigurationToolLookup.create!(
        assignment: assignment,
        tool_vendor_code: product_family.vendor_code,
        tool_product_code: product_family.product_code,
        tool_resource_type_code: resource_handler.resource_type_code,
        tool_type: 'Lti::MessageHandler'
      )

      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      has_tool = json['submissions'].first['submission_history'].first['submission']['has_plagiarism_tool']
      expect(has_tool).to be_truthy
    end

    it 'includes "has_originality_score" if the originality report includes an originality score' do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})
      OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission)
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      has_score = json['submissions'].first['submission_history'].first['submission']['has_originality_score']
      expect(has_score).to be_truthy
    end

    it 'includes originality data' do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {blah: 1})
      OriginalityReport.create!(attachment: attachment, originality_score: '1', submission: submission)
      OriginalityReport.create!(originality_score: '1', submission: submission)
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      keys = json['submissions'].first['submission_history'].first['submission']['turnitin_data'].keys
      expect(keys).to include submission.asset_string, attachment.asset_string
    end

    it 'does not override "turnitin_data"' do
      submission = assignment.submit_homework(test_student, submission_type: 'online_upload', attachments: [attachment])
      submission.update_attribute(:turnitin_data, {test_key: 1})
      json = Assignment::SpeedGrader.new(assignment, test_teacher).json
      keys = json['submissions'].first['submission_history'].first['submission']['turnitin_data'].keys
      expect(keys).to include 'test_key'
    end
  end

  context "honoring gradebook preferences" do
    let_once(:test_course) do
      test_course = course_factory(active_course: true)
      test_course.enroll_teacher(teacher, enrollment_state: 'active')
      test_course.enroll_student(active_student, enrollment_state: 'active')
      test_course.enroll_student(inactive_student, enrollment_state: 'inactive')
      test_course.enroll_student(concluded_student, enrollment_state: 'completed')
      test_course
    end

    let_once(:teacher) { User.create }
    let_once(:active_student) { User.create }
    let_once(:inactive_student) { User.create }
    let_once(:concluded_student) { User.create }

    let(:gradebook_settings) do
      { test_course.id =>
        {
          'show_inactive_enrollments' => 'false',
          'show_concluded_enrollments' => 'false'
        }}
    end

    let_once(:assignment) do
      Assignment.create!(title: "title", context: test_course)
    end

    it "returns active students and enrollments when inactive and concluded settings are false" do
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id.to_s)
    end

    it "returns active and inactive students and enrollments when inactive enromments is true" do
      gradebook_settings[test_course.id]['show_inactive_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id.to_s, inactive_student.id.to_s)
    end

    it "returns active and concluded students and enrollments when concluded is true" do
      gradebook_settings[test_course.id]['show_concluded_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id.to_s, concluded_student.id.to_s)
    end

    it "returns active, inactive, and concluded students and enrollments when both settings are true" do
      gradebook_settings[test_course.id]['show_inactive_enrollments'] = 'true'
      gradebook_settings[test_course.id]['show_concluded_enrollments'] = 'true'
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = Assignment::SpeedGrader.new(assignment, teacher).json

      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id.to_s, inactive_student.id.to_s,
                                  concluded_student.id.to_s)
    end

    it "returns concluded students if the course is concluded" do
      test_course.complete
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      students = json['context']['students'].map { |s| s['id'] }
      expect(students).to include(active_student.id.to_s, concluded_student.id.to_s)
    end
  end

  describe "student anonymity" do
    let_once(:course) { course_with_teacher(active_all: true, name: "Teacher").course }
    let_once(:teacher) { @teacher }
    let_once(:ta) do
      course_with_ta(course: course, active_all: true)
      @ta
    end

    let_once(:section_1) { course.course_sections.create!(name: "Section 1") }
    let_once(:section_2) { course.course_sections.create!(name: "Section 2") }

    let_once(:student_1) { user_with_pseudonym(active_all: true, username: "student1@example.com") }
    let_once(:student_2) { user_with_pseudonym(active_all: true, username: "student2@example.com") }
    let_once(:test_student) { course.student_view_student }

    let_once(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        grader_count: 2,
        graders_anonymous_to_graders: false,
        moderated_grading: true,
        submission_types: ['online_text_entry'],
        title: "Example Assignment"
      )
    end
    let_once(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
    end

    let(:attachment_1) { student_1.attachments.create!(uploaded_data: dummy_io, filename: "homework.png", context: student_1) }
    let(:attachment_2) { teacher.attachments.create!(uploaded_data: dummy_io, filename: "homework.png", context: teacher) }

    let(:submission_1) { assignment.submit_homework(student_1, submission_type: "online_upload", attachments: [attachment_1]) }
    let(:submission_2) { assignment.submit_homework(student_2, submission_type: "online_upload", attachments: [attachment_2]) }
    let(:test_submission) { Submission.find_by!(user_id: test_student.id, assignment_id: assignment.id) }

    let(:teacher_pg) { submission_1.provisional_grade(teacher) }
    let(:ta_pg) { submission_1.provisional_grade(ta) }

    let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }
    let(:grader_json) { Assignment::SpeedGrader.new(assignment, ta, avatars: true, grading_role: :grader).json }

    before :once do
      course.enroll_student(student_1, section: section_1).accept!
      course.enroll_student(student_2, section: section_2).accept!

      assignment.moderation_graders.create!(user: teacher, anonymous_id: 'teach')
      assignment.moderation_graders.create!(user: ta, anonymous_id: 'atata')

      selection = assignment.moderated_grading_selections.find_by!(student_id: student_1.id)

      submission_1.add_comment(author: teacher, comment: 'comment by teacher', provisional: false)
      submission_1.add_comment(author: teacher, comment: 'provisional comment by teacher', provisional: true)
      teacher_pg.update_attribute(:score, 2)

      rubric_association.assess(
        artifact: teacher_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'a comment',
            points: 2
          }
        },
        assessor: teacher,
        user: student_1
      )

      selection.provisional_grade = teacher_pg
      selection.save!

      submission_1.add_comment(author: ta, comment: 'comment by ta', provisional: false)
      submission_1.add_comment(author: ta, comment: 'provisional comment by ta', provisional: true)
      ta_pg.update_attribute(:score, 3)

      rubric_association.assess(
        artifact: ta_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'a comment',
            points: 3
          }
        },
        assessor: ta,
        user: student_1
      )
    end

    before :each do
      submission_1.anonymous_id = 'aaaaa'
      submission_1.save!

      submission_2.anonymous_id = 'bbbbb'
      submission_2.save!

      test_submission.anonymous_id = 'ccccc'
      test_submission.save!

      allow(assignment).to receive(:can_view_other_grader_comments?).and_return(true)
      allow(assignment).to receive(:can_view_other_grader_identities?).and_return(true)
    end

    context "when the user can view student names" do
      let(:submission_1_json) { json['submissions'].detect { |s| s['user_id'] == student_1.id.to_s } }
      let(:student_comments) do
        submission_1_json['submission_comments'].select do |comment|
          comment['author_id'] == student_1.id.to_s || comment['author_id'] == student_2.id.to_s
        end
      end

      before :each do
        allow(assignment).to receive(:can_view_student_names?).with(teacher).and_return(true)
        allow(assignment).to receive(:can_view_student_names?).with(ta).and_return(true)
      end

      it "includes user ids on student enrollments" do
        user_ids = json['context']['enrollments'].map { |enrollment| enrollment['user_id'] }
        expect(user_ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from student enrollments" do
        expect(json['context']['enrollments']).to all(not_have_key('anonymous_id'))
      end

      it "includes ids on students" do
        ids = json['context']['students'].map { |student| student['id'] }
        expect(ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from students" do
        expect(json['context']['students']).to all(not_have_key('anonymous_id'))
      end

      it "includes user ids on submissions" do
        user_ids = json['submissions'].map { |submission| submission['user_id'] }
        expect(user_ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from submissions" do
        expect(json['submissions']).to all(not_have_key('anonymous_id'))
      end

      it "includes user ids on rubrics" do
        student = json['context']['students'].detect { |s| s['id'] == student_1.id.to_s }
        user_ids = student['rubric_assessments'].map {|assessment| assessment['user_id']}
        expect(user_ids).to include(student_1.id.to_s)
      end

      it "includes user ids from rubrics on provisional grades" do
        rubric_assessments = submission_1_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        user_ids = rubric_assessments.map {|assessment| assessment['user_id']}
        expect(user_ids).to include(student_1.id.to_s)
      end

      it "includes student author ids on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).not_to be_empty
      end

      it "excludes anonymous ids from submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        expect(student_comments).to all(not_have_key('anonymous_id'))
      end

      it "includes student author names on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(include("author_name" => student_1.name))
      end

      it "uses the user avatar for students on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        avatar_paths = student_comments.map {|s| s['avatar_path']}
        expect(avatar_paths.uniq).to include(student_1.avatar_path, student_2.avatar_path)
      end

      it "optionally does not include avatars" do
        submission_1.add_comment(author: student_1, comment: "Example")
        json = Assignment::SpeedGrader.new(assignment, teacher, avatars: false).json
        submission = json['submissions'].detect { |s| s['user_id'] == student_1.id.to_s }
        expect(submission['submission_comments']).to all(not_have_key('avatar_path'))
      end

      it "includes student user ids on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        expect(student_comments).not_to be_empty
      end
    end

    context "when the user cannot view student names" do
      let(:submission_1_json) { json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' } }
      let(:student_comments) do
        submission_1_json['submission_comments'].select do |comment|
          comment['anonymous_id'] == 'aaaaa' || comment['anonymous_id'] == 'bbbbb'
        end
      end

      before :each do
        allow(assignment).to receive(:can_view_student_names?).with(teacher).and_return(false)
        allow(assignment).to receive(:can_view_student_names?).with(ta).and_return(false)
      end

      it "adds anonymous ids to student enrollments" do
        anonymous_ids = json['context']['enrollments'].map { |enrollment| enrollment['anonymous_id'] }
        expect(anonymous_ids.uniq).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
      end

      it "excludes user ids from student enrollments" do
        expect(json['context']['enrollments']).to all(not_have_key('user_id'))
      end

      it "excludes ids from students" do
        expect(json['context']['students']).to all(not_have_key('id'))
      end

      it "adds anonymous ids to students" do
        anonymous_ids = json['context']['students'].map { |student| student['anonymous_id'] }
        expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
      end

      it "excludes user ids from submissions" do
        expect(json['submissions']).to all(not_have_key('user_id'))
      end

      it "includes anonymous ids on submissions" do
        anonymous_ids = json['submissions'].map { |submission| submission['anonymous_id'] }
        expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
      end

      it "excludes user ids on rubrics" do
        student = json['context']['students'].detect {|s| s['anonymous_id'] == 'aaaaa'}
        expect(student['rubric_assessments']).to all(not_have_key('user_id'))
      end

      it "excludes user ids from rubrics on provisional grades" do
        rubric_assessments = submission_1_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        expect(rubric_assessments).to all(not_have_key('user_id'))
      end

      it "includes anonymous ids on student submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).not_to be_empty
      end

      it "excludes student author ids from submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(not_have_key('author_id'))
      end

      it "excludes student author names from submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(not_have_key('author_name'))
      end

      it "includes author ids of other graders on submission comments" do
        submission = grader_json['submissions'].detect {|s| s['anonymous_id'] == "aaaaa"}
        author_ids = submission['submission_comments'].map { |s| s['author_id'] }
        expect(author_ids).to include(teacher.id.to_s, ta.id.to_s)
      end

      it "includes author names of other graders on submission comments" do
        submission = grader_json['submissions'].detect {|s| s['anonymous_id'] == "aaaaa"}
        author_names = submission['submission_comments'].map {|s| s['author_name']}
        expect(author_names).to include(teacher.name, ta.name)
      end

      it "uses the default avatar for students on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        avatars = student_comments.map { |s| s['avatar_path'] }
        expect(avatars).to all(eql(User.default_avatar_fallback))
      end

      it "uses the user avatar for other graders on submission comments" do
        avatars = submission_1_json['submission_comments'].map { |s| s['avatar_path'] }
        expect(avatars).to include(ta.avatar_path, teacher.avatar_path)
      end

      it "adds anonymous ids to submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        anonymous_ids = student_comments.map { |s| s['anonymous_id'] }
        expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb'])
      end

      it "includes the current user's author ids on submission comments" do
        expect(submission_1_json['submission_comments'].map { |s| s['author_id'] }).to include(teacher.id.to_s)
      end

      it "includes the current user's author name on submission comments" do
        expect(submission_1_json['submission_comments'].map { |s| s['author_name'] }).to include(teacher.name)
      end
    end
  end

  describe "grader anonymity" do
    let_once(:course) { course_with_teacher(active_all: true, name: "Teacher").course }
    let_once(:teacher) { @teacher }
    let_once(:ta) do
      course_with_ta(course: course, active_all: true)
      @ta
    end
    let_once(:moderator) do
      course_with_teacher(course: course, active_all: true, name: "Moderator")
      @teacher
    end

    let_once(:section) { course.course_sections.create!(name: "Section 1") }
    let_once(:student) { user_with_pseudonym(active_all: true, username: "student1@example.com") }

    let_once(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        final_grader_id: moderator.id,
        grader_count: 2,
        moderated_grading: true,
        submission_types: ['online_text_entry'],
        title: "Example Assignment"
      )
    end
    let_once(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
    end

    let_once(:submission) { assignment.submit_homework(student, submission_type: "online_text_entry") }

    let(:teacher_pg) { submission.provisional_grade(teacher) }
    let(:ta_pg) { submission.provisional_grade(ta) }
    let(:moderator_pg) { submission.provisional_grade(moderator) }

    let(:submission_json) { json['submissions'][0] }

    before :once do
      course.enroll_student(student, section: section).accept!
      assignment.update_submission(student, comment: 'comment by student', commenter: student)

      assignment.moderation_graders.create!(user: teacher, anonymous_id: 'teach')
      assignment.moderation_graders.create!(user: ta, anonymous_id: 'atata')
      assignment.moderation_graders.create!(user: moderator, anonymous_id: 'moder')

      selection = assignment.moderated_grading_selections.find_by!(student_id: student.id)

      submission.add_comment(author: moderator, comment: 'comment by moderator', provisional: false)
      submission.add_comment(author: moderator, comment: 'provisional comment by moderator', provisional: true)
      moderator_pg.update_attribute(:score, 4)

      submission.add_comment(author: teacher, comment: 'comment by teacher', provisional: false)
      submission.add_comment(author: teacher, comment: 'provisional comment by teacher', provisional: true)
      teacher_pg.update_attribute(:score, 2)

      rubric_association.assess(
        artifact: teacher_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'a comment',
            points: 2
          }
        },
        assessor: teacher,
        user: student
      )

      selection.provisional_grade = teacher_pg
      selection.save!

      submission.add_comment(author: ta, comment: 'comment by ta', provisional: false)
      submission.add_comment(author: ta, comment: 'provisional comment by ta', provisional: true)
      ta_pg.update_attribute(:score, 3)

      rubric_association.assess(
        artifact: ta_pg,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            comments: 'a comment',
            points: 3
          }
        },
        assessor: ta,
        user: student
      )
    end

    before :each do
      submission.anonymous_id = 'aaaaa'
      submission.save!

      allow(assignment).to receive(:can_view_student_names?).and_return(true)
      allow(assignment).to receive(:can_view_other_grader_comments?).and_return(true)
    end

    context "when the user is the final grader and cannot view other grader names" do
      let(:json) { Assignment::SpeedGrader.new(assignment, moderator, avatars: true, grading_role: :moderator).json }

      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(moderator).and_return(false)
      end

      it "excludes scorer_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key('scorer_id')
      end

      it "includes anonymous_grader_id on submissions when the user assigned a provisional grade" do
        expect(submission_json['anonymous_grader_id']).to eq 'moder'
      end

      # submission comments

      it "excludes author_id from grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        expect(grader_comments).to all(not_have_key("author_id"))
      end

      it "includes anonymous_id on grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        anonymous_ids = grader_comments.map {|comment| comment['anonymous_id']}
        expect(anonymous_ids.uniq).to match_array ["teach", "atata", "moder"]
      end

      it "excludes author_name from other graders' comments" do
        ta_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'atata'}
        expect(ta_comment).not_to have_key('author_name')
      end

      it "includes author_name on the current graders' comments" do
        moderator_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'moder'}
        expect(moderator_comment['author_name']).to eql("Moderator")
      end

      it "uses the default avatar for other graders' comments" do
        ta_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'atata'}
        expect(ta_comment['avatar_path']).to eql(User.default_avatar_fallback)
      end

      it "uses the user avatar for the current grader's comments" do
        moderator_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'moder'}
        expect(moderator_comment['avatar_path']).to eql(moderator.avatar_path)
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['author_name']).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['avatar_path']).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before :each do
          allow(assignment).to receive(:can_view_student_names?).with(moderator).and_return(false)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment).not_to have_key('author_name')
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment['avatar_path']).to eql(User.default_avatar_fallback)
        end
      end

      # all provisional grades (current user)

      it "includes anonymous_grader_id on provisional grades given by the current user'" do
        moderator_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'moder'}
        expect(moderator_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by the current user'" do
        moderator_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'moder'}
        expect(moderator_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grades (other graders)

      it "includes anonymous_grader_id on provisional grades given by another grader'" do
        ta_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'atata'}
        expect(ta_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by another grader'" do
        ta_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'atata'}
        expect(ta_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grade rubric assessments (other graders)

      it "excludes assessor_name other grader's rubric assessments on provisional grades'" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(include("anonymous_assessor_id" => "atata"))
      end

      # final provisional grade (current user)

      it "excludes scorer_id from the final provisional grade when given by the current user'" do
        moderator_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by the current user'" do
        moderator_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['anonymous_grader_id']).to eql("moder")
      end

      # final provisional grade (other graders)

      it "excludes scorer_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['anonymous_grader_id']).to eql("atata")
      end

      # final provisional grade rubric assessments (other graders)

      it "excludes assessor_name from the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("anonymous_assessor_id" => "atata"))
      end
    end

    context "when the user is the final grader and can view other grader names" do
      let(:json) { Assignment::SpeedGrader.new(assignment, moderator, avatars: true, grading_role: :moderator).json }

      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(moderator).and_return(true)
      end

      it "includes scorer_id on submissions when the user assigned a provisional grade" do
        expect(submission_json['scorer_id']).to eql(moderator.id.to_s)
      end

      it "excludes anonymous_grader_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key('anonymous_grader_id')
      end

      # submission comments

      it "includes author_id on grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        anonymous_ids = grader_comments.map {|comment| comment['author_id']}
        expect(anonymous_ids.uniq).to match_array([teacher.id, ta.id, moderator.id].map(&:to_s))
      end

      it "excludes anonymous_id from grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        expect(grader_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes author_name on the all graders' comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        grader_names = grader_comments.map {|comment| comment['author_name']}
        expect(grader_names.uniq).to match_array([teacher, ta, moderator].map(&:name))
      end

      it "uses the user avatar for the all grader's comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        grader_avatars = grader_comments.map {|comment| comment['avatar_path']}
        expect(grader_avatars.uniq).to match_array([teacher, ta, moderator].map(&:avatar_path))
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['author_name']).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['avatar_path']).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before :each do
          allow(assignment).to receive(:can_view_student_names?).with(moderator).and_return(false)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment).not_to have_key('author_name')
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment['avatar_path']).to eql(User.default_avatar_fallback)
        end
      end

      # all provisional grades

      it "includes scorer_id on all provisional grades" do
        scorer_ids = submission_json['provisional_grades'].map {|grade| grade['scorer_id']}
        expect(scorer_ids.uniq).to match_array([teacher.id, ta.id, moderator.id].map(&:to_s))
      end

      it "excludes anonymous_grader_id from all provisional grades" do
        expect(submission_json['provisional_grades']).to all(not_have_key("anonymous_grader_id"))
      end

      # all provisional grade rubric assessments

      it "includes assessor_name on all graders' rubric assessments on provisional grades'" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        grader_names = grader_assessments.map {|assessment| assessment['assessor_name']}
        expect(grader_names.uniq).to match_array([teacher, ta].map(&:name))
      end

      it "includes assessor_id on all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessor_ids = grader_assessments.map {|assessment| assessment['assessor_id']}
        expect(assessor_ids.uniq).to match_array([teacher.id, ta.id].map(&:to_s))
      end

      it "excludes anonymous_assessor_id from all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        expect(grader_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # final provisional grade (current user)

      it "includes scorer_id on the final provisional grade when given by the current user'" do
        moderator_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['scorer_id']).to eql(moderator.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by the current user'" do
        moderator_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade (other graders)

      it "includes scorer_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['scorer_id']).to eql(ta.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade rubric assessments (other graders)

      it "includes assessor_name on the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("assessor_name" => ta.name))
      end

      it "includes assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("assessor_id" => ta.id.to_s))
      end

      it "excludes anonymous_assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("anonymous_assessor_id"))
      end
    end

    context "when the user is not the final grader and cannot view other grader names" do
      let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }

      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(teacher).and_return(false)
      end

      it "excludes scorer_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key('scorer_id')
      end

      it "includes anonymous_grader_id on submissions when the user assigned a provisional grade" do
        expect(submission_json['anonymous_grader_id']).to eq 'teach'
      end

      # submission comments

      it "excludes author_id from grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        expect(grader_comments).to all(not_have_key("author_id"))
      end

      it "includes anonymous_id on grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        anonymous_ids = grader_comments.map {|comment| comment['anonymous_id']}
        expect(anonymous_ids.uniq).to match_array ["teach", "atata", "moder"]
      end

      it "excludes author_name from other graders' comments" do
        ta_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'atata'}
        expect(ta_comment).not_to have_key('author_name')
      end

      it "includes author_name on the current graders' comments" do
        teacher_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'teach'}
        expect(teacher_comment['author_name']).to eq "Teacher"
      end

      it "uses the default avatar for other graders' comments" do
        ta_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'atata'}
        expect(ta_comment['avatar_path']).to eql(User.default_avatar_fallback)
      end

      it "uses the user avatar for the current grader's comments" do
        teacher_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'teach'}
        expect(teacher_comment['avatar_path']).to eql(teacher.avatar_path)
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['author_name']).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['avatar_path']).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before :each do
          allow(assignment).to receive(:can_view_student_names?).with(teacher).and_return(false)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment).not_to have_key('author_name')
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment['avatar_path']).to eql(User.default_avatar_fallback)
        end
      end

      # current user's rubric assessments

      it "includes assessor_name on the current grader's rubric assessments' on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => "teach"))
      end

      # all provisional grades (current user)

      it "includes anonymous_grader_id on provisional grades given by the current user'" do
        teacher_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'teach'}
        expect(teacher_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by the current user'" do
        teacher_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'teach'}
        expect(teacher_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grades (other graders)

      it "includes anonymous_grader_id on provisional grades given by another grader'" do
        ta_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'atata'}
        expect(ta_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by another grader'" do
        ta_grades = submission_json['provisional_grades'].select {|grade| grade['anonymous_grader_id'] == 'atata'}
        expect(ta_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on provisional grades'" do
        teacher_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'moder'}
        teacher_assessments = teacher_grade['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on provisional grades" do
        teacher_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'moder'}
        teacher_assessments = teacher_grade['rubric_assessments']
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on provisional grades" do
        teacher_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'moder'}
        teacher_assessments = teacher_grade['rubric_assessments']
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => "moder"))
      end

      # all provisional grade rubric assessments (other graders)

      it "excludes assessor_name other grader's rubric assessments on provisional grades'" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json['provisional_grades'].detect {|grade| grade['anonymous_grader_id'] == 'atata'}
        ta_assessments = ta_grade['rubric_assessments']
        expect(ta_assessments).to all(include("anonymous_assessor_id" => "atata"))
      end

      # final provisional grade (current user)

      it "excludes scorer_id from the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['anonymous_grader_id']).to eql("teach")
      end

      # final provisional grade (other graders)

      it "excludes scorer_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['anonymous_grader_id']).to eql("atata")
      end

      # final provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on the final provisional grade'" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => "teach"))
      end

      # final provisional grade rubric assessments (other graders)

      it "excludes assessor_name from the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("anonymous_assessor_id" => "atata"))
      end
    end

    context "when the user is not the final grader and can view other grader names" do
      let(:json) { Assignment::SpeedGrader.new(assignment, teacher, avatars: true, grading_role: :moderator).json }

      before :each do
        allow(assignment).to receive(:can_view_other_grader_identities?).with(teacher).and_return(true)
      end

      it "includes scorer_id on submissions when the user assigned a provisional grade" do
        expect(submission_json['scorer_id']).to eql(teacher.id.to_s)
      end

      it "excludes anonymous_grader_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key('anonymous_grader_id')
      end

      # submission comments

      it "includes author_id on grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        anonymous_ids = grader_comments.map {|comment| comment['author_id']}
        expect(anonymous_ids.uniq).to match_array([teacher.id, ta.id, moderator.id].map(&:to_s))
      end

      it "excludes anonymous_id from grader comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        expect(grader_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes author_name on the all graders' comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        grader_names = grader_comments.map {|comment| comment['author_name']}
        expect(grader_names.uniq).to match_array([teacher, ta, moderator].map(&:name))
      end

      it "uses the user avatar for the all grader's comments" do
        grader_comments = submission_json['submission_comments'].reject {|comment| comment['author_id'] == student.id.to_s}
        grader_avatars = grader_comments.map {|comment| comment['avatar_path']}
        expect(grader_avatars.uniq).to match_array([teacher, ta, moderator].map(&:avatar_path))
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['author_name']).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['author_id'] == student.id.to_s}
          expect(student_comment['avatar_path']).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before :each do
          allow(assignment).to receive(:can_view_student_names?).with(teacher).and_return(false)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json['submission_comments'].select {|comment| comment['anonymous_id'] == "aaaaa"}
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment).not_to have_key('author_name')
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json['submission_comments'].detect {|comment| comment['anonymous_id'] == 'aaaaa'}
          expect(student_comment['avatar_path']).to eql(User.default_avatar_fallback)
        end
      end

      # current user's rubric assessments

      it "includes assessor_name on the current grader's rubric assessments' on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "includes assessor_id from the current grader's rubric assessments on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_id" => teacher.id.to_s))
      end

      it "excludes anonymous_assessor_id on the current grader's rubric assessments on students" do
        teacher_assessments = json['context']['students'][0]['rubric_assessments']
        expect(teacher_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # all provisional grades

      it "includes scorer_id on all provisional grades" do
        scorer_ids = submission_json['provisional_grades'].map {|grade| grade['scorer_id']}
        expect(scorer_ids.uniq).to match_array([teacher.id, ta.id, moderator.id].map(&:to_s))
      end

      it "excludes anonymous_grader_id from all provisional grades" do
        expect(submission_json['provisional_grades']).to all(not_have_key("anonymous_grader_id"))
      end

      # all provisional grade rubric assessments

      it "includes assessor_name on all graders' rubric assessments on provisional grades'" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        grader_names = grader_assessments.map {|assessment| assessment['assessor_name']}
        expect(grader_names.uniq).to match_array([teacher, ta].map(&:name))
      end

      it "includes assessor_id on all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        assessor_ids = grader_assessments.map {|assessment| assessment['assessor_id']}
        expect(assessor_ids.uniq).to match_array([teacher.id, ta.id].map(&:to_s))
      end

      it "excludes anonymous_assessor_id from all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json['provisional_grades'].map {|grade| grade['rubric_assessments']}.flatten
        expect(grader_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # final provisional grade (current user)

      it "includes scorer_id on the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['scorer_id']).to eql(teacher.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade (other graders)

      it "includes scorer_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']['scorer_id']).to eql(ta.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json['final_provisional_grade']).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on the final provisional grade'" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "includes assessor_id on the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(include("assessor_id" => teacher.id.to_s))
      end

      it "excludes anonymous_assessor_id from the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(teacher_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # final provisional grade rubric assessments (other graders)

      it "includes assessor_name on the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("assessor_name" => ta.name))
      end

      it "includes assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(include("assessor_id" => ta.id.to_s))
      end

      it "excludes anonymous_assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json['final_provisional_grade']['rubric_assessments']
        expect(ta_assessments).to all(not_have_key("anonymous_assessor_id"))
      end
    end
  end

  def setup_assignment_with_homework
    setup_assignment_without_submission
    res = @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
    expect(res).not_to be_nil
    expect(res).to be_is_a(Submission)
    @assignment.reload
  end

  def setup_assignment_without_submission
    assignment_model(:course => @course)
    @assignment.reload
  end
end
