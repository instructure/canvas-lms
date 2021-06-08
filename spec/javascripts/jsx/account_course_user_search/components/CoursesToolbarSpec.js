/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {shallow} from 'enzyme'
import CoursesToolbar from 'ui/features/account_course_user_search/react/components/CoursesToolbar.js'

const allTermsProps = {
  can_create_courses: true,
  onUpdateFilters: () => {},
  onApplyFilters: () => {},
  isLoading: false,
  draftFilters: {
    search_by: 'course',
    search_term: '',
    enrollment_term_id: ''
  },
  errors: {},
  terms: {
    data: [
      {
        id: '1',
        name: 'Future Term 1',
        start_at: '2099-01-01',
        end_at: '3099-01-01'
      },
      {
        id: '2',
        name: 'Future Term 2',
        start_at: '2099-01-01'
      },
      {
        id: '3',
        name: 'Active Term 1',
        start_at: '1999-01-01',
        end_at: '3099-01-01'
      },
      {
        id: '4',
        name: 'Term With No Start Or End 1'
      },
      {
        id: '5',
        name: 'Past Term 1',
        end_at: '1999-01-01'
      }
    ],
    loading: false
  }
}

QUnit.module('CoursesToolbar', suiteHooks => {
  let container
  let component

  suiteHooks.beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))
  })

  suiteHooks.afterEach(() => {
    component.unmount()
    container.remove()
  })

  function renderComponent(props) {
    component = render(<CoursesToolbar {...props} />, {container})
  }

  function getSelect() {
    return container.querySelector('input[type="text"]')
  }

  function clickToExpand() {
    getSelect().click()
  }

  function getOptionsList() {
    const optionsListId = getSelect().getAttribute('aria-controls')
    return document.getElementById(optionsListId)
  }

  function getOptions() {
    return [...getOptionsList().querySelectorAll('[role="option"]')]
  }

  function getOptionLabels() {
    return getOptions().map(option => option.textContent.trim())
  }

  test('groups terms properly', () => {
    renderComponent(allTermsProps)
    clickToExpand()
    getOptionLabels()

    deepEqual(getOptionLabels(), [
      'All Terms',
      'Active Term 1',
      'Term With No Start Or End 1',
      'Future Term 1',
      'Future Term 2',
      'Past Term 1'
    ])
  })

  QUnit.module('blueprint_courses checkbox', () => {
    test('clicking it causes "onUpdateFilters" to be called', () => {
      const onUpdateFilters = sinon.stub()
      const checkbox = shallow(
        <CoursesToolbar {...allTermsProps} onUpdateFilters={onUpdateFilters} />
      ).find('Checkbox[label="Show only blueprint courses"]')

      checkbox.simulate('change', {target: {checked: true}})
      ok(onUpdateFilters.calledWith({blueprint: true}))

      checkbox.simulate('change', {target: {checked: false}})
      ok(onUpdateFilters.calledWith({blueprint: null}))
    })
  })
})
