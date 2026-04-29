// eslint-disable-next-line @typescript-eslint/ban-ts-comment
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
import {getStatuses, statusesTitleMap} from '../../constants/statuses'
import StatusColorPanel from '../StatusColorPanel'

describe('StatusColorPanel', () => {
  let colors
  let onColorsUpdated

  beforeEach(() => {
    colors = statusColors()
    onColorsUpdated = vi.fn()
  })

  it('renders a list item for each color in .colors', () => {
    const {container} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />,
    )

    const colorListItems = container.querySelectorAll('li')
    expect(colorListItems).toHaveLength(getStatuses().length)
    getStatuses().forEach((status, idx) => {
      expect(colorListItems[idx]).toHaveStyle({backgroundColor: statusColors[status]})
      expect(colorListItems[idx]).toHaveTextContent(statusesTitleMap[status])
    })
  })

  it('shows a popover when the "More" button is clicked for an item', () => {
    const {getByText} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />,
    )

    const excusedPickerButton = getByText(/Excused Color Picker/i).closest('button')
    expect(excusedPickerButton).toHaveAttribute('aria-expanded', 'false')

    fireEvent.click(excusedPickerButton)

    expect(excusedPickerButton).toHaveAttribute('aria-expanded', 'true')
    expect(getByText('Apply')).toBeInTheDocument()
  })

  it('only shows a single popover at a time', () => {
    const {getAllByText, getByText} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />,
    )

    const excusedPickerButton = getByText(/Excused Color Picker/i).closest('button')
    fireEvent.click(excusedPickerButton)

    const latePickerButton = getByText(/Late Color Picker/i).closest('button')
    fireEvent.click(latePickerButton)

    // Only one "Apply" button should be visible, indicating only one popover is open
    const applyButtons = getAllByText('Apply')
    expect(applyButtons).toHaveLength(1)
  })

  it('returns focus to the "More" button when the popover is closed', () => {
    const {getByText} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />,
    )

    const excusedPickerButton = getByText(/Excused Color Picker/i).closest('button')
    fireEvent.click(excusedPickerButton)

    const cancelButton = getByText('Cancel')
    fireEvent.click(cancelButton)
    expect(excusedPickerButton).toHaveFocus()
  })

  it('calls the .onColorsUpdated prop when the user saves a change to a color', () => {
    const customColors = {...colors, excused: defaultColors.lavender}
    const {getByText} = render(
      <StatusColorPanel colors={customColors} onColorsUpdated={onColorsUpdated} />,
    )

    fireEvent.click(getByText(/Excused Color Picker/i).closest('button'))
    // The radio button has screenreader text with the color name and hex code
    const salmonRadio = getByText(/salmon \(#/i).closest('button')
    fireEvent.click(salmonRadio)
    fireEvent.click(getByText('Apply'))

    expect(onColorsUpdated).toHaveBeenCalledWith(
      expect.objectContaining({excused: defaultColors.salmon}),
    )
  })

  it('does not call the .onColorsUpdated prop when the user cancels a change', () => {
    const customColors = {...colors, excused: defaultColors.lavender}
    const {getByText} = render(
      <StatusColorPanel colors={customColors} onColorsUpdated={onColorsUpdated} />,
    )

    fireEvent.click(getByText(/Excused Color Picker/i).closest('button'))
    // The radio button has screenreader text with the color name and hex code
    const salmonRadio = getByText(/salmon \(#/i).closest('button')
    fireEvent.click(salmonRadio)
    fireEvent.click(getByText('Cancel'))

    expect(onColorsUpdated).not.toHaveBeenCalled()
  })

  describe('icon visibility', () => {
    it('displays icons for standard statuses when viewStatusForColorblindness is true', () => {
      const {container} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          viewStatusForColorblindness={true}
        />,
      )

      const icons = container.querySelectorAll('img')
      // Should have one icon per standard status
      expect(icons).toHaveLength(getStatuses().length)
    })

    it('does not display icons for standard statuses when viewStatusForColorblindness is false', () => {
      const {container} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          viewStatusForColorblindness={false}
        />,
      )

      expect(container.querySelectorAll('img')).toHaveLength(0)
    })
  })

  describe('custom grade statuses', () => {
    const customGradeStatuses = [
      {
        id: '1',
        name: 'Custom Status 1',
        color: '#FF0000',
        icon: 'custom-1',
        applies_to_submissions: true,
        applies_to_finals: false,
      },
      {
        id: '2',
        name: 'Custom Status 2',
        color: '#00FF00',
        icon: 'custom-2',
        applies_to_submissions: true,
        applies_to_finals: false,
      },
    ]

    it('renders custom grade statuses when provided', () => {
      const {container, getByText} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          customGradeStatuses={customGradeStatuses}
          viewStatusForColorblindness={false}
        />,
      )

      expect(getByText('Custom Status 1')).toBeInTheDocument()
      expect(getByText('Custom Status 2')).toBeInTheDocument()

      const listItems = container.querySelectorAll('li')
      // Standard statuses + custom statuses
      expect(listItems).toHaveLength(getStatuses().length + customGradeStatuses.length)
    })

    it('displays icons for custom statuses when viewStatusForColorblindness is true', () => {
      const {container} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          customGradeStatuses={customGradeStatuses}
          viewStatusForColorblindness={true}
        />,
      )

      const icons = container.querySelectorAll('img')
      // Standard statuses + custom statuses
      expect(icons).toHaveLength(getStatuses().length + customGradeStatuses.length)
    })

    it('does not display icons for custom statuses when viewStatusForColorblindness is false', () => {
      const {container} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          customGradeStatuses={customGradeStatuses}
          viewStatusForColorblindness={false}
        />,
      )

      expect(container.querySelectorAll('img')).toHaveLength(0)
    })

    it('custom statuses do not have color picker buttons', () => {
      const {getAllByText} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          customGradeStatuses={customGradeStatuses}
          viewStatusForColorblindness={false}
        />,
      )

      const colorPickerButtons = getAllByText(/Color Picker/i)
      // Only standard statuses should have color pickers
      expect(colorPickerButtons).toHaveLength(getStatuses().length)
    })

    it('applies correct background colors to custom status items', () => {
      const {container} = render(
        <StatusColorPanel
          colors={colors}
          onColorsUpdated={onColorsUpdated}
          customGradeStatuses={customGradeStatuses}
          viewStatusForColorblindness={false}
        />,
      )

      const listItems = container.querySelectorAll('li')
      const customStatusItems = Array.from(listItems).slice(getStatuses().length)

      expect(customStatusItems[0]).toHaveStyle({backgroundColor: '#FF0000'})
      expect(customStatusItems[1]).toHaveStyle({backgroundColor: '#00FF00'})
    })
  })
})
