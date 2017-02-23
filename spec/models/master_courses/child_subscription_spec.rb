require 'spec_helper'

describe MasterCourses::ChildSubscription do
  describe "is_child_course?" do
    before :once do
      mc = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(mc)
      course_factory
    end

    def check
      MasterCourses::ChildSubscription.is_child_course?(@course)
    end

    it "should cache the result" do
      enable_cache do
        expect(check).to be_falsey
        MasterCourses::ChildSubscription.expects(:where).never
        expect(check).to be_falsey
        expect(MasterCourses::ChildSubscription.is_child_course?(@course.id)).to be_falsey # should work with ids too
      end
    end

    it "should invalidate the cache when set/unset as master course" do
      enable_cache do
        expect(check).to be_falsey
        sub = @template.add_child_course!(@course) # invalidate on create
        expect(check).to be_truthy
        sub.destroy
        expect(check).to be_falsey
      end
    end
  end

  describe "migration id invalidation" do
    it "should deactivate and reactivate migration ids for course content" do
      master_course = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(master_course)
      child_course = course_factory
      sub = @template.add_child_course!(@course)

      original_page = master_course.wiki.wiki_pages.create!(:title => "blah")
      mc_tag = @template.create_content_tag_for!(original_page)

      page_copy = child_course.wiki.wiki_pages.create!(:title => "blah", :migration_id => mc_tag.migration_id)
      child_tag = sub.create_content_tag_for!(page_copy)

      sub.destroy!
      expect(page_copy.reload.migration_id).to eq (sub.deactivation_prefix + mc_tag.migration_id)
      expect(child_tag.reload.migration_id).to eq (sub.deactivation_prefix + mc_tag.migration_id)

      sub.undestroy
      expect(page_copy.reload.migration_id).to eq mc_tag.migration_id
      expect(child_tag.reload.migration_id).to eq mc_tag.migration_id
    end
  end
end
