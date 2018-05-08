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

require 'spec_helper'

describe DataFixup::ReclaimInstfsAttachments do
  describe "reclaim_attachment" do
    let(:file_contents) { 'file contents' }
    let(:instfs_uuid) { 'uuid' }
    let(:instfs_body) { StringIO.new(file_contents) }
    let(:attachment) { attachment_model(instfs_uuid: instfs_uuid) }

    before :each do
      # this method is only called during the `instfs_hosted?` branch of
      # attachment.open, so it'll be stubbed out when fetching the contents
      # from inst-fs, but note when checking the contents in s3 after reclaim
      allow(attachment).to receive(:create_tempfile).and_return(instfs_body)
    end

    it "produces a working attachment served by non-instfs storage" do
      DataFixup::ReclaimInstfsAttachments.reclaim_attachment(attachment)
      expect(attachment).not_to be_instfs_hosted
      expect(attachment.open.read).to be_present
    end

    it "preserves the contents unmodified" do
      DataFixup::ReclaimInstfsAttachments.reclaim_attachment(attachment)
      expect(attachment.open.read).to eql(file_contents)
    end
  end

  describe "run" do
    let(:account1) { account_model }
    let(:account2) { account_model }
    let(:account3) { account_model }
    let(:subaccount) { account_model(root_account: account1) }

    it "reclaims inst-fs attachments associated with objects in specified root accounts" do
      # not exhaustive, but a variety
      question = account1.assessment_question_banks.create!.assessment_questions.create!
      folder = folder_model(context: subaccount)

      attachment1 = attachment_model(context: subaccount, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: question, instfs_uuid: 'uuid2')
      attachment3 = attachment_model(context: folder, instfs_uuid: 'uuid3')

      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment2)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment3)
      DataFixup::ReclaimInstfsAttachments.run([account1])
    end

    it "reclaims inst-fs attachments associated with objects in groups in specified root accounts" do
      # not exhaustive, but a variety
      group1 = group_model(context: subaccount)
      group2 = group_model(context: course_model(account: subaccount))
      folder = folder_model(context: group1)

      attachment1 = attachment_model(context: group1, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: group2, instfs_uuid: 'uuid2')
      attachment3 = attachment_model(context: folder, instfs_uuid: 'uuid3')

      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment2)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment3)
      DataFixup::ReclaimInstfsAttachments.run([account1])
    end

    it "reclaims inst-fs attachments associated with objects in courses in specified root accounts" do
      # not exhaustive, but a variety
      course = course_model(account: subaccount)
      question = course.assessment_question_banks.create!.assessment_questions.create!
      folder = folder_model(context: course)
      submission = submission_model(assignment: assignment_model(context: course), user: user_model)
      quiz = quiz_model(course: course, assignment: assignment_model(course: course))

      attachment1 = attachment_model(context: course, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: question, instfs_uuid: 'uuid2')
      attachment3 = attachment_model(context: folder, instfs_uuid: 'uuid3')
      attachment4 = attachment_model(context: submission, instfs_uuid: 'uuid4')
      attachment5 = attachment_model(context: quiz, instfs_uuid: 'uuid5')

      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment2)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment3)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment4)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment5)
      DataFixup::ReclaimInstfsAttachments.run([account1])
    end

    it "reclaims inst-fs attachments associated with any of the specified root accounts" do
      attachment1 = attachment_model(context: account1, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: account2, instfs_uuid: 'uuid2')
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment2)
      DataFixup::ReclaimInstfsAttachments.run([account1, account2])
    end

    it "ignores attachments from other root accounts" do
      attachment1 = attachment_model(context: account1, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: account3, instfs_uuid: 'uuid3')
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).not_to receive(:reclaim_attachment).with(attachment2)
      DataFixup::ReclaimInstfsAttachments.run([account1])
    end

    it "ignores non inst-fs attachments" do
      attachment1 = attachment_model(context: account1, instfs_uuid: 'uuid1')
      attachment2 = attachment_model(context: account1, instfs_uuid: nil)
      expect(DataFixup::ReclaimInstfsAttachments).to receive(:reclaim_attachment).with(attachment1)
      expect(DataFixup::ReclaimInstfsAttachments).not_to receive(:reclaim_attachment).with(attachment2)
      DataFixup::ReclaimInstfsAttachments.run([account1])
    end
  end
end
