# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe AttachmentAssociation do
  let(:enrollment) { course_with_teacher({ active_all: true }) }
  let(:course) { enrollment.course }
  let(:teacher) { enrollment.user }
  let(:course_attachment) { attachment_with_context(course) }
  let(:course_attachment2) { attachment_with_context(course) }
  let(:course_attachment3) { attachment_with_context(course) }
  let(:another_user) { user_with_pseudonym({ account: enrollment.course.account }) }
  let(:user_attachment) { attachment_with_context(another_user) }
  let(:teacher_attachment) { attachment_with_context(teacher) }
  let(:student_enrollment) { course_with_user("StudentEnrollment", { course:, active_all: true }) }
  let(:student) { student_enrollment.user }

  context "create" do
    it "sets the root_account_id using course context" do
      attachment_model filename: "test.txt", context: account_model(root_account_id: nil)
      course_model
      association = @attachment.attachment_associations.create!(context: @course)
      expect(association.root_account_id).to eq @course.root_account_id
    end

    context "when context is a converation message" do
      it "sets the root_account_id using attachment" do
        attachment_model filename: "test.txt", context: account_model(root_account_id: nil)
        cm = conversation(user_model).messages.first
        association = @attachment.attachment_associations.create!(context: cm)
        expect(association.root_account_id).to eq @attachment.root_account_id
      end
    end
  end

  describe "#verify_access" do
    before do
      course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
      course.root_account.enable_feature!(:file_association_access)
    end

    def make_associations
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
      HTML
      html2 = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment3.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      course.associate_attachments_to_rce_object(html2, teacher, context_concern: "syllabus_body")
    end

    it "returns false if the attachment is locked" do
      course_attachment.update!(locked: true)
      make_associations
      expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment, teacher)).to be_falsey
    end

    it "returns false if the attachment is not associated with the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment2, teacher)).to be_falsey
    end

    it "returns false if the user is not allowed to read the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment, another_user)).to be_falsey
    end

    it "returns true if the attachment is associated with the context and the user has read rights to the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment, teacher)).to be_truthy
    end

    context "with a syllabus body attachment" do
      context "when the course syllabus is public" do
        before do
          course.public_syllabus = true
          course.save!
        end

        it "returns true for a public syllabus for an unassociated user" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3, another_user)).to be_truthy
        end

        it "returns true for a public syllabus for an enrolled student" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3, student)).to be_truthy
        end
      end

      context "when the course syllabus is not public" do
        before do
          course.public_syllabus = false
          course.save!
        end

        it "returns false for a nonpublic syllabus for an unassociated user" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3, another_user)).to be_falsey
        end

        it "returns true for a nonpublic syllabus for an enrolled student" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3, student)).to be_truthy
        end
      end
    end

    context "with AssessmentQuestion context" do
      before do
        course_with_teacher
        @course.root_account.enable_feature!(:file_association_access)
        assessment_question_bank_model(course: @course)
        assessment_question_bank_with_questions(count: 2)
        @aq_att = attachment_with_context(@q1)
        @q1.question_data[:description] = "<p>You are a locust! <a href=\"/assessment_questions/#{@q1.id}/files/#{@aq_att.id}/download\">Download</a></p>"
        @q1.save!
      end

      it "returns true when all conditions are met" do
        result = AttachmentAssociation.verify_access("assessment_question_#{@q1.id}", @aq_att, @teacher)
        expect(result).to be_truthy
      end

      it "returns false when context_type doesn't match attachment context_type" do
        other_attachment = attachment_with_context(@course)
        result = AttachmentAssociation.verify_access("assessment_question_#{@q1.id}", other_attachment, @teacher)
        expect(result).to be_falsey
      end

      it "returns false when context_id doesn't match" do
        result = AttachmentAssociation.verify_access("assessment_question_#{@q2.id}", @aq_att, @teacher)
        expect(result).to be_falsey
      end

      it "returns false when attachment_associations_enabled is false" do
        @q1.root_account.disable_feature!(:file_association_access)
        result = AttachmentAssociation.verify_access("assessment_question_#{@q1.id}", @aq_att, @teacher)
        expect(result).to be_falsey
      end

      it "returns false when access_for_attachment_association returns false" do
        other_user = user_with_pseudonym
        result = AttachmentAssociation.verify_access("assessment_question_#{@q1.id}", @aq_att, other_user)
        expect(result).to be_falsey
      end
    end

    context "with QuizSubmissions" do
      before do
        course_with_teacher_and_student_enrolled({ active_all: true })
        @course.root_account.enable_feature!(:file_association_access)

        assessment_question_bank_model

        @assessment_questions = []
        @assessment_question_attachments = []
        (1..4).each do |i|
          q = @bank.assessment_questions.create!(
            question_data: true_false_question_data
          )
          instance_variable_set(:"@aq#{i}", q)
          @assessment_questions << q
          aq_a = attachment_with_context(q)
          @assessment_question_attachments << aq_a
          q.question_data[:description] = "<p>Question #{i} description <a href=\"/assessment_questions/#{q.id}/files/#{aq_a.id}/download\">Download</a></p>"
          q.save!
          instance_variable_set(:"@aq_attachment#{i}", aq_a)
        end

        course_quiz(true)
        @quiz_desc_att = attachment_with_context(@teacher)
        @quiz.description = "<p>Quiz description <a href=\"/users/#{@teacher.id}/files/#{@quiz_desc_att.id}/download\">Download</a></p>"
        @quiz.updating_user = @teacher
        @quiz.save!

        @group = @quiz.quiz_groups.create!(name: "question group", pick_count: 2, question_points: 5.0)
        @group.assessment_question_bank = @bank
        @group.save!

        @question_att = attachment_with_context(@course)
        @question = @quiz.quiz_questions.create!(
          question_data: true_false_question_data.merge(question_text: "<p>Native question description <a href=\"/courses/#{@course.id}/files/#{@question_att.id}/download\">Download</a></p>"),
          updating_user: @teacher
        )

        @quiz.generate_quiz_data
        @quiz.save!
        @quiz.reload

        @qsub = @quiz.generate_submission(@student)
        @qsub_user_attachment = attachment_with_context(@qsub)

        @aq_attachments_in_submission = @qsub.quiz_data.filter_map do |q|
          aq = @assessment_questions.find { |a| a.id == q[:assessment_question_id] }
          next unless aq

          @assessment_question_attachments.find { |a| a.context_id == aq.id }
        end

        @aq_attachments_not_in_submission = @assessment_question_attachments - @aq_attachments_in_submission
      end

      it "allows access to quiz description attachment" do
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @quiz_desc_att, @student)
        expect(result).to be_truthy
      end

      it "does not allow access to quiz description attachment for an unassociated user" do
        other_user = user_with_pseudonym
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @quiz_desc_att, other_user)
        expect(result).to be_falsey
      end

      it "allows access to native question attachment" do
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @question_att, @student)
        expect(result).to be_truthy
      end

      it "allows access to an associated assessment question attachment" do
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @aq_attachments_in_submission.first, @student)
        expect(result).to be_truthy
      end

      it "does not allow access to an unassociated assessment question attachment" do
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @aq_attachments_not_in_submission.first, @student)
        expect(result).to be_falsey
      end

      it "allows access to quiz submission attachment" do
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", @qsub_user_attachment, @student)
        expect(result).to be_truthy
      end

      it "does not allow access to quiz submission attachment with another submission id" do
        other_qsub = @quiz.generate_submission(user_with_pseudonym)
        other_qsub_user_attachment = attachment_with_context(other_qsub)
        result = AttachmentAssociation.verify_access("quiz_submission_#{@qsub.id}", other_qsub_user_attachment, @student)
        expect(result).to be_falsey
      end
    end
  end
end
