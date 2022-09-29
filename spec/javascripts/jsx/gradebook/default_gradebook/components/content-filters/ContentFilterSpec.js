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

import ContentFilter from '@canvas/gradebook-content-filters/react/ContentFilter'
import ContentFilterDriver from './ContentFilterDriver'

QUnit.module('Gradebook > Default Gradebook > Components > Content Filters', () => {
  QUnit.module('ContentFilter', suiteHooks => {
    let $container
    let component
    let filter
    let props

    suiteHooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))

      props = {
        allItemsId: 'all',
        allItemsLabel: 'All Items',
        disabled: false,
        items: [
          {id: '1', name: 'Item 1'},
          {id: '2', name: 'Item 2'},
        ],
        label: 'Example Filter',
        onSelect: sinon.stub(),
        selectedItemId: 'all',
      }

      component = null
    })

    suiteHooks.afterEach(() => {
      component.unmount()
      $container.remove()
    })

    function renderComponent() {
      component = render(<ContentFilter {...props} />, {container: $container})
      filter = ContentFilterDriver.findWithLabelText('Example Filter', $container)
    }

    test('labels the filter using the given .label', () => {
      renderComponent()
      equal(filter.labelText, 'Example Filter')
    })

    test('displays the label of the selected item as the value', () => {
      props.selectedItemId = '2'
      renderComponent()
      equal(filter.selectedItemLabel, 'Item 2')
    })

    test('displays "All Items" as the value when selected', () => {
      renderComponent()
      equal(filter.selectedItemLabel, 'All Items')
    })

    QUnit.module('options list', () => {
      test('is collapsed when the filter is initially rendered', () => {
        renderComponent()
        equal(filter.isExpanded, false)
      })

      test('is expanded when the input is clicked', () => {
        renderComponent()
        filter.clickToExpand()
        equal(filter.isExpanded, true)
      })

      test('includes an option for each item plus the "all items" option', () => {
        renderComponent()
        filter.clickToExpand()
        strictEqual(filter.$options.length, props.items.length + 1)
      })

      test('labels the "all items" option using the given .allItemsLabel', () => {
        renderComponent()
        filter.clickToExpand()
        const $allItemsOption = filter.$options[0]
        equal($allItemsOption.textContent.trim(), 'All Items')
      })

      test('labels each item option using the related item .name', () => {
        renderComponent()
        filter.clickToExpand()
        deepEqual(filter.optionLabels.slice(1), ['Item 1', 'Item 2'])
      })

      QUnit.module('when sortAlphabetically is enabled', hooks => {
        hooks.beforeEach(() => {
          props.sortAlphabetically = true
          props.items = [
            {id: '2', name: 'Item 2'},
            {id: '1', name: 'Item 1'},
          ]
        })

        test('labels each item option using the related item .name in alphabetical order', () => {
          renderComponent()
          filter.clickToExpand()
          deepEqual(filter.optionLabels.slice(1), ['Item 1', 'Item 2'])
        })
      })

      QUnit.module('when using option groups', hooks => {
        hooks.beforeEach(() => {
          props.items = [
            {
              children: [
                {id: '11', name: 'Item A1'},
                {id: '12', name: 'Item A2'},
              ],
              id: '1',
              name: 'Group A',
            },

            {
              id: '3',
              name: 'Root Item',
            },

            {
              children: [
                {id: '21', name: 'Item B1'},
                {id: '22', name: 'Item B2'},
              ],
              id: '2',
              name: 'Group B',
            },
          ]
        })

        test('includes an option group for each item with children', () => {
          renderComponent()
          filter.clickToExpand()
          strictEqual(filter.$optionGroups.length, 2)
        })

        test('labels each option group using the related item .name', () => {
          renderComponent()
          filter.clickToExpand()
          deepEqual(filter.optionGroupLabels, ['Group A', 'Group B'])
        })
      })
    })

    QUnit.module('active option', () => {
      test('starts as the selected option', () => {
        props.selectedItemId = '2'
        renderComponent()
        filter.clickToExpand()
        equal(filter.activeItemLabel, 'Item 2')
      })

      test('starts as the "all items" option when selected', () => {
        renderComponent()
        filter.clickToExpand()
        equal(filter.activeItemLabel, 'All Items')
      })

      QUnit.module('when handling down arrow', () => {
        test('activates the option after the current active option', () => {
          renderComponent()
          filter.clickToExpand()
          filter.keyDown(40)
          equal(filter.activeItemLabel, 'Item 1')
        })
      })

      QUnit.module('when handling up arrow', () => {
        test('activates the option previous to the current active option', () => {
          props.selectedItemId = '2'
          renderComponent()
          filter.clickToExpand()
          filter.keyDown(38)
          equal(filter.activeItemLabel, 'Item 1')
        })
      })
    })

    QUnit.module('clicking an options list item', () => {
      test('calls the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Item 1')
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the item .id when calling the .onSelect callback', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Item 1')
        const [selectedItemId] = props.onSelect.lastCall.args
        strictEqual(selectedItemId, '1')
      })

      test('uses the .allItemsId when the "all items" option is clicked', () => {
        props.selectedItemId = '1'
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('All Items')
        const [selectedItemId] = props.onSelect.lastCall.args
        strictEqual(selectedItemId, 'all')
      })

      test('collapses the options list', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Item 1')
        strictEqual(filter.isExpanded, false)
      })

      QUnit.module('when clicking the currently selected item', contextHooks => {
        contextHooks.beforeEach(() => {
          props.selectedItemId = '1'
          renderComponent()
          filter.clickToExpand()
          filter.clickToSelectOption('Item 1')
        })

        test('does not call the .onSelect callback', () => {
          strictEqual(props.onSelect.callCount, 0)
        })

        test('collapses the options list', () => {
          strictEqual(filter.isExpanded, false)
        })
      })
    })

    QUnit.module('when the filter is disabled', contextHooks => {
      contextHooks.beforeEach(() => {
        props.disabled = true
      })

      function isDisabled($option) {
        return $option.getAttribute('aria-disabled') === 'true'
      }

      test('can still be expanded', () => {
        renderComponent()
        filter.clickToExpand()
        strictEqual(filter.isExpanded, true)
      })

      test('does not disable the selected item', () => {
        props.selectedItemId = '1'
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Item 1')
        strictEqual(isDisabled($option), false)
      })

      test('disables items not selected', () => {
        props.selectedItemId = '1'
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('Item 2')
        strictEqual(isDisabled($option), true)
      })

      test('disables the "all items" option when not selected', () => {
        props.selectedItemId = '1'
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('All Items')
        strictEqual(isDisabled($option), true)
      })

      test('does not disable the "all items" option when selected', () => {
        renderComponent()
        filter.clickToExpand()
        const $option = filter.getOptionWithLabel('All Items')
        strictEqual(isDisabled($option), false)
      })

      test('does not call the .onSelect callback when clicking an option', () => {
        renderComponent()
        filter.clickToExpand()
        filter.clickToSelectOption('Item 2')
        strictEqual(props.onSelect.callCount, 0)
      })
    })
  })
})
