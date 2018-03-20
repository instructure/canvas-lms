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
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(:comment => 'comment', :provisional => true)
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

  describe "with moderated grading" do
    before(:once) do
      course_with_ta(:course => @course, :active_all => true)
      assignment_model(:course => @course, :submission_types => 'online_text_entry')
      rubric_model
      @association = @rubric.associate_with(@assignment, @course, :purpose => 'grading', :use_for_grading => true)

      @submission = @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'ahem')
      @assignment.update_submission(@student, :comment => 'real comment', :score => 1, :commenter => @student)

      selection = @assignment.moderated_grading_selections.create!(:student => @student)

      @submission.add_comment(:author => @teacher, :comment => 'provisional comment', :provisional => true)
      teacher_pg = @submission.provisional_grade(@teacher)
      teacher_pg.update_attribute(:score, 2)
      @association.assess(
        :user => @student, :assessor => @teacher, :artifact => teacher_pg,
        :assessment => {
          :assessment_type => 'grading',
          :criterion_crit1 => {
            :points => 2,
            :comments => 'a comment',
          }
        }
      )

      selection.provisional_grade = teacher_pg
      selection.save!

      @submission.add_comment(:author => @ta, :comment => 'other provisional comment', :provisional => true)
      ta_pg = @submission.provisional_grade(@ta)
      ta_pg.update_attribute(:score, 3)
      @association.assess(
        :user => @student, :assessor => @ta, :artifact => ta_pg,
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

    it "returns submission comments with null provisional grade" do
      course_with_ta :course => @course, :active_all => true
      json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      expect(find_real_submission(json)['submission_comments'].map { |comment| comment['comment'] }).to match_array ['real comment']
    end

    describe "for provisional grader" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @ta, :grading_role => :provisional_grader).json
      end

      it "includes only the grader's provisional grades" do
        s = find_real_submission(@json)
        expect(s['score']).to eq 3
        expect(s['provisional_grades']).to be_nil
      end

      it "includes only the grader's provisional comments (and the real ones)" do
        comments = find_real_submission(@json)['submission_comments'].map { |comment| comment['comment'] }
        expect(comments).to match_array ['other provisional comment', 'real comment']
      end

      it "only includes the grader's provisional rubric assessments" do
        ras = @json['context']['students'][0]['rubric_assessments']
        expect(ras.count).to eq 1
        expect(ras[0]['assessor_id']).to eq @ta.id.to_s
      end

      it "determines whether the student needs a provisional grade" do
        expect(@json['context']['students'][0]['needs_provisional_grade']).to be_falsey
        expect(@json['context']['students'][1]['needs_provisional_grade']).to be_truthy # other student
      end
    end

    describe "for moderator" do
      before(:once) do
        @json = Assignment::SpeedGrader.new(@assignment, @teacher, :grading_role => :moderator).json
      end

      it "includes the moderator's provisional grades and comments" do
        s = find_real_submission(@json)
        expect(s['score']).to eq 2
        expect(s['submission_comments'].map { |comment| comment['comment'] }).to match_array ['provisional comment', 'real comment']
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

  context "with anonymous moderated marking enabled" do
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

    let_once(:assignment) { course.assignments.create!(title: "Example Assignment", submission_types: ['online_upload'], anonymous_grading: true) }
    let_once(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
    end

    let(:attachment_1) { student_1.attachments.create!(uploaded_data: dummy_io, filename: "homework.png", context: student_1) }
    let(:attachment_2) { teacher.attachments.create!(uploaded_data: dummy_io, filename: "homework.png", context: teacher) }

    let(:submission_1) { assignment.submit_homework(student_1, submission_type: "online_upload", attachments: [attachment_1]) }
    let(:submission_2) { assignment.submit_homework(student_2, submission_type: "online_upload", attachments: [attachment_2]) }
    let(:test_submission) { Submission.find_by(user_id: test_student.id, assignment_id: assignment.id) }

    before :once do
      course.account.enable_feature!(:anonymous_moderated_marking)

      course.enroll_student(student_1, section: section_1).accept!
      course.enroll_student(student_2, section: section_2).accept!
    end

    before :each do
      submission_1.anonymous_id = 'aaaaa'
      submission_1.save!

      submission_2.anonymous_id = 'bbbbb'
      submission_2.save!

      test_submission.anonymous_id = 'ccccc'
      test_submission.save!
    end

    it "adds anonymous ids to student enrollments" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      anonymous_ids = json['context']['enrollments'].map { |enrollment| enrollment['anonymous_id'] }
      expect(anonymous_ids.uniq).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
    end

    it "excludes user ids from student enrollments" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      expect(json['context']['enrollments']).to all(not_have_key('user_id'))
    end

    it "excludes ids from students" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      expect(json['context']['students']).to all(not_have_key('id'))
    end

    it "adds anonymous ids to students" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      anonymous_ids = json['context']['students'].map { |student| student['anonymous_id'] }
      expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
    end

    it "excludes user ids from submissions" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      expect(json['submissions']).to all(not_have_key('user_id'))
    end

    it "includes anonymous ids on submissions" do
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      anonymous_ids = json['submissions'].map { |submission| submission['anonymous_id'] }
      expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb', 'ccccc'])
    end

    it "excludes user ids from rubrics" do
      submission_1.add_comment(author: teacher, comment: "provisional comment", provisional: true)
      provisional_grade = submission_1.provisional_grade(teacher)
      provisional_grade.update_attribute(:score, 2)
      rubric_association.assess(
        artifact: provisional_grade,
        assessment: {
          assessment_type: 'grading',
          criterion_crit1: {
            points: 2,
            comments: 'Comment',
          }
        },
        assessor: teacher,
        user: student_1
      )
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      student = json['context']['students'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(student['rubric_assessments']).to all(not_have_key('user_id'))
    end

    it "excludes student author ids from submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: student_1, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(submission['submission_comments']).to all(not_have_key('author_id'))
    end

    it "excludes student author names from submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: student_1, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(submission['submission_comments']).to all(not_have_key('author_name'))
    end

    it "includes author ids of other graders on submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: ta, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      anonymous_ids = submission['submission_comments'].map { |s| s['author_id'] }
      expect(anonymous_ids).to match_array([nil, ta.id.to_s])
    end

    it "includes author names of other graders on submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: ta, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      author_names = submission['submission_comments'].map { |s| s['author_name'] }
      expect(author_names).to match_array([nil, ta.name])
    end

    it "uses the default avatar for students on submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: student_1, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher, avatars: true).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      avatars = submission['submission_comments'].map { |s| s['avatar_path'] }
      expect(avatars).to all(eql(User.default_avatar_fallback))
    end

    it "uses the user avatar for other graders on submission comments" do
      submission_1.add_comment(author: teacher, comment: "Example")
      submission_1.add_comment(author: ta, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher, avatars: true).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      avatars = submission['submission_comments'].map { |s| s['avatar_path'] }
      expect(avatars).to match_array([ta.avatar_path, teacher.avatar_path])
    end

    it "optionally does not include avatars" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: teacher, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher, avatars: false).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(submission['submission_comments']).to all(not_have_key('avatar_path'))
    end

    it "adds anonymous ids to submission comments" do
      submission_1.add_comment(author: student_1, comment: "Example")
      submission_1.add_comment(author: student_2, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      anonymous_ids = submission['submission_comments'].map { |s| s['anonymous_id'] }
      expect(anonymous_ids).to match_array(['aaaaa', 'bbbbb'])
    end

    it "includes the current user's author ids on submission comments" do
      submission_1.add_comment(author: teacher, comment: "Example")
      submission_1.add_comment(author: teacher, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(submission['submission_comments'].map { |s| s['author_id'] }).to match_array([teacher.id.to_s] * 2)
    end

    it "includes the current user's author names on submission comments" do
      submission_1.add_comment(author: teacher, comment: "Example")
      submission_1.add_comment(author: teacher, comment: "Sample")
      json = Assignment::SpeedGrader.new(assignment, teacher).json
      submission = json['submissions'].detect { |s| s['anonymous_id'] == 'aaaaa' }
      expect(submission['submission_comments'].map { |s| s['author_name'] }).to match_array(['Teacher'] * 2)
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
