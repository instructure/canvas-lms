#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from '@canvas/backbone'
import _ from 'underscore'
import numberHelper from '@canvas/i18n/numberHelper'
import template from '../../jst/PeerReviewsSelector.handlebars'
import '../../jquery/toggleAccessibly'

export default class PeerReviewsSelector extends Backbone.View

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
  @optionProperty 'hideAnonymousPeerReview'

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
    peerReviewsFrozen: _.includes(frozenAttributes, 'peer_reviews')
    nested: @nested
    prefix: 'assignment' if @nested
    hideAnonymousPeerReview: @hideAnonymousPeerReview
    hasGroupCategory: @parentModel.groupCategoryId()
    intraGroupPeerReviews: @parentModel.intraGroupPeerReviews()

  getFormData: =>
    data = super
    data.peerReviewCount = numberHelper.parse(data.peerReviewCount)
    data
