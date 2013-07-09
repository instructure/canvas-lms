define [
  'compiled/views/PublishButtonView'
], (PublishButtonView) ->

  class PublishIconView extends PublishButtonView
    disabledClass: 'publish-icon-disabled'
    publishClass: 'publish-icon-publish'
    publishedClass: 'publish-icon-published'
    unpublishClass: 'publish-icon-unpublish'
    tagName: 'span'
    className: 'publish-icon'

    initialize: ->
      super
      @$el.attr 'data-tooltip', ''

