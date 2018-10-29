//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import Backbone from 'Backbone'
import FeatureFlagDialog from '../feature_flags/FeatureFlagDialog'
import template from 'jst/feature_flags/featureFlag'

export default class FeatureFlagView extends Backbone.View {
  static initClass() {
    this.prototype.tagName = 'li'

    this.prototype.className = 'feature-flag'

    this.prototype.template = template

    this.prototype.els = {'.element_toggler i': '$detailToggle'}

    this.prototype.events = {
      'change .ff_button': 'onClickThreeState',
      'change .ff_toggle': 'onClickToggle',
      'click .element_toggler': 'onToggleDetails',
      'keyclick .element_toggler': 'onToggleDetails'
    }
  }

  afterRender() {
    return this.$('.ui-buttonset').buttonset()
  }

  onClickThreeState(e) {
    const $target = $(e.currentTarget)
    const action = $target.data('action')
    return this.applyAction(action)
  }

  onClickToggle(e) {
    const $target = $(e.currentTarget)
    return this.applyAction($target.is(':checked') ? 'on' : 'off')
  }

  onToggleDetails(e) {
    return this.toggleDetailsArrow()
  }

  toggleDetailsArrow() {
    this.$detailToggle.toggleClass('icon-mini-arrow-right')
    return this.$detailToggle.toggleClass('icon-mini-arrow-down')
  }

  applyAction(action) {
    return $.when(this.canUpdate(action)).then(
      () => this.model.updateState(action),
      () => this.render() // undo UI change if user cancels
    )
  }

  canUpdate(action) {
    const deferred = $.Deferred()
    const warning = this.model.warningFor(action)
    if (!warning) return deferred.resolve()
    const view = new FeatureFlagDialog({
      deferred,
      message: warning.message,
      title: this.model.get('display_name'),
      hasCancelButton: !warning.locked
    })
    view.render()
    view.show()
    return deferred
  }
}
FeatureFlagView.initClass()
