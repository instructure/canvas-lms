require 'minitest/autorun'
require 'active_support'

# this is a weird thing we have to do to avoid a weird circular
# require problem
_x = ActiveSupport::Deprecation
ActiveSupport::Dependencies.autoload_paths << File.expand_path("..", __FILE__)
ActiveSupport::Dependencies.hook!

require 'autoextend'

describe Autoextend do
  before do
    module AutoextendSpec; end
  end

  after do
    Object.send(:remove_const, :AutoextendSpec)
    Autoextend.send(:extensions_hash).reject! { |k, _| k =~ /^AutoextendSpec::/ }
  end

  it "should autoextend a class afterwards" do
    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension")
    defined?(AutoextendSpec::Class).must_equal nil
    class AutoextendSpec::Class; end
    AutoextendSpec::Class.ancestors.must_include AutoextendSpec::MyExtension
  end

  it "should autoextend an already defined class" do
    class AutoextendSpec::Class; end
    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension")
    AutoextendSpec::Class.ancestors.must_include AutoextendSpec::MyExtension
  end

  it "should call a block" do
    called = 42
    Autoextend.hook(:"AutoextendSpec::Class") { AutoextendSpec::Class.instance_variable_set(:@called, called) }
    defined?(AutoextendSpec::Class).must_equal nil
    class AutoextendSpec::Class; end

    AutoextendSpec::Class.instance_variable_get(:@called).must_equal 42
  end

  describe "modules" do
    it "should insert a prepended module _after_ the hooked module on first definition" do
      module AutoextendSpec::M1; end
      module AutoextendSpec::M2; end
      Autoextend.hook(:"AutoextendSpec::M1", :"AutoextendSpec::M2", method: :prepend)
      class AutoextendSpec::Class
        singleton_class.include(AutoextendSpec::M1)
      end
      # M2 is _before_ M1, but _after_ Class
      AutoextendSpec::Class.singleton_class.ancestors.must_equal [
        AutoextendSpec::Class.singleton_class,
        AutoextendSpec::M2,
        AutoextendSpec::M1
      ] + Object.singleton_class.ancestors

    end
  end

  it "should allow extending with a module instead of a module name" do
    class AutoextendSpec::Class; end
    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", AutoextendSpec::MyExtension)
    AutoextendSpec::Class.ancestors.must_include AutoextendSpec::MyExtension
  end

  # yes, this whole spec is awful and pollutes global state,
  # but it's just one spec, and this file is small and should never
  # be run in the same process as other specs
  describe "ActiveSupport" do
    it "should hook an autoloaded module" do
      hooked = 0
      Autoextend.hook(:"AutoextendSpec::TestModule") do
        hooked += 1
      end
      Autoextend.hook(:"AutoextendSpec::TestModule::Nested") do
        hooked += 1
      end
      defined?(AutoextendSpec::TestModule).must_equal(nil)
      hooked.must_equal(0)
      _x = AutoextendSpec::TestModule
      # this could have only been detected by Rails' autoloading
      defined?(AutoextendSpec::TestModule).must_equal('constant')
      hooked.must_equal(2)
    end
  end
end
