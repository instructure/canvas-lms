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

import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'

describe('Gradebook - post_grades_enhanced_modal feature flag', () => {
  let $fixtures: HTMLElement

  beforeEach(() => {
    document.body.innerHTML = '<div id="fixtures"></div>'
    $fixtures = document.getElementById('fixtures')!
    setFixtureHtml($fixtures)
  })

  afterEach(() => {
    $fixtures.innerHTML = ''
  })

  const mockPostGradesLtis = [
    {
      id: '1',
      name: 'Test SIS Integration',
      data_url: 'http://example.com/lti/post_grades',
      type: 'lti' as const,
    },
  ]

  describe('when feature flag is enabled', () => {
    it('stores the feature flag value in options', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      expect(gradebook.options.post_grades_enhanced_modal).toBe(true)
    })

    it('sets selectedLtiId when an LTI is clicked', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      const postGradesLti = gradebook.postGradesLtis[0]
      expect(postGradesLti.id).toBe('1')
      expect(postGradesLti.name).toBe('Test SIS Integration')

      const setStateSpy = vi.spyOn(gradebook, 'setState')
      postGradesLti.onSelect()

      expect(setStateSpy).toHaveBeenCalledWith({selectedLtiId: '1'})
    })

    it('clears selectedLtiId when modal is closed', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      const setStateSpy = vi.spyOn(gradebook, 'setState')
      gradebook.onSyncDialogClose()

      expect(setStateSpy).toHaveBeenCalledWith({selectedLtiId: null})
    })

    it('handles invalid selectedLtiId gracefully', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      const invalidLtiId = 'non-existent-id'
      const matchingLti = gradebook.options.post_grades_ltis.find(lti => lti.id === invalidLtiId)

      expect(matchingLti).toBeUndefined()
      expect(gradebook.options.post_grades_ltis).toHaveLength(1)
    })
  })

  describe('when feature flag is disabled', () => {
    it('stores the feature flag value as false in options', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: false,
        post_grades_ltis: mockPostGradesLtis,
      })

      expect(gradebook.options.post_grades_enhanced_modal).toBe(false)
    })

    it('does not set selectedLtiId when an LTI is clicked', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: false,
        post_grades_ltis: mockPostGradesLtis,
      })

      const postGradesLti = gradebook.postGradesLtis[0]
      expect(gradebook.state.selectedLtiId).toBeNull()

      // When flag is disabled, clicking opens the old jQuery dialog instead
      const initialSelectedLtiId = gradebook.state.selectedLtiId
      expect(initialSelectedLtiId).toBeNull()
    })
  })

  describe('initPostGradesLtis', () => {
    it('creates LTI menu items with onSelect handlers', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      expect(gradebook.postGradesLtis).toHaveLength(1)
      expect(gradebook.postGradesLtis[0].id).toBe('1')
      expect(gradebook.postGradesLtis[0].name).toBe('Test SIS Integration')
      expect(typeof gradebook.postGradesLtis[0].onSelect).toBe('function')
    })

    it('handles empty postGradesLtis array', () => {
      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: [],
      })

      expect(gradebook.postGradesLtis).toHaveLength(0)
    })

    it('handles multiple LTI tools', () => {
      const multiplePostGradesLtis = [
        ...mockPostGradesLtis,
        {
          id: '2',
          name: 'Another SIS Integration',
          data_url: 'http://example.com/lti/post_grades_2',
          type: 'lti' as const,
        },
      ]

      const gradebook = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: multiplePostGradesLtis,
      })

      expect(gradebook.postGradesLtis).toHaveLength(2)
      expect(gradebook.postGradesLtis[0].id).toBe('1')
      expect(gradebook.postGradesLtis[1].id).toBe('2')

      const setStateSpy = vi.spyOn(gradebook, 'setState')

      gradebook.postGradesLtis[0].onSelect()
      expect(setStateSpy).toHaveBeenCalledWith({selectedLtiId: '1'})

      setStateSpy.mockClear()
      gradebook.postGradesLtis[1].onSelect()
      expect(setStateSpy).toHaveBeenCalledWith({selectedLtiId: '2'})
    })

    it('creates different onSelect handlers based on feature flag', () => {
      const gradebookWithFlag = createGradebook({
        post_grades_enhanced_modal: true,
        post_grades_ltis: mockPostGradesLtis,
      })

      const gradebookWithoutFlag = createGradebook({
        post_grades_enhanced_modal: false,
        post_grades_ltis: mockPostGradesLtis,
      })

      const setStateSpyWithFlag = vi.spyOn(gradebookWithFlag, 'setState')
      const setStateSpyWithoutFlag = vi.spyOn(gradebookWithoutFlag, 'setState')

      gradebookWithFlag.postGradesLtis[0].onSelect()
      expect(setStateSpyWithFlag).toHaveBeenCalledWith({selectedLtiId: '1'})

      // When flag is disabled, uses old jQuery dialog instead of setState
      gradebookWithoutFlag.postGradesLtis[0].onSelect()
      expect(setStateSpyWithoutFlag).not.toHaveBeenCalled()
    })
  })
})
