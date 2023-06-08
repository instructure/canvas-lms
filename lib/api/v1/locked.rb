# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
#

module Api::V1::Locked
  include ApplicationHelper

  def locked_json(hash, object, user, type, options = {})
    context = object.context if object.respond_to?(:context)
    locked = nil
    locked = object.locked_for?(user, { check_policies: true, context: }.merge(options)) if object.respond_to?(:locked_for?)

    hash[:locked_for_user] = !!locked
    if locked
      hash[:lock_info] = locked
      hash[:lock_explanation] = lock_explanation(locked, type, context)
    end
  end
end
