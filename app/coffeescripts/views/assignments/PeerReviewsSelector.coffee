define [
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/PeerReviewsSelector'
], (Backbone, _, $, template) ->

  class PeerReviewsSelector extends Backbone.View

    template: template

    PEER_REVIEWS_ASSIGN_AT = '[name="peer_reviews_assign_at"]'
    PEER_REVIEWS = '[name="peer_reviews"]'
    AUTO_PEER_REVIEWS = '[name="automatic_peer_reviews"]'
    PEER_REVIEWS_DETAILS = '#peer_reviews_details'
    AUTO_PEER_REVIEWS_OPTIONS = '#automatic_peer_reviews_options'

    initialize: ->
      super
      @parentModel = @options.parentModel

    events: do ->
      events = {}
      events[ "change #{PEER_REVIEWS}" ] = 'handlePeerReviewsChange'
      events[ "change #{AUTO_PEER_REVIEWS}" ] = 'handleAutomaticPeerReviewsChange'
      events

    handlePeerReviewsChange: =>
      @showAccessibly @$peerReviewsDetails, @$peerReviews.prop('checked')

    handleAutomaticPeerReviewsChange: =>
      @showAccessibly(@$autoPeerReviewsOptions, @$autoPeerReviews.filter(':checked').val() is '1')

    render: =>
      super
      @_findElements()
      @_attachDatepickerToDateFields()
      this

    toJSON: =>
      peerReviews: @parentModel.peerReviews()
      automaticPeerReviews: @parentModel.automaticPeerReviews()
      peerReviewCount: @parentModel.peerReviewCount()
      peerReviewsAssignAt: @parentModel.peerReviewsAssignAt()
      frozenAttributes: @parentModel.frozenAttributes()

    _attachDatepickerToDateFields: =>
      @$peerReviewsAssignAt.datetime_field()

    _findElements: =>
      @$peerReviewsAssignAt = @find PEER_REVIEWS_ASSIGN_AT
      @$peerReviews = @find PEER_REVIEWS
      @$peerReviewsDetails = @find PEER_REVIEWS_DETAILS
      @$autoPeerReviews = @find AUTO_PEER_REVIEWS
      @$autoPeerReviewsOptions = @find AUTO_PEER_REVIEWS_OPTIONS

    find: (selector) => @$el.find selector

    showAccessibly: ($element, visible) ->
      if visible
        $element.show()
        $element.attr('aria-expanded', 'true')
      else
        $element.hide()
        $element.attr('aria-expanded', 'false')
