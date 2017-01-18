module DataFixup::FixImportedWikiPageWorkflow
  # finds unpublished wiki pages that are linked to active content_tags
  def self.broken_wiki_page_scope
    WikiPage.joins("INNER JOIN #{ContentTag.quoted_table_name} ON content_tags.content_id = wiki_pages.id"
    ).where(["content_tags.content_type = ? AND content_tags.workflow_state = ? AND
      wiki_pages.workflow_state = ?", "WikiPage", "active", "unpublished"])
  end

  def self.run
    self.broken_wiki_page_scope.find_in_batches do |wiki_pages|
      WikiPage.where(:id => wiki_pages).update_all(:workflow_state => 'active')
    end
  end
end
