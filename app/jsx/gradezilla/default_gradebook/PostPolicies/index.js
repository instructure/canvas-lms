/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'

import PostAssignmentGradesTray from '../../../grading/PostAssignmentGradesTray'

export default class PostPolicies {
  constructor(gradebook) {
    this._gradebook = gradebook
  }

  initialize() {
    const $container = document.getElementById('post-assignment-grades-tray')
    const bindRef = ref => {
      this._tray = ref
    }
    ReactDOM.render(<PostAssignmentGradesTray ref={bindRef} />, $container)
  }

  destroy() {
    const $container = document.getElementById('post-assignment-grades-tray')
    ReactDOM.unmountComponentAtNode($container)
  }

  showPostAssignmentGradesTray({assignmentId, onExited}) {
    const {id, name} = this._gradebook.getAssignment(assignmentId)

    this._tray.show({
      assignment: {id, name},
      onExited
    })
  }
}
