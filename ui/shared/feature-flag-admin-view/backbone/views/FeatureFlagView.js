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
import Backbone from '@canvas/backbone'
import FeatureFlagDialog from './FeatureFlagDialog'
import template from '../../jst/featureFlag.handlebars'
import I18n from 'i18n!feature_flags'

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
    this.$('.ui-buttonset').buttonset()
  }

  onClickThreeState(e) {
    const $target = $(e.currentTarget)
    const action = $target.data('action')
    this.applyAction(action)
  }

  onClickToggle(e) {
    const $target = $(e.currentTarget)
    this.applyAction($target.is(':checked') ? 'on' : 'off')
  }

  onToggleDetails() {
    this.toggleDetailsArrow()
  }

  toggleDetailsArrow() {
    this.$detailToggle.toggleClass('icon-mini-arrow-right')
    this.$detailToggle.toggleClass('icon-mini-arrow-down')
  }

  maybeReload(action) {
    const warning = this.model.warningFor(action)
    if (warning.reload_page) {
      window.location.reload()
    }
  }

  applyAction(action) {
    $.when(this.canUpdate(action)).then(
      () =>
        $.when(this.checkSiteAdmin()).then(
          () => this.model.updateState(action).then(() => this.maybeReload(action)),
          () => this.render() // undo UI change if user cancels
        ),
      () => this.render() // ditto
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

  checkSiteAdmin() {
    const deferred = $.Deferred()
    if (!this.model.isSiteAdmin()) {
      return deferred.resolve()
    }
    const view = new FeatureFlagDialog({
      deferred,
      message: I18n.t('This will affect every customer. Are you sure?'),
      title: this.model.get('display_name'),
      hasCancelButton: true
    })
    view.render()
    view.show()
    return deferred
  }
}
FeatureFlagView.initClass()
