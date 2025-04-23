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
    let(:enrollment) { course_with_teacher }
    let(:course) { enrollment.course }
    let(:teacher) { enrollment.user }
    let(:course_attachment) { attachment_with_context(course) }
    let(:course_attachment2) { attachment_with_context(course) }
    let(:course_attachment3) { attachment_with_context(course) }
    let(:another_user) { user_with_pseudonym({ account: enrollment.course.account }) }
    let(:user_attachment) { attachment_with_context(another_user) }

    def fetch_list_with_field_name(field_name)
      AttachmentAssociation.where(context: course, field_name:).pluck(:attachment_id)
    end

    def make_association_update(attachment_ids, field_name)
      AttachmentAssociation.update_associations(
        course,
        attachment_ids,
        teacher,
        nil,
        field_name
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

    it "works with fields" do
      make_association_update([course_attachment.id, course_attachment2.id], nil)
      make_association_update([course_attachment3.id], "syllabus_body")
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
      expect(fetch_list_with_field_name("syllabus_body")).to match_array([course_attachment3.id])
    end
  end
end
