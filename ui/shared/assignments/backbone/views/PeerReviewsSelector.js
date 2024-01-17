/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {includes} from 'lodash'
import Backbone from '@canvas/backbone'
import numberHelper from '@canvas/i18n/numberHelper'
import template from '../../jst/PeerReviewsSelector.handlebars'
import '../../jquery/toggleAccessibly'

extend(PeerReviewsSelector, Backbone.View)

const PEER_REVIEWS_ASSIGN_AT = '#assignment_peer_reviews_assign_at'
const PEER_REVIEWS = '#assignment_peer_reviews'
const MANUAL_PEER_REVIEWS = '#assignment_manual_peer_reviews'
const AUTO_PEER_REVIEWS = '#assignment_automatic_peer_reviews'
const PEER_REVIEWS_DETAILS = '#peer_reviews_details'
const AUTO_PEER_REVIEWS_OPTIONS = '#automatic_peer_reviews_options'

function PeerReviewsSelector() {
  this.getFormData = this.getFormData.bind(this)
  this.toJSON = this.toJSON.bind(this)
  this.afterRender = this.afterRender.bind(this)
  this.handleAutomaticPeerReviewsChange = this.handleAutomaticPeerReviewsChange.bind(this)
  this.handlePeerReviewsChange = this.handlePeerReviewsChange.bind(this)
  return PeerReviewsSelector.__super__.constructor.apply(this, arguments)
}

PeerReviewsSelector.prototype.template = template

PeerReviewsSelector.prototype.events = (function () {
  const events = {}
  events['change ' + PEER_REVIEWS] = 'handlePeerReviewsChange'
  events['change ' + MANUAL_PEER_REVIEWS] = 'handleAutomaticPeerReviewsChange'
  events['change ' + AUTO_PEER_REVIEWS] = 'handleAutomaticPeerReviewsChange'
  return events
})()

PeerReviewsSelector.prototype.els = (function () {
  const els = {}
  els['' + PEER_REVIEWS_ASSIGN_AT] = '$peerReviewsAssignAt'
  els['' + PEER_REVIEWS] = '$peerReviews'
  els['' + PEER_REVIEWS_DETAILS] = '$peerReviewsDetails'
  els['' + AUTO_PEER_REVIEWS] = '$autoPeerReviews'
  els['' + AUTO_PEER_REVIEWS_OPTIONS] = '$autoPeerReviewsOptions'
  return els
})()

PeerReviewsSelector.optionProperty('parentModel')

PeerReviewsSelector.optionProperty('nested')

PeerReviewsSelector.optionProperty('hideAnonymousPeerReview')

PeerReviewsSelector.prototype.handlePeerReviewsChange = function () {
  return this.$peerReviewsDetails.toggleAccessibly(this.$peerReviews.prop('checked'))
}

PeerReviewsSelector.prototype.handleAutomaticPeerReviewsChange = function () {
  return this.$autoPeerReviewsOptions.toggleAccessibly(
    this.$autoPeerReviews.filter(':checked').val() === '1'
  )
}

PeerReviewsSelector.prototype.afterRender = function () {
  return this.$peerReviewsAssignAt.datetime_field()
}

PeerReviewsSelector.prototype.toJSON = function () {
  const frozenAttributes = this.parentModel.frozenAttributes()
  return {
    anonymousPeerReviews: this.parentModel.anonymousPeerReviews(),
    peerReviews: this.parentModel.peerReviews(),
    automaticPeerReviews: this.parentModel.automaticPeerReviews(),
    peerReviewCount: this.parentModel.peerReviewCount(),
    peerReviewsAssignAt: this.parentModel.peerReviewsAssignAt(),
    frozenAttributes,
    peerReviewsFrozen: includes(frozenAttributes, 'peer_reviews'),
    nested: this.nested,
    prefix: this.nested ? 'assignment' : void 0,
    hideAnonymousPeerReview: this.hideAnonymousPeerReview,
    hasGroupCategory: this.parentModel.groupCategoryId(),
    intraGroupPeerReviews: this.parentModel.intraGroupPeerReviews(),
  }
}

PeerReviewsSelector.prototype.getFormData = function () {
  const data = PeerReviewsSelector.__super__.getFormData.apply(this, arguments)
  data.peerReviewCount = numberHelper.parse(data.peerReviewCount)
  return data
}

export default PeerReviewsSelector
