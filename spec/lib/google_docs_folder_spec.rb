#
# Copyright (C) 2011-2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe GoogleDocs::Folder do
  class MockFile < Struct.new(:name); end

  let(:folder) do
    folder1 = GoogleDocs::Folder.new(
        "one",
        [],
        [
          MockFile.new("one-1"),
          MockFile.new("one-2"),
          MockFile.new("one-3")
        ]
    )

    folder2 = GoogleDocs::Folder.new(
        "two",
        [],
        [
          MockFile.new("two-1"),
          MockFile.new("two-2")
        ]
    )

    GoogleDocs::Folder.new(
        "root",
        [
          folder1,
          folder2
        ]
    )
  end

  it "can map files" do
    names = folder.map{ |f| f.name }
    names.should == ['one-1', 'one-2', 'one-3', 'two-1', 'two-2']
  end

  it "can select files" do
    tree = folder.select{ |f| f.name =~ /one-[12]/ }
    tree.name.should == 'root'
    tree.folders.size.should == 1
    tree.folders.first.name.should == 'one'
    tree.folders.first.files.size.should == 2
    tree.folders.first.files.map{ |f| f.name }.should == ['one-1', 'one-2']
  end
end