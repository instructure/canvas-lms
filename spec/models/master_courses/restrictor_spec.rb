require 'spec_helper'

describe MasterCourses::Restrictor do
  before :once do
    @copy_from = course
    @template = MasterCourses::MasterTemplate.set_as_master_course(@copy_from)
    @original_page = @copy_from.wiki.wiki_pages.create!(:title => "blah", :body => "bloo")
    @tag = @template.create_content_tag_for!(@original_page)

    @copy_to = course
    @page_copy = @copy_to.wiki.wiki_pages.new(:title => "blah", :body => "bloo") # just create a copy directly instead of doing a real migraiton
    @page_copy.migration_id = @tag.migration_id
    @page_copy.save!
    @page_copy.master_course_restrictions = nil
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

    it "should not prevent changes if validations are skipped" do
      @tag.update_attribute(:restrictions, {:content => true})
      @page_copy.skip_master_course_validation!
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
    end

    it "should return what you would expect" do
      @tag.update_attribute(:restrictions, {:content => true})
      expect(@page_copy.editing_restricted?(:content)).to be_truthy
      expect(@page_copy.editing_restricted?(:settings)).to be_falsey
      expect(@page_copy.editing_restricted?(:any)).to be_truthy
      expect(@page_copy.editing_restricted?(:all)).to be_falsey
    end

    it "should return true if fully locked" do
      @tag.update_attribute(:restrictions, {:content => true, :settings => true})
      expect(@page_copy.editing_restricted?(:content)).to be_truthy
      expect(@page_copy.editing_restricted?(:settings)).to be_truthy
      expect(@page_copy.editing_restricted?(:any)).to be_truthy
      expect(@page_copy.editing_restricted?(:all)).to be_truthy
    end
  end

  describe "preload_restrictions" do
    it "should bulk preload restrictions in a single query" do
      page2 = @copy_from.wiki.wiki_pages.create!(:title => "blah2")
      tag2 = @template.create_content_tag_for!(page2, {:restrictions => {:content => true}})

      page2_copy = @copy_to.wiki.wiki_pages.new(:title => "blah2") # just create a copy directly instead of doing a real migraiton
      page2_copy.migration_id = tag2.migration_id
      page2_copy.save!

      MasterCourses::Restrictor.preload_restrictions([@page_copy, page2_copy])

      MasterCourses::MasterContentTag.expects(:where).never # don't load again
      expect(@page_copy.master_course_restrictions).to eq({})
      expect(page2_copy.master_course_restrictions).to eq({:content => true})
    end
  end
end
