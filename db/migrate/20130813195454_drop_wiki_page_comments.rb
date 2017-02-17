class DropWikiPageComments < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    drop_table :wiki_page_comments
  end

  def self.down
  end
end
