module DataFixup::SetWikiHasNoFrontPage
  def self.run
    while Wiki.where(:has_no_front_page => nil, :front_page_url => nil).
      where("NOT EXISTS (?)", WikiPage.where("id=wiki_pages.wiki_id AND wiki_pages.url = ?",
            Wiki::DEFAULT_FRONT_PAGE_URL)).
      limit(1000).update_all(:has_no_front_page => true) > 0
    end
  end
end
