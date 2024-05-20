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

module Autoextend
  @trace = TracePoint.trace(:end) do |tp|
    const = tp.binding.receiver
    next unless const.name

    TracePoint.allow_reentry do
      extensions_list = extensions_hash.fetch(const.name.to_sym, [])
      sorted_extensions(extensions_list).each do |extension|
        extension.extend(const)
      end
    end
  end

  class << self
    # Add a hook to automatically extend a class or module with a module,
    # or by calling a block, when it is extended (module or class)
    # or defined (class only).
    #
    #   Autoextend.hook(:User, :MyUserExtension)
    #
    #   Autoextend.hook(:User, :"MyUserExtension::ClassMethods", singleton: true)
    #
    #   Autoextend.hook(:User) do |klass|
    #     klass.include MyUserExtension
    #   end
    #
    # If User is already defined, it will immediately include
    # the MyUserExtension module into it. It then sets up a hook
    # to automatically include in User if it becomes defined again
    # (like from ActiveSupport reloading).
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
