require 'spec_helper'

describe MasterCourses::MasterTemplate do
  before :once do
    course
  end

  describe "set_as_master_course" do
    it "should add a template to a course" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template.course).to eq @course
      expect(template.full_course).to eq true

      expect(MasterCourses::MasterTemplate.set_as_master_course(@course)).to eq template # should not create a copy
      expect(MasterCourses::MasterTemplate.full_template_for(@course)).to eq template
    end

    it "should ignore deleted templates" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.destroy!

      expect(template).to be_deleted

      template2 = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template2).to_not eq template
      expect(template2).to be_active
    end
  end

  describe "content_tag_for" do
    before :once do
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @assignment = @course.assignments.create!
    end

    it "should create tags for course content" do
      tag = @template.content_tag_for(@assignment)
      expect(tag.reload.content).to eq @assignment
    end

    it "should find tags" do
      tag = @template.create_content_tag_for!(@assignment)
      @template.expects(:create_content_tag_for!).never # don't try to recreate
      expect(@template.content_tag_for(@assignment)).to eq tag
    end

    it "should not fail on double-create" do
      tag = @template.create_content_tag_for!(@assignment)
      expect(@template.create_content_tag_for!(@assignment)).to eq tag # should retry on unique constraint failure
    end

    it "should be able to load tags for fast searching" do
      tag = @template.create_content_tag_for!(@assignment)
      @template.load_tags!

      old_tag_id = tag.id
      tag.destroy! # delete in the db - proves that we cached them

      expect(@template.content_tag_for(@assignment).id).to eq old_tag_id

      # should still create a tag even if it's not found in the index
      @page = @course.wiki.wiki_pages.create!(:title => "title")
      page_tag = @template.content_tag_for(@page)
      expect(page_tag.reload.content).to eq @page
    end
  end

  describe "child subscriptions" do
    it "should be able to add other courses as 'child' courses" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      new_course = course
      sub = template.add_child_course!(new_course)
      expect(sub.child_course).to eq new_course
      expect(sub.master_template).to eq template
      expect(sub).to be_active
      expect(sub.use_selective_copy).to be_falsey # should default to false - we'll set it to true later after the first import

      expect(template.child_subscriptions.active.count).to eq 1
      sub.destroy!

      # can re-add
      new_sub = template.add_child_course!(new_course)
      expect(new_sub).to_not eq sub
      expect(template.child_subscriptions.active.count).to eq 1
    end

    it "should require child courses to belong to the same root account" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      new_root_account = Account.create!
      new_course = course(:account => new_root_account)
      expect { template.add_child_course!(new_course) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
