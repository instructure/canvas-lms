# frozen_string_literal: true

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

require "active_support"

# this is a weird thing we have to do to avoid a weird circular
# require problem
_x = ActiveSupport::Deprecation
ActiveSupport::Dependencies.autoload_paths << File.expand_path("autoload", __dir__)
ActiveSupport::Dependencies.hook!

require "autoextend"

# CANVAS_RAILS="6.1" this pattern will need reworking in a rails >= 7.0 world
require "zeitwerk"
require "rails"
Rails.application = Class.new do
  def self.config
    Class.new do
      def self.autoloader
        :zeitwerk
      end
    end
  end
end
require "active_support/dependencies/zeitwerk_integration"
ActiveSupport::Dependencies::ZeitwerkIntegration.take_over(enable_reloading: true)
# In an actual rails app this is handled by an initializer through railties
Autoextend.inject_into_zetwerk

# rubocop:disable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration, Lint/EmptyClass
# these specs needs to work with real constants, because we're testing the hooking
# of constants being defined
describe Autoextend do
  before do
    module AutoextendSpec
      module PrependHelper
        def self.register_prepend(klass, id)
          prepend_order = klass.class_variable_defined?(:@@prepend_order) ? klass.class_variable_get(:@@prepend_order) : []
          prepend_order << id
          klass.class_variable_set(:@@prepend_order, prepend_order)
        end
      end

      module Prepend1
        def self.prepended(klass)
          PrependHelper.register_prepend(klass, 1)
        end
      end

      module Prepend2
        def self.prepended(klass)
          PrependHelper.register_prepend(klass, 2)
        end
      end

      module Prepend3
        def self.prepended(klass)
          PrependHelper.register_prepend(klass, 3)
        end
      end

      module PrependExistingMethod
        def self.prepended(klass)
          klass.a_method
        end

        def b_method
          true
        end
      end
    end
  end

  after do
    Object.send(:remove_const, :AutoextendSpec)
    Autoextend.send(:extensions_hash).reject! { |k, _| k =~ /^AutoextendSpec::/ }
    ActiveSupport::Dependencies.clear
  end

  it "autoextends a class afterwards" do
    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension")
    expect(defined?(AutoextendSpec::Class)).to eq nil
    class AutoextendSpec::Class; end
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
  end

  it "autoextends an already defined class" do
    class AutoextendSpec::Class; end

    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", :"AutoextendSpec::MyExtension")
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
  end

  it "calls a block" do
    called = 42
    Autoextend.hook(:"AutoextendSpec::Class") { AutoextendSpec::Class.instance_variable_set(:@called, called) }
    expect(defined?(AutoextendSpec::Class)).to equal nil
    class AutoextendSpec::Class; end

    expect(AutoextendSpec::Class.instance_variable_get(:@called)).to equal 42
  end

  describe "modules" do
    it "inserts a prepended module _after_ the hooked module on first definition" do
      module AutoextendSpec::M1; end

      module AutoextendSpec::M2; end
      Autoextend.hook(:"AutoextendSpec::M1", :"AutoextendSpec::M2", method: :prepend)
      class AutoextendSpec::Class
        singleton_class.include(AutoextendSpec::M1)
      end
      # M2 is _before_ M1, but _after_ Class
      expect(AutoextendSpec::Class.singleton_class.ancestors).to eq [
        AutoextendSpec::Class.singleton_class,
        AutoextendSpec::M2,
        AutoextendSpec::M1
      ] + Object.singleton_class.ancestors
    end
  end

  describe "ordering" do
    describe "manually-loaded classes" do
      it "raises an error for unfufilliable after constraints" do
        module AutoextendSpec::Ordering; end
        expect do
          Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend3", method: :prepend, after: "AutoextendSpec::Prepend2")
          Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend2", method: :prepend)
        end.to raise_error(/Could not find/)
      end

      it "raises an error for unfufilliable before constraints" do
        module AutoextendSpec::Ordering; end
        expect do
          Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend2", method: :prepend)
          Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend1", method: :prepend, before: "AutoextendSpec::Prepend2")
        end.to raise_error(/Already included/)
      end

      it "includes in the correct order" do
        module AutoextendSpec::Ordering; end

        Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend1", method: :prepend, before: "AutoextendSpec::Prepend2")
        Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend2", method: :prepend)
        Autoextend.hook(:"AutoextendSpec::Ordering", :"AutoextendSpec::Prepend3", method: :prepend, after: "AutoextendSpec::Prepend2")

        expect(AutoextendSpec::Ordering.class_variable_get(:@@prepend_order)).to eq([1, 2, 3])
      end
    end

    describe "auto-loaded classes" do
      it "raises an error for unfufilliable after constraints" do
        Autoextend.hook(:"AutoextendSpec::TestModule", :"AutoextendSpec::Prepend3", method: :prepend, after: "AutoextendSpec::Prepend2")

        expect { _x = AutoextendSpec::TestModule }.to raise_error(/Could not find/)
      end

      it "raises an error for unfufilliable before constraints" do
        Autoextend.hook(:"AutoextendSpec::TestModule", :"AutoextendSpec::Prepend1", method: :prepend, before: "AutoextendSpec::Prepend2")

        expect { _x = AutoextendSpec::TestModule }.to raise_error(/Could not find/)
      end

      it "includes in the correct order" do
        Autoextend.hook(:"AutoextendSpec::TestModule", :"AutoextendSpec::Prepend1", method: :prepend, before: "AutoextendSpec::Prepend2")
        Autoextend.hook(:"AutoextendSpec::TestModule", :"AutoextendSpec::Prepend2", method: :prepend)
        Autoextend.hook(:"AutoextendSpec::TestModule", :"AutoextendSpec::Prepend3", method: :prepend, after: "AutoextendSpec::Prepend2")

        expect(AutoextendSpec::TestModule.class_variable_get(:@@prepend_order)).to eq([1, 2, 3])
      end
    end
  end

  it "allows extending with a module instead of a module name" do
    class AutoextendSpec::Class; end

    module AutoextendSpec::MyExtension; end
    Autoextend.hook(:"AutoextendSpec::Class", AutoextendSpec::MyExtension)
    expect(AutoextendSpec::Class.ancestors).to include AutoextendSpec::MyExtension
  end

  describe "ActiveSupport" do
    it "hooks an autoloaded module" do
      hooked = 0
      Autoextend.hook(:"AutoextendSpec::TestModule") do
        hooked += 1
      end
      Autoextend.hook(:"AutoextendSpec::TestModule::Nested") do
        hooked += 1
      end
      expect(AutoextendSpec.autoload?(:TestModule)).not_to be_nil
      expect(hooked).to equal(0)
      _x = AutoextendSpec::TestModule
      # this could have only been detected by Rails' autoloading
      expect(AutoextendSpec.autoload?(:TestModule)).to be_nil
      expect(hooked).to equal(2)
    end

    it "hooks an autoloaded module after_load" do
      # This method will call an existing method on load
      Autoextend.hook(:"AutoextendSpec::TestLaterMethod", :"AutoextendSpec::PrependExistingMethod", method: :prepend, after_load: true)
      expect(AutoextendSpec::TestLaterMethod.new.b_method).to eq(true)
    end
  end
end
# rubocop:enable Lint/ConstantDefinitionInBlock, RSpec/LeakyConstantDeclaration, Lint/EmptyClass
