#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
    expect(defined?(AutoextendSpec::Class)).to eq nil
    class AutoextendSpec::Class; end
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
  end

  it "should autoextend an already defined class" do
    class AutoextendSpec::Class; end
    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension")
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
  end

  it "should call a block" do
    called = 42
    Autoextend.hook(:"AutoextendSpec::Class") { AutoextendSpec::Class.instance_variable_set(:@called, called) }
    expect(defined?(AutoextendSpec::Class)).to equal nil
    class AutoextendSpec::Class; end

    expect(AutoextendSpec::Class.instance_variable_get(:@called)).to equal 42
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
      expect(AutoextendSpec::Class.singleton_class.ancestors). to eq [
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
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
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
      expect(defined?(AutoextendSpec::TestModule)).to equal(nil)
      expect(hooked).to equal(0)
      _x = AutoextendSpec::TestModule
      # this could have only been detected by Rails' autoloading
      expect(defined?(AutoextendSpec::TestModule)).to eq('constant')
      expect(hooked).to equal(2)
    end
  end
end
