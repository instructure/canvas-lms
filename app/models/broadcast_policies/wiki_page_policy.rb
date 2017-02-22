module BroadcastPolicies
  class WikiPagePolicy
    attr_reader :wiki_page

    def initialize(wiki_page)
      @wiki_page = wiki_page
    end

    def should_dispatch_updated_wiki_page?
      if wiki_page.wiki && wiki_page.wiki.context
        return false if wiki_page.wiki.context.concluded?
        return false if wiki_page.wiki.context.respond_to?(:unpublished?) && wiki_page.wiki.context.unpublished?
      end
      return false unless created_before?(1.minutes.ago)
      changed_while_published? || wiki_page.changed_state(:active)
    end

    def created_before?(time)
      wiki_page.created_at < time
    end

    def changed_while_published?
      wiki_page.published? &&
        wiki_page.wiki_page_changed &&
        !wiki_page.just_created
    end
  end
end
