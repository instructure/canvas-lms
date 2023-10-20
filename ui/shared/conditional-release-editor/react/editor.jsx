/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import ReactDom from 'react-dom'
import {Provider} from 'react-redux'

import createReduxStore from './create-redux-store'
import EditorView from './editor-view'
import createRootReducer from './reducer'
import * as actions from './actions'
import initActors from './actors'

class ConditionalReleaseEditor {
  constructor(options = {}) {
    this.rootReducer = createRootReducer()
    this.store = options.store || createReduxStore(this.rootReducer)

    initActors(this.store)

    if (options.courseId) {
      this.loadCourseId(options.courseId)
    }

    if (options.assignment) {
      this.loadAssignment(options.assignment)
    } else {
      this.loadDefaultRule()
    }

    if (options.gradingType) {
      this.updateAssignment({grading_type: options.gradingType})
    }
  }

  // Returns a promise. Requires the assignment id to be set.
  saveRule() {
    return this.store.dispatch(actions.commitRule(this.store.getState()))
  }

  getReducer() {
    return this.rootReducer
  }

  attach(targetDomNode, targetRoot = null) {
    targetRoot = targetRoot || targetDomNode
    ReactDom.render(
      <Provider store={this.store}>
        <EditorView appElement={targetRoot} />
      </Provider>,
      targetDomNode
    )
  }

  // This does _not_ cause the editor to reload the data for the specified assignment.
  // Useful if you're creating a new assignment: set the new assignment's id here before saving
  updateAssignment(assignment) {
    this.store.dispatch(actions.updateAssignment(assignment))
  }

  // set the assignment id and load it
  loadAssignment(newAssignment) {
    this.updateAssignment(newAssignment)
    return this.store.dispatch(actions.loadRuleForAssignment(this.store.getState()))
  }

  loadDefaultRule() {
    this.store.dispatch(actions.loadDefaultRule(this.store.getState()))
  }

  loadCourseId(newCourseId) {
    this.store.dispatch(actions.setCourseId(newCourseId))
    this.store.dispatch(actions.getAssignments(this.store.getState()))
  }

  subscribe(callback) {
    return this.store.subscribe(callback)
  }

  getErrors() {
    return this.store
      .getState()
      .getIn(['rule', 'scoring_ranges'])
      .reduce((acc, sr, index) => {
        if (sr.get('error')) {
          acc.push({index, error: sr.get('error')})
        }
        return acc
      }, [])
  }

  focusOnError() {
    const errors = this.getErrors()
    if (errors.length > 0) {
      const index = errors[0].index
      document.querySelectorAll('.cr-percent-input__input')[index].focus()
    }
  }
}

export default ConditionalReleaseEditor
