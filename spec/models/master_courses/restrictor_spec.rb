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

require 'spec_helper'

describe MasterCourses::Restrictor do
  before :once do
    @copy_from = course_factory
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_page = @copy_from.wiki.wiki_pages.create!(:title => "blah", :body => "bloo")
    @tag = @template.create_content_tag_for!(@original_page)

    @copy_to = course_factory
    @page_copy = @copy_to.wiki.wiki_pages.new(:title => "blah", :body => "bloo") # just create a copy directly instead of doing a real migraiton
    @page_copy.migration_id = @tag.migration_id
    @page_copy.save!
    @page_copy.child_content_restrictions = nil
  end

  describe "column locking validations" do
    it "should not prevent changes if there are no restrictions" do
      @page_copy.body = "something else"
      @page_copy.save!
    end

    it "should not prevent changes to settings columns on content-locked objects" do
      @tag.update_attribute(:restrictions, {:content => true})
      @page_copy.editing_roles = "teachers,students"
      @page_copy.save!
    end

    it "should not prevent changes to content columns on settings-locked objects" do
      @tag.update_attribute(:restrictions, {:settings => true})
      @page_copy.body = "another something else"
      @page_copy.save!
    end

    it "should prevent changes to content columns on content-locked objects" do
      @tag.update_attribute(:restrictions, {:content => true})
      @page_copy.body = "something else"
      expect(@page_copy.save).to be_falsey
      expect(@page_copy.errors[:base].first.to_s).to include("locked by Master Course")
    end

    it "should prevent changes to settings columns on settings-locked objects" do
      @tag.update_attribute(:restrictions, {:settings => true})
      @page_copy.editing_roles = "teachers,students"
      expect(@page_copy.save).to be_falsey
      expect(@page_copy.errors[:base].first.to_s).to include("locked by Master Course")
    end
  end

  describe "editing_restricted?" do
    it "should return false by default" do
      expect(@page_copy.editing_restricted?(:any)).to be_falsey
      expect(@page_copy.editing_restricted?(:content)).to be_falsey
      expect(@page_copy.editing_restricted?(:settings)).to be_falsey
      expect(@page_copy.editing_restricted?(:availability_dates)).to be_falsey
      expect(@page_copy.editing_restricted?(:due_dates)).to be_falsey
      expect(@page_copy.editing_restricted?(:points)).to be_falsey
      expect(@page_copy.editing_restricted?(:all)).to be_falsey
    end

    it "should return what you would expect" do
      @tag.update_attribute(:restrictions, {:content => true})
      expect(@page_copy.editing_restricted?(:content)).to be_truthy
      expect(@page_copy.editing_restricted?(:settings)).to be_falsey
      expect(@page_copy.editing_restricted?(:availability_dates)).to be_falsey
      expect(@page_copy.editing_restricted?(:due_dates)).to be_falsey
      expect(@page_copy.editing_restricted?(:points)).to be_falsey
      expect(@page_copy.editing_restricted?(:any)).to be_truthy
      expect(@page_copy.editing_restricted?(:all)).to be_falsey
    end

    it "should return true if fully/individually locked" do
      @tag.update_attribute(:restrictions, {:content => true, :settings => true, :points => true, :availability_dates => true, :due_dates => true})
      expect(@page_copy.editing_restricted?(:content)).to be_truthy
      expect(@page_copy.editing_restricted?(:settings)).to be_truthy
      expect(@page_copy.editing_restricted?(:points)).to be_truthy
      expect(@page_copy.editing_restricted?(:availability_dates)).to be_truthy
      expect(@page_copy.editing_restricted?(:due_dates)).to be_truthy
      expect(@page_copy.editing_restricted?(:any)).to be_truthy
      expect(@page_copy.editing_restricted?(:all)).to be_truthy
    end

    it "should return true if locked via :all" do
      @tag.update_attribute(:restrictions, {:all => true})
      expect(@page_copy.editing_restricted?(:content)).to be_truthy
      expect(@page_copy.editing_restricted?(:settings)).to be_truthy
      expect(@page_copy.editing_restricted?(:points)).to be_truthy
      expect(@page_copy.editing_restricted?(:availability_dates)).to be_truthy
      expect(@page_copy.editing_restricted?(:due_dates)).to be_truthy
      expect(@page_copy.editing_restricted?(:any)).to be_truthy
      expect(@page_copy.editing_restricted?(:all)).to be_truthy
    end
  end

  describe "preload_child_restrictions" do
    it "should bulk preload restrictions in a single query" do
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "blah2")
      tag2 = @template.create_content_tag_for!(page2, {:restrictions => {:content => true}})

      page2_copy = @copy_to.wiki.wiki_pages.new(:title => "blah2") # just create a copy directly instead of doing a real migraiton
      page2_copy.migration_id = tag2.migration_id
      page2_copy.save!

      MasterCourses::Restrictor.preload_child_restrictions([@page_copy, page2_copy])

      MasterCourses::MasterContentTag.expects(:where).never # don't load again
      expect(@page_copy.child_content_restrictions).to eq({})
      expect(page2_copy.child_content_restrictions).to eq({:content => true})
    end
  end

  describe "preload_default_template_restrictions" do
    it "should bulk preload master-side restrictions in a single query" do
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "blah2")
      tag2 = @template.create_content_tag_for!(page2, {:restrictions => {:content => true}})

      # should also work for associated assignments (since they share a master content tag)
      quiz = @copy_from.quizzes.create!(:title => "quiz", :quiz_type => "assignment")
      assignment = quiz.assignment
      tag3 = @template.create_content_tag_for!(quiz, {:restrictions => {:all => true}})

      MasterCourses::Restrictor.preload_default_template_restrictions([@original_page, page2, assignment], @copy_from)

      expect(@original_page.current_master_template_restrictions).to eq({})
      expect(page2.current_master_template_restrictions).to eq(tag2.restrictions)
      expect(assignment.current_master_template_restrictions).to eq(tag3.restrictions)
    end
  end

  describe "file weirdness" do
    before(:once) do
      @original_file = @copy_from.attachments.create! :display_name => 'blargh',
                                                      :uploaded_data => default_uploaded_data,
                                                      :folder => Folder.root_folders(@copy_from).first
      @file_tag = @template.create_content_tag_for!(@original_file)
      @copied_file = @original_file.clone_for(@copy_to, nil, :migration_id => @file_tag.migration_id)
      @copied_file.update_attribute(:folder, Folder.root_folders(@copy_to).first)
    end

    it "allows overwriting a non-restricted file" do
      new_file = @copy_to.attachments.create! :display_name => 'blargh',
                                              :uploaded_data => default_uploaded_data,
                                              :folder => Folder.root_folders(@copy_to).first
      deleted_files = new_file.handle_duplicates(:overwrite)
      expect(deleted_files).to match_array([@copied_file])
      expect(@copied_file.reload).to be_deleted
      expect(new_file.reload).not_to be_deleted
      expect(new_file.display_name).to eq 'blargh'
    end

    it "prevents overwriting a restricted file" do
      @file_tag.update_attribute(:restrictions, {:content => true})
      new_file = @copy_to.attachments.create! :display_name => 'blargh',
                                              :uploaded_data => default_uploaded_data,
                                              :folder => Folder.root_folders(@copy_to).first
      deleted_files = new_file.handle_duplicates(:overwrite)
      expect(deleted_files).to be_empty
      expect(@copied_file.reload).not_to be_deleted
      expect(new_file.reload).not_to be_deleted
      expect(new_file.display_name).not_to eq 'blargh'
    end
  end

  it "should prevent updating a title on a module item for restricted content" do
    mod = @copy_to.context_modules.create!
    item = mod.add_item(:id => @page_copy.id, :type => 'wiki_page')
    item.update_attribute(:title, "new title") # should work
    @tag.update_attribute(:restrictions, {:content => true})
    item.reload
    item.title = "another new title"
    expect(item.save).to be_falsey
    expect(item.errors[:title].first.to_s).to include("locked by Master Course")
  end
end
