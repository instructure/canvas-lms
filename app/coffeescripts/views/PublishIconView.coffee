define [
  'compiled/views/PublishButtonView',
  'underscore'
], (PublishButtonView, _) ->

  class PublishIconView extends PublishButtonView
    publishClass: 'publish-icon-publish'
    publishedClass: 'publish-icon-published'
    unpublishClass: 'publish-icon-unpublish'

    tagName: 'span'
    className: 'publish-icon'

    # These values allow the default text to be overridden if necessary
    @optionProperty 'publishText'
    @optionProperty 'unpublishText'

    initialize: ->
      super
      @events = _.extend({}, PublishButtonView.prototype.events, @events)

    events: {'keyclick' : 'click'}
