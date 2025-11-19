/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import React from 'react'
import {createRoot} from 'react-dom/client'
import {AnonymousSubmissionComponent} from '../../react/AnonymousSubmissionComponent'

extend(AnonymousSubmissionSelector, Backbone.View)

function AnonymousSubmissionSelector() {
  this.handleAnonymousChange = this.handleAnonymousChange.bind(this)
  this.updateComponent = this.updateComponent.bind(this)
  this.root = null
  return AnonymousSubmissionSelector.__super__.constructor.apply(this, arguments)
}

AnonymousSubmissionSelector.optionProperty('parentModel')

AnonymousSubmissionSelector.prototype.handleAnonymousChange = function (isAnonymous) {
  // Update the component immediately to show the new value
  this.updateComponent(isAnonymous)
  // Then trigger the event for other listeners
  return this.trigger('change:anonymousSubmission', isAnonymous)
}

AnonymousSubmissionSelector.prototype.updateComponent = function (isAnonymous = null) {
  // Don't render if the element doesn't exist in the DOM
  // This happens when the feature flag is disabled or assignment isn't a survey
  if (!this.el || !document.body.contains(this.el)) {
    return
  }

  const currentIsAnonymous =
    isAnonymous !== null ? isAnonymous : this.parentModel.newQuizzesAnonymousSubmission() || false

  if (!this.root) {
    this.root = createRoot(this.el)
  }

  this.root.render(
    React.createElement(AnonymousSubmissionComponent, {
      isAnonymous: currentIsAnonymous,
      disabled: !this.parentModel.isNew(),
      onChange: this.handleAnonymousChange,
    }),
  )
}

AnonymousSubmissionSelector.prototype.render = function () {
  this.updateComponent()
  return this
}

AnonymousSubmissionSelector.prototype.remove = function () {
  if (this.root) {
    this.root.unmount()
    this.root = null
  }
  return Backbone.View.prototype.remove.call(this)
}

export default AnonymousSubmissionSelector
