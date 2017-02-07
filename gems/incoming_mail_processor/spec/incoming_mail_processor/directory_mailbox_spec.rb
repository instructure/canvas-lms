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
    expect(@mailbox).to receive(:folder_exists?).with(default_config[:folder]).and_return(true)
    expect { @mailbox.connect }.to_not raise_error
  end

  it "should raise on connect if folder does not exist" do
    expect(@mailbox).to receive(:folder_exists?).with(default_config[:folder]).and_return(false)
    expect { @mailbox.connect }.to raise_error(/Folder .* does not exist/)
  end

  describe ".each_message" do
    it "should iterate through and yield files in a directory" do
      folder = default_config[:folder]
      folder_entries = %w(. .. foo bar baz)
      expect(@mailbox).to receive(:files_in_folder).with(folder).and_return(folder_entries)
      folder_entries.each do |entry|
        expect(@mailbox).to receive(:file?).with(folder, entry).and_return(!entry.include?('.'))
      end

      expect(@mailbox).to receive(:read_file).with(folder, "foo").and_return("foo body")
      expect(@mailbox).to receive(:read_file).with(folder, "bar").and_return("bar body")
      expect(@mailbox).to receive(:read_file).with(folder, "baz").and_return("baz body")

      yielded_values = []
      @mailbox.each_message do |*values|
        yielded_values << values
      end
      expect(yielded_values).to eql [["foo", "foo body"], ["bar", "bar body"], ["baz", "baz body"], ]
    end

    it "iterates with stride and offset" do
      folder = default_config[:folder]
      folder_entries = %w(. .. foo bar baz)
      expect(@mailbox).to receive(:files_in_folder).with(folder).twice.and_return(folder_entries)
      folder_entries.each do |entry|
        expect(@mailbox).to receive(:file?).with(folder, entry).and_return(!entry.include?('.'))
      end

      # the crc32 of the filename is used to determine whether a given worker picks up the file
      # with these file and two workers, foo goes to worker 1 and foo goes to worker 0
      expect(@mailbox).to receive(:read_file).with(folder, "foo").and_return("foo body")
      expect(@mailbox).to receive(:read_file).with(folder, "bar").and_return("bar body")
      expect(@mailbox).to receive(:read_file).with(folder, "baz").and_return("baz body")

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 0) do |*values|
        yielded_values << values
      end
      expect(yielded_values).to eql [["bar", "bar body"], ["baz", "baz body"], ]

      yielded_values = []
      @mailbox.each_message(stride: 2, offset: 1) do |*values|
        yielded_values << values
      end
      expect(yielded_values).to eql [["foo", "foo body"]]
    end
  end

  describe '#unprocessed_message_count' do
    it "should return nil" do
      expect(@mailbox.unprocessed_message_count).to be_nil
    end
  end

  context "with simple foo file" do

    before do
      expect(@mailbox).to receive(:file?).and_return(true)
      expect(@mailbox).to receive(:read_file).and_return("foo body")
      expect(@mailbox).to receive(:files_in_folder).and_return(["foo"])
      expect(@mailbox).to receive(:folder_exists?).with(default_config[:folder]).and_return(true)
      @mailbox.connect
    end

    it "should delete files" do
      expect(@mailbox).to receive(:delete_file).with(default_config[:folder], "foo")
      @mailbox.each_message do |id, body|
        @mailbox.delete_message(id)
      end
    end

    it "should move files" do
      folder = default_config[:folder]
      expect(@mailbox).to receive(:move_file).with(folder, "foo", "aside")
      expect(@mailbox).to receive(:folder_exists?).with(folder, "aside").and_return(true)
      expect(@mailbox).to receive(:create_folder).never
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "aside")
      end
    end

    it "should create target folder when moving file if target folder doesn't exist" do
      folder = default_config[:folder]
      expect(@mailbox).to receive(:move_file).with(folder, "foo", "aside")
      expect(@mailbox).to receive(:folder_exists?).with(folder, "aside").and_return(false)
      expect(@mailbox).to receive(:create_folder).with(default_config[:folder], "aside")
      @mailbox.each_message do |id, body|
        @mailbox.move_message(id, "aside")
      end
    end

  end
end
