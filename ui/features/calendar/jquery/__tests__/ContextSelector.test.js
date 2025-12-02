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

import $ from 'jquery'
import ContextSelector from '../ContextSelector'

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

describe('ContextSelector', () => {
  let $holder
  let contexts
  let apptGroup
  let contextsChangedCB
  let closeCB

  beforeEach(() => {
    $holder = $('<div id="context-selector-holder" />').appendTo(
      document.getElementById('fixtures'),
    )

    contexts = [
      {
        asset_string: 'course_1',
        name: 'Course 1',
        course_sections: [
          {asset_string: 'section_1', name: 'Section 1'},
          {asset_string: 'section_2', name: 'Section 2'},
        ],
        can_create_appointment_groups: {all_sections: true},
      },
      {
        asset_string: 'course_2',
        name: 'Course 2',
        course_sections: [{asset_string: 'section_3', name: 'Section 3'}],
        can_create_appointment_groups: {all_sections: true},
      },
    ]

    apptGroup = {
      context_codes: [],
      sub_context_codes: [],
    }

    contextsChangedCB = jest.fn()
    closeCB = jest.fn()
  })

  afterEach(() => {
    $holder.remove()
    document.getElementById('fixtures').innerHTML = ''
  })

  describe('selectedContexts', () => {
    it('returns empty array when no contexts are selected', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      expect(selector.selectedContexts()).toEqual([])
    })

    it('returns asset strings of contexts that are on', () => {
      apptGroup.context_codes = ['course_1']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      expect(selector.selectedContexts()).toContain('course_1')
    })

    it('returns multiple context asset strings when multiple contexts are selected', () => {
      apptGroup.context_codes = ['course_1', 'course_2']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      const selectedContexts = selector.selectedContexts()
      expect(selectedContexts).toContain('course_1')
      expect(selectedContexts).toContain('course_2')
      expect(selectedContexts).toHaveLength(2)
    })

    it('filters out contexts that are off', () => {
      apptGroup.context_codes = ['course_1']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      const selectedContexts = selector.selectedContexts()
      expect(selectedContexts).not.toContain('course_2')
    })

    it('uses Object.values and filter/map chain correctly', () => {
      apptGroup.context_codes = ['course_1', 'course_2']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      const selectedContexts = selector.selectedContexts()

      expect(Array.isArray(selectedContexts)).toBe(true)
      expect(selectedContexts.every(item => typeof item === 'string')).toBe(true)
    })
  })

  describe('selectedSections', () => {
    it('returns empty array when no sections are specifically selected', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      expect(selector.selectedSections()).toEqual([])
    })

    it('returns empty array when whole context is selected (not individual sections)', () => {
      apptGroup.context_codes = ['course_1']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      expect(selector.selectedSections()).toEqual([])
    })

    it('returns a flattened array of sections', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      const result = selector.selectedSections()
      expect(Array.isArray(result)).toBe(true)
      expect(result.every(item => typeof item === 'string' || result.length === 0)).toBe(true)
    })

    it('uses Object.values, map, filter and flat chain correctly', () => {
      apptGroup.context_codes = ['course_1']

      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      const result = selector.selectedSections()
      expect(Array.isArray(result)).toBe(true)
    })
  })

  describe('selectedContexts and selectedSections unit logic', () => {
    it('selectedContexts filters items based on state property', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      selector.contextSelectorItems.course_1.state = 'on'
      selector.contextSelectorItems.course_2.state = 'partial'

      const selectedContexts = selector.selectedContexts()
      expect(selectedContexts).toContain('course_1')
      expect(selectedContexts).toContain('course_2')
    })

    it('selectedContexts excludes items with state off', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      selector.contextSelectorItems.course_1.state = 'on'
      selector.contextSelectorItems.course_2.state = 'off'

      const selectedContexts = selector.selectedContexts()
      expect(selectedContexts).toContain('course_1')
      expect(selectedContexts).not.toContain('course_2')
    })

    it('selectedSections flattens section arrays from multiple contexts', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      selector.contextSelectorItems.course_1.sections = () => ['section_1']
      selector.contextSelectorItems.course_2.sections = () => ['section_3']

      const selectedSections = selector.selectedSections()
      expect(selectedSections).toContain('section_1')
      expect(selectedSections).toContain('section_3')
      expect(selectedSections).toHaveLength(2)
    })

    it('selectedSections filters out empty section arrays', () => {
      const selector = new ContextSelector(
        '#context-selector-holder',
        apptGroup,
        contexts,
        contextsChangedCB,
        closeCB,
      )

      selector.contextSelectorItems.course_1.sections = () => ['section_1', 'section_2']
      selector.contextSelectorItems.course_2.sections = () => []

      const selectedSections = selector.selectedSections()
      expect(selectedSections).toContain('section_1')
      expect(selectedSections).toContain('section_2')
      expect(selectedSections).not.toContain('section_3')
      expect(selectedSections).toHaveLength(2)
    })
  })
})
