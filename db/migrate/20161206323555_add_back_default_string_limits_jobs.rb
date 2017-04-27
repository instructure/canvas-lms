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

class AddBackDefaultStringLimitsJobs < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    drop_triggers

    add_string_limit_if_missing :delayed_jobs, :queue
    add_string_limit_if_missing :delayed_jobs, :locked_by
    add_string_limit_if_missing :delayed_jobs, :tag
    add_string_limit_if_missing :delayed_jobs, :strand
    add_string_limit_if_missing :delayed_jobs, :source

    add_string_limit_if_missing :failed_jobs, :queue
    add_string_limit_if_missing :failed_jobs, :locked_by
    add_string_limit_if_missing :failed_jobs, :tag
    add_string_limit_if_missing :failed_jobs, :strand
    add_string_limit_if_missing :failed_jobs, :source

    readd_triggers
  end

  def drop_triggers
    execute %{DROP TRIGGER delayed_jobs_before_insert_row_tr ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name}}
    execute %{DROP TRIGGER delayed_jobs_after_delete_row_tr ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name}}
  end

  def readd_triggers
    execute("CREATE TRIGGER delayed_jobs_before_insert_row_tr BEFORE INSERT ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} FOR EACH ROW WHEN (NEW.strand IS NOT NULL) EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_before_insert_row_tr_fn')}()")
    execute("CREATE TRIGGER delayed_jobs_after_delete_row_tr AFTER DELETE ON #{Delayed::Backend::ActiveRecord::Job.quoted_table_name} FOR EACH ROW WHEN (OLD.strand IS NOT NULL AND OLD.next_in_strand = 't') EXECUTE PROCEDURE #{connection.quote_table_name('delayed_jobs_after_delete_row_tr_fn')}()")
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
