require 'minitest/autorun'
require 'autoextend'

describe Autoextend::ObjectMethods do
  before do
    module AutoextendSpec; end
  end

  after do
    Object.send(:remove_const, :AutoextendSpec)
    Autoextend.extensions.reject! { |k, _| k =~ /^AutoextendSpec::/ }
  end

  it "should autoextend a class afterwards" do
    module AutoextendSpec::MyExtension; end
    autoextend_class(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension", :include)
    defined?(AutoextendSpec::Class).must_equal nil
    class AutoextendSpec::Class; end
    AutoextendSpec::Class.ancestors.must_include AutoextendSpec::MyExtension
  end

  it "should autoextend an already defined class" do
    class AutoextendSpec::Class; end
    module AutoextendSpec::MyExtension; end
    autoextend_class(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension", :include)
    AutoextendSpec::Class.ancestors.must_include AutoextendSpec::MyExtension
  end

  it "should call a block" do
    called = 42
    autoextend_class(:"AutoextendSpec::Class") { AutoextendSpec::Class.instance_variable_set(:@called, called) }
    defined?(AutoextendSpec::Class).must_equal nil
    class AutoextendSpec::Class; end

    AutoextendSpec::Class.instance_variable_get(:@called).must_equal 42
  end
end
