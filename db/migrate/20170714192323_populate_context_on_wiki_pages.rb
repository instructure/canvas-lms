class PopulateContextOnWikiPages < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    DataFixup::PopulateContextOnWikiPages.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :strand => "populate_wiki_page_context_#{Shard.current.database_server.id}")
  end
end
