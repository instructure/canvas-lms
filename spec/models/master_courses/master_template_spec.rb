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
end
