/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {createGradebook} from '../../../__tests__/GradebookSpecHelper'
import ColumnHeaderRenderer from '../ColumnHeaderRenderer'

describe('GradebookGrid ColumnHeaderRenderer', () => {
  let container
  let assignmentColumn
  let assignmentColumnRendererFactory
  let gradebook
  let renderer

  beforeEach(() => {
    container = document.createElement('div')
    container.innerHTML = '<div class="slick-column-name"></div>'
    document.body.appendChild(container)

    gradebook = createGradebook({})
    const assignment = {
      id: '2301',
      name: 'Assignment 1',
      points_possible: 10,
      published: true,
      submission_types: ['online_text_entry'],
      visible_to_everyone: true,
    }
    assignmentColumn = gradebook.buildAssignmentColumn(assignment)
    gradebook.gridData.columns.definitions[assignmentColumn.id] = assignmentColumn
    renderer = new ColumnHeaderRenderer(gradebook)
    assignmentColumnRendererFactory = renderer.factories.assignment

    // Mock the render and destroy methods to avoid actual rendering
    jest.spyOn(assignmentColumnRendererFactory, 'render').mockImplementation(() => {})
    jest.spyOn(assignmentColumnRendererFactory, 'destroy').mockImplementation(() => {})
  })

  afterEach(() => {
    container.remove()
    jest.restoreAllMocks()
  })

  describe('renderColumnHeader', () => {
    it('uses the .slick-column-name element as container', () => {
      renderer.renderColumnHeader(assignmentColumn, container, {})
      const calls = assignmentColumnRendererFactory.render.mock.calls
      expect(calls).toHaveLength(1)
      expect(calls[0][1]).toBeInstanceOf(HTMLDivElement)
      expect(calls[0][1].className).toBe('slick-column-name')
    })
  })

  describe('destroyColumnHeader', () => {
    it('uses the .slick-column-name element as container', () => {
      renderer.destroyColumnHeader(assignmentColumn, container, {})
      const calls = assignmentColumnRendererFactory.destroy.mock.calls
      expect(calls).toHaveLength(1)
      expect(calls[0][1]).toBeInstanceOf(HTMLDivElement)
      expect(calls[0][1].className).toBe('slick-column-name')
    })
  })
})
