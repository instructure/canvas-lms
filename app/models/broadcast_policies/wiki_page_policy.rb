module BroadcastPolicies
  class WikiPagePolicy
    attr_reader :wiki_page

    def initialize(wiki_page)
      @wiki_page = wiki_page
    end

    def should_dispatch_updated_wiki_page?
      return false unless created_before?(30.minutes.ago)
      changed_while_published? || wiki_page.changed_state(:active)
    end

    def created_before?(time)
      wiki_page.created_at < time
    end

    def changed_while_published?
      wiki_page.published? &&
        wiki_page.wiki_page_changed &&
        wiki_page.prior_version
    end
  end
end
