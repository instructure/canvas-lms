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

import AssignmentGroupFilter from 'ui/features/gradebook/react/default_gradebook/components/content-filters/AssignmentGroupFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('AssignmentGroupFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        disabled: false,
        assignmentGroups: [
          {id: '2201', name: 'In-Class'},
          {id: '2202', name: 'Homework'},
        ],
        onSelect: sinon.stub(),
        selectedAssignmentGroupId: '0',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<AssignmentGroupFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Assignment Group Filter', $container)
    }

    test('labels the filter with "Assignment Group Filter"', () => {
      renderComponent()
      equal(filter.labelText, 'Assignment Group Filter')
    })

    test('displays the name of the selected assignment group as the value', () => {
      props.selectedAssignmentGroupId = '2202'
      renderComponent()
      equal(filter.selectedItemLabel, 'Homework')
    })

    test('displays "All Assignment Groups" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Assignment Groups')
    })

    QUnit.module('assignment groups list', () => {
      test('labels the "all items" option with "All Assignment Groups"', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Assignment Groups')
      })

      test('labels each option using the related assignment group name in alphabetical order', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.$options.slice(1).map($option => $option.textContent.trim())
        deepEqual(labels, ['Homework', 'In-Class'])
      })

      test('disables non-selected options when the filter is disabled', () => {
        props.disabled = true
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Homework')
        strictEqual($option.getAttribute('aria-disabled'), 'true')
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('In-Class')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the assignment group id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('In-Class')
        const [selectedAssignmentGroupId] = props.onSelect.lastCall.args
        strictEqual(selectedAssignmentGroupId, '2201')
      })

      test('includes "0" when the "All Assignment Groups" is clicked', () => {
        props.selectedAssignmentGroupId = '2201'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Assignment Groups')
        const [selectedAssignmentGroupId] = props.onSelect.lastCall.args
        strictEqual(selectedAssignmentGroupId, '0')
      })
    })
  })
})
