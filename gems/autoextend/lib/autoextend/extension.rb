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

require "tsort"

module Autoextend
  Extension = Struct.new(:const_name,
                         :module,
                         :method, # rubocop:disable Lint/StructNewOverride
                         :block,
                         :singleton,
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

    def extend(const)
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
        target.public_send(method, mod)
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

    def tsort_each_node(&)
      @list.each(&)
    end

    def tsort_each_child(node, &)
      node.after.map { |after_module| @list.find { |ext| ext.module_name == after_module } }.each(&)
    end
  end
end
