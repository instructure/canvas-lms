# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# monkey patches to discourage people writing horribly slow specs

Course.prepend(Module.new {
  def enroll_user(*)
    Course.enroll_user_call_count += 1
    max_calls = 10
    return super if Course.enroll_user_call_count <= max_calls
    raise "`enroll_user` is slow; if your spec needs more than #{max_calls} enrolled users you should use `create_users_in_course` instead"
  end
})
Course.singleton_class.class_eval do
  attr_accessor :enroll_user_call_count
end

