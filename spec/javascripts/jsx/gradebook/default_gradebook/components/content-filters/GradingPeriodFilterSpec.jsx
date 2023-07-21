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

import GradingPeriodFilter from 'ui/features/gradebook/react/default_gradebook/components/content-filters/GradingPeriodFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('GradingPeriodFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        disabled: false,
        gradingPeriods: [
          {id: '1501', title: 'Q1'},
          {id: '1502', title: 'Q2'},
        ],
        onSelect: sinon.stub(),
        selectedGradingPeriodId: '0',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<GradingPeriodFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Grading Period Filter', $container)
    }

    test('labels the filter with "Grading Period Filter"', () => {
      renderComponent()
      equal(filter.labelText, 'Grading Period Filter')
    })

    test('displays the title of the selected grading period as the value', () => {
      props.selectedGradingPeriodId = '1502'
      renderComponent()
      equal(filter.selectedItemLabel, 'Q2')
    })

    test('displays "All Grading Periods" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Grading Periods')
    })

    QUnit.module('grading periods list', () => {
      test('labels the "all items" option with "All Grading Periods"', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Grading Periods')
      })

      test('labels each option using the related grading period title', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.$options.slice(1).map($option => $option.textContent.trim())
        deepEqual(labels, ['Q1', 'Q2'])
      })

      test('disables non-selected options when the filter is disabled', () => {
        props.disabled = true
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Q2')
        strictEqual($option.getAttribute('aria-disabled'), 'true')
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Q1')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the grading period id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Q1')
        const [selectedGradingPeriodId] = props.onSelect.lastCall.args
        strictEqual(selectedGradingPeriodId, '1501')
      })

      test('includes "0" when the "All Grading Periods" is clicked', () => {
        props.selectedGradingPeriodId = '1501'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Grading Periods')
        const [selectedGradingPeriodId] = props.onSelect.lastCall.args
        strictEqual(selectedGradingPeriodId, '0')
      })
    })
  })
})
