#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe DataFixup::AssociateGradedDiscussionAttachments do
  it "should associate graded discussion attachments" do
    course_with_student(:active_all => true)
    assignment = @course.assignments.create!(:title => "asmt")
    topic = @course.discussion_topics.create!(:title => 'topic', :assignment => assignment)

    attachment_model(:context => @student, :uploaded_data => stub_png_data, :filename => "homework.png")
    entry = topic.reply_from(:user => @student, :text => "entry")
    entry.attachment = @attachment
    entry.save!

    sub = assignment.submissions.where(:user_id => @student).first
    Submission.where(:id => sub).update_all(:attachment_ids => nil)
    AttachmentAssociation.where(:attachment_id => @attachment).delete_all

    sub.reload
    expect(sub.attachments).to be_empty

    DataFixup::AssociateGradedDiscussionAttachments.run

    sub.reload
    expect(sub.attachments.to_a).to eq [@attachment]
    expect(AttachmentAssociation.where(:attachment_id => @attachment)).to be_exists
  end
end
