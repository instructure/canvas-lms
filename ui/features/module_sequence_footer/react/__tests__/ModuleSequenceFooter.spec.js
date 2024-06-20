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

import {renderModuleSequenceFooter} from '../index'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('renderModuleSequenceFooter', () => {
  let container
  let env

  beforeEach(() => {
    container = document.createElement('div')
    container.setAttribute('id', 'speed_grader_link_container')
    document.body.appendChild(container)

    env = {
      COURSE_ID: '1201',
      SETTINGS: {
        filter_speed_grader_by_student_group: false,
      },
      speed_grader_url: '/speedgrader',
    }

    fakeENV.setup(env)
  })

  afterEach(() => {
    fakeENV.teardown()
    container.remove()
  })

  function getSelect() {
    return container.querySelector('select')
  }

  function getSelectOptions() {
    return [...getSelect().querySelectorAll('option')]
  }

  function getSpeedGraderLink() {
    return [...container.querySelectorAll('a')].find(a => a.href.includes(env.speed_grader_url))
  }

  describe('when filter_speed_grader_by_student_group is false', () => {
    beforeEach(() => {
      env.SETTINGS.filter_speed_grader_by_student_group = false
      fakeENV.setup(env)
    })

    test('does not render a select dropdown', () => {
      renderModuleSequenceFooter()
      expect(getSelect()).toBeNull()
    })

    test('renders a SpeedGrader link', () => {
      renderModuleSequenceFooter()
      expect(getSpeedGraderLink()).not.toBeNull()
    })

    test('rendered SpeedGrader link is not disabled', () => {
      renderModuleSequenceFooter()
      expect(getSpeedGraderLink().hasAttribute('aria-disabled')).toBe(false)
    })
  })

  describe('when filter_speed_grader_by_student_group is true', () => {
    beforeEach(() => {
      env.group_categories = [
        {
          id: '2201',
          groups: [
            {id: '2101', name: 'group 1'},
            {id: '2102', name: 'group 2'},
          ],
          name: 'group category 1',
        },
      ]
      env.SETTINGS.filter_speed_grader_by_student_group = true
      env.selected_student_group_id = '2101'
      fakeENV.setup(env)
    })

    test('renders a select dropdown', () => {
      renderModuleSequenceFooter()
      expect(getSelect()).not.toBeNull()
    })

    test('rendered select dropdown contains group categories', () => {
      renderModuleSequenceFooter()
      const groupCategoryNames = [...getSelect().querySelectorAll('optgroup')].map(
        optgroup => optgroup.label
      )
      expect(groupCategoryNames).toEqual(['group category 1'])
    })

    test('rendered select dropdown contains groups', () => {
      renderModuleSequenceFooter()
      const groupIds = getSelectOptions().map(option => option.value)
      expect(groupIds).toEqual(['0', '2101', '2102'])
    })

    test('rendered SpeedGrader link is disabled when no student group is selected', () => {
      delete env.selected_student_group_id
      fakeENV.setup(env)
      renderModuleSequenceFooter()
      expect(getSpeedGraderLink().getAttribute('aria-disabled')).toBe('true')
    })

    test('rendered SpeedGrader link is not disabled when a student group is selected', () => {
      renderModuleSequenceFooter()
      expect(getSpeedGraderLink().hasAttribute('aria-disabled')).toBe(false)
    })
  })
})
