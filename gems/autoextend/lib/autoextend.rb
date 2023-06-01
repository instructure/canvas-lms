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

require_relative "autoextend/extension"
require_relative "autoextend/railtie" if defined?(Rails::Railtie)

module Autoextend
  class << self
    def const_added(const, source:, recursive: false)
      const_name = const.is_a?(String) ? const : const.name
      return [] unless const_name

      extensions_list = extensions_hash.fetch(const_name.to_sym, [])
      ret = sorted_extensions(extensions_list).each do |extension|
        if const == const_name
          const = Object.const_get(const_name, false)
        end
        extension.extend(const, source:)
      end

      if recursive
        const.constants(false).each do |child|
          # If the constant is set to autoload, don't accidentally autoload it
          # If we are processing a constant's parent while processing the child
          # the constant will be return by constants, but not defined, so just skip it
          next if const.autoload?(child) || !const.const_defined?(child, false)

          child_const = const.const_get(child, false)
          next unless child_const.is_a?(Module)

          const_added(child_const, source:, recursive: true)
        end
      end

      ret
    end

    # Add a hook to automatically extend a class or module with a module,
    # or by calling a block, when it is extended (module or class)
    # or defined (class only).
    #
    #   Autoextend.hook(:User, :MyUserExtension)
    #
    #   Autoextend.hook(:User, :"MyUserExtension::ClassMethods", singleton: true)
    #
    #   Autoextend.hook(:User) do |klass|
    #     klass.send(:include, MyUserExtension)
    #   end
    #
    # If User is already defined, it will immediately include
    # the MyUserExtension module into it. It then sets up a hook
    # to automatically include in User if it becomes defined again
    # (like from ActiveSupport reloading).
    #
    # Note that this hook happens before any methods have been
    # added to it, so you cannot directly modify anything you
    # expect to exist in the class. If you want to do that, you can
    # specify `after_load: true`, but this will only be compatible with
    # classes loaded via ActiveSupport's autoloading.
    #
    # Instead you should either use prepend with super, or
    # set up additional hooks to automatically modify methods
    # as they are added (if you use :include as your method)
    #
    # You can make an extension optional, which is for information only,
    # so that if you have a spec that checks if all extensions were used
    # it can ignore optional extensions.
    def hook(const_name,
             module_name = nil,
             method: :include,
             singleton: false,
             after_load: false,
             optional: false,
             before: [],
             after: [],
             &block)
      raise ArgumentError, "block is required if module_name is not passed" if !module_name && !block
      raise ArgumentError, "cannot pass both a module_name and a block" if module_name && block

      extension = Extension.new(const_name,
                                module_name,
                                method,
                                block,
                                singleton,
                                after_load,
                                optional,
                                Array(before),
                                Array(after))

      const_extensions = extensions_hash[const_name.to_sym] ||= []
      const_extensions << extension

      if module_name.is_a?(Module)
        module_name = module_name.name
      end

      # immediately extend the class if it's already defined
      # If autoload? is true, don't use const_defined? as it is set up to be autoloaded but hasn't been loaded yet
      module_chain = const_name.to_s.split("::").inject([]) { |all, val| all + [[(all.last ? "#{all.last.first}::#{all.last[1]}" : nil), val]] }
      exists_and_not_to_autoload = module_chain.all? do |mod, name|
        mod = mod.nil? ? Object : Object.const_get(mod)
        !mod.autoload?(name) && mod.const_defined?(name.to_s, false)
      end
      if exists_and_not_to_autoload
        extension.before.each do |before_module|
          if const_extensions.any? { |ext| ext.module_name == before_module }
            raise "Already included #{before_module}; cannot include #{module_name} first"
          end
        end
        extension.after.each do |after_module|
          unless const_extensions.any? { |ext| ext.module_name == after_module }
            raise "Could not find #{after_module}; cannot include #{module_name} after"
          end
        end
        extension.extend(Object.const_get(const_name.to_s, false))
      end
      nil
    end

    def extensions
      extensions_hash.values.flatten
    end

    def inject_into_zetwerk
      return unless Object.const_defined?(:Rails)

      Rails.autoloaders.each do |loader|
        loader.on_load do |_cpath, value, _abspath|
          next unless value.is_a?(Module)

          Autoextend.const_added(value, source: :Zeitwerk, recursive: true)
        end
      end
    end

    private

    def sorted_extensions(extensions_list)
      cloned_list = extensions_list.dup
      cloned_list.each do |ext|
        ext.before.each do |before_module|
          other_ext = cloned_list.find { |other| other.module_name == before_module }
          raise "Could not find #{before_module} to include after #{ext.module_name}" unless other_ext

          other_ext.after << ext.module_name
        end
        # This isn't needed to build the DAG, but it's useful for sanity
        ext.after.each do |after_module|
          other_ext = cloned_list.find { |other| other.module_name == after_module }
          raise "Could not find #{after_module} to include before #{ext.module_name}" unless other_ext

          other_ext.before << ext.module_name
        end
      end
      # Let's avoid having extra copies of things for no reason (makes debugging easier)
      cloned_list.each do |ext|
        ext.before.uniq!
        ext.after.uniq!
      end
      ExtensionArray.new(cloned_list).tsort
    end

    def extensions_hash
      @extensions ||= {}
    end
  end
end

module Autoextend::ClassMethods
  def inherited(klass)
    Autoextend.const_added(klass, source: :inherited)
    super
  end
end

# NOTE: Autoextend can't detect a module being defined,
# only when it gets included into a class.
module Autoextend::ModuleMethods
  def prepended(klass)
    Autoextend.const_added(self, source: :prepended).each do |extension|
      extension.extend(klass, source: :prepended)
    end
    super
  end

  def included(klass)
    Autoextend.const_added(self, source: :included).each do |extension|
      extension.extend(klass, source: :included)
    end
    super
  end
end

Module.prepend(Autoextend::ModuleMethods)
Class.prepend(Autoextend::ClassMethods)
