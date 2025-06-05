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

  describe "#update_associations" do
    def fetch_list_with_field_name(context_concern)
      AttachmentAssociation.where(context: course, context_concern:).pluck(:attachment_id)
    end

    def make_association_update(attachment_ids, context_concern, user = teacher)
      AttachmentAssociation.update_associations(
        course,
        attachment_ids,
        user,
        nil,
        context_concern
      )
    end

    it "creates new associations" do
      make_association_update([course_attachment.id, course_attachment2.id], nil)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
    end

    it "updates existing associations (delete+create)" do
      make_association_update([course_attachment.id, course_attachment2.id], nil)
      make_association_update([course_attachment.id, course_attachment3.id], nil)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment3.id])
    end

    it "removes all associations" do
      make_association_update([course_attachment.id, course_attachment2.id], nil)
      make_association_update([], nil)
      expect(fetch_list_with_field_name(nil)).to be_empty
    end

    it "does not allow associations to files the editing user doesn't have access to" do
      make_association_update([course_attachment.id, user_attachment.id], nil)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id])
    end

    it "does not allow associations to files the editing user doesn't have update access to" do
      make_association_update([course_attachment.id, user_attachment.id], nil, student)
      expect(fetch_list_with_field_name(nil)).to be_empty
    end

    it "works with fields" do
      make_association_update([course_attachment.id, course_attachment2.id], nil)
      make_association_update([course_attachment3.id], "syllabus_body")
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
      expect(fetch_list_with_field_name("syllabus_body")).to match_array([course_attachment3.id])
    end

    context "with sharding" do
      specs_require_sharding

      it "creates associations on the context's shard, not the attachment's" do
        @shard1.activate do
          account_model
          course_model(account: @account)
          @course.enroll_teacher(teacher)
          attachment_model(context: @course, filename: "shard1.txt")
          AttachmentAssociation.update_associations(course, [@attachment.id], teacher, nil, "syllabus_body")
        end

        aa = AttachmentAssociation.find_by(context: course, context_concern: "syllabus_body")
        expect(aa.attachment_id).to eql @attachment.global_id
        expect(aa.context_id).to eql course.local_id
      end
    end
  end

  describe "#verify_access" do
    before do
      course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
      course.root_account.enable_feature!(:file_association_access)
    end

    def make_associations
      AttachmentAssociation.update_associations(
        course,
        [course_attachment.id, course_attachment2.id],
        teacher,
        nil
      )
      AttachmentAssociation.update_associations(
        course,
        [course_attachment3.id],
        teacher,
        nil,
        "syllabus_body"
      )
    end

    it "returns false if the attachment is not associated with the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_#{course.id}", course_attachment3.id, teacher)).to be_falsey
    end

    it "returns false if the user is not allowed to read the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_#{course.id}", course_attachment.id, another_user)).to be_falsey
    end

    it "returns true if the attachment is associated with the context and the user has read rights to the context" do
      make_associations
      expect(AttachmentAssociation.verify_access("course_#{course.id}", course_attachment.id, teacher)).to be_truthy
    end

    context "with a syllabus body attachment" do
      context "when the course syllabus is public" do
        before do
          course.public_syllabus = true
          course.save!
        end

        it "returns true for a public syllabus for an unassociated user" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3.id, another_user)).to be_truthy
        end

        it "returns true for a public syllabus for an enrolled student" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3.id, student)).to be_truthy
        end
      end

      context "when the course syllabus is not public" do
        before do
          course.public_syllabus = false
          course.save!
        end

        it "returns false for a nonpublic syllabus for an unassociated user" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3.id, another_user)).to be_falsey
        end

        it "returns true for a nonpublic syllabus for an enrolled student" do
          make_associations
          expect(AttachmentAssociation.verify_access("course_syllabus_#{course.id}", course_attachment3.id, student)).to be_truthy
        end
      end
    end
  end
end
