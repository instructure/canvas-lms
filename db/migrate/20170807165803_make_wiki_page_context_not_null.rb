class MakeWikiPageContextNotNull < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    change_column_null :wiki_pages, :context_type, false
    change_column_null :wiki_pages, :context_id, false
  end
end
