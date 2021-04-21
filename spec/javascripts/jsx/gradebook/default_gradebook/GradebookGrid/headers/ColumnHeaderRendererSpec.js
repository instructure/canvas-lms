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

import {createGradebook} from 'jsx/gradebook/default_gradebook/__tests__/GradebookSpecHelper'
import ColumnHeaderRenderer from 'jsx/gradebook/default_gradebook/GradebookGrid/headers/ColumnHeaderRenderer'

QUnit.module('GradebookGrid ColumnHeaderRenderer', suiteHooks => {
  let $container
  let assignmentColumn
  let assignmentColumnRendererFactory
  let gradebook
  let renderer

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    $container.innerHTML = '<div class="slick-column-name"></div>'
    document.body.appendChild($container)
    buildGradebook()
  })

  suiteHooks.afterEach(() => {
    $container.remove()
  })

  function buildGradebook() {
    gradebook = createGradebook({})
    const assignment = {id: '2301'}
    assignmentColumn = gradebook.buildAssignmentColumn(assignment)
    gradebook.gridData.columns.definitions[assignmentColumn.id] = assignmentColumn
    renderer = new ColumnHeaderRenderer(gradebook)
    assignmentColumnRendererFactory = renderer.factories.assignment
  }

  QUnit.module('#renderColumnHeader', () => {
    test('uses the .slick-column-name element as container', () => {
      const renderStub = sinon.stub(assignmentColumnRendererFactory, 'render')
      renderer.renderColumnHeader(assignmentColumn, $container, {})
      strictEqual(renderStub.firstCall.args[1].className, 'slick-column-name')
    })
  })

  QUnit.module('#destroyColumnHeader', () => {
    test('uses the .slick-column-name element as container', () => {
      const destroyStub = sinon.stub(assignmentColumnRendererFactory, 'destroy')
      renderer.destroyColumnHeader(assignmentColumn, $container, {})
      strictEqual(destroyStub.firstCall.args[1].className, 'slick-column-name')
    })
  })
})
