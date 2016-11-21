class SetSearchPathsOnFunctions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.connection
    Delayed::Backend::ActiveRecord::Job.connection
  end

  def up
    set_search_path_on_function("delayed_jobs_after_delete_row_tr_fn", "()")
    set_search_path_on_function("delayed_jobs_before_insert_row_tr_fn", "()")
    set_search_path_on_function("half_md5_as_bigint", "(varchar)")
  end

  def down
    set_search_path_on_function("delayed_jobs_after_delete_row_tr_fn", "()", "DEFAULT")
    set_search_path_on_function("delayed_jobs_before_insert_row_tr_fn", "()", "DEFAULT")
    set_search_path_on_function("half_md5_as_bigint", "(varchar)", "DEFAULT")
  end
end
