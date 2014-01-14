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

    attachCollection: ->
      @collection.on('change:hidden', @render)

    render: ->
      super
      @$el.find('.no_content').toggle(@isEmpty())
      @

    renderItem: (model) =>
      return if model.get 'hidden'
      super
