/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import fakeENV from 'helpers/fakeENV'
import GradingStandard from '@canvas/grading-standard-collection/react/gradingStandard'

QUnit.module('GradingStandard', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      editing: false,
      justAdded: false,
      othersEditing: false,
      permissions: {manage: true},
      round(number) {
        return Math.round(number * 100) / 100
      },
      onDeleteGradingStandard: sinon.spy(),
      onSaveGradingStandard: sinon.spy(),
      onSetEditingStatus: sinon.spy(),
      standard: {
        context_code: 'course_1201',
        context_id: '1201',
        context_name: 'Calculus 101',
        context_type: 'Course',
        data: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0],
        ],
        id: '5001',
        title: 'Example Grading Scheme',
      },
      uniqueId: '5001',
    }

    fakeENV.setup({context_asset_string: 'course_1201'})
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    fakeENV.teardown()
  })

  function mountComponent() {
    wrapper = mount(<GradingStandard {...props} />)
  }

  function addRowAfter(rowIndex) {
    const dataRow = wrapper.find('.grading_standard_row').at(rowIndex)
    dataRow.find('.insert_row_button').simulate('click')
  }

  function removeRow(rowIndex) {
    const dataRow = wrapper.find('.grading_standard_row').at(rowIndex)
    dataRow.find('.delete_row_button').simulate('click')
  }

  function setRowName(rowIndex, name) {
    const dataRow = wrapper.find('.grading_standard_row').at(rowIndex)
    const input = dataRow.find('input.standard_name')
    input.simulate('change', {target: {value: name}})
  }

  function setRowMinScore(rowIndex, score) {
    const dataRow = wrapper.find('.grading_standard_row').at(rowIndex)
    const input = dataRow.find('input.standard_value')
    input.simulate('change', {target: {value: score}})
    input.simulate('blur')
  }

  QUnit.module('when not being edited', () => {
    test('includes the grading scheme id the id of the container', () => {
      mountComponent()
      strictEqual(wrapper.find('#grading_standard_5001').length, 1)
    })

    test('displays the grading scheme title', () => {
      mountComponent()
      const title = wrapper.find('.title').text()
      ok(title.includes('Example Grading Scheme'))
    })

    test('displays an edit button', () => {
      mountComponent()
      const button = wrapper.find('.edit_grading_standard_button')
      strictEqual(button.length, 1)
    })

    test('screenreader text contains contextual label describing scheme to edit', () => {
      mountComponent()
      ok(
        wrapper
          .find('.screenreader-only')
          .map(elem => elem.text())
          .find(text => text === 'Edit Grading Scheme Example Grading Scheme')
      )
    })

    test('does not display the button as read-only', () => {
      mountComponent()
      const button = wrapper.find('.edit_grading_standard_button')
      strictEqual(button.hasClass('read_only'), false)
    })

    test('displays a delete button', () => {
      mountComponent()
      const button = wrapper.find('.delete_grading_standard_button')
      strictEqual(button.length, 1)
    })

    test('screenreader text contains contextual label describing scheme to delete', () => {
      mountComponent()
      ok(
        wrapper
          .find('.screenreader-only')
          .map(elem => elem.text())
          .find(text => text === 'Delete Grading Scheme Example Grading Scheme')
      )
    })

    test('does not display a save button', () => {
      mountComponent()
      const button = wrapper.find('.save_button')
      strictEqual(button.length, 0)
    })

    test('does not display a cancel button', () => {
      mountComponent()
      const button = wrapper.find('.cancel_button')
      strictEqual(button.length, 0)
    })
  })

  QUnit.module('when clicking the "Edit" button', hooks => {
    hooks.beforeEach(() => {
      props.onSetEditingStatus = sinon.spy()
      mountComponent()
      wrapper.find('.edit_grading_standard_button').simulate('click')
    })

    test('calls the onSetEditingStatus prop', () => {
      strictEqual(props.onSetEditingStatus.callCount, 1)
    })

    test('includes the unique id of the grading scheme when calling the onSetEditingStatus prop', () => {
      const [uniqueId] = props.onSetEditingStatus.lastCall.args
      strictEqual(uniqueId, '5001')
    })

    test('sets the editing status to true when calling the onSetEditingStatus prop', () => {
      const [, status] = props.onSetEditingStatus.lastCall.args
      strictEqual(status, true)
    })
  })

  QUnit.module('when clicking the "Delete" button', hooks => {
    hooks.beforeEach(() => {
      props.onDeleteGradingStandard = sinon.spy()
      mountComponent()
      wrapper.find('.delete_grading_standard_button').simulate('click')
    })

    test('calls the onDeleteGradingStandard prop', () => {
      strictEqual(props.onDeleteGradingStandard.callCount, 1)
    })

    test('includes the unique id of the grading scheme when calling the onDeleteGradingStandard prop', () => {
      const [, uniqueId] = props.onDeleteGradingStandard.lastCall.args
      strictEqual(uniqueId, '5001')
    })
  })

  QUnit.module('when editing', contextHooks => {
    contextHooks.beforeEach(() => {
      props.editing = true
      mountComponent()
    })

    test('does not display an edit button', () => {
      const button = wrapper.find('.edit_grading_standard_button')
      strictEqual(button.length, 0)
    })

    test('does not display a delete button', () => {
      const button = wrapper.find('.delete_grading_standard_button')
      strictEqual(button.length, 0)
    })

    test('displays a save button', () => {
      const button = wrapper.find('.save_button')
      strictEqual(button.length, 1)
    })

    test('uses "Save" as the save button text', () => {
      const button = wrapper.find('.save_button')
      equal(button.text(), 'Save')
    })

    test('displays a cancel button', () => {
      const button = wrapper.find('.cancel_button')
      strictEqual(button.length, 1)
    })
  })

  QUnit.module('when editing and removing a row', contextHooks => {
    contextHooks.beforeEach(() => {
      props.editing = true
    })

    test('removes the related row', () => {
      mountComponent()
      removeRow(1)
      const rows = wrapper.find('.grading_standard_row')
      const rowNames = rows.map(row => row.find('input.standard_name').prop('value'))
      deepEqual(rowNames, ['A', 'C', 'D', 'F'])
    })

    test('does not include a delete button when only one row is present', () => {
      props.standard.data.splice(1)
      mountComponent()
      const buttons = wrapper.find('.delete_row_button')
      strictEqual(buttons.length, 0)
    })
  })

  QUnit.module('when editing and adding a row', contextHooks => {
    contextHooks.beforeEach(() => {
      props.editing = true
    })

    test('inserts an unnamed row after the related row', () => {
      mountComponent()
      addRowAfter(1)
      const rows = wrapper.find('.grading_standard_row')
      const rowNames = rows.map(row => row.find('input.standard_name').prop('value'))
      deepEqual(rowNames, ['A', 'B', '', 'C', 'D', 'F'])
    })

    test('assigns a minimum score value to the inserted row between adjacent row scores', () => {
      mountComponent()
      addRowAfter(1)
      const rows = wrapper.find('.grading_standard_row')
      const rowScores = rows.map(row => row.find('input.standard_value').prop('value'))
      deepEqual(rowScores, ['0.9', '0.8', '0.75', '0.7', '0.6', '0'])
    })

    test('assigns a minimum score of 0 to a row added after the last row', () => {
      mountComponent()
      addRowAfter(4)
      const rows = wrapper.find('.grading_standard_row')
      const rowScores = rows.map(row => row.find('input.standard_value').prop('value'))
      deepEqual(rowScores, ['0.9', '0.8', '0.7', '0.6', '0', '0'])
    })

    test('uses a score of 0 when a new last row is added and the previous last row was not zero', () => {
      mountComponent()
      setRowMinScore(4, 0.5)
      addRowAfter(4)
      const rows = wrapper.find('.grading_standard_row')
      const rowScores = rows.map(row => row.find('input.standard_value').prop('value'))
      deepEqual(rowScores, ['0.9', '0.8', '0.7', '0.6', '0.5', '0'])
    })
  })

  QUnit.module('when saving edits', contextHooks => {
    contextHooks.beforeEach(() => {
      props.editing = true
      mountComponent()
    })

    function save() {
      wrapper.find('.save_button').simulate('click')
    }

    function getSavedGradingScheme() {
      return props.onSaveGradingStandard.lastCall.args[0]
    }

    QUnit.module('when nothing was changed', () => {
      test('calls onSaveGradingStandard', () => {
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
      })

      test('calls onSaveGradingStandard with the grading scheme', () => {
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
        deepEqual(getSavedGradingScheme(), props.standard)
      })

      test('disables the save button', () => {
        save()
        const button = wrapper.find('.save_button')
        ok(button.prop('disabled'))
      })

      test('updates the save button to show "Saving..."', () => {
        save()
        const button = wrapper.find('.save_button')
        equal(button.text(), 'Saving...')
      })
    })

    QUnit.module('when the title was changed', hooks => {
      hooks.beforeEach(() => {
        const input = wrapper.find('input.scheme_name')
        input.simulate('change', {target: {value: 'Emoji Grading Scheme'}})
      })

      test('calls onSaveGradingStandard', () => {
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
      })

      test('saves with the updated title', () => {
        save()
        equal(getSavedGradingScheme().title, 'Emoji Grading Scheme')
      })
    })

    QUnit.module('when a row name was changed', () => {
      test('calls onSaveGradingStandard when the new name is valid', () => {
        setRowName(0, 'A+')
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
      })

      test('saves with the updated row name', () => {
        setRowName(0, 'A+')
        save()
        const {data} = getSavedGradingScheme()
        equal(data[0][0], 'A+')
      })

      test('does not call onSaveGradingStandard when the new name is a duplicate', () => {
        setRowName(0, 'B')
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about duplicate row names', () => {
        setRowName(0, 'B')
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have duplicate or empty row names.'))
      })

      test('does not call onSaveGradingStandard when the new name is blank', () => {
        setRowName(0, '')
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about empty row names', () => {
        setRowName(0, '')
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have duplicate or empty row names.'))
      })
    })

    QUnit.module('when a row minimum score was changed', () => {
      test('calls onSaveGradingStandard when the new score is valid', () => {
        setRowMinScore(0, 0.95)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
      })

      test('saves with the updated row score', () => {
        setRowMinScore(0, 0.95)
        save()
        const {data} = getSavedGradingScheme()
        strictEqual(data[0][1], '0.95')
      })

      test('does not call onSaveGradingStandard when the row score overlaps', () => {
        setRowMinScore(1, 0.91)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about overlapping ranges', () => {
        setRowMinScore(1, 0.91)
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have overlapping or empty ranges.'))
      })

      test('does not accept two scores which overlap after rounding to two decimal places', () => {
        setRowMinScore(0, 0.92)
        setRowMinScore(1, 0.91996)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })
    })

    QUnit.module('when a row was added', hooks => {
      hooks.beforeEach(() => {
        addRowAfter(0)
      })

      test('calls onSaveGradingStandard when the new row is valid', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, 0.89)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 1)
      })

      test('saves with the added row having the given name', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, 0.89)
        save()
        const {data} = getSavedGradingScheme()
        equal(data[1][0], 'B+')
      })

      test('saves with the added row having the given value', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, 0.89)
        save()
        const {data} = getSavedGradingScheme()
        equal(data[1][1], 0.89)
      })

      test('does not call onSaveGradingStandard when the new row name is a duplicate', () => {
        setRowName(1, 'B')
        setRowMinScore(1, 0.89)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about duplicate row names', () => {
        setRowName(1, 'B')
        setRowMinScore(1, 0.89)
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have duplicate or empty row names.'))
      })

      test('does not call onSaveGradingStandard when the new row name is blank', () => {
        setRowName(1, '')
        setRowMinScore(1, 0.89)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about blank row names', () => {
        setRowName(1, '')
        setRowMinScore(1, 0.89)
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have duplicate or empty row names.'))
      })

      test('does not call onSaveGradingStandard when the row score overlaps', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, 0.91)
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about overlapping ranges', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, 0.91)
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have overlapping or empty ranges.'))
      })

      test('does not call onSaveGradingStandard when the row score is blank', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, '5') // trigger a change
        setRowMinScore(1, '') // clear it again
        save()
        strictEqual(props.onSaveGradingStandard.callCount, 0)
      })

      test('displays a validation message about empty ranges', () => {
        setRowName(1, 'B+')
        setRowMinScore(1, '5') // trigger a change
        setRowMinScore(1, '') // clear it again
        save()
        const message = wrapper.find('#invalid_standard_message_5001').text()
        ok(message.includes('Cannot have overlapping or empty ranges.'))
      })
    })

    QUnit.module('when a row was removed', () => {
      test('saves without the removed row', () => {
        removeRow(1)
        save()
        const {data} = getSavedGradingScheme()
        deepEqual(
          data.map(datum => datum[0]),
          ['A', 'C', 'D', 'F']
        )
      })
    })
  })

  QUnit.module('when canceling edits', contextHooks => {
    contextHooks.beforeEach(() => {
      props.editing = true
      mountComponent()
      wrapper.find('.cancel_button').simulate('click')
    })

    test('calls onSetEditingStatus when the cancel button is clicked', () => {
      strictEqual(props.onSetEditingStatus.callCount, 1)
    })

    test('includes the unique id of the grading scheme when calling the onSetEditingStatus prop', () => {
      const [uniqueId] = props.onSetEditingStatus.lastCall.args
      strictEqual(uniqueId, '5001')
    })

    test('sets the editing status to false when calling the onSetEditingStatus prop', () => {
      const [, editing] = props.onSetEditingStatus.lastCall.args
      strictEqual(editing, false)
    })
  })

  QUnit.module('when an assignment using the grading scheme has been assessed', hooks => {
    hooks.beforeEach(() => {
      props.standard['assessed_assignment?'] = true
    })

    test('sets the id of the container to "grading_standard_blank"', () => {
      mountComponent()
      strictEqual(wrapper.find('#grading_standard_blank').length, 1)
    })

    test('displays the edit button as read-only', () => {
      mountComponent()
      const button = wrapper.find('.edit_grading_standard_button')
      strictEqual(button.hasClass('read_only'), true)
    })
  })

  QUnit.module('when another grading scheme is being edited', contextHooks => {
    contextHooks.beforeEach(() => {
      props.othersEditing = true
      mountComponent()
    })

    test('disables the edit button', () => {
      const button = wrapper.find('.disabled-buttons .icon-edit')
      strictEqual(button.length, 1)
    })

    test('disables the delete button', () => {
      const button = wrapper.find('.disabled-buttons .icon-trash')
      strictEqual(button.length, 1)
    })
  })

  QUnit.module('when the grading scheme belongs to a different context', contextHooks => {
    contextHooks.beforeEach(() => {
      ENV.context_asset_string = 'course_1202'
    })

    test('displays the context type and name', () => {
      mountComponent()
      equal(wrapper.find('div.cannot-manage-notification').text(), '(course: Calculus 101)')
    })

    test('displays only the context type when the grading standard has no context name', () => {
      delete props.standard.context_name
      mountComponent()
      equal(wrapper.find('div.cannot-manage-notification').text(), '(course level)')
    })

    test('disables the options menu when another grading scheme is being edited', () => {
      props.othersEditing = true
      mountComponent()
      strictEqual(wrapper.find('div.cannot-manage-notification').length, 1)
    })
  })

  QUnit.module('when the user cannot manage the grading scheme', contextHooks => {
    contextHooks.beforeEach(() => {
      props.permissions.manage = false
    })

    test('displays a "cannot manage" message', () => {
      mountComponent()
      strictEqual(wrapper.find('div.cannot-manage-notification').length, 1)
    })

    test('displays the grading scheme title', () => {
      mountComponent()
      const title = wrapper.find('.title').text()
      ok(title.includes('Example Grading Scheme'))
    })

    test('displays the context type and name', () => {
      mountComponent()
      equal(wrapper.find('div.cannot-manage-notification').text(), '(course: Calculus 101)')
    })

    test('displays only the context type when the grading standard has no context name', () => {
      delete props.standard.context_name
      mountComponent()
      equal(wrapper.find('div.cannot-manage-notification').text(), '(course level)')
    })
  })
})
