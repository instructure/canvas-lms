define [
  'jquery'
  'underscore'
  'compiled/views/CollectionView'
  'compiled/views/PublishIconView'
  'jst/quizzes/QuizItemGroupView'
  'compiled/views/quizzes/QuizItemView'
], ($, _, CollectionView, PublishIconView, template, QuizItemView) ->

  class ItemGroupView extends CollectionView
    template: template
    itemView: QuizItemView

    tagName:   'div'
    className: 'item-group-condensed'

    events:
      'click .ig-header .element_toggler': 'clickHeader'

    clickHeader: (e) ->
      $(e.currentTarget).find('i')
        .toggleClass('icon-mini-arrow-down')
        .toggleClass('icon-mini-arrow-right')

    isEmpty: ->
      @collection.isEmpty() or @collection.all((m) -> m.get('hidden'))

    filterResults: (term) =>
      anyChanged = false
      @collection.forEach (model) =>
        hidden = !@filter(model, term)
        if !!model.get('hidden') != hidden
          anyChanged = true
          model.set('hidden', hidden)

      @render() if anyChanged

    filter: (model, term) =>
      return true unless term

      title = model.get('title').toLowerCase()
      numMatches = 0
      keys = term.toLowerCase().split(' ')
      for part in keys
        #not using match to avoid javascript string to regex oddness
        numMatches++ if title.indexOf(part) != -1
      numMatches == keys.length


    render: ->
      super
      @$el.find('.no_content').toggle(@isEmpty())
      @

    renderItem: (model) =>
      return if model.get 'hidden'
      super
