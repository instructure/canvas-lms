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
  end
end
