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
import {QuizTypeSelectorComponent} from '../../react/QuizTypeSelectorComponent'

extend(QuizTypeSelector, Backbone.View)

function QuizTypeSelector() {
  this.handleQuizTypeChange = this.handleQuizTypeChange.bind(this)
  this.updateComponent = this.updateComponent.bind(this)
  this.root = null
  return QuizTypeSelector.__super__.constructor.apply(this, arguments)
}

QuizTypeSelector.optionProperty('parentModel')

QuizTypeSelector.prototype.handleQuizTypeChange = function (quizType) {
  // Update the component immediately to show the new value
  this.updateComponent(quizType)
  // Then trigger the event for other listeners
  return this.trigger('change:quizType', quizType)
}

QuizTypeSelector.prototype.updateComponent = function (quizType = null) {
  // Don't render if the element doesn't exist in the DOM
  // This happens when the feature flag is disabled or assignment isn't quiz LTI
  if (!this.el || !document.body.contains(this.el)) {
    return
  }

  const currentQuizType = quizType || this.parentModel.newQuizzesType() || 'graded_quiz'
  const isExistingAssignment = !this.parentModel.isNew()

  if (!this.root) {
    this.root = createRoot(this.el)
  }

  this.root.render(
    React.createElement(QuizTypeSelectorComponent, {
      quizType: currentQuizType,
      isExistingAssignment,
      onChange: this.handleQuizTypeChange,
    }),
  )
}

QuizTypeSelector.prototype.render = function () {
  this.updateComponent()
  return this
}

QuizTypeSelector.prototype.remove = function () {
  if (this.root) {
    this.root.unmount()
    this.root = null
  }
  return Backbone.View.prototype.remove.call(this)
}

export default QuizTypeSelector
