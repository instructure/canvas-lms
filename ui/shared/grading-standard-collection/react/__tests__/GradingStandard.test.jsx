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
import {fireEvent, render, screen} from '@testing-library/react'
import GradingStandard from '../gradingStandard'

const stubs = {
  onDeleteGradingStandard: jest.fn(),
  onSaveGradingStandard: jest.fn(),
  onSetEditingStatus: jest.fn(),
}
const defaultProps = (props = {}) => ({
  editing: false,
  justAdded: false,
  othersEditing: false,
  permissions: {manage: true},
  round(number) {
    return Math.round(number * 100) / 100
  },
  onDeleteGradingStandard: stubs.onDeleteGradingStandard,
  onSaveGradingStandard: stubs.onSaveGradingStandard,
  onSetEditingStatus: stubs.onSetEditingStatus,
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
  ...props,
})
const renderGradingStandard = (props = {}) => render(<GradingStandard {...defaultProps(props)} />)
const addRowAfter = (container, rowIndex) => {
  const dataRow = container.querySelectorAll('.grading_standard_row')[rowIndex]

  fireEvent.click(dataRow.querySelector('.insert_row_button'))
}
const removeRow = (container, rowIndex) => {
  const dataRow = container.querySelectorAll('.grading_standard_row')[rowIndex]

  fireEvent.click(dataRow.querySelector('.delete_row_button'))
}
const setRowName = (container, rowIndex, name) => {
  const dataRow = container.querySelectorAll('.grading_standard_row')[rowIndex]
  const input = dataRow.querySelector('input.standard_name')

  fireEvent.change(input, {target: {value: name}})
}
const setRowMinScore = (container, rowIndex, score) => {
  const dataRow = container.querySelectorAll('.grading_standard_row')[rowIndex]
  const input = dataRow.querySelector('input.standard_value')

  fireEvent.change(input, {target: {value: score}})
  fireEvent.blur(input)
}
const clickSave = () => {
  fireEvent.click(screen.getByRole('button', {name: /Save/i}))
}
const getSavedGradingScheme = () => {
  return stubs.onSaveGradingStandard.mock.calls[0][0]
}

describe('GradingStandard', () => {
  beforeEach(() => {
    window.ENV = {
      context_asset_string: 'course_1201',
    }
  })

  afterEach(() => {
    delete window.ENV
    jest.clearAllMocks()
  })

  describe('when not being edited', () => {
    it('includes the grading scheme id the id of the container', () => {
      const id = defaultProps().uniqueId

      const {container} = renderGradingStandard()

      expect(container.querySelector(`#grading_standard_${id}`)).toBeInTheDocument()
    })

    it('displays the grading scheme title', () => {
      renderGradingStandard()

      expect(screen.getByText('Example Grading Scheme')).toBeInTheDocument()
    })

    it('displays an edit button', () => {
      renderGradingStandard()

      expect(screen.getByRole('button', {name: /Edit Grading Scheme/i})).toBeInTheDocument()
    })

    it('screenreader text contains contextual label describing scheme to edit', () => {
      renderGradingStandard()

      expect(screen.getByText('Edit Grading Scheme Example Grading Scheme')).toHaveClass(
        'screenreader-only'
      )
    })

    it('does not display the button as read-only', () => {
      renderGradingStandard()

      expect(screen.getByRole('button', {name: /Edit Grading Scheme/i})).not.toHaveClass(
        'read_only'
      )
    })

    it('displays a delete button', () => {
      renderGradingStandard()

      expect(screen.getByRole('button', {name: /Delete Grading Scheme/i})).toBeInTheDocument()
    })

    it('screenreader text contains contextual label describing scheme to delete', () => {
      renderGradingStandard()

      expect(screen.getByText('Delete Grading Scheme Example Grading Scheme')).toHaveClass(
        'screenreader-only'
      )
    })

    it('does not display a clickSave button', () => {
      renderGradingStandard()

      expect(screen.queryByRole('button', {name: /Save/i})).not.toBeInTheDocument()
    })

    it('does not display a cancel button', () => {
      renderGradingStandard()

      expect(screen.queryByRole('button', {name: /Cancel/i})).not.toBeInTheDocument()
    })
  })

  describe('when clicking the "Edit" button', () => {
    beforeEach(() => {
      renderGradingStandard()

      fireEvent.click(screen.getByRole('button', {name: /Edit Grading Scheme/i}))
    })

    it('calls the onSetEditingStatus prop', () => {
      expect(stubs.onSetEditingStatus).toHaveBeenCalledTimes(1)
    })

    it('includes the unique id of the grading scheme when calling the onSetEditingStatus prop', () => {
      expect(stubs.onSetEditingStatus).toHaveBeenCalledWith('5001', true)
    })

    it('sets the editing status to true when calling the onSetEditingStatus prop', () => {
      expect(stubs.onSetEditingStatus).toHaveBeenCalledWith('5001', true)
    })
  })

  describe('when clicking the "Delete" button', () => {
    beforeEach(() => {
      renderGradingStandard()

      fireEvent.click(screen.getByRole('button', {name: /Delete Grading Scheme/i}))
    })

    it('calls the onDeleteGradingStandard prop', () => {
      expect(stubs.onDeleteGradingStandard).toHaveBeenCalledTimes(1)
    })

    it('includes the unique id of the grading scheme when calling the onDeleteGradingStandard prop', () => {
      const [, id] = stubs.onDeleteGradingStandard.mock.calls[0]

      expect(id).toEqual('5001')
    })
  })

  describe('when editing', () => {
    beforeEach(() => {
      renderGradingStandard({
        editing: true,
      })
    })

    it('does not display an edit button', () => {
      expect(screen.queryByRole('button', {name: /Edit Grading Scheme/i})).not.toBeInTheDocument()
    })

    it('does not display a delete button', () => {
      expect(screen.queryByRole('button', {name: /Delete Grading Scheme/i})).not.toBeInTheDocument()
    })

    it('displays a clickSave button', () => {
      expect(screen.getByRole('button', {name: /Save/i})).toBeInTheDocument()
    })

    it('displays a cancel button', () => {
      expect(screen.getByRole('button', {name: /Cancel/i})).toBeInTheDocument()
    })
  })

  describe('when editing and removing a row', () => {
    it('removes the related row', () => {
      const {container} = renderGradingStandard({
        editing: true,
      })

      removeRow(container, 1)

      const rows = container.querySelectorAll('.grading_standard_row')
      const rowNames = Array.from(rows).map(row => row.querySelector('input.standard_name').value)

      expect(rows).toHaveLength(4)
      expect(rowNames).toEqual(['A', 'C', 'D', 'F'])
    })

    it('does not include a delete button when only one row is present', () => {
      const props = defaultProps({
        editing: true,
      })

      props.standard.data.splice(1)

      renderGradingStandard(props)

      expect(screen.queryByRole('button', {name: /Delete Row/i})).not.toBeInTheDocument()
    })
  })

  describe('when editing and adding a row', () => {
    it('inserts an unnamed row after the related row', () => {
      const {container} = renderGradingStandard({
        editing: true,
      })

      addRowAfter(container, 1)

      const rows = container.querySelectorAll('.grading_standard_row')
      const rowNames = Array.from(rows).map(row => row.querySelector('input.standard_name').value)

      expect(rows).toHaveLength(6)
      expect(rowNames).toEqual(['A', 'B', '', 'C', 'D', 'F'])
    })

    it('assigns a minimum score value to the inserted row between adjacent row scores', () => {
      const {container} = renderGradingStandard({
        editing: true,
      })

      addRowAfter(container, 1)

      const rows = container.querySelectorAll('.grading_standard_row')
      const rowScores = Array.from(rows).map(row => row.querySelector('input.standard_value').value)

      expect(rowScores).toEqual(['0.9', '0.8', '0.75', '0.7', '0.6', '0'])
    })

    it('assigns a minimum score of 0 to a row added after the last row', () => {
      const {container} = renderGradingStandard({
        editing: true,
      })

      addRowAfter(container, 4)

      const rows = container.querySelectorAll('.grading_standard_row')
      const rowScores = Array.from(rows).map(row => row.querySelector('input.standard_value').value)

      expect(rowScores).toEqual(['0.9', '0.8', '0.7', '0.6', '0', '0'])
    })

    it('uses a score of 0 when a new last row is added and the previous last row was not zero', () => {
      const {container} = renderGradingStandard({
        editing: true,
      })

      setRowMinScore(container, 4, 0.5)
      addRowAfter(container, 4)

      const rows = container.querySelectorAll('.grading_standard_row')
      const rowScores = Array.from(rows).map(row => row.querySelector('input.standard_value').value)

      expect(rowScores).toEqual(['0.9', '0.8', '0.7', '0.6', '0.5', '0'])
    })
  })

  describe('when saving edits', () => {
    let container

    beforeEach(() => {
      container = renderGradingStandard({
        editing: true,
      }).container
    })

    describe('when nothing was changed', () => {
      it('calls onSaveGradingStandard', () => {
        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(1)
      })

      it('calls onSaveGradingStandard with the grading scheme', () => {
        const {standard} = defaultProps({editing: true})

        clickSave()

        expect(getSavedGradingScheme()).toEqual(standard)
      })

      it('disables the clickSave button', () => {
        clickSave()

        expect(screen.getByRole('button', {name: /Saving.../i})).toBeDisabled()
      })

      it('updates the clickSave button to show "Saving..."', () => {
        clickSave()

        expect(screen.getByRole('button', {name: /Saving.../i})).toBeInTheDocument()
      })
    })

    describe('when the title was changed', () => {
      beforeEach(() => {
        fireEvent.change(screen.getByTitle(/Grading standard title/i), {
          target: {value: 'Emoji Grading Scheme'},
        })
      })

      it('calls onSaveGradingStandard', () => {
        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(1)
      })

      it('saves with the updated title', () => {
        clickSave()

        expect(getSavedGradingScheme().title).toEqual('Emoji Grading Scheme')
      })
    })

    describe('when a row name was changed', () => {
      it('calls onSaveGradingStandard when the new name is valid', () => {
        setRowName(container, 0, 'A+')

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(1)
      })

      it('saves with the updated row name', () => {
        setRowName(container, 0, 'A+')

        clickSave()

        const {data} = getSavedGradingScheme()

        expect(data[0][0]).toEqual('A+')
      })

      it('does not call onSaveGradingStandard when the new name is a duplicate', () => {
        setRowName(container, 0, 'B')

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about duplicate row names', () => {
        setRowName(container, 0, 'B')

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have duplicate or empty row names.')
      })

      it('does not call onSaveGradingStandard when the new name is blank', () => {
        setRowName(container, 0, '')

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about empty row names', () => {
        setRowName(container, 0, '')

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have duplicate or empty row names.')
      })
    })

    describe('when a row minimum score was changed', () => {
      it('calls onSaveGradingStandard when the new score is valid', () => {
        setRowMinScore(container, 0, 0.95)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(1)
      })

      it('saves with the updated row score', () => {
        setRowMinScore(container, 0, 0.95)

        clickSave()

        const {data} = getSavedGradingScheme()

        expect(data[0][1]).toEqual('0.95')
      })

      it('does not call onSaveGradingStandard when the row score overlaps', () => {
        setRowMinScore(container, 1, 0.91)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about overlapping ranges', () => {
        setRowMinScore(container, 1, 0.91)

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have overlapping or empty ranges.')
      })

      it('does not accept two scores which overlap after rounding to two decimal places', () => {
        setRowMinScore(container, 0, 0.92)
        setRowMinScore(container, 1, 0.91996)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })
    })

    describe('when a row was added', () => {
      beforeEach(() => {
        addRowAfter(container, 0)
      })

      it('calls onSaveGradingStandard when the new row is valid', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(1)
      })

      it('saves with the added row having the given name', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        const {data} = getSavedGradingScheme()

        expect(data[1][0]).toEqual('B+')
      })

      it('saves with the added row having the given value', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        const {data} = getSavedGradingScheme()

        expect(data[1][1]).toEqual('0.89')
      })

      it('does not call onSaveGradingStandard when the new row name is a duplicate', () => {
        setRowName(container, 1, 'B')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about duplicate row names', () => {
        setRowName(container, 1, 'B')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have duplicate or empty row names.')
      })

      it('does not call onSaveGradingStandard when the new row name is blank', () => {
        setRowName(container, 1, '')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about blank row names', () => {
        setRowName(container, 1, '')
        setRowMinScore(container, 1, 0.89)

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have duplicate or empty row names.')
      })

      it('does not call onSaveGradingStandard when the row score overlaps', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, 0.91)

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about overlapping ranges', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, 0.91)

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have overlapping or empty ranges.')
      })

      it('does not call onSaveGradingStandard when the row score is blank', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, '5') // trigger a change
        setRowMinScore(container, 1, '') // clear it again

        clickSave()

        expect(stubs.onSaveGradingStandard).toHaveBeenCalledTimes(0)
      })

      it('displays a validation message about empty ranges', () => {
        setRowName(container, 1, 'B+')
        setRowMinScore(container, 1, '5') // trigger a change
        setRowMinScore(container, 1, '') // clear it again

        clickSave()

        const message = container.querySelector('#invalid_standard_message_5001').textContent

        expect(message).toContain('Cannot have overlapping or empty ranges.')
      })
    })

    describe('when a row was removed', () => {
      it('saves without the removed row', () => {
        removeRow(container, 1)

        clickSave()

        const {data} = getSavedGradingScheme()

        expect(data.map(datum => datum[0])).toEqual(['A', 'C', 'D', 'F'])
      })
    })
  })

  describe('when canceling edits', () => {
    beforeEach(() => {
      renderGradingStandard({
        editing: true,
      })

      fireEvent.click(screen.getByRole('button', {name: /Cancel/i}))
    })

    it('calls onSetEditingStatus when the cancel button is clicked', () => {
      expect(stubs.onSetEditingStatus).toHaveBeenCalledTimes(1)
    })

    it('includes the unique id of the grading scheme and editing status when calling the onSetEditingStatus prop', () => {
      expect(stubs.onSetEditingStatus).toHaveBeenCalledWith('5001', false)
    })
  })

  describe('when an assignment using the grading scheme has been assessed', () => {
    let props

    beforeEach(() => {
      props = defaultProps()

      props.standard['assessed_assignment?'] = true
    })

    it('sets the id of the container to "grading_standard_blank"', () => {
      const {container} = renderGradingStandard(props)

      expect(container.querySelector('#grading_standard_blank')).toBeInTheDocument()
    })

    it('displays the edit button as read-only', () => {
      const {container} = renderGradingStandard(props)

      expect(container.querySelector('.edit_grading_standard_button')).toHaveClass('read_only')
    })
  })

  describe('when another grading scheme is being edited', () => {
    let container

    beforeEach(() => {
      container = renderGradingStandard({
        othersEditing: true,
      }).container
    })

    it('disables the edit button', () => {
      expect(container.querySelector('.disabled-buttons .icon-edit')).toBeInTheDocument()
    })

    it('disables the delete button', () => {
      expect(container.querySelector('.disabled-buttons .icon-trash')).toBeInTheDocument()
    })
  })

  describe('when the grading scheme belongs to a different context', () => {
    beforeEach(() => {
      ENV.context_asset_string = 'course_1202'
    })

    it('displays the context type and name', () => {
      renderGradingStandard()

      expect(screen.getByText('(course: Calculus 101)')).toBeInTheDocument()
    })

    it('displays only the context type when the grading standard has no context name', () => {
      const props = defaultProps()

      delete props.standard.context_name

      renderGradingStandard(props)

      expect(screen.getByText('(course level)')).toBeInTheDocument()
    })

    it('disables the options menu when another grading scheme is being edited', () => {
      const {container} = renderGradingStandard({
        othersEditing: true,
      })

      expect(container.querySelector('div.cannot-manage-notification')).toBeInTheDocument()
    })
  })

  describe('when the user cannot manage the grading scheme', () => {
    let props

    beforeEach(() => {
      props = defaultProps()
      props.permissions.manage = false
    })

    it('displays a "cannot manage" message', () => {
      const {container} = renderGradingStandard(props)

      expect(container.querySelector('div.cannot-manage-notification')).toBeInTheDocument()
    })

    it('displays the grading scheme title', () => {
      renderGradingStandard(props)

      expect(screen.getByText('Example Grading Scheme')).toBeInTheDocument()
    })

    it('displays the context type and name', () => {
      renderGradingStandard(props)

      expect(screen.getByText('(course: Calculus 101)')).toBeInTheDocument()
    })

    it('displays only the context type when the grading standard has no context name', () => {
      delete props.standard.context_name

      renderGradingStandard(props)

      expect(screen.getByText('(course level)')).toBeInTheDocument()
    })
  })
})
