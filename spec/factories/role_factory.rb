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

module Factories
  def custom_role(base, name, opts = {})
    account = opts[:account] || @account
    role = account.roles.where(name:).first_or_initialize
    role.base_role_type = base
    role.save!
    role
  end

  def custom_student_role(name, opts = {})
    custom_role("StudentEnrollment", name, opts)
  end

  def custom_teacher_role(name, opts = {})
    custom_role("TeacherEnrollment", name, opts)
  end

  def custom_ta_role(name, opts = {})
    custom_role("TaEnrollment", name, opts)
  end

  def custom_designer_role(name, opts = {})
    custom_role("DesignerEnrollment", name, opts)
  end

  def custom_observer_role(name, opts = {})
    custom_role("ObserverEnrollment", name, opts)
  end

  def custom_account_role(name, opts = {})
    custom_role(Role::DEFAULT_ACCOUNT_TYPE, name, opts)
  end

  def student_role(root_account_id: Account.default.id)
    Role.get_built_in_role("StudentEnrollment", root_account_id:)
  end

  def teacher_role(root_account_id: Account.default.id)
    Role.get_built_in_role("TeacherEnrollment", root_account_id:)
  end

  def ta_role(root_account_id: Account.default.id)
    Role.get_built_in_role("TaEnrollment", root_account_id:)
  end

  def designer_role(root_account_id: Account.default.id)
    Role.get_built_in_role("DesignerEnrollment", root_account_id:)
  end

  def observer_role(root_account_id: Account.default.id)
    Role.get_built_in_role("ObserverEnrollment", root_account_id:)
  end

  def admin_role(root_account_id: Account.default.id)
    Role.get_built_in_role("AccountAdmin", root_account_id:)
  end
end
