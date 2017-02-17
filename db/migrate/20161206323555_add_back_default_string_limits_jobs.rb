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
