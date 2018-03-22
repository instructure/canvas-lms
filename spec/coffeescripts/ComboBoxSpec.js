/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'jquery'
import ComboBox from 'compiled/widget/ComboBox'
import simulateClick from 'helpers/simulateClick'

/* eslint-disable qunit/no-identical-names */

QUnit.module('ComboBox', suiteHooks => {
  let combobox
  let items
  let options

  suiteHooks.beforeEach(() => {
    items = [
      {label: 'Label 1', value: 'value1'},
      {label: 'Label 2', value: 'value2'},
      {label: 'Label 3', value: 'value3'}
    ]
    options = {}
  })

  suiteHooks.afterEach(() => {
    if (combobox != null) {
      combobox.$el.remove()
    }
  })

  function createComboBox() {
    combobox = new ComboBox(items, options)
  }

  function getOptionValues() {
    const $options = $('option', combobox.$menu)
    return [].map.call($options, option => $(option).prop('value'))
  }

  function getOptionLabels() {
    const $options = $('option', combobox.$menu)
    return [].map.call($options, $.text)
  }

  QUnit.module('when initialized', () => {
    test('adds the "ui-combobox" class to the combobox element', () => {
      createComboBox()
      ok(combobox.$el.hasClass('ui-combobox'))
    })

    test('adds the "ui-combobox-prev" class to the "previous" button', () => {
      createComboBox()
      ok(combobox.$prev.hasClass('ui-combobox-prev'))
    })

    test('adds the "ui-combobox-next" class to the "next" button', () => {
      createComboBox()
      ok(combobox.$next.hasClass('ui-combobox-next'))
    })

    test('stores a reference to the select element', () => {
      createComboBox()
      equal(combobox.$menu[0].tagName, 'SELECT')
    })

    test('includes each of the given options', () => {
      createComboBox()
      equal($('option', combobox.$menu).length, 3)
    })

    test('uses the given option labels', () => {
      createComboBox()
      deepEqual(getOptionLabels(), ['Label 1', 'Label 2', 'Label 3'])
    })

    test('uses the given option values', () => {
      createComboBox()
      deepEqual(getOptionValues(), ['value1', 'value2', 'value3'])
    })

    test('selects the first option by default', () => {
      createComboBox()
      equal(combobox.$menu.val(), 'value1')
    })

    test('uses the given label function to set the option labels', () => {
      options.label = item => item.label.toUpperCase()
      createComboBox()
      deepEqual(getOptionLabels(), ['LABEL 1', 'LABEL 2', 'LABEL 3'])
    })

    test('uses the given value function to set the option values', () => {
      options.value = item => item.value.toUpperCase()
      createComboBox()
      deepEqual(getOptionValues(), ['VALUE1', 'VALUE2', 'VALUE3'])
    })

    test('selects the given selected value', () => {
      options.selected = 'value2'
      createComboBox()
      equal(combobox.$menu.val(), 'value2')
    })

    test('matches the selected value using the given value function', () => {
      options.selected = 'VALUE2'
      options.value = item => item.value.toUpperCase()
      createComboBox()
      equal(combobox.$menu.val(), 'VALUE2')
    })
  })

  QUnit.module('#select()', () => {
    test('selects the given value', () => {
      createComboBox()
      combobox.select('value2')
      equal(combobox.$menu.val(), 'value2')
    })

    test('triggers the "change" event', () => {
      createComboBox()
      const spy = sinon.spy()
      combobox.on('change', spy)
      combobox.select('value2')
      equal(spy.callCount, 1)
    })

    test('sends the selected item to the "change" event', () => {
      createComboBox()
      let selectedValue
      combobox.on('change', value => {
        selectedValue = value
      })
      combobox.select('value2')
      equal(selectedValue, items[1])
    })

    test('does not trigger the "change" event for the currently-selected option', () => {
      createComboBox()
      const spy = sinon.spy()
      combobox.on('change', spy)
      combobox.select('value1')
      equal(spy.callCount, 0)
    })
  })

  QUnit.module('clicking the "Previous" button', () => {
    QUnit.module('with an intermediate option selected', hooks => {
      hooks.beforeEach(() => {
        options.selected = 'value2'
      })

      test('selects the previous option', () => {
        createComboBox()
        simulateClick(combobox.$prev[0])
        equal(combobox.$menu.val(), 'value1')
      })

      test('triggers the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$prev[0])
        equal(spy.callCount, 1)
      })

      test('sends the selected item to the "change" event', () => {
        createComboBox()
        let selectedValue
        combobox.on('change', value => {
          selectedValue = value
        })
        simulateClick(combobox.$prev[0])
        equal(selectedValue, items[0])
      })
    })

    QUnit.module('with the first option selected', hooks => {
      hooks.beforeEach(() => {
        options.selected = 'value1'
      })

      test('selects the last value', () => {
        createComboBox()
        simulateClick(combobox.$prev[0])
        equal(combobox.$menu.val(), 'value3')
      })

      test('triggers the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$prev[0])
        equal(spy.callCount, 1)
      })

      test('sends the selected item to the "change" event', () => {
        createComboBox()
        let selectedValue
        combobox.on('change', value => {
          selectedValue = value
        })
        simulateClick(combobox.$prev[0])
        equal(selectedValue, items[2])
      })
    })

    QUnit.module('with only one option', hooks => {
      hooks.beforeEach(() => {
        items = [items[0]]
      })

      test('does not change the selected value', () => {
        createComboBox()
        simulateClick(combobox.$prev[0])
        equal(combobox.$menu.val(), 'value1')
      })

      test('does not trigger the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$prev[0])
        equal(spy.callCount, 0)
      })
    })
  })

  QUnit.module('clicking the "Next" button', () => {
    QUnit.module('with an intermediate option selected', hooks => {
      hooks.beforeEach(() => {
        options.selected = 'value2'
      })

      test('selects the next option', () => {
        createComboBox()
        simulateClick(combobox.$next[0])
        equal(combobox.$menu.val(), 'value3')
      })

      test('triggers the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$next[0])
        equal(spy.callCount, 1)
      })

      test('sends the selected item to the "change" event', () => {
        createComboBox()
        let selectedValue
        combobox.on('change', value => {
          selectedValue = value
        })
        simulateClick(combobox.$next[0])
        equal(selectedValue, items[2])
      })
    })

    QUnit.module('with the last option selected', hooks => {
      hooks.beforeEach(() => {
        options.selected = 'value3'
      })

      test('selects the first value', () => {
        createComboBox()
        simulateClick(combobox.$next[0])
        equal(combobox.$menu.val(), 'value1')
      })

      test('triggers the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$next[0])
        equal(spy.callCount, 1)
      })

      test('sends the selected item to the "change" event', () => {
        createComboBox()
        let selectedValue
        combobox.on('change', value => {
          selectedValue = value
        })
        simulateClick(combobox.$next[0])
        equal(selectedValue, items[0])
      })
    })

    QUnit.module('with only one option', hooks => {
      hooks.beforeEach(() => {
        items = [items[0]]
      })

      test('does not change the selected value', () => {
        createComboBox()
        simulateClick(combobox.$prev[0])
        equal(combobox.$menu.val(), 'value1')
      })

      test('does not trigger the "change" event', () => {
        createComboBox()
        const spy = sinon.spy()
        combobox.on('change', spy)
        simulateClick(combobox.$prev[0])
        equal(spy.callCount, 0)
      })
    })
  })
})
