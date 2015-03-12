

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'db/migrate/20150312155754_remove_discussion_entry_attachment_foreign_key'

describe 'RemoveDiscussionEntryAttachmentForeignKey' do
  specs_require_sharding

  it "should allow cross-shard users and attachments" do
    @shard1.activate do
      @teacher = user
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
