# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# dummy methods
module Onceler
  module Noop
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def onceler!; end

      def before(scope = nil, &)
        scope = :each if scope == :once || scope.nil?
        return if scope == :record || scope == :replay

        super(scope, &)
      end

      def after(scope = nil, &)
        scope = :each if scope.nil?
        return if scope == :record || scope == :replay

        super(scope, &)
      end

      %w[let_once subject_once let_each let_each! subject_each subject_each!].each do |method|
        define_method(method) do |*args, &block|
          # make _once behave like !, because that's essentially what onceler is doing
          frd_method = method.sub(/_each!?\z/, "").sub(/_once!?\z/, "!")
          send frd_method, args.first, &block
        end
      end
    end
  end
end
