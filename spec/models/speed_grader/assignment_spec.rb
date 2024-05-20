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

require "lti2_spec_helper"

describe SpeedGrader::Assignment do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: "some user")
  end

  context "create and publish a course with 2 students" do
    let_once(:first_student) do
      course_with_student(course: @course)
      @student
    end
    let_once(:second_student) do
      course_with_student(course: @course)
      @student
    end
    let_once(:teacher) do
      course_with_teacher(course: @course)
      @teacher
    end

    context "add students to the group" do
      let(:category) { @course.group_categories.create! name: "Group Set" }
      let(:assignment) do
        @course.assignments.create!(
          group_category_id: category.id,
          grade_group_students_individually: false,
          submission_types: %w[text_entry]
        )
      end
      let(:homework_params) do
        {
          submission_type: "online_text_entry",
          body: "blah",
          comment: "a group comment during submission from first student",
          group_comment: true
        }.freeze
      end
      let(:comment_two_to_group_params) do
        {
          comment: "a group comment from first student",
          user_id: first_student.id,
          group_comment: true
        }.freeze
      end
      let(:comment_three_to_group_params) do
        {
          comment: "a group comment from second student",
          user_id: second_student.id,
          group_comment: true
        }.freeze
      end
      let(:comment_four_private_params) do
        {
          comment: "a private comment from first student",
          user_id: first_student.id,
        }.freeze
      end
      let(:comment_five_private_params) do
        {
          comment: "a private comment from second student",
          user_id: second_student.id,
        }.freeze
      end
      let(:comment_six_to_group_params) do
        {
          comment: "a group comment from teacher",
          user_id: teacher.id,
          group_comment: true
        }.freeze
      end
      let(:comment_seven_private_params) do
        {
          comment: "a private comment from teacher",
          user_id: teacher.id,
        }.freeze
      end

      before do
        group = category.groups.create!(name: "a group", context: @course)
        group.add_user(first_student)
        group.add_user(second_student)
        assignment.submit_homework(first_student, homework_params.dup)
        assignment.update_submission(first_student, comment_two_to_group_params.dup)
        assignment.update_submission(first_student, comment_three_to_group_params.dup)
        assignment.update_submission(first_student, comment_four_private_params.dup)
        assignment.update_submission(first_student, comment_five_private_params.dup)
        assignment.update_submission(first_student, comment_six_to_group_params.dup)
        assignment.update_submission(first_student, comment_seven_private_params.dup)
      end

      describe "only shows group comments" do
        subject { @comments }

        before do
          json = SpeedGrader::Assignment.new(assignment, teacher).json
          student_a_submission = json.fetch(:submissions).find { |s| s[:user_id] == first_student.id.to_s }
          @comments = student_a_submission.fetch(:submission_comments).map do |comment|
            comment.slice(:author_id, :comment)
          end
        end

        it do
          expect(subject).to include({ "author_id" => first_student.id.to_s, "comment" => homework_params.fetch(:comment) })
        end

        it do
          expect(subject).to include({
                                       "author_id" => comment_two_to_group_params.fetch(:user_id).to_s,
                                       "comment" => comment_two_to_group_params.fetch(:comment)
                                     })
        end

        it do
          expect(subject).to include({
                                       "author_id" => comment_three_to_group_params.fetch(:user_id).to_s,
                                       "comment" => comment_three_to_group_params.fetch(:comment)
                                     })
        end

        it do
          expect(subject).to include({
                                       "author_id" => comment_six_to_group_params.fetch(:user_id).to_s,
                                       "comment" => comment_six_to_group_params.fetch(:comment)
                                     })
        end

        it do
          expect(subject).not_to include({
                                           "author_id" => comment_four_private_params.fetch(:user_id).to_s,
                                           "comment" => comment_four_private_params.fetch(:comment)
                                         })
        end

        it do
          expect(subject).not_to include({
                                           "author_id" => comment_five_private_params.fetch(:user_id).to_s,
                                           "comment" => comment_five_private_params.fetch(:comment)
                                         })
        end

        it do
          expect(subject).not_to include({
                                           "author_id" => comment_seven_private_params.fetch(:user_id).to_s,
                                           "comment" => comment_seven_private_params.fetch(:comment)
                                         })
        end
      end
    end
  end

  it "includes comments' created_at" do
    assignment_model(course: @course)
    @assignment.submit_homework(@user, { submission_type: "online_text_entry", body: "blah" })
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(comment: "comment")
    json = SpeedGrader::Assignment.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments].first[:created_at].to_i).to eql @comment.created_at.to_i
  end

  it "excludes provisional comments" do
    assignment_model(course: @course)
    @assignment.submit_homework(@user, { submission_type: "online_text_entry", body: "blah" })
    @assignment.moderated_grading = true
    @assignment.grader_count = 2
    @assignment.save!
    @submission = @assignment.submissions.first
    @comment = @submission.add_comment(comment: "comment", author: @teacher, provisional: true)
    json = SpeedGrader::Assignment.new(@assignment, @user).json
    expect(json[:submissions].first[:submission_comments]).to be_empty
  end

  it "includes submission resource_link_lookup_uuid" do
    params = {
      submission_type: "basic_lti_launch",
      url: "http://lti13testtool.docker/launch?deep_linking=true",
      resource_link_lookup_uuid: "41b67e00-c2ae-44b1-8c8e-e9a782f39e30"
    }

    assignment_model(course: @course)
    @assignment.submit_homework(@user, params)
    @assignment.save!

    json = SpeedGrader::Assignment.new(@assignment, @user).json
    expect(json[:submissions].first[:resource_link_lookup_uuid]).to eq params[:resource_link_lookup_uuid]
  end

  it "returns provisional grade ids to provisional grader" do
    final_grader = @course.enroll_teacher(User.create!, enrollment_state: "active").user
    assignment = Assignment.create!(
      context: @course,
      moderated_grading: true,
      grader_count: 2,
      final_grader:
    )
    assignment.submit_homework(@user, { submission_type: "online_text_entry", body: "blah" })
    submission = assignment.submissions.first
    comment = submission.add_comment(comment: "comment", author: final_grader, provisional: true)
    json = SpeedGrader::Assignment.new(assignment, @teacher, grading_role: :provisional_grader).json
    expect(
      json[:submissions].first[:provisional_grades].first[:provisional_grade_id]
    ).to eq comment.provisional_grade_id.to_s
  end

  context "rubric association" do
    before(:once) do
      @assignment = assignment_model(course: @course)
    end

    let(:json) { SpeedGrader::Assignment.new(@assignment, @user).json }

    it "does not include rubric_association when one does not exist" do
      expect(json).not_to have_key "rubric_association"
    end

    it "does not include rubric_association when one exists but it is not active" do
      rubric = rubric_model
      association = rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      association.destroy
      expect(json).not_to have_key "rubric_association"
    end

    it "includes a rubric_association when one exists and is active" do
      rubric = rubric_model
      association = rubric.associate_with(@assignment, @course, purpose: "grading", use_for_grading: true)
      expect(json.dig("rubric_association", "id")).to eq association.id.to_s
    end
  end

  context "students and active course sections" do
    before(:once) do
      @course = course_factory(active_course: true)
      @teacher, @student1, @student2 = (1..3).map { User.create }
      @assignment = Assignment.create!(title: "title", context: @course, only_visible_to_overrides: true)
      @course.enroll_teacher(@teacher)
      @course.enroll_student(@student2, enrollment_state: "active")
      @section1 = @course.course_sections.create!(name: "test section 1")
      @section2 = @course.course_sections.create!(name: "test section 2")
      student_in_section(@section1, user: @student1)
      create_section_override_for_assignment(@assignment, { course_section: @section1 })
    end

    it "includes only students and sections with overrides for differentiated assignments" do
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json

      expect(json[:context][:students].pluck(:id)).to include(@student1.id.to_s)
      expect(json[:context][:students].pluck(:id)).not_to include(@student2.id.to_s)
      expect(json[:context][:active_course_sections].pluck(:id)).to include(@section1.id.to_s)
      expect(json[:context][:active_course_sections].pluck(:id)).not_to include(@section2.id.to_s)
    end

    it "sorts student view students last" do
      test_student = @course.student_view_student
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      expect(json[:context][:students].last[:id]).to eq(test_student.id.to_s)
    end

    it "includes all students when is only_visible_to_overrides false" do
      @assignment.only_visible_to_overrides = false
      @assignment.save!
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json

      expect(json[:context][:students].pluck(:id)).to include(@student1.id.to_s)
      expect(json[:context][:students].pluck(:id)).to include(@student2.id.to_s)
      expect(json[:context][:active_course_sections].pluck(:id)).to include(@section1.id.to_s)
      expect(json[:context][:active_course_sections].pluck(:id)).to include(@section2.id.to_s)
    end
  end

  context "with submissions" do
    let(:now) { Time.zone.now }

    before do
      section_1 = @course.course_sections.create!(name: "Section one")
      section_2 = @course.course_sections.create!(name: "Section two")

      @assignment = @course.assignments.create!(title: "Overridden assignment", due_at: 5.days.ago(now))

      @student_1 = user_with_pseudonym(active_all: true, username: "student1@example.com")
      @student_2 = user_with_pseudonym(active_all: true, username: "student2@example.com")

      @course.enroll_student(@student_1, section: section_1).accept!
      @course.enroll_student(@student_2, section: section_2).accept!

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

      @assignment.submit_homework(@student_1, submission_type: "online_text_entry", body: "blah")
      @assignment.submit_homework(@student_2, submission_type: "online_text_entry", body: "blah")

      allow(Canvadocs).to receive(:config).and_return({ a: 1 })
      allow(Canvadoc).to receive(:mime_types).and_return("image/png")
    end

    describe "has_postable_comments" do
      before do
        @assignment.ensure_post_policy(post_manually: true)
      end

      it "is true when submission is unposted and hidden comments exist" do
        student1_sub = @assignment.submissions.find_by!(user: @student_1)
        student1_sub.add_comment(author: @teacher, comment: "good job!", hidden: true)
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        submission_json = json[:submissions].find { |sub| sub["user_id"] == student1_sub.user_id.to_s }
        expect(submission_json["has_postable_comments"]).to be true
      end

      it "is false when submission is unposted and only non-hidden comments exist" do
        student1_sub = @assignment.submissions.find_by!(user: @student_1)
        student1_sub.add_comment(author: @student1, comment: "good job!", hidden: false)
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        submission_json = json[:submissions].find { |sub| sub["user_id"] == student1_sub.user_id.to_s }
        expect(submission_json["has_postable_comments"]).to be false
      end

      it "is false when submission is unposted and only draft comments exist" do
        student1_sub = @assignment.submissions.find_by!(user: @student_1)
        student1_sub.add_comment(
          author: @teacher,
          comment: "conspiratorial draft comment",
          hidden: true,
          draft_comment: true
        )
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        submission_json = json[:submissions].find { |sub| sub["user_id"] == student1_sub.user_id.to_s }
        expect(submission_json["has_postable_comments"]).to be false
      end
    end

    it "returns submission lateness" do
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        if submission[:workflow_state] == "submitted"
          expect(submission[:late]).to eq user.submissions.first.late?
        end
      end
    end

    it "returns grading_period_id on submissions" do
      group = @course.root_account.grading_period_groups.create!
      group.enrollment_terms << @course.enrollment_term
      period = group.grading_periods.create!(
        title: "A Grading Period",
        start_date: now - 2.months,
        end_date: now + 2.months
      )
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      submission = json[:submissions].first
      expect(submission.fetch("grading_period_id")).to eq period.id.to_s
    end

    context "DocViewer" do
      let(:course) { student_in_course(active_all: true).course }
      let(:assignment) { assignment_model(course:) }
      let(:attachment) do
        attachment_model(
          context: @student,
          uploaded_data: stub_png_data,
          filename: "homework.png"
        )
      end
      let(:json) { SpeedGrader::Assignment.new(assignment, @teacher).json }
      let(:sub) do
        json[:submissions].find do |submission|
          submission[:submission_history][0][:submission][:versioned_attachments].any?
        end
      end
      let(:versioned_attachments) { sub[:submission_history][0][:submission][:versioned_attachments] }
      let(:canvadoc_url) { versioned_attachments.first.dig(:attachment, :canvadoc_url) }

      it "creates a non-annotatable DocViewer session for Discussion attachments" do
        assignment.anonymous_grading = true
        topic = course.discussion_topics.create!(assignment:)
        entry = topic.reply_from(user: @student, text: "entry")
        entry.attachment = attachment
        entry.save!
        topic.ensure_submission(@student)

        expect(canvadoc_url.include?("enable_annotations%22:false")).to be true
      end

      it "creates DocViewer session anonymous instructor annotations if assignment has it set" do
        assignment.anonymous_instructor_annotations = true
        topic = course.discussion_topics.create!(assignment:)
        entry = topic.reply_from(user: @student, text: "entry")
        entry.attachment = attachment
        entry.save!
        topic.ensure_submission(@student)

        expect(canvadoc_url.include?("anonymous_instructor_annotations%22:true")).to be true
      end

      it "passes enrollment type to DocViewer" do
        topic = course.discussion_topics.create!(assignment:)
        entry = topic.reply_from(user: @student, text: "entry")
        entry.attachment = attachment
        entry.save!
        topic.ensure_submission(@student)

        expect(canvadoc_url.include?("enrollment_type%22:%22teacher%22")).to be true
      end

      it "passes submission id to DocViewer" do
        submission = assignment.submit_homework(@student, attachments: [attachment])
        allow(Canvadocs).to receive(:enabled?).and_return(true)

        expect(canvadoc_url.include?("%22submission_id%22:#{submission.id}")).to be true
      end

      describe "disable_annotation_notifications" do
        it "disables annotations if the assignment posts manually and the submission is not posted" do
          assignment.ensure_post_policy(post_manually: true)
          assignment.submit_homework(@student, attachments: [attachment])
          allow(Canvadocs).to receive(:enabled?).and_return(true)
          expect(canvadoc_url).to include "disable_annotation_notifications%22:true"
        end

        it "enables annotations if the assignment posts automatically" do
          assignment.submit_homework(@student, attachments: [attachment])
          allow(Canvadocs).to receive(:enabled?).and_return(true)
          expect(canvadoc_url).to include "disable_annotation_notifications%22:false"
        end

        it "enables annotations if the assignment posts manually and the submission has been posted" do
          assignment.ensure_post_policy(post_manually: true)
          submission = assignment.submit_homework(@student, attachments: [attachment])
          assignment.post_submissions(submission_ids: [submission.id])
          allow(Canvadocs).to receive(:enabled?).and_return(true)
          expect(canvadoc_url).to include "disable_annotation_notifications%22:false"
        end
      end
    end

    it "includes submission missing status in each submission history version" do
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        next unless user

        submission[:submission_history].each_with_index do |version, idx|
          expect(version[:submission][:missing]).to eq user.submissions.first.submission_history[idx].missing?
        end
      end
    end

    it "includes submission late status in each submission history version" do
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      json[:submissions].each do |submission|
        user = [@student_1, @student_2].detect { |s| s.id.to_s == submission[:user_id] }
        next unless user

        submission[:submission_history].each_with_index do |version, idx|
          expect(version[:submission][:late]).to eq user.submissions.first.submission_history[idx].late?
        end
      end
    end

    it "includes submission entered_score and entered_grade in each submission history version" do
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
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

    describe "submission posting" do
      let(:submission_json) do
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        json[:submissions].detect { |submission| submission[:user_id] == @student_1.id.to_s }
      end

      it "includes the submission's posted-at date in the posted_at field" do
        posted_at_time = 1.day.ago
        @assignment.submission_for_student(@student_1).update!(posted_at: posted_at_time)
        expect(submission_json["posted_at"]).to eq posted_at_time
      end

      it "includes nil for the posted_at field if the submission is not posted" do
        expect(submission_json["posted_at"]).to be_nil
      end
    end

    describe "custom grade statuses" do
      let(:submission_json) do
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        json[:submissions].detect { |submission| submission[:user_id] == @student_1.id.to_s }
      end

      let(:custom_grade_status) { CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account_id, created_by: @teacher) }

      it "includes the submission's custom grade status in the custom_grade field when the feature flag is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        @assignment.submission_for_student(@student_1).update!(custom_grade_status:)
        expect(submission_json["custom_grade_status_id"]).to eq custom_grade_status.id.to_s
      end

      it "includes nil for the custom_grade field if the submission does not have a custom grade status" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        expect(submission_json["custom_grade_status_id"]).to be_nil
      end

      it "does not include the custom grade status in the custom_grade field when the feature flag is disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        @assignment.submission_for_student(@student_1).update!(custom_grade_status:)
        expect(submission_json["custom_grade_status_id"]).to be_nil
      end
    end

    describe "attachment JSON" do
      let(:viewed_at_time) { Time.zone.now }

      let(:course) { Course.create! }
      let(:assignment) { course.assignments.create!(title: "test", points_possible: 10) }
      let(:student) { course_with_student(course:).user }
      let(:teacher) { course_with_teacher(course:).user }
      let(:attachment) do
        student.attachments.create!(uploaded_data: stub_png_data, filename: "file.png", viewed_at: viewed_at_time)
      end

      before do
        assignment.submit_homework(student, attachments: [attachment])
      end

      it "includes redo_request field" do
        json = SpeedGrader::Assignment.new(assignment, teacher).json
        expect(json.dig("submissions", 0)).to have_key :redo_request
      end

      it "includes the viewed_at field if the assignment is not anonymized" do
        json = SpeedGrader::Assignment.new(assignment, teacher).json
        submission_json = json.dig(:submissions, 0, :submission_history, 0, :submission)
        attachment_json = submission_json.dig(:versioned_attachments, 0, :attachment)
        expect(attachment_json.fetch(:viewed_at)).to eq viewed_at_time
      end

      context "for an anonymized assignment" do
        before do
          allow(assignment).to receive(:anonymize_students?).and_return(true)
        end

        it "includes the viewed_at field if the user is an admin" do
          admin = User.create!
          Account.default.account_users.create!(user: admin)

          json = SpeedGrader::Assignment.new(assignment, admin).json

          submission_json = json.dig(:submissions, 0, :submission_history, 0, :submission)
          attachment_json = submission_json.dig(:versioned_attachments, 0, :attachment)
          expect(attachment_json[:viewed_at]).to eq viewed_at_time
        end

        it "omits the viewed_at field if the user is not an admin" do
          json = SpeedGrader::Assignment.new(assignment, teacher).json
          submission_json = json.dig(:submissions, 0, :submission_history, 0, :submission)
          attachment_json = submission_json.dig(:versioned_attachments, 0, :attachment)
          expect(attachment_json).not_to include(:viewed_at)
        end
      end
    end
  end

  it "includes inline view pingback url for files" do
    assignment = @course.assignments.create! submission_types: ["online_upload"]
    attachment = @student.attachments.create! uploaded_data: dummy_io, filename: "doc.doc", display_name: "doc.doc", context: @student
    assignment.submit_homework @student, submission_type: :online_upload, attachments: [attachment]
    json = SpeedGrader::Assignment.new(assignment, @teacher).json
    attachment_json = json["submissions"][0]["submission_history"][0]["submission"]["versioned_attachments"][0]["attachment"]
    expect(attachment_json["view_inline_ping_url"]).to match %r{/assignments/#{assignment.id}/files/#{attachment.id}/inline_view\z}
  end

  it "includes lti launch url in submission history" do
    assignment_model(course: @course)
    @assignment.submit_homework(@user, submission_type: "basic_lti_launch", url: "http://www.example.com")
    json = SpeedGrader::Assignment.new(@assignment, @teacher).json
    url_json = json["submissions"][0]["submission_history"][0]["submission"]["external_tool_url"]
    expect(url_json).to eql("http://www.example.com")
  end

  context "course is soft concluded" do
    before :once do
      course_with_teacher(active_all: true)
      @student1 = User.create!
      @student2 = User.create!
      @course.enroll_student(@student1, enrollment_state: "active")
      @course.enroll_student(@student2, enrollment_state: "active")
      assignment_model(course: @course)
      @teacher.preferences[:gradebook_settings] = {}
      @teacher.preferences[:gradebook_settings][@course.global_id] = {
        "show_concluded_enrollments" => "false"
      }
    end

    it "does not include concluded students when user preference is to not include" do
      Enrollment.find_by(user: @student1).conclude
      @course.update!(conclude_at: 1.day.ago, start_at: 2.days.ago)
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      expect(json[:context][:students].count).to be 1
    end

    it "includes concluded when user preference is to include" do
      @teacher.preferences[:gradebook_settings][@course.global_id]["show_concluded_enrollments"] = "true"
      Enrollment.find_by(user: @student1).conclude
      @course.update!(conclude_at: 1.day.ago, start_at: 2.days.ago)
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json
      expect(json[:context][:students].count).to be 2
    end
  end

  context "group assignments" do
    before :once do
      @teacher = course_with_teacher(active_all: true).user
      @group_category = @course.group_categories.create!(name: "Group Set")
      @first_group = @group_category.groups.create!(name: "Group 1", context: @course)
      @second_group = @group_category.groups.create!(name: "Group 2", context: @course)
      @groups = [@first_group, @second_group]
      students = create_users_in_course(@course, 6, return_type: :record)
      students.each_with_index do |student, index|
        @groups.fetch(index % @groups.size).add_user(student)
      end
    end

    context "given an assignment" do
      before(:once) do
        @assignment = @course.assignments.create!
      end

      it "is not in group mode for non-group assignments" do
        @assignment.submit_homework(@student, { submission_type: "online_text_entry", body: "blah" })
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json["GROUP_GRADING_MODE"]).to be false
      end

      context "when a course has new gradeook and filter by student group enabled" do
        before(:once) do
          @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
          @course.update!(filter_speed_grader_by_student_group: true)
        end

        context "when no group filter is present" do
          it "returns all students" do
            @teacher.preferences.deep_merge!(gradebook_settings: {
                                               @course.id => { "filter_rows_by" => { "student_group_id" => nil } }
                                             })
            json = SpeedGrader::Assignment.new(@assignment, @teacher).json
            json_students = json.fetch(:context).fetch(:students).map { |s| s.except(:rubric_assessments, :fake_student) }
            students = @course.students.as_json(include_root: false, only: %i[id name sortable_name])
            StringifyIds.recursively_stringify_ids(students)
            expect(json_students).to match_array(students)
          end
        end

        context "when the first group filter is present" do
          let(:group) { @first_group }

          before(:once) do
            @teacher.preferences.deep_merge!(gradebook_settings: {
                                               @course.global_id => { "filter_rows_by" => { "student_group_id" => group.id.to_s } }
                                             })
          end

          it "returns only students that belong to the first group" do
            json = SpeedGrader::Assignment.new(@assignment, @teacher).json
            json_students = json.fetch(:context).fetch(:students).map { |s| s.except(:rubric_assessments, :fake_student) }
            group_students = group.users.as_json(include_root: false, only: %i[id name sortable_name])
            StringifyIds.recursively_stringify_ids(group_students)
            expect(json_students).to match_array(group_students)
          end

          context "when a student is removed from a group" do
            let(:first_student) { group.users.first }

            before { group.group_memberships.find_by!(user: first_student).destroy! }

            it "that student is no longer included" do
              json = SpeedGrader::Assignment.new(@assignment, @teacher).json
              json_students = json.fetch(:context).fetch(:students).map { |s| s.except(:rubric_assessments, :fake_student) }
              group_students = group.users.where.not(id: first_student)
                                    .as_json(include_root: false, only: %i[id name sortable_name])
              StringifyIds.recursively_stringify_ids(group_students)
              expect(json_students).to match_array(group_students)
            end
          end

          context "when the second group filter is present" do
            let(:group) { @second_group }

            it "returns only students that belong to the second group" do
              @teacher.preferences.deep_merge!(gradebook_settings: {
                                                 @course.global_id => { "filter_rows_by" => { "student_group_id" => group.id.to_s } }
                                               })
              json = SpeedGrader::Assignment.new(@assignment, @teacher).json
              json_students = json.fetch(:context).fetch(:students).map { |s| s.except(:rubric_assessments, :fake_student) }
              group_students = group.users.as_json(include_root: false, only: %i[id name sortable_name])
              StringifyIds.recursively_stringify_ids(group_students)
              expect(json_students).to match_array(group_students)
            end
          end

          context "when the group the user is filtering by has been deleted" do
            let(:group) { @second_group }

            it "returns all students rather than attempting to filter by the deleted group" do
              @teacher.preferences.deep_merge!(gradebook_settings: {
                                                 @course.global_id => { "filter_rows_by" => { "student_group_id" => group.id.to_s } }
                                               })
              group.destroy!

              json = SpeedGrader::Assignment.new(@assignment, @teacher).json
              json_students = json.fetch(:context).fetch(:students).map { |s| s.except(:rubric_assessments, :fake_student) }
              course_students = @course.students.as_json(include_root: false, only: %i[id name sortable_name])
              StringifyIds.recursively_stringify_ids(course_students)
              expect(json_students).to match_array(course_students)
            end
          end
        end
      end
    end

    context "given a group assignment" do
      before(:once) do
        @assignment = @course.assignments.create!(
          group_category_id: @group_category.id,
          grade_group_students_individually: false,
          submission_types: %w[text_entry]
        )
      end

      it "sorts student view students last" do
        test_student = @course.student_view_student
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json[:context][:students].last[:id]).to eq(test_student.id.to_s)
      end

      it 'returns "groups" instead of students' do
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        @groups.each do |group|
          j = json["context"]["students"].find { |g| g["name"] == group.name }
          expect(group.users.map { |u| u.id.to_s }).to include j["id"]
        end
        expect(json["GROUP_GRADING_MODE"]).to be_truthy
      end

      it "chooses the student with turnitin data to represent" do
        @assignment.update!(turnitin_enabled: true)
        submissions = @groups.map do |group|
          rep = group.users.sample
          @assignment.grade_student(rep, grade: 10, grader: @teacher).first.tap do |submission|
            submission.update!(turnitin_data: { blah: 1 })
          end
        end

        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        json_submission_ids = json["submissions"].map { |s| s.fetch("id") }
        submission_ids = submissions.map { |t| t.id.to_s }
        expect(json_submission_ids).to match_array(submission_ids)
      end

      it "prefers people with submissions" do
        @assignment.grade_student(@first_group.users.first, score: 10, grader: @teacher)
        first_group_representative = @first_group.users.sample
        submission = @assignment.submission_for_student(first_group_representative)
        submission.update!(submission_type: "online_upload")
        expect(@assignment.representatives(user: @teacher)).to include first_group_representative
      end

      it "prefers people who aren't excused when submission exists" do
        first_group_representative, *everyone_else = @first_group.users.to_a.shuffle
        @assignment.submit_homework(first_group_representative, {
                                      submission_type: "online_text_entry",
                                      body: "hi"
                                    })
        everyone_else.each do |user|
          @assignment.grade_student(user, excuse: true, grader: @teacher)
        end
        expect(@assignment.representatives(user: @teacher)).to include first_group_representative
      end

      it "includes users who aren't in a group" do
        student_in_course active_all: true
        expect(@assignment.representatives(user: @teacher)).to include @student
      end

      it "includes groups" do
        student_in_course active_all: true
        group = @group_category.groups.create!(context: @course)
        group.add_user(@student)
        expect(@assignment.representatives(user: @teacher).map(&:name)).to include group.name
      end

      it "doesn't include deleted groups" do
        student_in_course active_all: true
        group = @group_category.groups.create!(context: @course)
        group.add_user(@student)
        group.destroy!
        expect(@assignment.representatives(user: @teacher).map(&:name)).not_to include group.name
      end

      it "prefers active users over other workflow states" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.first.deactivate
        enrollments.second.conclude

        reps = @assignment.representatives(user: @teacher, includes: %i[inactive completed])
        user = reps.find { |u| u.name == @first_group.name }
        expect(user).to eql(enrollments.third.user)
      end

      it "prefers inactive users when no active users are present" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.first.conclude
        enrollments.second.deactivate
        enrollments.third.conclude

        reps = @assignment.representatives(user: @teacher, includes: %i[inactive completed])
        user = reps.find { |u| u.name == @first_group.name }
        expect(user).to eql(enrollments.second.user)
      end

      it "includes concluded students when included" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.each(&:conclude)

        reps = @assignment.representatives(user: @teacher, includes: [:completed])
        user = reps.find { |u| u.name == @first_group.name }
        expect(enrollments.find_by(user:)).to be_present
      end

      it "does not include concluded students when included" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.each(&:conclude)

        reps = @assignment.representatives(user: @teacher, includes: [])
        user = reps.find { |u| u.name == @first_group.name }
        expect(user).to be_nil
      end

      it "includes inactive students when included" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.each(&:deactivate)

        reps = @assignment.representatives(user: @teacher, includes: [:inactive])
        user = reps.find { |u| u.name == @first_group.name }
        expect(enrollments.find_by(user:)).to be_present
      end

      it "does not include inactive students when included" do
        enrollments = @first_group.all_real_student_enrollments
        enrollments.each(&:deactivate)

        reps = @assignment.representatives(user: @teacher, includes: [])
        user = reps.find { |u| u.name == @first_group.name }
        expect(user).to be_nil
      end
    end
  end

  describe "filtering students by section" do
    let_once(:course) { Course.create! }
    let_once(:teacher) { course.enroll_teacher(User.create, enrollment_state: :active).user }

    let_once(:section1) { course.course_sections.create!(name: "first") }

    let_once(:section2) { course.course_sections.create!(name: "second") }

    let_once(:section1_student) { User.create! }
    let_once(:section2_student) { User.create! }
    let_once(:default_section_student) { User.create! }
    let_once(:sectionless_student) { User.create! }

    let_once(:assignment) { course.assignments.create! }

    let(:json) { SpeedGrader::Assignment.new(assignment, teacher).json }
    let(:returned_student_ids) { json.dig(:context, :students).pluck(:id) }
    let(:all_course_student_ids) { course.students.pluck(:id).map(&:to_s) }

    before(:once) do
      course.enroll_student(section1_student, enrollment_state: :active, section: section1)
      course.enroll_student(section2_student, enrollment_state: :active, section: section2)
      course.enroll_student(default_section_student, enrollment_state: :active)
    end

    before do
      user_session(teacher)
    end

    it "only returns students from the selected section if the user has selected one" do
      teacher.preferences.deep_merge!(gradebook_settings: {
                                        course.global_id => { "filter_rows_by" => { "section_id" => section1.id.to_s } }
                                      })
      expect(returned_student_ids).to contain_exactly(section1_student.id.to_s)
    end

    it "returns all eligible students if the user has not selected a section" do
      expect(returned_student_ids).to match_array(all_course_student_ids)
    end

    it "returns all eligible students if the selected section is set to nil" do
      teacher.preferences.deep_merge!(gradebook_settings: {
                                        course.global_id => { "filter_rows_by" => { "section_id" => nil } }
                                      })
      expect(returned_student_ids).to match_array(all_course_student_ids)
    end

    context "when the user is filtering by both section and group" do
      let_once(:group) do
        category = course.group_categories.create!(name: "Group Set")
        category.create_groups(2)

        group = category.groups.first
        group.add_user(section1_student)
        group.add_user(section2_student)
        group
      end

      it "restricts by both section and group when section_id and group_id are both specified" do
        teacher.preferences.deep_merge!(gradebook_settings: {
                                          course.global_id => { "filter_rows_by" => { "section_id" => section1.id.to_s, "student_group_id" => group.id.to_s } }
                                        })
        expect(returned_student_ids).to contain_exactly(section1_student.id.to_s)
      end
    end
  end

  context "quizzes" do
    it "works for quizzes without quiz_submissions" do
      quiz = @course.quizzes.create! title: "Final",
                                     quiz_type: "assignment"
      quiz.did_edit
      quiz.offer

      assignment = quiz.assignment
      assignment.grade_student(@student, grade: 1, grader: @teacher)
      json = SpeedGrader::Assignment.new(assignment, @teacher).json
      expect(json[:submissions]).to all(have_key("submission_history"))
    end

    context "with quiz_submissions" do
      before :once do
        @quiz_submission = quiz_with_graded_submission [], course: @course, user: @student
      end

      it "doesn't include quiz_submissions when there are too many attempts" do
        stub_const("AbstractAssignment::QUIZ_SUBMISSION_VERSIONS_LIMIT", 3)
        3.times do
          @quiz_submission.versions.create!
        end
        json = SpeedGrader::Assignment.new(@quiz.assignment, @teacher).json
        json[:submissions].all? { |s| expect(s["submission_history"].size).to eq 1 }
      end

      it "returns quiz lateness correctly" do
        @quiz.time_limit = 10
        @quiz.save!

        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json[:submissions].first["submission_history"].first[:submission]["late"]).to be_falsey

        @quiz.due_at = 1.day.ago
        @quiz.save!

        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json[:submissions].first["submission_history"].first[:submission]["late"]).to be_truthy
      end

      it "returns quiz lateness correctly with overrides" do
        o = @quiz.assignment_overrides.build
        o.due_at = 1.day.ago
        o.due_at_overridden = true
        o.set = @course.default_section
        o.save!

        @assignment.reload
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json[:submissions].first["submission_history"].first[:submission]["late"]).to be_truthy
      end

      it "returns quiz history for records before and after namespace change" do
        @quiz.save!

        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        expect(json[:submissions].first["submission_history"].size).to eq 1

        Version.where("versionable_type = 'QuizSubmission'").update_all("versionable_type = 'Quizzes::QuizSubmission'")
        json = SpeedGrader::Assignment.new(@assignment.reload, @teacher).json
        expect(json[:submissions].first["submission_history"].size).to eq 1
      end

      it "includes the Submission id in the submission history" do
        json = SpeedGrader::Assignment.new(@assignment, @teacher).json
        submission_id = json.fetch(:submissions).first.fetch(:submission_history).first.fetch(:submission).fetch(:id)
        expect(submission_id).to eq @quiz_submission.submission_id.to_s
      end
    end
  end

  context "quizzes.next" do
    before do
      assignment_model(submission_types: "external_tool", course: @course)

      tool = @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @assignment.external_tool_tag_attributes = { content: tool }
    end

    it "works for quizzes without submissions" do
      expect(BasicLTI::QuizzesNextVersionedSubmission)
        .to receive(:new).and_call_original
      json = SpeedGrader::Assignment.new(@assignment, @teacher).json

      expect(json[:submissions]).to be_all do |ss|
        ss.key?("submission_history") && ss["submission_history"].empty?
      end
    end

    context "with quiz_submissions" do
      before do
        i = 1
        url_grades.each do |h|
          grade = "#{TextHelper.round_if_whole(h[:grade] * 100)}%"
          grade, score = @assignment.compute_grade_and_score(grade, nil)
          submission.grade = grade
          submission.score = score
          submission.submission_type = "basic_lti_launch"
          submission.workflow_state = "submitted"
          submission.submitted_at = i.hours.ago
          submission.url = h[:url]
          submission.grader_id = -1
          submission.with_versioning(explicit: true) { submission.save! }
          i += 1
        end
      end

      let(:submission) { Submission.find_or_initialize_by(assignment: @assignment, user: @student) }

      let(:urls) do
        %w[
          https://abcdef.com/uuurrrlll00
          https://abcdef.com/uuurrrlll01
          https://abcdef.com/uuurrrlll02
          https://abcdef.com/uuurrrlll03
        ]
      end

      let(:url_grades) do
        [
          # url 0 group
          { url: urls[0], grade: 0.11 },
          { url: urls[0], grade: 0.12 },
          # url 1 group
          { url: urls[1], grade: 0.22 },
          { url: urls[1], grade: 0.23 },
          { url: urls[1], grade: 0.24 },
          # url 2 group
          { url: urls[2], grade: 0.33 },
          # url 3 group
          { url: urls[3], grade: 0.44 },
          { url: urls[3], grade: 0.45 },
          { url: urls[3], grade: 0.46 },
          { url: urls[3], grade: 0.47 },
          { url: urls[3], grade: 0.48 }
        ]
      end

      it "returns submission json correctly" do
        json = SpeedGrader::Assignment.new(@assignment, @student).json
        json_submission = json.fetch(:submissions).first.fetch(:submission_history)

        expect(json_submission.count).to be 4
        json_submission1 = json_submission.first.fetch("submission")
        expect(json_submission1["score"]).to eq(@assignment.points_possible * 0.12)
        expect(json_submission1["url"]).to eq(urls[0])
        json_submission2 = json_submission.second.fetch("submission")
        expect(json_submission2["score"]).to eq(@assignment.points_possible * 0.24)
        expect(json_submission2["url"]).to eq(urls[1])
        json_submission3 = json_submission.third.fetch("submission")
        expect(json_submission3["score"]).to eq(@assignment.points_possible * 0.33)
        expect(json_submission3["url"]).to eq(urls[2])
        json_submission4 = json_submission.last.fetch("submission")
        expect(json_submission4["score"]).to eq(@assignment.points_possible * 0.48)
        expect(json_submission4["url"]).to eq(urls[3])
      end
    end
  end

  describe "grader comment visibility" do
    let(:comment_ids) { submission_json.fetch("submission_comments").map { |comment| comment.fetch("id") } }
    let(:submission_json) do
      json.fetch("submissions").fetch(0)
    end

    let(:course) { Course.create! }
    let(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        final_grader_id: final_grader.id,
        grader_count: 2,
        moderated_grading: true,
        submission_types: ["online_text_entry"],
        title: "Example Assignment"
      ).tap do |assignment|
        assignment.moderation_graders.create!(user: teacher, anonymous_id: "ababa")
        assignment.moderation_graders.create!(user: ta, anonymous_id: "atata")
      end
    end

    let(:final_grader) { course_with_teacher(course:, name: "final grader", active_all: true).user }
    let(:final_grader_comment) do
      submission.add_comment(author: final_grader, comment: "comment by final grader", provisional: false)
    end
    let(:final_grader_provisional_comment) do
      submission.add_comment(author: final_grader, comment: "comment by final grader", provisional: true)
    end

    let(:teacher) { course_with_teacher(course:, active_all: true, name: "Teacher").user }
    let(:teacher_comment) do
      submission.add_comment(author: teacher, comment: "comment by teacher", provisional: false)
    end
    let(:teacher_provisional_comment) do
      submission.add_comment(author: teacher, comment: "provisional comment by teacher", provisional: true)
    end

    let(:ta) { course_with_ta(course:, name: "ta", active_all: true).user }
    let(:ta_comment) do
      submission.add_comment(author: ta, comment: "comment by ta", provisional: false)
    end
    let(:ta_provisional_comment) do
      submission.add_comment(author: ta, comment: "provisional comment by ta", provisional: true)
    end

    let(:student) { course_with_student(course:, name: "student", active_all: true).user }
    let(:teacher_pg) do
      submission.provisional_grade(teacher).tap do |pg|
        pg.update!(score: 2)
        selection = assignment.moderated_grading_selections.find_by!(student:)
        selection.update!(provisional_grade: pg)
      end
    end

    let(:ta_pg) { submission.provisional_grade(ta).tap { |pg| pg.update!(score: 3) } }
    let(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true).tap do |ra|
        ra.assess(
          artifact: teacher_pg,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              comments: "teacher comment",
              points: 2
            }
          },
          assessor: teacher,
          user: student
        )
        ra.assess(
          artifact: ta_pg,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              comments: "ta comment",
              points: 3
            }
          },
          assessor: ta,
          user: student
        )
      end
    end

    let(:submission) do
      assignment.submit_homework(student, submission_type: "online_text_entry").tap do |submission|
        submission.add_comment(comment: "comment by student", commenter: student)
      end
    end
    let(:student_comment) do
      SubmissionComment.find_by!(submission:, author: student, comment: "comment by student")
    end

    before do
      final_grader_comment
      final_grader_provisional_comment
      teacher_comment
      teacher_provisional_comment
      ta_comment
      ta_provisional_comment
      rubric_association
    end

    context "when the user is the final grader" do
      let(:json) do
        SpeedGrader::Assignment.new(assignment, final_grader, avatars: true, grading_role: :moderator).json
      end

      it "includes submission comments from other graders such as the TA" do
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes provisional grade submission comments from other graders such as the TA" do
        expect(comment_ids).to include(ta_provisional_comment.id.to_s)
      end

      it "includes submission comments from students" do
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        expect(comment_ids).to include(final_grader_comment.id.to_s)
      end

      it "includes provisional grade submission comments from the current user" do
        expect(comment_ids).to include(final_grader_provisional_comment.id.to_s)
      end

      it "includes submission comments from other graders such as the teacher" do
        expect(comment_ids).to include(teacher_comment.id.to_s)
      end

      it "includes provisional grade submission comments from other graders such as the teacher" do
        expect(comment_ids).to include(teacher_provisional_comment.id.to_s)
      end

      it "includes rubric assessment comments from other graders" do
        rubric_assessments = submission_json["provisional_grades"].pluck("rubric_assessments").flatten
        assessment_data = rubric_assessments.pluck("data").flatten
        comments = assessment_data.pluck("comments")
        expect(comments).to include("ta comment")
      end

      it "includes rubric assessment comments html from other graders" do
        rubric_assessments = submission_json["provisional_grades"].pluck("rubric_assessments").flatten
        assessment_data = rubric_assessments.pluck("data").flatten
        comments = assessment_data.pluck("comments_html")
        expect(comments).to include("ta comment")
      end
    end

    context "when the user is not the final grader and can view other grader comments" do
      let(:json) do
        SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json
      end

      it "includes submission comments from other graders" do
        expect(comment_ids).to include(ta_comment.id.to_s)
      end

      it "includes submission comments from the final grader" do
        expect(comment_ids).to include(final_grader_comment.id.to_s)
      end

      it "includes submission comments from students" do
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        expect(comment_ids).to include(teacher_comment.id.to_s)
      end

      it "includes provisional grade submission comments from other graders" do
        expect(comment_ids).to include(ta_provisional_comment.id.to_s)
      end

      it "includes provisional grade submission comments from the final grader" do
        expect(comment_ids).to include(final_grader_provisional_comment.id.to_s)
      end
    end

    context "when the user is not the final grader and cannot view other grader comments" do
      let(:json) do
        assignment.update!(grader_comments_visible_to_graders: false)
        SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json
      end

      it "excludes submission comments from other graders" do
        expect(comment_ids).not_to include(ta_comment.id.to_s)
      end

      it "excludes submission comments from the final grader" do
        expect(comment_ids).not_to include(final_grader_comment.id.to_s)
      end

      it "includes submission comments from students" do
        expect(comment_ids).to include(student_comment.id.to_s)
      end

      it "includes submission comments from the current user" do
        expect(comment_ids).to include(teacher_comment.id.to_s)
      end

      it "excludes provisional grade submission comments from other graders" do
        expect(comment_ids).not_to include(ta_provisional_comment.id.to_s)
      end

      it "excludes provisional grade submission comments from the final grader" do
        expect(comment_ids).not_to include(final_grader_provisional_comment.id.to_s)
      end
    end
  end

  describe "moderated grading" do
    let(:course) { Course.create! }
    let(:ta) { course_with_ta(course:, name: "Ta", active_all: true).user }
    let(:second_ta) { course_with_user("TaEnrollment", course:, active_all: true, name: "Second Ta").user }
    let(:third_ta) { course_with_user("TaEnrollment", course:, active_all: true, name: "Third Ta").user }
    let(:teacher) { course_with_teacher(course:, name: "Teacher", active_all: true).user }
    let(:student) { course_with_student(course:, name: "student", active_all: true).user }
    let(:assignment) do
      course.assignments.create!(
        submission_types: "online_text_entry",
        moderated_grading: true,
        grader_count: 2,
        final_grader: teacher
      )
    end
    let(:rubric_association) do
      rubric = rubric_model
      rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true).tap do |ra|
        ra.assess(
          artifact: teacher_pg,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              comments: "teacher comment",
              points: 2
            }
          },
          assessor: teacher,
          user: student
        )
        ra.assess(
          artifact: ta_pg,
          assessment: {
            assessment_type: "grading",
            criterion_crit1: {
              comments: "ta comment",
              points: 3
            }
          },
          assessor: ta,
          user: student
        )
      end
    end
    let(:submission) do
      assignment.submit_homework(student, submission_type: "online_text_entry", body: "a body").tap do |submission|
        submission.add_comment(comment: "student comment", commenter: student)
        submission.add_comment(author: teacher, comment: "teacher provisional comment", provisional: true)
        submission.add_comment(author: ta, comment: "ta provisional comment", provisional: true)
        submission.add_comment(author: second_ta, comment: "Second Ta provisional comment", provisional: true)
        submission.add_comment(author: third_ta, comment: "Third Ta provisional comment", provisional: true)
      end
    end

    let(:teacher_pg) do
      submission.provisional_grade(teacher).tap do |pg|
        pg.update!(score: 2)
        selection = assignment.moderated_grading_selections.find_by!(student:)
        selection.update!(provisional_grade: pg)
      end
    end

    let(:final_grader) do
      course_with_teacher(course:, active_all: true, name: "Final Grader").user
    end

    let(:ta_pg) { submission.provisional_grade(ta).tap { |pg| pg.update!(score: 3) } }

    before do
      rubric_association
      submission
      ta_pg
    end

    def find_real_submission(json)
      json.fetch("submissions").find { |s| s.fetch("workflow_state") != "unsubmitted" }
    end

    it "includes all provisional comments when grades have not been posted" do
      json = SpeedGrader::Assignment.new(assignment, second_ta, grading_role: :provisional_grader).json
      comments = find_real_submission(json).fetch("submission_comments").map { |comment| comment.fetch("comment") }
      expect(comments).to match_array [
        "student comment",
        "teacher provisional comment",
        "ta provisional comment",
        "Second Ta provisional comment",
        "Third Ta provisional comment"
      ]
    end

    context "when graders cannot view other grader's comments" do
      before do
        assignment.update!(grader_comments_visible_to_graders: false)
      end

      it "includes own and student's comments when grades have not been posted" do
        json = SpeedGrader::Assignment.new(assignment, second_ta, grading_role: :provisional_grader).json
        comments = find_real_submission(json).fetch("submission_comments").map { |comment| comment.fetch("comment") }
        expect(comments).to match_array([
                                          "student comment",
                                          "Second Ta provisional comment"
                                        ])
      end

      it "includes own, chosen grader's, final grader's, and student's comments when grades have posted" do
        ta_pg.publish!
        assignment.update!(grades_published_at: 1.hour.ago)
        json = SpeedGrader::Assignment.new(assignment, second_ta, grading_role: :provisional_grader).json
        comments = find_real_submission(json).fetch("submission_comments").map { |comment| comment.fetch("comment") }
        expect(comments).to match_array([
                                          "student comment",
                                          "ta provisional comment",
                                          "Second Ta provisional comment",
                                          "teacher provisional comment"
                                        ])
      end
    end

    it "creates a non-annotatable DocViewer session when the user cannot adjudicate" do
      assignment.final_grader = final_grader
      assignment.save!
      assignment.moderation_graders.create!(user: teacher, anonymous_id: "ababa")
      assignment.moderation_graders.create!(user: ta, anonymous_id: "atata")

      other_ta = course_with_ta(course:, active_all: true).user

      attachment = attachment_model(
        context: student,
        uploaded_data: stub_png_data,
        filename: "homework.png"
      )
      assignment.submit_homework(student, attachments: [attachment])

      allow(Canvadocs).to receive(:enabled?).twice.and_return(true)
      allow(Canvadocs).to receive(:config).and_return({ a: 1 })
      allow(Canvadoc).to receive(:mime_types).and_return("image/png")

      json = SpeedGrader::Assignment.new(assignment, other_ta, grading_role: :provisional_grader).json
      sub = json[:submissions].first[:submission_history].last[:submission]

      canvadoc_url = sub[:versioned_attachments].first.dig(:attachment, :canvadoc_url)
      expect(canvadoc_url).to include("enable_annotations%22:false")
    end

    context "for provisional grader" do
      let(:json) { SpeedGrader::Assignment.new(assignment, ta, grading_role: :provisional_grader).json }

      it "has a submission with score" do
        s = find_real_submission(json)
        expect(s.fetch("score")).to eq ta_pg.score
      end

      it "includes all provisional grades" do
        submission = find_real_submission(json)
        scorer_ids = submission["provisional_grades"].map { |pg| pg.fetch("scorer_id") }
        expect(scorer_ids).to contain_exactly(teacher.id.to_s, ta.id.to_s, second_ta.id.to_s, third_ta.id.to_s)
      end

      it "only includes the grader's provisional rubric assessments" do
        ras = json["context"]["students"][0]["rubric_assessments"]
        expect(ras.count).to eq 1
        expect(ras[0]["assessor_id"]).to eq ta.id.to_s
      end
    end

    context "for final grader" do
      let(:json) { SpeedGrader::Assignment.new(assignment, teacher, grading_role: :moderator).json }

      it "includes all comments" do
        s = find_real_submission(json)
        expect(s["score"]).to eq 2
        comments = s["submission_comments"].pluck("comment")
        expect(comments).to match_array [
          "student comment",
          "teacher provisional comment",
          "ta provisional comment",
          "Second Ta provisional comment",
          "Third Ta provisional comment"
        ]
      end

      it "includes the final grader's provisional rubric assessments" do
        ras = json["context"]["students"][0]["rubric_assessments"]
        expect(ras.count).to eq 1
        expect(ras[0]["assessor_id"]).to eq teacher.id.to_s
      end

      it "lists all provisional grades" do
        pgs = find_real_submission(json)["provisional_grades"]
        expect(pgs.map { |pg| [pg.fetch("score"), pg.fetch("scorer_id")] }).to match_array([
                                                                                             [2.0, teacher.id.to_s],
                                                                                             [3.0, ta.id.to_s],
                                                                                             [nil, second_ta.id.to_s],
                                                                                             [nil, third_ta.id.to_s]
                                                                                           ])
      end

      it "includes all the other provisional rubric assessments in their respective grades" do
        ta_pras = find_real_submission(json)["provisional_grades"][1]["rubric_assessments"]
        expect(ta_pras.count).to eq 1
        expect(ta_pras[0]["assessor_id"]).to eq ta.id.to_s
      end

      it "includes whether the provisional grade is selected" do
        s = find_real_submission(json)
        expect(s["provisional_grades"][0]["selected"]).to be_truthy
        expect(s["provisional_grades"][1]["selected"]).to be_falsey
      end
    end
  end

  context "when an assignment is anonymous" do
    before(:once) do
      course_with_teacher

      @active_student = @course.enroll_student(User.create!, enrollment_state: "active").user
      @inactive_student = User.create!
      @course.enroll_student(@inactive_student, enrollment_state: "inactive")
      @concluded_student = User.create!
      @course.enroll_student(@concluded_student, enrollment_state: "completed")
      @concluded_student2 = User.create!
      @course.enroll_student(@concluded_student2, enrollment_state: "completed")
    end

    let(:assignment) { @course.assignments.create!(title: "anonymous", anonymous_grading: true) }
    let(:speed_grader_json) { SpeedGrader::Assignment.new(assignment, @teacher).json }
    let(:students) { speed_grader_json[:context][:students] }
    let(:returned_ids) { students.pluck("anonymous_id") }

    context "unposted assignments" do
      it "returns only active students if the teacher is not viewing inactive or concluded" do
        active_student_submission = assignment.submission_for_student(@active_student)
        expect(returned_ids).to match_array [active_student_submission.anonymous_id]
      end

      it "returns active and inactive if the teacher is viewing inactive" do
        @teacher.preferences[:gradebook_settings] = {
          @course.global_id => { "show_inactive_enrollments" => "true" }
        }
        expected_ids = assignment.submissions.where(user: [@active_student, @inactive_student]).pluck(:anonymous_id)
        expect(returned_ids).to match_array expected_ids
      end

      it "returns active and concluded if the teacher is viewing concluded" do
        @teacher.preferences[:gradebook_settings] = {
          @course.global_id => { "show_concluded_enrollments" => "true" }
        }
        expected_ids = assignment.submissions.where(
          user: [@active_student, @concluded_student, @concluded_student2]
        ).pluck(:anonymous_id)
        expect(returned_ids).to match_array expected_ids
      end

      it "returns all students if teacher is viewing inactive and concluded" do
        @teacher.preferences[:gradebook_settings] = {
          @course.global_id => {
            "show_concluded_enrollments" => "true",
            "show_inactive_enrollments" => "true"
          }
        }
        expected_ids = assignment.submissions.where(
          user: [@active_student, @inactive_student, @concluded_student, @concluded_student2]
        ).pluck(:anonymous_id)
        expect(returned_ids).to match_array expected_ids
      end
    end

    context "posted assignments" do
      it "returns students in accord with user gradebook preferences if assignment is not muted" do
        @teacher.preferences[:gradebook_settings] = {}
        @teacher.preferences[:gradebook_settings][@course.global_id] = {
          "show_concluded_enrollments" => "true",
          "show_inactive_enrollments" => "true"
        }
        assignment.unmute!

        expect(students.length).to eq 4
      end
    end
  end

  describe "OriginalityReport" do
    include_context "lti2_spec_helper"

    let_once(:test_course) do
      test_course = course_factory(active_course: true)
      test_course.enroll_teacher(test_teacher, enrollment_state: "active")
      test_course.enroll_student(test_student, enrollment_state: "active")
      test_course
    end

    let_once(:test_teacher) { User.create }
    let_once(:test_student) { User.create }

    let(:assignment) { Assignment.create!(title: "title", context: test_course) }
    let(:attachment) do
      attachment = test_student.attachments.new filename: "homework.doc"
      attachment.content_type = "foo/bar"
      attachment.size = 10
      attachment.save!
      attachment
    end

    it "includes the OriginalityReport in the json" do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      tii_data = json["submissions"].first["submission_history"].first["submission"]["turnitin_data"]
      expect(tii_data[attachment.asset_string]["state"]).to eq "acceptable"
    end

    it "includes 'has_originality_report' in the json for text entry submissions" do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })
      OriginalityReport.create!(originality_score: "1", submission:)
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      has_report = json["submissions"].first["submission_history"].first["submission"]["has_originality_report"]
      expect(has_report).to be_truthy
    end

    it "includes 'has_originality_report' in the json for group assignments" do
      user_two = test_student.dup
      user_two.update!(lti_context_id: SecureRandom.uuid, lti_id: SecureRandom.uuid, uuid: CanvasSlug.generate_securish_uuid)
      assignment.course.enroll_student(user_two)

      group = group_model(context: assignment.course)
      group.update!(users: [user_two, test_student])

      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      assignment.submit_homework(user_two, submission_type: "online_upload", attachments: [attachment])

      assignment.submissions.each do |s|
        s.update!(group:, turnitin_data: { blah: 1 })
      end

      report = OriginalityReport.create!(originality_score: "1", submission:, attachment:)
      report.copy_to_group_submissions!

      json = SpeedGrader::Assignment.new(assignment, test_teacher).json

      has_report = json["submissions"].map { |s| s["submission_history"].first["submission"]["has_originality_report"] }
      expect(has_report).to match_array [true, true]
    end

    it "includes 'has_originality_report' in the json" do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      has_report = json["submissions"].first["submission_history"].first["submission"]["has_originality_report"]
      expect(has_report).to be_truthy
    end

    it 'includes "has_plagiarism_tool" if the assignment has a plagiarism tool' do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })

      AssignmentConfigurationToolLookup.create!(
        assignment:,
        tool_vendor_code: product_family.vendor_code,
        tool_product_code: product_family.product_code,
        tool_resource_type_code: resource_handler.resource_type_code,
        tool_type: "Lti::MessageHandler"
      )

      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      has_tool = json["submissions"].first["submission_history"].first["submission"]["has_plagiarism_tool"]
      expect(has_tool).to be_truthy
    end

    it 'includes "has_originality_score" if the originality report includes an originality score' do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      has_score = json["submissions"].first["submission_history"].first["submission"]["has_originality_score"]
      expect(has_score).to be_truthy
    end

    it "includes originality data" do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { blah: 1 })
      OriginalityReport.create!(attachment:, originality_score: "1", submission:)
      OriginalityReport.create!(originality_score: "1", submission:)
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      keys = json["submissions"].first["submission_history"].first["submission"]["turnitin_data"].keys
      expect(keys).to include(
        OriginalityReport.submission_asset_key(submission),
        attachment.asset_string
      )
    end

    it 'does not override "turnitin_data"' do
      submission = assignment.submit_homework(test_student, submission_type: "online_upload", attachments: [attachment])
      submission.update_attribute(:turnitin_data, { test_key: 1 })
      json = SpeedGrader::Assignment.new(assignment, test_teacher).json
      keys = json["submissions"].first["submission_history"].first["submission"]["turnitin_data"].keys
      expect(keys).to include "test_key"
    end
  end

  describe "honoring gradebook preferences" do
    let_once(:test_course) do
      test_course = course_factory(active_course: true)
      test_course.enroll_teacher(teacher, enrollment_state: "active")
      test_course.enroll_student(active_student, enrollment_state: "active")
      test_course.enroll_student(inactive_student, enrollment_state: "inactive")
      test_course.enroll_student(concluded_student, enrollment_state: "completed")
      test_course
    end

    let_once(:teacher) { User.create }
    let_once(:active_student) { User.create }
    let_once(:inactive_student) { User.create }
    let_once(:concluded_student) { User.create }

    let(:gradebook_settings) do
      { test_course.global_id =>
        {
          "show_inactive_enrollments" => "false",
          "show_concluded_enrollments" => "false"
        } }
    end

    let_once(:assignment) do
      Assignment.create!(title: "title", context: test_course)
    end

    it "returns active students and enrollments when inactive and concluded settings are false" do
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = SpeedGrader::Assignment.new(assignment, teacher).json

      students = json["context"]["students"].pluck("id")
      expect(students).to include(active_student.id.to_s)
    end

    it "returns active and inactive students and enrollments when inactive enrollments is true" do
      gradebook_settings[test_course.global_id]["show_inactive_enrollments"] = "true"
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = SpeedGrader::Assignment.new(assignment, teacher).json

      students = json["context"]["students"].pluck("id")
      expect(students).to include(active_student.id.to_s, inactive_student.id.to_s)
    end

    it "returns active and concluded students and enrollments when concluded is true" do
      gradebook_settings[test_course.global_id]["show_concluded_enrollments"] = "true"
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = SpeedGrader::Assignment.new(assignment, teacher).json

      students = json["context"]["students"].pluck("id")
      expect(students).to include(active_student.id.to_s, concluded_student.id.to_s)
    end

    it "returns active, inactive, and concluded students and enrollments when both settings are true" do
      gradebook_settings[test_course.global_id]["show_inactive_enrollments"] = "true"
      gradebook_settings[test_course.global_id]["show_concluded_enrollments"] = "true"
      teacher.preferences[:gradebook_settings] = gradebook_settings
      json = SpeedGrader::Assignment.new(assignment, teacher).json

      students = json["context"]["students"].pluck("id")
      expect(students).to include(active_student.id.to_s,
                                  inactive_student.id.to_s,
                                  concluded_student.id.to_s)
    end

    it "returns concluded students if the course is concluded" do
      test_course.complete
      json = SpeedGrader::Assignment.new(assignment, teacher).json
      students = json["context"]["students"].pluck("id")
      expect(students).to include(active_student.id.to_s, concluded_student.id.to_s)
    end

    context "differentiated assignments" do
      before do
        assignment.update!(only_visible_to_overrides: true)
      end

      it "returns inactive students when inactive enrollments is true" do
        create_adhoc_override_for_assignment(assignment, inactive_student)
        gradebook_settings[test_course.global_id]["show_inactive_enrollments"] = "true"
        teacher.preferences[:gradebook_settings] = gradebook_settings
        json = SpeedGrader::Assignment.new(assignment, teacher).json

        students = json["context"]["students"].pluck("id")
        expect(students).to include inactive_student.id.to_s
      end

      it "does not return inactive students when inactive enrollments is false" do
        create_adhoc_override_for_assignment(assignment, inactive_student)
        teacher.preferences[:gradebook_settings] = gradebook_settings
        json = SpeedGrader::Assignment.new(assignment, teacher).json

        students = json["context"]["students"].pluck("id")
        expect(students).not_to include inactive_student.id.to_s
      end

      it "returns concluded students when concluded enrollments is true" do
        create_adhoc_override_for_assignment(assignment, concluded_student)
        gradebook_settings[test_course.global_id]["show_concluded_enrollments"] = "true"
        teacher.preferences[:gradebook_settings] = gradebook_settings
        json = SpeedGrader::Assignment.new(assignment, teacher).json

        students = json["context"]["students"].pluck("id")
        expect(students).to include concluded_student.id.to_s
      end

      it "does not return concluded students when concluded enrollments is false" do
        create_adhoc_override_for_assignment(assignment, concluded_student)
        teacher.preferences[:gradebook_settings] = gradebook_settings
        json = SpeedGrader::Assignment.new(assignment, teacher).json

        students = json["context"]["students"].pluck("id")
        expect(students).not_to include concluded_student.id.to_s
      end
    end
  end

  describe "student anonymity" do
    let_once(:course) { course_with_teacher(active_all: true, name: "Teacher").course }
    let_once(:teacher) { @teacher }
    let_once(:ta) do
      course_with_ta(course:, active_all: true)
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
        submission_types: ["online_text_entry"],
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

    let(:json) { SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :moderator).json }
    let(:grader_json) { SpeedGrader::Assignment.new(assignment, ta, avatars: true, grading_role: :grader).json }

    before :once do
      course.enroll_student(student_1, section: section_1).accept!
      course.enroll_student(student_2, section: section_2).accept!

      assignment.moderation_graders.create!(user: teacher, anonymous_id: "teach")
      assignment.moderation_graders.create!(user: ta, anonymous_id: "atata")

      selection = assignment.moderated_grading_selections.find_by!(student_id: student_1.id)

      submission_1.add_comment(author: teacher, comment: "comment by teacher", provisional: false)
      submission_1.add_comment(author: teacher, comment: "provisional comment by teacher", provisional: true)
      teacher_pg.update!(score: 2)

      rubric_association.assess(
        artifact: teacher_pg,
        assessment: {
          assessment_type: "grading",
          criterion_crit1: {
            comments: "a comment",
            points: 2
          }
        },
        assessor: teacher,
        user: student_1
      )

      selection.provisional_grade = teacher_pg
      selection.save!

      submission_1.add_comment(author: ta, comment: "comment by ta", provisional: false)
      submission_1.add_comment(author: ta, comment: "provisional comment by ta", provisional: true)
      ta_pg.update!(score: 3)

      rubric_association.assess(
        artifact: ta_pg,
        assessment: {
          assessment_type: "grading",
          criterion_crit1: {
            comments: "a comment",
            points: 3
          }
        },
        assessor: ta,
        user: student_1
      )
    end

    before do
      submission_1.anonymous_id = "aaaaa"
      submission_1.save!

      submission_2.anonymous_id = "bbbbb"
      submission_2.save!

      test_submission.anonymous_id = "ccccc"
      test_submission.save!
    end

    context "when the user can view student names" do
      let(:submission_1_json) { json["submissions"].detect { |s| s["user_id"] == student_1.id.to_s } }
      let(:student_comments) do
        submission_1_json["submission_comments"].select do |comment|
          comment["author_id"] == student_1.id.to_s || comment["author_id"] == student_2.id.to_s
        end
      end

      before do
        assignment.update!(anonymous_grading: false)
      end

      it "includes user ids on student enrollments" do
        user_ids = json["context"]["enrollments"].pluck("user_id")
        expect(user_ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from student enrollments" do
        expect(json["context"]["enrollments"]).to all(not_have_key("anonymous_id"))
      end

      it "includes ids on students" do
        ids = json["context"]["students"].pluck("id")
        expect(ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from students" do
        expect(json["context"]["students"]).to all(not_have_key("anonymous_id"))
      end

      it "includes user ids on submissions" do
        user_ids = json["submissions"].pluck("user_id")
        expect(user_ids.uniq).to match_array([student_1.id, student_2.id, test_student.id].map(&:to_s))
      end

      it "excludes anonymous ids from submissions" do
        expect(json["submissions"]).to all(not_have_key("anonymous_id"))
      end

      it "includes user ids on rubrics" do
        student = json["context"]["students"].detect { |s| s["id"] == student_1.id.to_s }
        user_ids = student["rubric_assessments"].pluck("user_id")
        expect(user_ids).to include(student_1.id.to_s)
      end

      it "includes user ids from rubrics on provisional grades" do
        rubric_assessments = submission_1_json["provisional_grades"].pluck("rubric_assessments").flatten
        user_ids = rubric_assessments.pluck("user_id")
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
        expect(student_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes student author names on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(include("author_name" => student_1.name))
      end

      it "uses the user avatar for students on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        avatar_paths = student_comments.pluck("avatar_path")
        expect(avatar_paths.uniq).to include(student_1.avatar_path, student_2.avatar_path)
      end

      it "optionally does not include avatars" do
        submission_1.add_comment(author: student_1, comment: "Example")
        json = SpeedGrader::Assignment.new(assignment, teacher, avatars: false).json
        submission = json["submissions"].detect { |s| s["user_id"] == student_1.id.to_s }
        expect(submission["submission_comments"]).to all(not_have_key("avatar_path"))
      end

      it "includes student user ids on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        expect(student_comments).not_to be_empty
      end

      it "sets anonymize_students to false in the response" do
        expect(json["anonymize_students"]).to be false
      end
    end

    context "when the user cannot view student names" do
      let(:submission_1_json) { json["submissions"].detect { |s| s["anonymous_id"] == "aaaaa" } }
      let(:student_comments) do
        submission_1_json["submission_comments"].select do |comment|
          comment["anonymous_id"] == "aaaaa" || comment["anonymous_id"] == "bbbbb"
        end
      end

      it "adds anonymous ids to student enrollments" do
        anonymous_ids = json["context"]["enrollments"].pluck("anonymous_id")
        expect(anonymous_ids.uniq).to match_array(%w[aaaaa bbbbb ccccc])
      end

      it "excludes user ids from student enrollments" do
        expect(json["context"]["enrollments"]).to all(not_have_key("user_id"))
      end

      it "excludes ids from students" do
        expect(json["context"]["students"]).to all(not_have_key("id"))
      end

      it "adds anonymous ids to students" do
        anonymous_ids = json["context"]["students"].pluck("anonymous_id")
        expect(anonymous_ids).to match_array(%w[aaaaa bbbbb ccccc])
      end

      it "includes anonymous names and positions on students" do
        anonymous_names = json.dig("context", "students").map do |student|
          { student["anonymous_name_position"] => student["anonymous_name"] }
        end
        expect(anonymous_names).to match_array([{ 1 => "Student 1" }, { 2 => "Student 2" }, { 3 => "Student 3" }])
      end

      it "excludes user ids from submissions" do
        expect(json["submissions"]).to all(not_have_key("user_id"))
      end

      it "includes anonymous ids on submissions" do
        anonymous_ids = json["submissions"].pluck("anonymous_id")
        expect(anonymous_ids).to match_array(%w[aaaaa bbbbb ccccc])
      end

      it "excludes user ids on rubrics" do
        student = json["context"]["students"].detect { |s| s["anonymous_id"] == "aaaaa" }
        expect(student["rubric_assessments"]).to all(not_have_key("user_id"))
      end

      it "excludes user ids from rubrics on provisional grades" do
        rubric_assessments = submission_1_json["provisional_grades"].pluck("rubric_assessments").flatten
        expect(rubric_assessments).to all(not_have_key("user_id"))
      end

      it "includes anonymous ids on student submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).not_to be_empty
      end

      it "excludes student author ids from submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(not_have_key("author_id"))
      end

      it "excludes student author names from submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        expect(student_comments).to all(not_have_key("author_name"))
      end

      it "includes author ids of other graders on submission comments" do
        submission = grader_json["submissions"].detect { |s| s["anonymous_id"] == "aaaaa" }
        author_ids = submission["submission_comments"].pluck("author_id")
        expect(author_ids).to include(teacher.id.to_s, ta.id.to_s)
      end

      it "includes author names of other graders on submission comments" do
        submission = grader_json["submissions"].detect { |s| s["anonymous_id"] == "aaaaa" }
        author_names = submission["submission_comments"].pluck("author_name")
        expect(author_names).to include(teacher.name, ta.name)
      end

      it "uses the default avatar for students on submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_1, comment: "Sample")
        avatars = student_comments.pluck("avatar_path")
        expect(avatars).to all(eql(User.default_avatar_fallback))
      end

      it "uses the user avatar for other graders on submission comments" do
        avatars = submission_1_json["submission_comments"].pluck("avatar_path")
        expect(avatars).to include(ta.avatar_path, teacher.avatar_path)
      end

      it "adds anonymous ids to submission comments" do
        submission_1.add_comment(author: student_1, comment: "Example")
        submission_1.add_comment(author: student_2, comment: "Sample")
        anonymous_ids = student_comments.pluck("anonymous_id")
        expect(anonymous_ids).to match_array(["aaaaa", "bbbbb"])
      end

      it "includes the current user's author ids on submission comments" do
        expect(submission_1_json["submission_comments"].pluck("author_id")).to include(teacher.id.to_s)
      end

      it "includes the current user's author name on submission comments" do
        expect(submission_1_json["submission_comments"].pluck("author_name")).to include(teacher.name)
      end

      it "excludes students who are not assigned" do
        create_adhoc_override_for_assignment(assignment, [student_1, student_2])
        assignment.update!(only_visible_to_overrides: true)

        student_3 = user_with_pseudonym(active_all: true, username: "student3@example.com")
        course.enroll_student(student_3, section: section_2).accept!

        expect(json["context"]["students"].count).to be(2)
      end

      context "when a submission has multiple versions" do
        it "uses the current submission's anonymous ID for older versions that lack one" do
          student = User.create!
          course.enroll_student(student).accept!
          assignment = course.assignments.create!(title: "new assignment", anonymous_grading: true)

          # Clear this first submission's anonymous ID so it gets serialized without one
          old_submission = assignment.submit_homework(student)
          old_submission.update!(anonymous_id: nil)

          submission = assignment.submit_homework(student)
          submission.update!(anonymous_id: "zxcvb")

          json = SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :moderator).json

          submission_json = json["submissions"].detect { |s| s["anonymous_id"] == submission.anonymous_id }

          returned_anonymous_ids = submission_json["submission_history"].map do |historical_submission|
            historical_submission.dig(:submission, :anonymous_id)
          end

          expect(returned_anonymous_ids.uniq).to eq [submission.anonymous_id]
        end
      end

      it "sets anonymize_students to true in the response" do
        expect(json["anonymize_students"]).to be true
      end
    end
  end

  describe "grader anonymity" do
    let_once(:course) { course_with_teacher(active_all: true, name: "Teacher").course }
    let_once(:teacher) { @teacher }
    let_once(:ta) do
      course_with_ta(course:, active_all: true)
      @ta
    end
    let_once(:final_grader) do
      course_with_teacher(course:, active_all: true, name: "Final Grader")
      @teacher
    end

    let_once(:section) { course.course_sections.create!(name: "Section 1") }
    let_once(:student) { user_with_pseudonym(active_all: true, username: "student1@example.com") }

    let_once(:assignment) do
      course.assignments.create!(
        anonymous_grading: true,
        final_grader_id: final_grader.id,
        grader_count: 2,
        moderated_grading: true,
        submission_types: ["online_text_entry"],
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
    let(:final_grader_pg) { submission.provisional_grade(final_grader) }

    let(:submission_json) { json["submissions"].first }
    let(:teacher_anonymous_id) { assignment.moderation_graders.find_by(user: teacher).anonymous_id }
    let(:ta_anonymous_id) { assignment.moderation_graders.find_by(user: ta).anonymous_id }
    let(:final_grader_anonymous_id) { assignment.moderation_graders.find_by(user: final_grader).anonymous_id }

    before :once do
      course.enroll_student(student, section:).accept!
      assignment.update_submission(student, comment: "comment by student", commenter: student)

      assignment.grade_student(student, grader: teacher, provisional: true, score: 10)
      assignment.grade_student(student, grader: ta, provisional: true, score: 5)
      assignment.grade_student(student, grader: final_grader, provisional: true, score: 0)

      selection = assignment.moderated_grading_selections.find_by!(student_id: student.id)

      submission.add_comment(author: final_grader, comment: "comment by final grader", provisional: false)
      submission.add_comment(author: final_grader, comment: "provisional comment by final grader", provisional: true)
      final_grader_pg.update!(score: 4)

      submission.add_comment(author: teacher, comment: "comment by teacher", provisional: false)
      submission.add_comment(author: teacher, comment: "provisional comment by teacher", provisional: true)
      teacher_pg.update!(score: 2)

      rubric_association.assess(
        artifact: teacher_pg,
        assessment: {
          assessment_type: "grading",
          criterion_crit1: {
            comments: "a comment",
            points: 2
          }
        },
        assessor: teacher,
        user: student
      )

      selection.provisional_grade = teacher_pg
      selection.save!

      submission.add_comment(author: ta, comment: "comment by ta", provisional: false)
      submission.add_comment(author: ta, comment: "provisional comment by ta", provisional: true)
      ta_pg.update!(score: 3)

      rubric_association.assess(
        artifact: ta_pg,
        assessment: {
          assessment_type: "grading",
          criterion_crit1: {
            comments: "a comment",
            points: 3
          }
        },
        assessor: ta,
        user: student
      )
    end

    before do
      submission.anonymous_id = "aaaaa"
      submission.save!

      assignment.update!(anonymous_grading: false)
    end

    context "when the user is the final grader and cannot view other grader names" do
      let(:json) { SpeedGrader::Assignment.new(assignment, final_grader, avatars: true, grading_role: :moderator).json }

      before do
        assignment.update!(grader_names_visible_to_final_grader: false)
      end

      it "excludes scorer_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on submissions when the user assigned a provisional grade" do
        expect(submission_json["anonymous_grader_id"]).to eq final_grader_anonymous_id
      end

      # submission comments

      it "excludes author_id from grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        expect(grader_comments).to all(not_have_key("author_id"))
      end

      it "includes anonymous_id on grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        anonymous_ids = grader_comments.pluck("anonymous_id")
        expect(anonymous_ids.uniq).to match_array [teacher_anonymous_id, ta_anonymous_id, final_grader_anonymous_id]
      end

      it "excludes author_name from other graders' comments" do
        ta_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == ta_anonymous_id }
        expect(ta_comment).not_to have_key("author_name")
      end

      it "includes author_name on the current graders' comments" do
        final_grader_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == final_grader_anonymous_id }
        expect(final_grader_comment["author_name"]).to eql("Final Grader")
      end

      it "uses the default avatar for other graders' comments" do
        ta_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == ta_anonymous_id }
        expect(ta_comment["avatar_path"]).to eql(User.default_avatar_fallback)
      end

      it "uses the user avatar for the current grader's comments" do
        final_grader_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == final_grader_anonymous_id }
        expect(final_grader_comment["avatar_path"]).to eql(final_grader.avatar_path)
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["author_name"]).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["avatar_path"]).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before do
          assignment.update!(anonymous_grading: true)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment).not_to have_key("author_name")
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment["avatar_path"]).to eql(User.default_avatar_fallback)
        end
      end

      # all provisional grades (current user)

      it "includes anonymous_grader_id on provisional grades given by the current user'" do
        final_grader_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == final_grader_anonymous_id }
        expect(final_grader_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by the current user'" do
        final_grader_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == final_grader_anonymous_id }
        expect(final_grader_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grades (other graders)

      it "includes anonymous_grader_id on provisional grades given by another grader'" do
        ta_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        expect(ta_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by another grader'" do
        ta_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        expect(ta_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grade rubric assessments (other graders)

      it "excludes assessor_name other grader's rubric assessments on provisional grades'" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(include("anonymous_assessor_id" => ta_anonymous_id))
      end

      # final provisional grade (current user)

      it "excludes scorer_id from the final provisional grade when given by the current user'" do
        final_grader_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by the current user'" do
        final_grader_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["anonymous_grader_id"]).to eql(final_grader_anonymous_id)
      end

      # final provisional grade (other graders)

      it "excludes scorer_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["anonymous_grader_id"]).to eql(ta_anonymous_id)
      end

      # final provisional grade rubric assessments (other graders)

      it "excludes assessor_name from the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("anonymous_assessor_id" => ta_anonymous_id))
      end

      it "sets anonymize_graders to true in the response" do
        expect(json["anonymize_graders"]).to be true
      end
    end

    context "when the user is the final grader and can view other grader names" do
      let(:json) do
        SpeedGrader::Assignment.new(assignment, final_grader, avatars: true, grading_role: :moderator).json
      end

      it "includes scorer_id on submissions when the user assigned a provisional grade" do
        expect(submission_json["scorer_id"]).to eql(final_grader.id.to_s)
      end

      it "excludes anonymous_grader_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key("anonymous_grader_id")
      end

      # submission comments

      it "includes author_id on grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        anonymous_ids = grader_comments.pluck("author_id")
        expect(anonymous_ids.uniq).to match_array([teacher.id, ta.id, final_grader.id].map(&:to_s))
      end

      it "excludes anonymous_id from grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        expect(grader_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes author_name on the all graders' comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        grader_names = grader_comments.pluck("author_name")
        expect(grader_names.uniq).to match_array([teacher, ta, final_grader].map(&:name))
      end

      it "uses the user avatar for the all grader's comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        grader_avatars = grader_comments.pluck("avatar_path")
        expect(grader_avatars.uniq).to match_array([teacher, ta, final_grader].map(&:avatar_path))
      end

      context "when the user can view student names" do
        before do
          assignment.update!(anonymous_grading: false)
        end

        it "includes author_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["author_name"]).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["avatar_path"]).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before do
          assignment.update!(anonymous_grading: true)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment).not_to have_key("author_name")
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment["avatar_path"]).to eql(User.default_avatar_fallback)
        end
      end

      # all provisional grades

      it "includes scorer_id on all provisional grades" do
        scorer_ids = submission_json["provisional_grades"].pluck("scorer_id")
        expect(scorer_ids.uniq).to match_array([teacher.id, ta.id, final_grader.id].map(&:to_s))
      end

      it "excludes anonymous_grader_id from all provisional grades" do
        expect(submission_json["provisional_grades"]).to all(not_have_key("anonymous_grader_id"))
      end

      # all provisional grade rubric assessments

      it "includes assessor_name on all graders' rubric assessments on provisional grades'" do
        grader_assessments = submission_json["provisional_grades"].pluck("rubric_assessments").flatten
        grader_names = grader_assessments.pluck("assessor_name")
        expect(grader_names.uniq).to match_array([teacher, ta].map(&:name))
      end

      it "includes assessor_id on all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json["provisional_grades"].pluck("rubric_assessments").flatten
        assessor_ids = grader_assessments.pluck("assessor_id")
        expect(assessor_ids.uniq).to match_array([teacher.id, ta.id].map(&:to_s))
      end

      it "excludes anonymous_assessor_id from all graders' rubric assessments on provisional grades" do
        grader_assessments = submission_json["provisional_grades"].pluck("rubric_assessments").flatten
        expect(grader_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # final provisional grade (current user)

      it "includes scorer_id on the final provisional grade when given by the current user'" do
        final_grader_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["scorer_id"]).to eql(final_grader.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by the current user'" do
        final_grader_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade (other graders)

      it "includes scorer_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["scorer_id"]).to eql(ta.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade rubric assessments (other graders)

      it "includes assessor_name on the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("assessor_name" => ta.name))
      end

      it "includes assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("assessor_id" => ta.id.to_s))
      end

      it "excludes anonymous_assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      it "sets anonymize_graders to false in the response" do
        expect(json["anonymize_graders"]).to be false
      end
    end

    context "when the user is not the final grader and cannot view other grader names" do
      let(:json) do
        assignment.update!(graders_anonymous_to_graders: true)
        SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json
      end

      it "excludes scorer_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on submissions when the user assigned a provisional grade" do
        expect(submission_json["anonymous_grader_id"]).to eq teacher_anonymous_id
      end

      # submission comments

      it "excludes author_id from grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        expect(grader_comments).to all(not_have_key("author_id"))
      end

      it "includes anonymous_id on grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        anonymous_ids = grader_comments.pluck("anonymous_id")
        expect(anonymous_ids.uniq).to match_array [teacher_anonymous_id, ta_anonymous_id, final_grader_anonymous_id]
      end

      it "excludes author_name from other graders' comments" do
        ta_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == ta_anonymous_id }
        expect(ta_comment).not_to have_key("author_name")
      end

      it "includes author_name on the current graders' comments" do
        teacher_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == teacher_anonymous_id }
        expect(teacher_comment["author_name"]).to eq "Teacher"
      end

      it "uses the default avatar for other graders' comments" do
        ta_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == ta_anonymous_id }
        expect(ta_comment["avatar_path"]).to eql(User.default_avatar_fallback)
      end

      it "uses the user avatar for the current grader's comments" do
        teacher_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == teacher_anonymous_id }
        expect(teacher_comment["avatar_path"]).to eql(teacher.avatar_path)
      end

      # current user's rubric assessments

      it "includes assessor_name on the current grader's rubric assessments' on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => teacher_anonymous_id))
      end

      # all provisional grades (current user)

      it "includes anonymous_grader_id on provisional grades given by the current user'" do
        teacher_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == teacher_anonymous_id }
        expect(teacher_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by the current user'" do
        teacher_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == teacher_anonymous_id }
        expect(teacher_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grades (other graders)

      it "includes anonymous_grader_id on provisional grades given by another grader'" do
        ta_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        expect(ta_grades).not_to be_empty
      end

      it "excludes scorer_id from provisional grades given by another grader'" do
        ta_grades = submission_json["provisional_grades"].select { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        expect(ta_grades).to all(not_have_key("scorer_id"))
      end

      # all provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on provisional grades'" do
        teacher_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == final_grader_anonymous_id }
        teacher_assessments = teacher_grade["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on provisional grades" do
        teacher_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == final_grader_anonymous_id }
        teacher_assessments = teacher_grade["rubric_assessments"]
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on provisional grades" do
        teacher_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == final_grader_anonymous_id }
        teacher_assessments = teacher_grade["rubric_assessments"]
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => final_grader_anonymous_id))
      end

      # all provisional grade rubric assessments (other graders)

      it "excludes assessor_name other grader's rubric assessments on provisional grades'" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on other grader's rubric assessments on provisional grades" do
        ta_grade = submission_json["provisional_grades"].detect { |grade| grade["anonymous_grader_id"] == ta_anonymous_id }
        ta_assessments = ta_grade["rubric_assessments"]
        expect(ta_assessments).to all(include("anonymous_assessor_id" => ta_anonymous_id))
      end

      # final provisional grade (current user)

      it "excludes scorer_id from the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["anonymous_grader_id"]).to eql(teacher_anonymous_id)
      end

      # final provisional grade (other graders)

      it "excludes scorer_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("scorer_id")
      end

      it "includes anonymous_grader_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["anonymous_grader_id"]).to eql(ta_anonymous_id)
      end

      # final provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on the final provisional grade'" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "excludes assessor_id from the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(include("anonymous_assessor_id" => teacher_anonymous_id))
      end

      # final provisional grade rubric assessments (other graders)

      it "excludes assessor_name from the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_name"))
      end

      it "excludes assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("assessor_id"))
      end

      it "includes anonymous_assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("anonymous_assessor_id" => ta_anonymous_id))
      end

      it "sets anonymize_graders to true in the response" do
        expect(json["anonymize_graders"]).to be true
      end
    end

    context "when the user can view student names" do
      let(:json) do
        assignment.update!(anonymous_grading: false, graders_anonymous_to_graders: false)
        SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json
      end

      it "includes author_id on student comments" do
        student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
        expect(student_comments).not_to be_empty
      end

      it "excludes anonymous_id from student comments" do
        student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
        expect(student_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes author_name on student comments" do
        student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
        expect(student_comment["author_name"]).to eql student.name
      end

      it "uses the user avatar for students on submission comments" do
        student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
        expect(student_comment["avatar_path"]).to eql(student.avatar_path)
      end
    end

    context "when the user cannot view student names" do
      let(:json) do
        assignment.update!(anonymous_grading: true)
        SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json
      end

      it "includes anonymous_id on student comments" do
        student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
        expect(student_comments).not_to be_empty
      end

      it "excludes author_id from student comments" do
        student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
        expect(student_comments).to all(not_have_key("author_id"))
      end

      it "excludes author_name from student comments" do
        student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
        expect(student_comment).not_to have_key("author_name")
      end

      it "uses the default avatar for student comments" do
        student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
        expect(student_comment["avatar_path"]).to eql(User.default_avatar_fallback)
      end
    end

    context "when the user is not the final grader and can view other grader names" do
      let(:json) { SpeedGrader::Assignment.new(assignment, teacher, avatars: true, grading_role: :provisional_grader).json }

      it "includes scorer_id on submissions when the user assigned a provisional grade" do
        expect(submission_json["scorer_id"]).to eql(teacher.id.to_s)
      end

      it "excludes anonymous_grader_id from submissions when the user assigned a provisional grade" do
        expect(submission_json).not_to have_key("anonymous_grader_id")
      end

      # submission comments

      it "includes author_id on grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        anonymous_ids = grader_comments.pluck("author_id")
        expect(anonymous_ids.uniq).to match_array([teacher.id, ta.id, final_grader.id].map(&:to_s))
      end

      it "excludes anonymous_id from grader comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        expect(grader_comments).to all(not_have_key("anonymous_id"))
      end

      it "includes author_name on the all graders' comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        grader_names = grader_comments.pluck("author_name")
        expect(grader_names.uniq).to match_array([teacher, ta, final_grader].map(&:name))
      end

      it "uses the user avatar for the all grader's comments" do
        grader_comments = submission_json["submission_comments"].reject { |comment| comment["author_id"] == student.id.to_s }
        grader_avatars = grader_comments.pluck("avatar_path")
        expect(grader_avatars.uniq).to match_array([teacher, ta, final_grader].map(&:avatar_path))
      end

      context "when the user can view student names" do
        it "includes author_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).not_to be_empty
        end

        it "excludes anonymous_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comments).to all(not_have_key("anonymous_id"))
        end

        it "includes author_name on student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["author_name"]).to eql student.name
        end

        it "uses the user avatar for students on submission comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["author_id"] == student.id.to_s }
          expect(student_comment["avatar_path"]).to eql(student.avatar_path)
        end
      end

      context "when the user cannot view student names" do
        before do
          assignment.update!(anonymous_grading: true)
        end

        it "includes anonymous_id on student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).not_to be_empty
        end

        it "excludes author_id from student comments" do
          student_comments = submission_json["submission_comments"].select { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comments).to all(not_have_key("author_id"))
        end

        it "excludes author_name from student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment).not_to have_key("author_name")
        end

        it "uses the default avatar for student comments" do
          student_comment = submission_json["submission_comments"].detect { |comment| comment["anonymous_id"] == "aaaaa" }
          expect(student_comment["avatar_path"]).to eql(User.default_avatar_fallback)
        end
      end

      # current user's rubric assessments

      it "includes assessor_name on the current grader's rubric assessments' on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "includes assessor_id from the current grader's rubric assessments on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_id" => teacher.id.to_s))
      end

      it "excludes anonymous_assessor_id on the current grader's rubric assessments on students" do
        teacher_assessments = json["context"]["students"][0]["rubric_assessments"]
        expect(teacher_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # all provisional grades

      it "includes scorer_id on all provisional grades" do
        scorer_ids = submission_json["provisional_grades"].pluck("scorer_id")
        expect(scorer_ids.uniq).to match_array([teacher.id, ta.id, final_grader.id].map(&:to_s))
      end

      it "excludes anonymous_grader_id from all provisional grades" do
        expect(submission_json["provisional_grades"]).to all(not_have_key("anonymous_grader_id"))
      end

      # all provisional grade rubric assessments

      it "does not include assessments" do
        grader_assessments = submission_json["provisional_grades"].map { |grade| grade.fetch("rubric_assessments") }.flatten
        expect(grader_assessments).to be_empty
      end

      # final provisional grade (current user)

      it "includes scorer_id on the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["scorer_id"]).to eql(teacher.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by the current user'" do
        teacher_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade (other graders)

      it "includes scorer_id on the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]["scorer_id"]).to eql(ta.id.to_s)
      end

      it "excludes anonymous_grader_id from the final provisional grade when given by another grader'" do
        ta_pg.update!(final: true)
        expect(submission_json["final_provisional_grade"]).not_to have_key("anonymous_grader_id")
      end

      # final provisional grade rubric assessments (current user)

      it "includes assessor_name on the current grader's rubric assessments on the final provisional grade'" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_name" => "Teacher"))
      end

      it "includes assessor_id on the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(include("assessor_id" => teacher.id.to_s))
      end

      it "excludes anonymous_assessor_id from the current grader's rubric assessments on the final provisional grade" do
        teacher_pg.update!(final: true)
        teacher_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(teacher_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      # final provisional grade rubric assessments (other graders)

      it "includes assessor_name on the other grader's rubric assessments on the final provisional grade'" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("assessor_name" => ta.name))
      end

      it "includes assessor_id on the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(include("assessor_id" => ta.id.to_s))
      end

      it "excludes anonymous_assessor_id from the other grader's rubric assessments on the final provisional grade" do
        ta_pg.update!(final: true)
        ta_assessments = submission_json["final_provisional_grade"]["rubric_assessments"]
        expect(ta_assessments).to all(not_have_key("anonymous_assessor_id"))
      end

      it "sets anonymize_graders to false in the response" do
        expect(json["anonymize_graders"]).to be false
      end
    end
  end

  describe "post policies" do
    let_once(:assignment) { @course.assignments.create!(title: "hi") }
    let(:json) { SpeedGrader::Assignment.new(assignment, @teacher).json }

    it "sets post_manually to true in the response if the assignment is manually-posted" do
      assignment.ensure_post_policy(post_manually: true)
      expect(json["post_manually"]).to be true
    end

    it "sets post_manually to false in the response if the assignment is not manually-posted" do
      assignment.ensure_post_policy(post_manually: false)
      expect(json["post_manually"]).to be false
    end
  end
end
