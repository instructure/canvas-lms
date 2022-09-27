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

QUnit.module('Gradebook > Context Modules', suiteHooks => {
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

  QUnit.module('#updateContextModules()', hooks => {
    let contextModules

    hooks.beforeEach(() => {
      gradebook = createGradebook()

      contextModules = [
        {id: '2601', name: 'Algebra', position: 1},
        {id: '2602', name: 'English', position: 2},
      ]
    })

    test('stores the given context modules', () => {
      gradebook.updateContextModules(contextModules)
      const storedModules = gradebook.courseContent.contextModules
      deepEqual(
        storedModules.map(contextModule => contextModule.id),
        ['2601', '2602']
      )
    })

    test('renders the view options menu after storing the context modules', () => {
      sinon.spy(gradebook, 'renderViewOptionsMenu')
      gradebook.updateContextModules(contextModules)
      strictEqual(gradebook.renderViewOptionsMenu.callCount, 1)
    })

    test('renders filters', () => {
      sinon.spy(gradebook, 'renderFilters')
      gradebook.updateContextModules(contextModules)
      strictEqual(gradebook.renderFilters.callCount, 1)
    })

    test('renders filters after storing the context modules', () => {
      sinon.stub(gradebook, 'renderFilters').callsFake(() => {
        const storedModules = gradebook.courseContent.contextModules
        strictEqual(storedModules.length, 2)
      })
      gradebook.updateContextModules(contextModules)
    })

    test('renders filters after updating the context modules', () => {
      sinon.spy(gradebook, 'renderFilters')
      gradebook.updateContextModules(contextModules)
      strictEqual(gradebook.renderFilters.callCount, 1)
    })

    test('updates essential data load status', () => {
      sinon.spy(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateContextModules(contextModules)
      strictEqual(gradebook._updateEssentialDataLoaded.callCount, 1)
    })

    test('updates essential data load status after rendering filters', () => {
      sinon.spy(gradebook, 'renderFilters')
      sinon.stub(gradebook, '_updateEssentialDataLoaded').callsFake(() => {
        strictEqual(gradebook.renderFilters.callCount, 1)
      })
      gradebook.updateContextModules(contextModules)
    })
  })
})
