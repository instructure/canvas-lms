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

import {renderModuleSequenceFooter} from 'ui/features/module_sequence_footer/react/index'
import fakeENV from 'helpers/fakeENV'

QUnit.module('renderModuleSequenceFooter', hooks => {
  let $container
  let env

  hooks.beforeEach(() => {
    $container = document.createElement('div')
    $container.setAttribute('id', 'speed_grader_link_container')
    document.body.appendChild($container)

    env = {
      COURSE_ID: '1201',
      SETTINGS: {
        filter_speed_grader_by_student_group: false,
      },
      speed_grader_url: '/speedgrader',
    }

    fakeENV.setup(env)
  })

  hooks.afterEach(() => {
    fakeENV.teardown()
    $container.remove()
  })

  function getSelect() {
    return $container.querySelector('select')
  }

  function getSelectOptions() {
    return [...getSelect().querySelectorAll('option')]
  }

  function getSpeedGraderLink() {
    return [...$container.querySelectorAll('a')].find($a => $a.href.includes(env.speed_grader_url))
  }

  QUnit.module('when filter_speed_grader_by_student_group is false', contextHooks => {
    contextHooks.beforeEach(() => {
      env.SETTINGS.filter_speed_grader_by_student_group = false
      fakeENV.setup(env)
    })

    test('does not render a select dropdown', () => {
      renderModuleSequenceFooter()
      notOk(getSelect())
    })

    test('renders a SpeedGrader link', () => {
      renderModuleSequenceFooter()
      ok(getSpeedGraderLink())
    })

    test('rendered SpeedGrader link is not disabled', () => {
      renderModuleSequenceFooter()
      strictEqual(getSpeedGraderLink().hasAttribute('aria-disabled'), false)
    })
  })

  QUnit.module('when filter_speed_grader_by_student_group is true', contextHooks => {
    contextHooks.beforeEach(() => {
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
      ok(getSelect())
    })

    test('rendered select dropdown contains group categories', () => {
      renderModuleSequenceFooter()
      const groupCategoryNames = [...getSelect().querySelectorAll('optgroup')].map(
        $optgroup => $optgroup.label
      )
      deepEqual(groupCategoryNames, ['group category 1'])
    })

    test('rendered select dropdown contains groups', () => {
      renderModuleSequenceFooter()
      const groupIds = getSelectOptions().map($option => $option.value)
      deepEqual(groupIds, ['0', '2101', '2102'])
    })

    test('rendered SpeedGrader link is disabled when no student group is selected', () => {
      delete env.selected_student_group_id
      fakeENV.setup(env)
      renderModuleSequenceFooter()
      strictEqual(getSpeedGraderLink().getAttribute('aria-disabled'), 'true')
    })

    test('rendered SpeedGrader link is not disabled when a student group is selected', () => {
      renderModuleSequenceFooter()
      strictEqual(getSpeedGraderLink().hasAttribute('aria-disabled'), false)
    })
  })
})
