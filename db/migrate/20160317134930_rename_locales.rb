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

class RenameLocales < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  CHANGES = {
      'zh_Hant' => 'zh-Hant',
      'zh' => 'zh-Hans',
      'fa-IR' => 'fa'
  }.freeze

  def up
    CHANGES.each do |(old, new)|
      apply_change(old, new)
    end
  end

  def down
    CHANGES.each do |(new, old)|
      apply_change(old, new)
    end
  end

  def apply_change(old, new)
    Account.where(default_locale: old).update_all(default_locale: new)
    Course.where(locale: old).update_all(locale: new)
    User.where(locale: old).update_all(locale: new)
  end
end
