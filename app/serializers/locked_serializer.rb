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

# If you set the serializer option "skip_lock_tests" to true, then this mixin
# will not add any of its fields.
module LockedSerializer
  include Canvas::LockExplanation
  extend Forwardable

  def_delegators :@controller,
                 :course_context_modules_url,
                 :course_context_module_prerequisites_needing_finishing_path

  def lock_info
    locked_for_hash
  end

  def lock_explanation
    super(lock_info, locked_for_json_type, context, include_js: false)
  end

  def locked_for_user
    !!locked_for_hash
  end

  private

  def locked_for_hash
    return @_locked_for_hash unless @_locked_for_hash.nil?

    @_locked_for_hash = (
      if scope && object.respond_to?(:locked_for?)
        context = object.try(:context)
        object.locked_for?(scope, check_policies: true, context:)
      else
        false
      end
    )
  end

  def filter(keys)
    excluded = if serializer_option(:skip_lock_tests)
                 %i[lock_info lock_explanation locked_for_user]
               elsif !locked_for_hash
                 [:lock_info, :lock_explanation]
               else
                 []
               end

    keys - excluded
  end
end
