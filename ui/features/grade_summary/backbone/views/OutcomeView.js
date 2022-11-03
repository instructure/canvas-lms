//
// Copyright (C) 2014 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import ProgressBarView from './ProgressBarView'
import OutcomePopoverView from './OutcomePopoverView'
import OutcomeDialogView from './OutcomeDialogView'
import template from '../../jst/outcome.handlebars'

class OutcomeView extends Backbone.View {
  initialize() {
    super.initialize(...arguments)
    return (this.progress = new ProgressBarView({model: this.model}))
  }

  afterRender() {
    this.popover = new OutcomePopoverView({
      el: this.$('.more-details'),
      model: this.model,
    })
    return (this.dialog = new OutcomeDialogView({
      model: this.model,
    }))
  }

  show(e) {
    return this.dialog.show(e)
  }

  toJSON() {
    return {
      ...super.toJSON(...arguments),
      progress: this.progress,
    }
  }
}

OutcomeView.prototype.className = 'outcome'
OutcomeView.prototype.tagName = 'li'
OutcomeView.prototype.template = template
OutcomeView.prototype.events = {
  'click .more-details': 'show',
  'keydown .more-details': 'show',
}

export default OutcomeView
