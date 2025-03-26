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

import $ from 'jquery'
import Backbone from '@canvas/backbone'

class ExternalContentHomeworkSubmissionView extends Backbone.View {
  constructor(...args) {
    super(...args)
    this._relaunchTool = this._relaunchTool.bind(this)
    this._triggerCancel = this._triggerCancel.bind(this)
    this._triggerSubmit = this._triggerSubmit.bind(this)
    this._showPledgeError = this._showPledgeError.bind(this)
  }

  _relaunchTool(event) {
    event.preventDefault()
    event.stopPropagation()
    return this.trigger('relaunchTool', this.externalTool, this.model)
  }

  _triggerCancel(event) {
    event.preventDefault()
    event.stopPropagation()
    return this.trigger('cancel', this.externalTool, this.model)
  }

  _triggerSubmit(event) {
    event.preventDefault()
    event.stopPropagation()
    this.model.set('comment', this.$el.find('.submission_comment').val())
    const checkbox = document.getElementById('turnitin_pledge_external_content')
    if (checkbox && !checkbox.checked) {
      this.shouldShowPledgeError = true
      this._showPledgeError(checkbox)
    } else {
      return this.submitHomework()
    }
  }

  _showPledgeError(checkbox) {
    checkbox?.focus()
  }
}

ExternalContentHomeworkSubmissionView.optionProperty('externalTool')

ExternalContentHomeworkSubmissionView.prototype.events = {
  'click .relaunch-tool': '_relaunchTool',
  'click .submit_button': '_triggerSubmit',
  'click .cancel_button': '_triggerCancel',
}

export default ExternalContentHomeworkSubmissionView
