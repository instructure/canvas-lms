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

    it "should invalidate the cache when set as master course" do
      enable_cache do
        expect(check).to be_falsey
        template = @template.add_child_course!(@course) # invalidate on create
        expect(check).to be_truthy
      end
    end
  end
end
