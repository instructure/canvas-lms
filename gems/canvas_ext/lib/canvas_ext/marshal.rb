# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module CanvasExt
  module Marshal
    # load the class if Rails has not loaded it yet
    def load(*args)
      viewed_class_names = []

      begin
        super
      rescue ArgumentError => e
        if e.message =~ %r{undefined class/module (.+)}
          class_name = $1
          raise e if viewed_class_names.include?(class_name)

          viewed_class_names << class_name
          retry if class_name.constantize
        else
          raise
        end
      end
    end
  end
end

Marshal.singleton_class.prepend(CanvasExt::Marshal)
