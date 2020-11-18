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

require 'tsort'

module Autoextend
  Extension = Struct.new(:const_name,
      :module,
      :method,
      :block,
      :singleton,
      :after_load,
      :optional,
      :before,
      :after,
      :used) do
    # Once on ruby 2.5, use keyword_init: true for clarity

    def module_name
      if self.module.is_a?(Module)
        self.module.name
      else
        self.module.to_s
      end
    end

    def extend(const, source: nil)
      return if after_load && source == :inherited
      self.used = true

      target = singleton ? const.singleton_class : const
      if block
        block.call(target)
      else
        mod = if self.module.is_a?(Module)
                self.module
              else
                Object.const_get(self.module.to_s, false)
              end
        real_method = method
        # if we're hooking a module, and that module was included/prepended into
        # another module/class, we also get called on that class, so that the
        # extension can also be included into it. It won't otherwise have the
        # extension, because the extension target didn't have it when it was
        # included in the class
        if [:included, :prepended].include?(source) && const.name != const_name
          real_method = :include
        end
        target.send(real_method, mod)
      end
    end
  end
  # private_constant :Extension

  class ExtensionArray
    include TSort

    attr_reader :list

    def initialize(list)
      @list = list
    end

    def tsort_each_node(&block)
      @list.each(&block)
    end

    def tsort_each_child(node, &block)
      node.after.map { |after_module| @list.find { |ext| ext.module_name == after_module } }.each(&block)
    end
  end
end