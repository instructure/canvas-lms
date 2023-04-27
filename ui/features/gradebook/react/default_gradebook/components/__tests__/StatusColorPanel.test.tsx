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
import {statuses, statusesTitleMap} from '../../constants/statuses'
import StatusColorPanel from '../StatusColorPanel'

describe('StatusColorPanel', () => {
  let colors
  let onColorsUpdated

  beforeEach(() => {
    colors = statusColors()
    onColorsUpdated = jest.fn()
  })

  it('renders a list item for each color in .colors', () => {
    const {getAllByRole} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />
    )

    const colorListItems = getAllByRole('listitem')
    expect(colorListItems).toHaveLength(statuses.length)
    statuses.forEach((status, idx) => {
      expect(colorListItems[idx]).toHaveStyle({backgroundColor: statusColors[status]})
      expect(colorListItems[idx]).toHaveTextContent(statusesTitleMap[status])
    })
  })

  it('shows a popover when the "More" button is clicked for an item', () => {
    const {getByRole} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />
    )

    const excusedPickerButton = getByRole('button', {name: /Excused Color Picker/i})
    fireEvent.click(excusedPickerButton)

    const colorPickerRadioGroup = getByRole('radiogroup', {name: /Select a predefined color/})
    expect(colorPickerRadioGroup).toBeInTheDocument()
  })

  it('only shows a single popover at a time', () => {
    const {getAllByRole, getByRole} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />
    )

    const excusedPickerButton = getByRole('button', {name: /Excused Color Picker/i})
    fireEvent.click(excusedPickerButton)

    const latePickerButton = getByRole('button', {name: /Late Color Picker/i})
    fireEvent.click(latePickerButton)

    const colorPickerRadioGroups = getAllByRole('radiogroup', {name: /Select a predefined color/})
    expect(colorPickerRadioGroups).toHaveLength(1)
  })

  it('returns focus to the "More" button when the popover is closed', () => {
    const {getByRole} = render(
      <StatusColorPanel colors={colors} onColorsUpdated={onColorsUpdated} />
    )

    const excusedPickerButton = getByRole('button', {name: /Excused Color Picker/i})
    fireEvent.click(excusedPickerButton)

    const cancelButton = getByRole('button', {name: /Cancel/})
    fireEvent.click(cancelButton)
    expect(excusedPickerButton).toHaveFocus()
  })

  it('calls the .onColorsUpdated prop when the user saves a change to a color', () => {
    const customColors = {...colors, excused: defaultColors.lavender}
    const {getByRole} = render(
      <StatusColorPanel colors={customColors} onColorsUpdated={onColorsUpdated} />
    )

    fireEvent.click(getByRole('button', {name: /Excused Color Picker/i}))
    fireEvent.click(getByRole('radio', {name: /salmon/i}))
    fireEvent.click(getByRole('button', {name: /Apply/}))

    expect(onColorsUpdated).toHaveBeenCalledWith(
      expect.objectContaining({excused: defaultColors.salmon})
    )
  })

  it('does not call the .onColorsUpdated prop when the user cancels a change', () => {
    const customColors = {...colors, excused: defaultColors.lavender}
    const {getByRole} = render(
      <StatusColorPanel colors={customColors} onColorsUpdated={onColorsUpdated} />
    )

    fireEvent.click(getByRole('button', {name: /Excused Color Picker/i}))
    fireEvent.click(getByRole('radio', {name: /salmon/i}))
    fireEvent.click(getByRole('button', {name: /Cancel/}))

    expect(onColorsUpdated).not.toHaveBeenCalled()
  })
})
