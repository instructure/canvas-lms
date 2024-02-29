//
// Copyright (C) 2015 - present Instructure, Inc.
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
import DialogBaseView from '@canvas/dialog-base-view'
import OutcomeLineGraphView from './OutcomeLineGraphView'
import template from '@canvas/outcomes/jst/outcomePopover.handlebars'

class OutcomeResultsDialogView extends DialogBaseView {
  constructor(...args) {
    super(...args)
    this.onClose = this.onClose.bind(this)
    this._getKey = this._getKey.bind(this)
  }

  initialize() {
    super.initialize(...arguments)
    return (this.outcomeLineGraphView = new OutcomeLineGraphView({
      model: this.model,
    }))
  }

  afterRender() {
    this.outcomeLineGraphView.setElement(this.$('div.line-graph'))
    return this.outcomeLineGraphView.render()
  }

  dialogOptions() {
    return {
      containerId: 'outcome_results_dialog',
      close: this.onClose,
      buttons: [],
      width: 460,
      modal: true,
      zIndex: 1000,
    }
  }

  show(e) {
    if (e.type !== 'click' && !this._getKey(e.keyCode)) return
    this.$target = $(e.target)
    e.preventDefault()
    this.$el.dialog('option', 'title', this.model.get('title'))
    super.show(...arguments)
    return this.render()
  }

  onClose() {
    this.$target.focus()
    delete this.$target
  }

  toJSON() {
    return {
      ...super.toJSON(...arguments),
      dialog: true,
    }
  }

  // Private
  _getKey(keycode) {
    const keys = {
      13: 'enter',
      32: 'spacebar',
    }
    return keys[keycode]
  }
}

OutcomeResultsDialogView.optionProperty('model')
OutcomeResultsDialogView.prototype.$target = null
OutcomeResultsDialogView.prototype.template = template

export default OutcomeResultsDialogView
