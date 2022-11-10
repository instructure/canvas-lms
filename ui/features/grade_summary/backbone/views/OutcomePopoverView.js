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

/*
 * decaffeinate suggestions:
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */

import Backbone from '@canvas/backbone'
import Popover from 'jquery-popover'
import OutcomeLineGraphView from './OutcomeLineGraphView'
import template from '@canvas/outcomes/jst/outcomePopover.handlebars'

const TIMEOUT_LENGTH = 50

class OutcomePopoverView extends Backbone.View {
  constructor(...args) {
    super(...args)
    this.mouseenter = this.mouseenter.bind(this)
    this.mouseleave = this.mouseleave.bind(this)
  }

  initialize() {
    super.initialize(...arguments)
    return (this.outcomeLineGraphView = new OutcomeLineGraphView({
      model: this.model,
    }))
  }

  // Overrides
  render() {
    return template(this.toJSON())
  }

  // Instance methods
  closePopover(e) {
    e?.preventDefault()
    if (this.popover === null || typeof this.popover === 'undefined') return true
    this.popover.hide()
    return delete this.popover
  }

  mouseenter(e) {
    this.openPopover(e)
    this.inside = true
    return true
  }

  mouseleave(_e) {
    this.inside = false
    setTimeout(() => {
      if (!this.inside && this.popover) this.closePopover()
    }, TIMEOUT_LENGTH)
  }

  openPopover(e) {
    if (this.closePopover()) {
      this.popover = new Popover(e, this.render(), {
        verticalSide: 'bottom',
        manualOffset: 14,
      })
    }
    this.outcomeLineGraphView.setElement(this.popover.el.find('div.line-graph'))
    return this.outcomeLineGraphView.render()
  }
}

OutcomePopoverView.prototype.events = {
  'click i': 'mouseleave',
  'mouseenter i': 'mouseenter',
  'mouseleave i': 'mouseleave',
}
OutcomePopoverView.prototype.inside = false
OutcomePopoverView.prototype.TIMEOUT_LENGTH = TIMEOUT_LENGTH

OutcomePopoverView.optionProperty('el')
OutcomePopoverView.optionProperty('model')

export default OutcomePopoverView
