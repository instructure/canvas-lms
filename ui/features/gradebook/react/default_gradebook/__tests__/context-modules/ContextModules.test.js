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

import {createGradebook, setFixtureHtml} from '../GradebookSpecHelper'

describe('Gradebook Context Modules', () => {
  let $fixtures
  let gradebook

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $fixtures = document.getElementById('fixtures')
    setFixtureHtml($fixtures)
    gradebook = createGradebook()
  })

  afterEach(() => {
    gradebook.destroy()
    $fixtures.innerHTML = ''
  })

  describe('#updateContextModules()', () => {
    const contextModules = [
      {id: '2601', name: 'Algebra', position: 1},
      {id: '2602', name: 'English', position: 2},
    ]

    it('stores the given context modules', () => {
      gradebook.updateContextModules(contextModules)
      const storedModules = gradebook.courseContent.contextModules
      expect(storedModules.map(contextModule => contextModule.id)).toEqual(['2601', '2602'])
    })

    it('renders the view options menu after storing the context modules', () => {
      const renderViewOptionsMenuSpy = jest.spyOn(gradebook, 'renderViewOptionsMenu')
      gradebook.updateContextModules(contextModules)
      expect(renderViewOptionsMenuSpy).toHaveBeenCalledTimes(1)
    })

    it('renders filters', () => {
      const renderFiltersSpy = jest.spyOn(gradebook, 'renderFilters')
      gradebook.updateContextModules(contextModules)
      expect(renderFiltersSpy).toHaveBeenCalledTimes(1)
    })

    it('renders filters after storing the context modules', () => {
      const renderFiltersSpy = jest.spyOn(gradebook, 'renderFilters').mockImplementation(() => {
        const storedModules = gradebook.courseContent.contextModules
        expect(storedModules).toHaveLength(2)
      })
      gradebook.updateContextModules(contextModules)
      expect(renderFiltersSpy).toHaveBeenCalled()
    })

    it('updates essential data load status', () => {
      const updateEssentialDataSpy = jest.spyOn(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateContextModules(contextModules)
      expect(updateEssentialDataSpy).toHaveBeenCalledTimes(1)
    })

    it('updates essential data load status after rendering filters', () => {
      const renderFiltersSpy = jest.spyOn(gradebook, 'renderFilters')
      const updateEssentialDataSpy = jest.spyOn(gradebook, '_updateEssentialDataLoaded')
      gradebook.updateContextModules(contextModules)
      expect(renderFiltersSpy).toHaveBeenCalled()
      expect(updateEssentialDataSpy).toHaveBeenCalled()
    })
  })
})
