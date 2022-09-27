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

import SectionFilter from '@canvas/gradebook-content-filters/react/SectionFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('SectionFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        disabled: false,
        sections: [
          {id: '2002', name: 'Section 2'},
          {id: '2001', name: 'Section 1'},
        ],
        onSelect: sinon.stub(),
        selectedSectionId: '0',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<SectionFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Section Filter', $container)
    }

    test('labels the filter with "Section Filter"', () => {
      renderComponent()
      equal(filter.labelText, 'Section Filter')
    })

    test('displays the name of the selected section as the value', () => {
      props.selectedSectionId = '2002'
      renderComponent()
      equal(filter.selectedItemLabel, 'Section 2')
    })

    test('displays "All Sections" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Sections')
    })

    QUnit.module('sections list', () => {
      test('labels the "all items" option with "All Sections"', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Sections')
      })

      test('labels each option using the related section name in alphabetical order', () => {
        renderComponent()
        filter.clickToExpand()
        const labels = filter.$options.slice(1).map($option => $option.textContent.trim())
        deepEqual(labels, ['Section 1', 'Section 2'])
      })

      test('disables non-selected options when the filter is disabled', () => {
        props.disabled = true
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Section 2')
        strictEqual($option.getAttribute('aria-disabled'), 'true')
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Section 1')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the section id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Section 1')
        const [selectedSectionId] = props.onSelect.lastCall.args
        strictEqual(selectedSectionId, '2001')
      })

      test('includes "0" when the "All Sections" is clicked', () => {
        props.selectedSectionId = '2001'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Sections')
        const [selectedSectionId] = props.onSelect.lastCall.args
        strictEqual(selectedSectionId, '0')
      })
    })
  })
})
