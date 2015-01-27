define [
  'Backbone'
  'underscore'
  'jquery'
  'jst/assignments/PeerReviewsSelector'
  'compiled/jquery/toggleAccessibly'
], (Backbone, _, $, template, toggleAccessibly) ->

  class PeerReviewsSelector extends Backbone.View

    template: template

    PEER_REVIEWS_ASSIGN_AT    = '#assignment_peer_reviews_assign_at'
    PEER_REVIEWS              = '#assignment_peer_reviews'
    MANUAL_PEER_REVIEWS       = '#assignment_manual_peer_reviews'
    AUTO_PEER_REVIEWS         = '#assignment_automatic_peer_reviews'
    PEER_REVIEWS_DETAILS      = '#peer_reviews_details'
    AUTO_PEER_REVIEWS_OPTIONS = '#automatic_peer_reviews_options'
    ANONYMOUS_PEER_REVIEWS    = '#anonymous_peer_reviews'

    events: do ->
      events = {}
      events["change #{PEER_REVIEWS}"] = 'handlePeerReviewsChange'
      events["change #{MANUAL_PEER_REVIEWS}"] = 'handleAutomaticPeerReviewsChange'
      events["change #{AUTO_PEER_REVIEWS}"] = 'handleAutomaticPeerReviewsChange'
      events

    els: do ->
      els = {}
      els["#{PEER_REVIEWS_ASSIGN_AT}"] = '$peerReviewsAssignAt'
      els["#{PEER_REVIEWS}"] = '$peerReviews'
      els["#{PEER_REVIEWS_DETAILS}"] = '$peerReviewsDetails'
      els["#{AUTO_PEER_REVIEWS}"] = '$autoPeerReviews'
      els["#{AUTO_PEER_REVIEWS_OPTIONS}"] = '$autoPeerReviewsOptions'
      els

    @optionProperty 'parentModel'
    @optionProperty 'nested'

    handlePeerReviewsChange: =>
      @$peerReviewsDetails.toggleAccessibly @$peerReviews.prop('checked')

    handleAutomaticPeerReviewsChange: =>
      @$autoPeerReviewsOptions.toggleAccessibly(@$autoPeerReviews.filter(':checked').val() is '1')

    afterRender: =>
      @$peerReviewsAssignAt.datetime_field()

    toJSON: =>
      frozenAttributes = @parentModel.frozenAttributes()

      anonymousPeerReviews: @parentModel.anonymousPeerReviews()
      peerReviews: @parentModel.peerReviews()
      automaticPeerReviews: @parentModel.automaticPeerReviews()
      peerReviewCount: @parentModel.peerReviewCount()
      peerReviewsAssignAt: @parentModel.peerReviewsAssignAt()
      frozenAttributes: frozenAttributes
      peerReviewsFrozen: _.include(frozenAttributes, 'peer_reviews')
      nested: @nested
      prefix: 'assignment' if @nested
