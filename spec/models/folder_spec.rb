#
# Copyright (C) 2011 Instructure, Inc.
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

describe Folder do
  before(:each) do
    course
  end
  
  it "should create a new instance given valid attributes" do
    folder_model
  end
  
  it "should infer its full name if it has a parent folder" do
    f = @course.folders.create!(:name => "root")
    f.full_name.should eql("root")
    child = f.active_sub_folders.build(:name => "child")
    child.context = @course
    child.save!
    child.parent_folder.should eql(f)
    child.full_name.should eql("root/child")
    grandchild = child.sub_folders.build(:name => "grandchild")
    grandchild.context = @course
    grandchild.save!
    grandchild.full_name.should eql("root/child/grandchild")
    great_grandchild = grandchild.sub_folders.build(:name => "great_grandchild")
    great_grandchild.context = @course
    great_grandchild.save!
    great_grandchild.full_name.should eql("root/child/grandchild/great_grandchild")
    child.parent_folder = nil
    child.save!
    child.reload
    child.parent_folder.should be_nil
    child.full_name.should eql("child")
    grandchild.reload
    grandchild.full_name.should eql("child/grandchild")
    great_grandchild.reload
    great_grandchild.full_name.should eql("child/grandchild/great_grandchild")
  end

  it "should not allow recursive folder structures" do
    f1 = @course.folders.create!(:name => "f1")
    f2 = f1.sub_folders.create!(:name => "f2", :context => @course)
    f3 = f2.sub_folders.create!(:name => "f3", :context => @course)
    f1.parent_folder = f3
    f1.save.should == false
    f1.errors.on(:parent_folder_id).should be_present
  end

  it "files without an explicit folder_id should be inferred" do
    f = @course.folders.create!(:name => "unfiled")
    a = f.active_file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.new
    nil_a.update_attributes(:uploaded_data => default_uploaded_data)
    nil_a.folder_id.should_not be_nil
    f.active_file_attachments.should be_include(a)
    # f.active_file_attachments.should be_include(nil_a)
  end
  it "should assign unfiled files to the 'unfiled' folder" do
    f = Folder.unfiled_folder(@course)
    a = f.file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.new
    nil_a.update_attributes(:uploaded_data => default_uploaded_data)
    f.active_file_attachments.should be_include(a)
    f.active_file_attachments.should be_include(nil_a)
  end
  
  it "should not return files without a folder_id if it's not the 'unfiled' folder" do
    f = @course.folders.create!(:name => "not_unfiled")
    a = f.active_file_attachments.build
    a.context = @course
    a.uploaded_data = default_uploaded_data
    a.save!
    nil_a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
    f.active_file_attachments.should be_include(a)
    f.active_file_attachments.should_not be_include(nil_a)
  end
  
end
