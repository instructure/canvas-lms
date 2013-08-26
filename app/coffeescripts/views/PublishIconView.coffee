define [
  'compiled/views/PublishButtonView'
], (PublishButtonView) ->

  class PublishIconView extends PublishButtonView
    publishClass: 'publish-icon-publish'
    publishedClass: 'publish-icon-published'
    unpublishClass: 'publish-icon-unpublish'

    tagName: 'span'
    className: 'publish-icon'

    setElement: ->
      super
      @$el.attr 'data-tooltip', ''

