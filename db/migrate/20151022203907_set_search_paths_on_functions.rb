class SetSearchPathsOnFunctions < ActiveRecord::Migration
  tag :predeploy

  def set_search_path_on_function(function, args, search_path = Shard.current.name)
    execute("ALTER FUNCTION #{connection.quote_table_name(function)}#{args} SET search_path TO #{search_path}")
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
