require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

class MarshalTesting
  def self.const_missing(class_name)
    class_eval "class #{class_name}; end; #{class_name}"
  end
end

describe Marshal do
  it "should retry .load() when an 'undefined class/module ...' error is raised" do
    str = Marshal.dump(MarshalTesting::BlankClass.new)
    MarshalTesting.send :remove_const, "BlankClass"
    Marshal.load(str).should be_instance_of(MarshalTesting::BlankClass)
  end
end