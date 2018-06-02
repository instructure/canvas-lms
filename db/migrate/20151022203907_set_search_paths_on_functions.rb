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

class SetSearchPathsOnFunctions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    set_search_path("delayed_jobs_after_delete_row_tr_fn", "()")
    set_search_path("delayed_jobs_before_insert_row_tr_fn", "()")
    set_search_path("half_md5_as_bigint", "(varchar)")
  end

  def down
    set_search_path("delayed_jobs_after_delete_row_tr_fn", "()", "DEFAULT")
    set_search_path("delayed_jobs_before_insert_row_tr_fn", "()", "DEFAULT")
    set_search_path("half_md5_as_bigint", "(varchar)", "DEFAULT")
  end
end
