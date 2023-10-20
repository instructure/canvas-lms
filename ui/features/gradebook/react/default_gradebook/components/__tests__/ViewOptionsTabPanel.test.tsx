// @ts-nocheck
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
        onChange: jest.fn(),
      },
      finalGradeOverrideEnabled: true,
      hideAssignmentGroupTotals: {
        checked: false,
        onChange: jest.fn(),
      },
      hideTotal: {
        checked: false,
        onChange: jest.fn(),
      },
      showNotes: {
        checked: true,
        onChange: jest.fn(),
      },
      showUnpublishedAssignments: {
        checked: true,
        onChange: jest.fn(),
      },
      statusColors: {
        currentValues: statusColors(),
        onChange: jest.fn(),
      },
      viewUngradedAsZero: {
        allowed: true,
        checked: true,
        onChange: jest.fn(),
      },
      showSeparateFirstLastNames: {
        allowed: true,
        checked: false,
        onChange: jest.fn(),
      },
    }
  })

  describe('.columnSort', () => {
    it('includes options for module sorting if .modulesEnabled is true', () => {
      const {getByText} = renderPanel({columnSort: {...props.columnSort, modulesEnabled: true}})
      const selectButton = getByText(/Arrange By/)
      fireEvent.click(selectButton)
      expect(getByText(/Module - First to Last/)).toBeInTheDocument()
      expect(getByText(/Module - Last to First/)).toBeInTheDocument()
    })

    it('omits options for module sorting if .modulesEnabled is false', () => {
      const {getByText, queryByText} = renderPanel({
        columnSort: {...props.columnSort, modulesEnabled: false},
      })
      const selectButton = getByText(/Arrange By/)
      fireEvent.click(selectButton)
      expect(queryByText(/Module - First to Last/)).not.toBeInTheDocument()
      expect(queryByText(/Module - Last to First/)).not.toBeInTheDocument()
    })

    it('defaults to the sort option expressed by .currentValue', () => {
      const {getByLabelText} = renderPanel({
        columnSort: {
          ...props.columnSort,
          currentValue: {criterion: 'points', direction: 'ascending'},
        },
      })
      const selectButton = getByLabelText(/Arrange By/)
      expect(selectButton).toHaveValue('Points - Lowest to Highest')
    })

    it('defaults to the first sort option if .currentValue does not match a sort order', () => {
      const {getByLabelText} = renderPanel({
        columnSort: {
          ...props.columnSort,
          currentValue: {criterion: 'module_position', direction: 'ascending'},
          modulesEnabled: false,
        },
      })
      const selectButton = getByLabelText(/Arrange By/)
      expect(selectButton).toHaveValue('Default Order')
    })

    it('calls .onChange when the user selects a new setting', () => {
      const onChange = jest.fn()
      const {getByText} = renderPanel({
        columnSort: {...props.columnSort, onChange},
      })

      const selectButton = getByText(/Arrange By/)
      fireEvent.click(selectButton)
      const defaultOrder = getByText(/Default Order/)
      fireEvent.click(defaultOrder)
      expect(onChange).toHaveBeenCalledWith({
        criterion: 'default',
        direction: 'ascending',
      })
    })
  })

  describe('.showNotes', () => {
    it('is checked if .checked is true', () => {
      const {getByLabelText} = renderPanel({showNotes: {checked: true, onChange: () => {}}})
      expect(getByLabelText('Notes')).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByLabelText} = renderPanel({showNotes: {checked: false, onChange: () => {}}})
      expect(getByLabelText('Notes')).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByLabelText} = renderPanel({showNotes: {checked: false, onChange}})

      fireEvent.click(getByLabelText('Notes'))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.showUnpublishedAssignments', () => {
    it('is checked if .checked is true', () => {
      const {getByLabelText} = renderPanel({
        showUnpublishedAssignments: {checked: true, onChange: () => {}},
      })
      expect(getByLabelText('Unpublished Assignments')).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByLabelText} = renderPanel({
        showUnpublishedAssignments: {checked: false, onChange: () => {}},
      })
      expect(getByLabelText('Unpublished Assignments')).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByLabelText} = renderPanel({showUnpublishedAssignments: {checked: false, onChange}})

      fireEvent.click(getByLabelText('Unpublished Assignments'))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.viewUngradedAsZero', () => {
    describe('when .allowed is true', () => {
      it('is checked if .checked is true', () => {
        const {getByLabelText} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: true, onChange: () => {}},
        })
        expect(getByLabelText('View ungraded as 0')).toBeChecked()
      })

      it('is unchecked if .checked is false', () => {
        const {getByLabelText} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: false, onChange: () => {}},
        })
        expect(getByLabelText('View ungraded as 0')).not.toBeChecked()
      })

      it('calls .onChange when the user toggles the item', () => {
        const onChange = jest.fn()
        const {getByLabelText} = renderPanel({
          viewUngradedAsZero: {allowed: true, checked: false, onChange},
        })

        fireEvent.click(getByLabelText('View ungraded as 0'))
        expect(onChange).toHaveBeenCalledWith(true)
      })
    })

    it('is not present when .allowed is false', () => {
      const {queryByText} = renderPanel({
        viewUngradedAsZero: {allowed: false, checked: true, onChange: () => {}},
      })
      expect(queryByText('View ungraded as 0')).not.toBeInTheDocument()
    })
  })

  describe('.hideAssignmentGroupTotals', () => {
    it('is checked if .checked is true', () => {
      const {getByLabelText} = renderPanel({
        hideAssignmentGroupTotals: {checked: true, onChange: () => {}},
      })
      expect(getByLabelText('Hide Assignment Group Totals')).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByLabelText} = renderPanel({
        hideAssignmentGroupTotals: {allowed: true, checked: false, onChange: () => {}},
      })
      expect(getByLabelText('Hide Assignment Group Totals')).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByLabelText} = renderPanel({
        hideAssignmentGroupTotals: {allowed: true, checked: false, onChange},
      })

      fireEvent.click(getByLabelText('Hide Assignment Group Totals'))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.hideTotal', () => {
    it('reads "Hide Total and Override Columns" when "Final Grade Override" is enabled', () => {
      const {getByLabelText} = renderPanel()
      expect(getByLabelText('Hide Total and Override Columns')).toBeInTheDocument()
    })

    it('reads "Hide Total Column" when "Final Grade Override" is disabled', () => {
      props.finalGradeOverrideEnabled = false
      const {getByLabelText} = renderPanel()
      expect(getByLabelText('Hide Total Column')).toBeInTheDocument()
    })

    it('is checked if .checked is true', () => {
      const {getByLabelText} = renderPanel({
        hideTotal: {checked: true, onChange: () => {}},
      })
      expect(getByLabelText('Hide Total and Override Columns')).toBeChecked()
    })

    it('is unchecked if .checked is false', () => {
      const {getByLabelText} = renderPanel({
        hideTotal: {allowed: true, checked: false, onChange: () => {}},
      })
      expect(getByLabelText('Hide Total and Override Columns')).not.toBeChecked()
    })

    it('calls .onChange when the user toggles the item', () => {
      const onChange = jest.fn()
      const {getByLabelText} = renderPanel({
        hideTotal: {allowed: true, checked: false, onChange},
      })

      fireEvent.click(getByLabelText('Hide Total and Override Columns'))
      expect(onChange).toHaveBeenCalledWith(true)
    })
  })

  describe('.showSeparateFirstLastNames', () => {
    describe('when .allowed is true', () => {
      it('is checked if .checked is true', () => {
        const {getByLabelText} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: true, onChange: () => {}},
        })
        expect(getByLabelText('Split Student Names')).toBeChecked()
      })

      it('is unchecked if .checked is false', () => {
        const {getByLabelText} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: false, onChange: () => {}},
        })
        expect(getByLabelText('Split Student Names')).not.toBeChecked()
      })

      it('calls .onChange when the user toggles the item', () => {
        const onChange = jest.fn()
        const {getByLabelText} = renderPanel({
          showSeparateFirstLastNames: {allowed: true, checked: false, onChange},
        })

        fireEvent.click(getByLabelText('Split Student Names'))
        expect(onChange).toHaveBeenCalledWith(true)
      })
    })

    it('is not present when .allowed is false', () => {
      const {queryByText} = renderPanel({
        showSeparateFirstLastNames: {allowed: false, checked: true, onChange: () => {}},
      })
      expect(queryByText('Split Student Names')).not.toBeInTheDocument()
    })
  })

  describe('.statusColors', () => {
    it('renders the status color panel with the colors supplied in .currentValues', () => {
      const {getByText, getByLabelText} = renderPanel({
        statusColors: {
          currentValues: {...statusColors(), excused: '#ffffff'},
          onChange: () => {},
        },
      })

      fireEvent.click(getByText(/Excused Color Picker/i))
      const colorInput = getByLabelText(/Enter a hexcode here/)
      expect(colorInput).toHaveValue('#ffffff')
    })

    it('calls .onChange when the user changes a color', () => {
      const onChange = jest.fn()
      const {getByText} = renderPanel({
        statusColors: {
          currentValues: {...statusColors(), excused: '#ffffff'},
          onChange,
        },
      })

      fireEvent.click(getByText(/Excused Color Picker/i))
      fireEvent.click(getByText(/salmon/i))
      fireEvent.click(getByText(/Apply/))

      expect(onChange).toHaveBeenCalledWith(
        expect.objectContaining({excused: defaultColors.salmon})
      )
    })
  })
})
