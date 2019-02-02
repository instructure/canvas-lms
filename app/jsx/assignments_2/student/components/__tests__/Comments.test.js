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
import $ from 'jquery'
import {mockAssignment} from '../../test-utils'

import Comments from '../Comments'

describe('Comments', () => {
  beforeAll(() => {
    const found = document.getElementById('fixtures')
    if (!found) {
      const fixtures = document.createElement('div')
      fixtures.setAttribute('id', 'fixtures')
      document.body.appendChild(fixtures)
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
  })

  it('renders Comments', () => {
    ReactDOM.render(<Comments assignment={mockAssignment()} />, document.getElementById('fixtures'))
    const container = $('[data-test-id="comments-container"]')
    expect(container).toHaveLength(1)
  })

  it('renders CommentTextArea', () => {
    ReactDOM.render(<Comments assignment={mockAssignment()} />, document.getElementById('fixtures'))
    const container = $('[data-test-id="comments-text-area-container"]')
    expect(container).toHaveLength(1)
  })

  it('renders place holder text when no comments', () => {
    const assignment = mockAssignment()
    assignment.submissionsConnection.nodes[0].commentsConnection.nodes = []
    ReactDOM.render(<Comments assignment={assignment} />, document.getElementById('fixtures'))
    const container = $(
      '#fixtures:contains("Send a comment to your instructor about this assignment.")'
    )
    expect(container).toHaveLength(1)
  })

  it('renders comment rows when provided', () => {
    const assignment = mockAssignment()
    ReactDOM.render(<Comments assignment={assignment} />, document.getElementById('fixtures'))
    const container = $('.comment-row-container')
    expect(container).toHaveLength(1)
  })

  it('renders shortname when shortname is provided', () => {
    const assignment = mockAssignment()
    ReactDOM.render(<Comments assignment={assignment} />, document.getElementById('fixtures'))
    const container = $('#fixtures:contains("bob builder")')
    expect(container).toHaveLength(1)
  })

  it('renders Anonymous when shortname is not provided', () => {
    const assignment = mockAssignment()
    assignment.submissionsConnection.nodes[0].commentsConnection.nodes[0].author = null
    ReactDOM.render(<Comments assignment={assignment} />, document.getElementById('fixtures'))
    let container = $('#fixtures:contains("bob builder")')
    expect(container).toHaveLength(0)
    container = $('#fixtures:contains("Anonymous")')
    expect(container).toHaveLength(1)
  })
})
