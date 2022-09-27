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

import ModuleFilter from 'ui/features/gradebook/react/default_gradebook/components/content-filters/ModuleFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('ModuleFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        disabled: false,
        modules: [
          {id: '2002', name: 'Module 2'},
          {id: '2001', name: 'Module 1'},
        ],
        onSelect: sinon.stub(),
        selectedModuleId: '0',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<ModuleFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Module Filter', $container)
    }

    test('labels the filter with "Module Filter"', () => {
      renderComponent()
      equal(filter.labelText, 'Module Filter')
    })

    test('displays the name of the selected module as the value', () => {
      props.selectedModuleId = '2002'
      renderComponent()
      equal(filter.selectedItemLabel, 'Module 2')
    })

    test('displays "All Modules" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Modules')
    })

    QUnit.module('modules list', () => {
      test('labels the "all items" option with "All Modules"', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Modules')
      })

      test('labels each option using the related module name in alphabetical order', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.$options.slice(1).map($option => $option.textContent.trim())
        deepEqual(labels, ['Module 1', 'Module 2'])
      })

      test('disables non-selected options when the filter is disabled', () => {
        props.disabled = true
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Module 2')
        strictEqual($option.getAttribute('aria-disabled'), 'true')
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Module 1')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the module id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Module 1')
        const [selectedModuleId] = props.onSelect.lastCall.args
        strictEqual(selectedModuleId, '2001')
      })

      test('includes "0" when the "All Modules" is clicked', () => {
        props.selectedModuleId = '2001'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Modules')
        const [selectedModuleId] = props.onSelect.lastCall.args
        strictEqual(selectedModuleId, '0')
      })
    })
  })
})
