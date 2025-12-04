# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

describe LinkedAttachmentHandler do
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

  describe "#associate_attachments_to_rce_object" do
    before do
      course.root_account.enable_feature!(:allow_attachment_association_creation)
      course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
    end

    def fetch_list_with_field_name(context_concern)
      AttachmentAssociation.where(context: course, context_concern:).pluck(:attachment_id)
    end

    it "creates new associations" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
    end

    it "skips cross-course associations" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/users/#{another_user.id}/files/#{user_attachment.id}/preview"></p>
      HTML

      course.associate_attachments_to_rce_object(html, teacher)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id])

      course2 = course_with_teacher(active_all: true, user: teacher).course
      course2.associate_attachments_to_rce_object(html, teacher)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id])
    end

    it "updates existing associations (delete+create)" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      html2 = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment3.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html2, teacher)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment3.id])
    end

    it "does not allow associations to files the editing user doesn't have access to" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/users/#{another_user.id}/files/#{user_attachment.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id])
    end

    it "does not allow associations to files the editing user doesn't have update access to" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/users/#{another_user.id}/files/#{user_attachment.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, student)
      expect(fetch_list_with_field_name(nil)).to be_empty
    end

    it "does not create associations for user files with UUID verifiers when not in migration context" do
      html = <<~HTML
        <p><a href="/users/#{another_user.id}/files/#{user_attachment.id}/download?verifier=#{user_attachment.uuid}">file 1</a></p>
        <p><iframe src="/media_attachments_iframe/#{user_attachment.id}?verifier=#{user_attachment.uuid}"></iframe></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      expect(fetch_list_with_field_name(nil)).to be_empty
    end

    it "works with fields" do
      html = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
          <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      html2 = <<~HTML
        <p><a href="/courses/#{course.id}/files/#{course_attachment3.id}/download">file 2</a></p>
      HTML
      course.associate_attachments_to_rce_object(html, teacher)
      course.associate_attachments_to_rce_object(html2, teacher, context_concern: "syllabus_body")
      expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
      expect(fetch_list_with_field_name("syllabus_body")).to match_array([course_attachment3.id])
    end

    context "deleting associations" do
      it "removes all associations" do
        html = <<~HTML
          <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
            <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
        HTML
        course.associate_attachments_to_rce_object(html, teacher)
        course.associate_attachments_to_rce_object("", teacher)
        expect(fetch_list_with_field_name(nil)).to be_empty
      end

      it "keeps wiki page associations" do
        wiki_page = course.wiki_pages.create!(title: "Test Page")
        html = <<~HTML
          <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
            <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
        HTML
        wiki_page.associate_attachments_to_rce_object(html, teacher)
        wiki_page.associate_attachments_to_rce_object("", teacher)
        associations = AttachmentAssociation.where(context: wiki_page).pluck(:attachment_id)
        expect(associations).to match_array([course_attachment.id, course_attachment2.id])
      end

      it "keeps association if the user doesn't have manage access to the file" do
        html = <<~HTML
          <p><a href="/courses/#{course.id}/files/#{course_attachment.id}/download">file 1</a>
            <img id="3" src="/courses/#{course.id}/files/#{course_attachment2.id}/preview"></p>
        HTML
        course.associate_attachments_to_rce_object(html, teacher)
        course.associate_attachments_to_rce_object("", student)
        expect(fetch_list_with_field_name(nil)).to match_array([course_attachment.id, course_attachment2.id])
      end
    end

    context "with sharding" do
      specs_require_sharding

      it "creates associations on the context's shard, not the attachment's" do
        @shard1.activate do
          account_model
          teacher2 = user_model(name: "Shard 1 Teacher")
          course.enroll_teacher(teacher2)
          attachment_model(context: teacher2, filename: "shard1.txt")
          html = <<~HTML
            <p><a href="/users/#{teacher2.id}/files/#{@attachment.id}/download">file</a>
          HTML
          course.associate_attachments_to_rce_object(html, teacher2, context_concern: "syllabus_body")
        end

        aa = AttachmentAssociation.find_by(context: course, context_concern: "syllabus_body")
        expect(aa.attachment_id).to eql @attachment.global_id
        expect(aa.context_id).to eql course.local_id
      end
    end
  end
end
