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

import React from 'react'
import {render} from '@testing-library/react'

import StudentGroupFilter from 'ui/features/gradebook/react/default_gradebook/components/content-filters/StudentGroupFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('StudentGroupFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        disabled: false,

        studentGroupSets: [
          {
            groups: [
              {id: '2103', name: 'Group B1'},
              {id: '2104', name: 'Group B2'},
            ],
            id: '2152',
            name: 'Group Set B',
          },
          {
            groups: [
              {id: '2101', name: 'Group A2'},
              {id: '2102', name: 'Group A1'},
            ],
            id: '2151',
            name: 'Group Set A',
          },
        ],

        onSelect: sinon.stub(),
        selectedStudentGroupId: '0',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<StudentGroupFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Student Group Filter', $container)
    }

    test('labels the filter with "Student Group Filter"', () => {
      renderComponent()
      equal(filter.labelText, 'Student Group Filter')
    })

    test('displays the name of the selected student group as the value', () => {
      props.selectedStudentGroupId = '2101'
      renderComponent()
      equal(filter.selectedItemLabel, 'Group A2')
    })

    test('displays "All Student Groups" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Student Groups')
    })

    QUnit.module('student group sets', () => {
      test('labels each group set option group using the related name in alphabetical order', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.optionGroupLabels
        deepEqual(labels, ['Group Set A', 'Group Set B'])
      })
    })

    QUnit.module('student groups list', () => {
      test('labels the "all items" option with "All Student Groups"', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Student Groups')
      })

      test('labels each option using the related student group name in alphabetical order', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.$options.slice(1).map($option => $option.textContent.trim())
        deepEqual(labels, ['Group A1', 'Group A2', 'Group B1', 'Group B2'])
      })

      test('disables non-selected options when the filter is disabled', () => {
        props.disabled = true
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Group A2')
        strictEqual($option.getAttribute('aria-disabled'), 'true')
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Group A1')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the student group id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Group A1')
        const [selectedStudentGroupId] = props.onSelect.lastCall.args
        strictEqual(selectedStudentGroupId, '2102')
      })

      test('includes "0" when the "All Student Groups" is clicked', () => {
        props.selectedStudentGroupId = '2101'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Student Groups')
        const [selectedStudentGroupId] = props.onSelect.lastCall.args
        strictEqual(selectedStudentGroupId, '0')
      })
    })
  })
})
