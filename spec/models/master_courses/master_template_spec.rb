require 'spec_helper'

describe MasterCourses::MasterTemplate do
  before :once do
    course_factory
  end

  describe "set_as_master_course" do
    it "should add a template to a course" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template.course).to eq @course
      expect(template.full_course).to eq true

      expect(MasterCourses::MasterTemplate.set_as_master_course(@course)).to eq template # should not create a copy
      expect(MasterCourses::MasterTemplate.full_template_for(@course)).to eq template
    end

    it "should restore deleted templates" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.destroy!

      expect(template).to be_deleted

      template2 = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template2).to eq template
      expect(template2).to be_active
    end
  end

  describe "remove_as_master_course" do
    it "should remove a template from a course" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      expect(template.workflow_state).to eq "active"
      expect(template.active?).to eq true

      expect{MasterCourses::MasterTemplate.remove_as_master_course(@course)}.to change{template.reload.workflow_state}.from("active").to("deleted")
      expect(MasterCourses::MasterTemplate.full_template_for(@course)).to be_nil
    end

    it "should ignore deleted templates" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      template.destroy
      expect(template).to be_deleted

      MasterCourses::MasterTemplate.remove_as_master_course(@course)

      template.expects(:destroy).never
      expect(template).to be_deleted
    end
  end

  describe "is_master_course?" do
    def check
      MasterCourses::MasterTemplate.is_master_course?(@course)
    end

    it "should cache the result" do
      enable_cache do
        expect(check).to be_falsey
        @course.expects(:master_course_templates).never
        expect(check).to be_falsey
        expect(MasterCourses::MasterTemplate.is_master_course?(@course.id)).to be_falsey # should work with ids too
      end
    end

    it "should invalidate the cache when set as master course" do
      enable_cache do
        expect(check).to be_falsey
        template = MasterCourses::MasterTemplate.set_as_master_course(@course) # invalidate on create
        expect(check).to be_truthy
        template.destroy! # and on workflow_state change
        expect(check).to be_falsey
      end
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
      new_course = course_factory
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
      new_course = course_factory(:account => new_root_account)
      expect { template.add_child_course!(new_course) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "master_migrations" do
    it "should be able to create a migration" do
      template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      mig = template.master_migrations.create!
      expect(mig.master_template).to eq template
    end
  end

  describe "preload_index_data" do
    it "should preload child subscription counts and last_export_completed_at" do
      t1 = MasterCourses::MasterTemplate.set_as_master_course(@course)
      t2 = MasterCourses::MasterTemplate.set_as_master_course(Course.create!)
      t3 = MasterCourses::MasterTemplate.set_as_master_course(Course.create!)

      t1.add_child_course!(Course.create!)
      3.times do
        t2.add_child_course!(Course.create!)
      end

      time1 = 2.days.ago
      time2 = 1.day.ago
      t1.master_migrations.create!(:imports_completed_at => time1, :workflow_state => 'completed')
      t1.master_migrations.create!(:imports_completed_at => time2, :workflow_state => 'completed')
      t2.master_migrations.create!(:imports_completed_at => time1, :workflow_state => 'completed')

      MasterCourses::MasterTemplate.preload_index_data([t1, t2, t3])

      expect(t1.child_course_count).to eq 1
      expect(t2.child_course_count).to eq 3
      expect(t3.child_course_count).to eq 0

      expect(t1.instance_variable_get(:@last_export_completed_at)).to eq time2
      expect(t2.instance_variable_get(:@last_export_completed_at)).to eq time1
      expect(t3.instance_variable_defined?(:@last_export_completed_at)).to be_truthy
      expect(t3.instance_variable_get(:@last_export_completed_at)).to be_nil
    end
  end
end
