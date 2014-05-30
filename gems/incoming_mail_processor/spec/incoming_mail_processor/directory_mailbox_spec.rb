#
# Copyright (C) 2013 Instructure, Inc.
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

require 'spec_helper'

describe IncomingMailProcessor::DirectoryMailbox do
  include_examples 'Mailbox'

  def default_config
    {
      :folder => "/tmp/directory_mailbox",
    }
  end

  before do
    @mailbox = IncomingMailProcessor::DirectoryMailbox.new(default_config)
  end

  it "should connect if folder exists" do
    @mailbox.expects(:folder_exists?).with(default_config[:folder]).returns(true)
    expect { @mailbox.connect}.to_not raise_error
  end

  it "should raise on connect if folder does not exist" do
    @mailbox.expects(:folder_exists?).with(default_config[:folder]).returns(false)
    expect { @mailbox.connect }.to raise_error
  end

  it "should iterate through and yield files in a directory" do
    folder = default_config[:folder]
    folder_entries = %w(. .. foo bar baz)
    @mailbox.expects(:files_in_folder).with(folder).returns(folder_entries)
    folder_entries.each do |entry|
      @mailbox.expects(:file?).with(folder, entry).returns(!entry.include?('.'))
    end

    @mailbox.expects(:read_file).with(folder, "foo").returns("foo body")
    @mailbox.expects(:read_file).with(folder, "bar").returns("bar body")
    @mailbox.expects(:read_file).with(folder, "baz").returns("baz body")

    yielded_values = []
    @mailbox.each_message do |*values|
      yielded_values << values
    end
    yielded_values.should eql [["foo", "foo body"], ["bar", "bar body"], ["baz", "baz body"], ]
  end

  context "with simple foo file" do

    before do
      @mailbox.expects({
        :file? => true,
        :read_file => "foo body",
        :files_in_folder => ["foo"],
      })
      @mailbox.expects(:folder_exists?).with(default_config[:folder]).returns(true)
      @mailbox.connect
    end

    it "should delete files" do
      @mailbox.expects(:delete_file).with(default_config[:folder], "foo")
      @mailbox.each_message do |id, body|
        @mailbox.delete_message(id)
      end
    end

    it "should move files" do
      folder = default_config[:folder]
      @mailbox.expects(:move_file).with(folder, "foo", "aside")
      @mailbox.expects(:folder_exists?).with(folder, "aside").returns(true)
      @mailbox.expects(:create_folder).never
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "aside")
      end
    end

    it "should create target folder when moving file if target folder doesn't exist" do
      folder = default_config[:folder]
      @mailbox.expects(:move_file).with(folder, "foo", "aside")
      @mailbox.expects(:folder_exists?).with(folder, "aside").returns(false)
      @mailbox.expects(:create_folder).with(default_config[:folder], "aside")
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "aside")
      end
    end

  end
end

