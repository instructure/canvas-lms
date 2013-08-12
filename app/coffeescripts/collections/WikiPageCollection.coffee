define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/WikiPage'
], (PaginatedCollection, WikiPage) ->

  class WikiPageCollection extends PaginatedCollection
    model: WikiPage

    initialize: ->
      super

      # remove the front_page indicator on all other models when one is set
      @on 'change:front_page', (model, value) =>
        # only change other models if one of the models is being set to true
        return if !value

        for m in @filter((m) -> !!m.get('front_page'))
          m.set('front_page', false) if m != model
