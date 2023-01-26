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

import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('Gradebook > Custom Columns', suiteHooks => {
  let $container
  let gradebook

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    setFixtureHtml($container)
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    $container.remove()
  })

  QUnit.module('#gotCustomColumns()', hooks => {
    let customColumns

    hooks.beforeEach(() => {
      gradebook = createGradebook()

      customColumns = [
        {id: '2401', teacher_notes: true, hidden: true, title: 'Notes'},
        {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'},
        {id: '2403', teacher_notes: false, hidden: false, title: 'Next Steps'},
      ]
    })

    test('stores the given custom columns', () => {
      gradebook.gotCustomColumns(customColumns)
      const storedColumns = gradebook.gradebookContent.customColumns
      deepEqual(
        storedColumns.map(customColumn => customColumn.id),
        customColumns.map(customColumn => customColumn.id)
      )
    })

    test('updates essential data load status', () => {
      sinon.spy(gradebook, '_updateEssentialDataLoaded')
      gradebook.gotCustomColumns(customColumns)
      strictEqual(gradebook._updateEssentialDataLoaded.callCount, 1)
    })
  })
})
