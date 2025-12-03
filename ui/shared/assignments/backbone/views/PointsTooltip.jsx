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
import {PointsTooltipComponent} from '../../react/PointsTooltipComponent'

extend(PointsTooltip, Backbone.View)

function PointsTooltip() {
  this.updateComponent = this.updateComponent.bind(this)
  this.root = null
  return PointsTooltip.__super__.constructor.apply(this, arguments)
}

PointsTooltip.optionProperty('parentModel')

PointsTooltip.prototype.updateComponent = function (quizType = null) {
  // Don't render if the element doesn't exist in the DOM
  // This happens when the feature flag is disabled or assignment isn't quiz LTI
  if (!this.el || !document.body.contains(this.el)) {
    return
  }

  const currentQuizType = quizType || this.parentModel.newQuizzesType() || 'graded_quiz'
  const shouldShow = currentQuizType === 'graded_survey'

  if (!this.root) {
    this.root = createRoot(this.el)
  }

  this.root.render(
    React.createElement(PointsTooltipComponent, {
      shouldShow,
    }),
  )
}

PointsTooltip.prototype.render = function () {
  this.updateComponent()
  return this
}

PointsTooltip.prototype.remove = function () {
  if (this.root) {
    this.root.unmount()
    this.root = null
  }
  return Backbone.View.prototype.remove.call(this)
}

export default PointsTooltip
