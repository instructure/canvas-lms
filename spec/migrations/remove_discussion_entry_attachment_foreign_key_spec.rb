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


require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')
require 'db/migrate/20150312155754_remove_discussion_entry_attachment_foreign_key'

describe 'RemoveDiscussionEntryAttachmentForeignKey' do
  specs_require_sharding

  it "should allow cross-shard users and attachments" do
    @shard1.activate do
      @teacher = user_factory
      @file = attachment_model context: @teacher, filename: 'wat.txt', uploaded_data: stub_file_data('wat.txt', nil, 'text/plain')
    end
    course_with_teacher user: @teacher
    @topic = @course.discussion_topics.create!
    @entry = @topic.reply_from(user: @teacher, text: "wat")
    expect(@entry.shard).not_to eq(@file.shard)

    migration = RemoveDiscussionEntryAttachmentForeignKey.new

    migration.down
    @entry.attachment = @file
    expect { @entry.save! }.to raise_error(ActiveRecord::InvalidForeignKey)

    migration.up
    @entry.reload
    @entry.attachment = @file
    expect { @entry.save! }.not_to raise_error
    expect(@entry.reload.attachment).to eq(@file)
  end
end
