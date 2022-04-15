/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {defaultColors, statusColors} from '../../constants/colors'
import ViewOptionsTabPanel from '../ViewOptionsTabPanel'

describe('ViewOptionsTabPanel', () => {
  let props

  const renderPanel = (customProps = {}) =>
    render(<ViewOptionsTabPanel {...props} {...customProps} />)

  beforeEach(() => {
    props = {
      columnSort: {
        currentValue: {criterion: 'points', direction: 'descending'},
        modulesEnabled: true,
        onChange: jest.fn()
      },
      hideAssignmentGroupTotals: {
        checked: false,
        onChange: jest.fn()
      },
      showNotes: {
        checked: true,
        onChange: jest.fn()
      },
      showUnpublishedAssignments: {
        checked: true,
        onChange: jest.fn()
      },
      statusColors: {
        currentValues: statusColors(),
        onChange: jest.fn()
      },
      viewUngradedAsZero: {
        allowed: true,
        checked: true,
        onChange: jest.fn()
      },
      showSeparateFirstLastNames: {
        allowed: true,
        checked: false,
        onChange: jest.fn()
      }
    }
  })

  describe('.columnSort', () => {
    it('includes options for module sorting if .modulesEnabled is true', () => {
      const {getByRole} = renderPanel({columnSort: {...props.columnSort, modulesEnabled: true}})
      const selectButton = getByRole('button', {name: /Arrange By/})
      fireEvent.click(selectButton)
      expect(getByRole('option', {name: /Module - First to Last/})).toBeInTheDocument()
      expect(getByRole('option', {name: /Module - Last to First/})).toBeInTheDocument()
    })

    it('omits options for module sorting if .modulesEnabled is false', () => {
      const {getByRole, queryByRole} = renderPanel({
        columnSort: {...props.columnSort, modulesEnabled: false}
      })
      const selectButton = getByRole('button', {name: /Arrange By/})
      fireEvent.click(selectButton)
      expect(queryByRole('option', {name: /Module - First to Last/})).not.toBeInTheDocument()
      expect(queryByRole('option', {name: /Module - Last to First/})).not.toBeInTheDocument()
    })

    it('defaults to the sort option expressed by .currentValue', () => {
      const {getByRole} = renderPanel({
        columnSort: {
          ...props.columnSort,
          currentValue: {criterion: 'points', direction: 'ascending'}
        }
      })
      const selectButton = getByRole('button', {name: /Arrange By/})
      expect(selectButton).toHaveValue('Points - Lowest to Highest')
    })

    it('defaults to the first sort option if .currentValue does not match a sort order', () => {
      const {getByRole} = renderPanel({
        columnSort: {
          ...props.columnSort,
          currentValue: {criterion: 'module_position', direction: 'ascending'},
          modulesEnabled: false
        }
      })
      const selectButton = getByRole('button', {name: /Arrange By/})
      expect(selectButton).toHaveValue('Default Order')
    })

    it('calls .onChange when the user selects a new setting', () => {
      const onChange = jest.fn()
      const {getByRole} = renderPanel({
        columnSort: {...props.columnSort, onChange}
      })

      const selectButton = getByRole('button', {name: /Arrange By/})
      fireEvent.click(selectButton)
      const defaultOrder = getByRole('option', {name: /Default Order/})
      fireEvent.click(defaultOrder)
      expect(onChange).toHaveBeenCalledWith({
        criterion: 'default',
        direction: 'ascending'
      })
    })
  })

  describe('.showNotes', () => {
    it('is checked if .checked is true', () => {
      const {getByRole} = renderPanel({showNotes: {checked: true, onChange: () => {}}})
      expect(getByRole('checkbox', {name: 'Notes'})).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByRole} = renderPanel({showNotes: {checked: false, onChange: () => {}}})
      expect(getByRole('checkbox', {name: 'Notes'})).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByRole} = renderPanel({showNotes: {checked: false, onChange}})

      fireEvent.click(getByRole('checkbox', {name: 'Notes'}))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.showUnpublishedAssignments', () => {
    it('is checked if .checked is true', () => {
      const {getByRole} = renderPanel({
        showUnpublishedAssignments: {checked: true, onChange: () => {}}
      })
      expect(getByRole('checkbox', {name: 'Unpublished Assignments'})).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByRole} = renderPanel({
        showUnpublishedAssignments: {checked: false, onChange: () => {}}
      })
      expect(getByRole('checkbox', {name: 'Unpublished Assignments'})).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByRole} = renderPanel({showUnpublishedAssignments: {checked: false, onChange}})

      fireEvent.click(getByRole('checkbox', {name: 'Unpublished Assignments'}))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.viewUngradedAsZero', () => {
    describe('when .allowed is true', () => {
      it('is checked if .checked is true', () => {
        const {getByRole} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: true, onChange: () => {}}
        })
        expect(getByRole('checkbox', {name: 'View ungraded as 0'})).toBeChecked()
      })

      it('is unchecked if .checked is false', () => {
        const {getByRole} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: false, onChange: () => {}}
        })
        expect(getByRole('checkbox', {name: 'View ungraded as 0'})).not.toBeChecked()
      })

      it('calls .onChange when the user toggles the item', () => {
        const onChange = jest.fn()
        const {getByRole} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: false, onChange}
        })

        fireEvent.click(getByRole('checkbox', {name: 'View ungraded as 0'}))
        expect(onChange).toHaveBeenCalledWith(true)
      })
    })

    it('is not present when .allowed is false', () => {
      const {queryByRole} = renderPanel({
        viewUngradedAsZero: {allowed: false, checked: true, onChange: () => {}}
      })
      expect(queryByRole('checkbox', {name: 'View ungraded as 0'})).not.toBeInTheDocument()
    })
  })

  describe('.hideAssignmentGroupTotals', () => {
    it('is checked if .checked is true', () => {
      const {getByRole} = renderPanel({
        hideAssignmentGroupTotals: {checked: true, onChange: () => {}}
      })
      expect(getByRole('checkbox', {name: 'Hide Assignment Group Totals'})).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByRole} = renderPanel({
        hideAssignmentGroupTotals: {allowed: true, checked: false, onChange: () => {}}
      })
      expect(getByRole('checkbox', {name: 'Hide Assignment Group Totals'})).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByRole} = renderPanel({
        hideAssignmentGroupTotals: {allowed: true, checked: false, onChange}
      })

      fireEvent.click(getByRole('checkbox', {name: 'Hide Assignment Group Totals'}))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.showSeparateFirstLastNames', () => {
    describe('when .allowed is true', () => {
      it('is checked if .checked is true', () => {
        const {getByRole} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: true, onChange: () => {}}
        })
        expect(getByRole('checkbox', {name: 'Split Student Names'})).toBeChecked()
      })

      it('is unchecked if .checked is false', () => {
        const {getByRole} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: false, onChange: () => {}}
        })
        expect(getByRole('checkbox', {name: 'Split Student Names'})).not.toBeChecked()
      })

      it('calls .onChange when the user toggles the item', () => {
        const onChange = jest.fn()
        const {getByRole} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: false, onChange}
        })

        fireEvent.click(getByRole('checkbox', {name: 'Split Student Names'}))
        expect(onChange).toHaveBeenCalledWith(true)
      })
    })

    it('is not present when .allowed is false', () => {
      const {queryByRole} = renderPanel({
        showSeparateFirstLastNames: {allowed: false, checked: true, onChange: () => {}}
      })
      expect(queryByRole('checkbox', {name: 'Split Student Names'})).not.toBeInTheDocument()
    })
  })

  describe('.statusColors', () => {
    it('renders the status color panel with the colors supplied in .currentValues', () => {
      const {getByRole} = renderPanel({
        statusColors: {
          currentValues: {...statusColors(), excused: '#ffffff'},
          onChange: () => {}
        }
      })

      fireEvent.click(getByRole('button', {name: /Excused Color Picker/i}))
      const colorInput = getByRole('textbox', {name: /Enter a hexcode here/})
      expect(colorInput).toHaveValue('#ffffff')
    })

    it('calls .onChange when the user changes a color', () => {
      const onChange = jest.fn()
      const {getByRole} = renderPanel({
        statusColors: {
          currentValues: {...statusColors(), excused: '#ffffff'},
          onChange
        }
      })

      fireEvent.click(getByRole('button', {name: /Excused Color Picker/i}))
      fireEvent.click(getByRole('radio', {name: /salmon/i}))
      fireEvent.click(getByRole('button', {name: /Apply/}))

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({excused: defaultColors.salmon})
      )
    })
  })
})
