require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe DataFixup::RemoveOrphanedContextModuleProgressions do
  it "should work" do
    c1 = Course.create!
    c2 = Course.create!
    cm1 = c1.context_modules.create!
    cm2 = c2.context_modules.create!
    u = User.create!
    c1.enroll_student(u)
    cmp1 = cm1.context_module_progressions.create!(user: u)
    cmp2 = cm2.context_module_progressions.create!(user: u)

    DataFixup::RemoveOrphanedContextModuleProgressions.run

    cmp1.reload
    expect { cmp2.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
