/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {mount} from 'enzyme'

import GradebookFilter from 'jsx/gradezilla/default_gradebook/components/GradebookFilter'

QUnit.module('Gradezilla > Default Gradebook > Components > GradebookFilter', suiteHooks => {
  let $container
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      disabled: false,
      items: [{id: '1', name: 'Item 1', position: 2}, {id: '2', name: 'Item 2', position: 1}],
      onSelect: sinon.stub(),
      selectedItemId: '0'
    }

    wrapper = null
    renderComponent()
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  function renderComponent() {
    if (wrapper == null) {
      wrapper = mount(<GradebookFilter {...props} />)
    } else {
      wrapper.setProps(props)
    }
  }

  function getContainer() {
    return wrapper.getDOMNode()
  }

  function getSelect() {
    return getContainer().querySelector('select')
  }

  function getOption(optionLabel) {
    return [...getSelect().querySelectorAll('option')].find(
      $option => $option.textContent.trim() === optionLabel
    )
  }

  function changeValue(value) {
    wrapper.find('select').simulate('change', {target: {value}})
  }

  test('renders a Select component', () => {
    strictEqual(wrapper.find('Select').length, 1)
  })

  test('renders a screenreader-friendly label', () => {
    strictEqual(wrapper.find('ScreenReaderContent').text(), 'Item Filter')
  })

  test('the Select component has three options', () => {
    strictEqual(wrapper.find('option').length, 3)
  })

  test('the options are in the same order as they were sent in', () => {
    const actualOptionIds = wrapper.find('option').map(opt => opt.instance().value)
    const expectedOptionIds = ['0', '1', '2']

    deepEqual(actualOptionIds, expectedOptionIds)
  })

  test('the options are displayed in the same order as they were sent in', () => {
    const actualOptionIds = wrapper.find('option').map(opt => opt.text())
    const expectedOptionIds = ['All Items', 'Item 1', 'Item 2']

    deepEqual(actualOptionIds, expectedOptionIds)
  })

  test('selecting an option while the control is disabled does not call the onSelect prop', () => {
    props.disabled = true
    renderComponent()
    changeValue('2')

    strictEqual(props.onSelect.callCount, 0)
  })

  QUnit.module('when an option is selected', () => {
    test('calls the .onSelect prop', () => {
      changeValue('2')
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the item id when calling the .onSelect prop', () => {
      changeValue('2')
      strictEqual(props.onSelect.firstCall.args[0], '2')
    })
  })

  QUnit.module('when the filter is disabled', hooks => {
    hooks.beforeEach(() => {
      props = {...props, disabled: true, selectedItemId: '1'}
      renderComponent()
    })

    test('does not disable the `select` element', () => {
      strictEqual(getSelect().disabled, false)
    })

    test('does not disable the "all items" option when selected', () => {
      props.selectedItemId = '0'
      renderComponent()
      strictEqual(getOption('All Items').disabled, false)
    })

    test('disables the "all items" option when a defined option is selected', () => {
      strictEqual(getOption('All Items').disabled, true)
    })

    QUnit.module('when not using optgroups', () => {
      test('does not disable the selected option', () => {
        strictEqual(getOption('Item 1').disabled, false)
      })

      test('disables each defined option not selected', () => {
        strictEqual(getOption('Item 2').disabled, true)
      })
    })

    QUnit.module('when using optgroups', contextHooks => {
      contextHooks.beforeEach(() => {
        props.items = [
          {
            children: [{id: '1001', name: 'Item A1'}, {id: '1002', name: 'Item A2'}],
            id: '10',
            name: 'Collection A'
          },

          {
            children: [{id: '1003', name: 'Item B1'}, {id: '1004', name: 'Item B2'}],
            id: '11',
            name: 'Collection B'
          }
        ]
        props.selectedItemId = '1003'
        renderComponent()
      })

      test('does not disable the selected option', () => {
        strictEqual(getOption('Item B1').disabled, false)
      })

      test('disables each defined option not selected within the same optgroup', () => {
        strictEqual(getOption('Item A2').disabled, true)
      })

      test('disables each defined option not selected within other optgroups', () => {
        strictEqual(getOption('Item A1').disabled, true)
      })
    })

    test('does not call the .onSelect prop when a change event is dispatched', () => {
      props.selectedItemId = '1'
      renderComponent()
      changeValue('2')
      strictEqual(props.onSelect.callCount, 0)
    })
  })

  /* eslint-disable qunit/no-identical-names */
  QUnit.module('when using optgroups', () => {
    /* eslint-enable qunit/no-identical-names */
    test('options containing child options are rendered as optgroups', () => {
      const itemWithChildItems = {
        children: [{id: '1001', name: 'Child 1'}, {id: '1002', name: 'Child 2'}],
        id: '10',
        name: 'Hierarchical'
      }

      props.items = [itemWithChildItems]
      renderComponent()
      ok(wrapper.exists('optgroup[label="Hierarchical"]'))
    })

    test('child options are rendered within their parent optgroup', () => {
      const itemWithChildItems = {
        children: [{id: '1001', name: 'Child 1'}, {id: '1002', name: 'Child 2'}],
        id: '10',
        name: 'Hierarchical'
      }

      props.items = [itemWithChildItems]
      renderComponent()
      deepEqual(
        wrapper.find('optgroup[label="Hierarchical"] option').map(option => option.props().value),
        ['1001', '1002']
      )
    })
  })
})
