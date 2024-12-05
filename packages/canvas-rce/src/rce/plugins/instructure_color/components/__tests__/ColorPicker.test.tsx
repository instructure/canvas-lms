/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {ColorPicker} from '../ColorPicker'

const user = userEvent.setup()

const getPresetTooltip = (preset: HTMLElement) => {
  return document.getElementById(preset.getAttribute('aria-describedby')!)
}

const renderComponent = (props = {}) => {
  return render(
    <ColorPicker
      tabs={{
        foreground: '#111111',
        background: '#ff0000',
      }}
      onCancel={jest.fn()}
      onSave={jest.fn()}
      {...props}
    />
  )
}

describe('ColorPicker', () => {
  it('renders', () => {
    const {getAllByRole, getByText, queryByTestId} = renderComponent()

    const tabs = getAllByRole('tab')
    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background')
    expect(queryByTestId('color-contrast-summary')).toBeInTheDocument()
    expect(queryByTestId('color-contrast')).not.toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Apply')).toBeInTheDocument()
  })

  it('renders the given tabs', () => {
    const {getAllByRole} = renderComponent({
      tabs: {
        background: '#ffffff',
        border: '#000000',
      },
    })

    const tabs = getAllByRole('tab')
    expect(tabs).toHaveLength(2)
    expect(tabs[0]).toHaveTextContent('Background')
    expect(tabs[1]).toHaveTextContent('Border')
  })

  it('considers a transparent background not a custom color', () => {
    const {getAllByRole, getByTestId} = renderComponent({
      tabs: {
        background: 'transparent',
        border: '#000000',
      },
    })

    const radioButtons = getAllByRole('radio')
    expect(radioButtons[0]).toBeChecked()
    expect(getByTestId('color-mixer')).toHaveAttribute('aria-disabled', 'true')
    // black and white
    expect(getByTestId('color-preset').querySelectorAll('[disabled]')).toHaveLength(2)
  })

  it('enables the UI when a custom color is selected', () => {
    const {getAllByRole, getByTestId} = renderComponent({
      tabs: {
        background: 'transparent',
        border: '#000000',
      },
    })

    const radioButtons = getAllByRole('radio')
    radioButtons[1].click()
    expect(getByTestId('color-mixer')).toHaveAttribute('aria-disabled', 'false')
    expect(getByTestId('color-preset').querySelectorAll('[disabled]')).toHaveLength(0)
  })

  it('does not show color contrast when the background is transparent', () => {
    const {queryByTestId} = renderComponent({
      tabs: {
        background: 'transparent',
        foreground: '#000000',
      },
    })

    expect(queryByTestId('color-contrast-summary')).not.toBeInTheDocument()
  })

  it('does not show the color contrast when the border is transparent', () => {
    const {queryByTestId} = renderComponent({
      tabs: {
        background: '#ffffff',
        border: '#00000000',
      },
    })

    expect(queryByTestId('color-contrast-summary')).not.toBeInTheDocument()
  })

  it('does show color contrast when given a foreground and effective background color', () => {
    const {getAllByRole, getByTestId} = renderComponent({
      tabs: {
        effectiveBgColor: '#ff0000',
        foreground: '#000000',
      },
    })

    const tabs = getAllByRole('tab')
    expect(tabs).toHaveLength(1)
    const contrastSummary = getByTestId('color-contrast-summary')
    expect(contrastSummary.textContent).toContain('PASS')
    contrastSummary.click()
    const constrast = getByTestId('color-contrast')
    expect(constrast.textContent).toContain('5.25:1')
  })

  it('does show color contrast when given a background and border color', () => {
    const {getAllByRole, getByTestId} = renderComponent({
      tabs: {
        background: '#ffffff',
        border: '#000000',
      },
    })

    const tabs = getAllByRole('tab')
    expect(tabs).toHaveLength(2)
    const contrastSummary = getByTestId('color-contrast-summary')
    expect(contrastSummary.textContent).toContain('PASS')
    contrastSummary.click()
    const constrast = getByTestId('color-contrast')
    expect(constrast.textContent).toContain('21:1')
  })

  it('uses colors on the page for presets', async () => {
    const {getByTestId} = renderComponent({
      tabs: {
        background: '#ff0000',
        border: '#000000',
      },
      colorsInUse: {background: ['#ababab', '#cdcdcd']},
    })

    const presets = getByTestId('color-preset').querySelectorAll('button')
    expect(presets).toHaveLength(4)
    expect(getPresetTooltip(presets[0])?.textContent).toEqual('#000000')
    expect(getPresetTooltip(presets[1])?.textContent).toEqual('#ffffff')
    expect(getPresetTooltip(presets[2])?.textContent).toEqual('#ababab')
    expect(getPresetTooltip(presets[3])?.textContent).toEqual('#cdcdcd')
  })

  it('calls onCancel when the cancel button is clicked', () => {
    const onCancel = jest.fn()
    const {getByText} = renderComponent({onCancel})

    getByText('Cancel').click()
    expect(onCancel).toHaveBeenCalled()
  })

  it('calls onSave with the new colors when the apply button is clicked', async () => {
    const onSave = jest.fn()
    const {getByText, getByTestId} = renderComponent({onSave})

    const mixer = getByTestId('color-mixer')
    const rgb = mixer.querySelectorAll('input')
    // #B82828
    await user.click(rgb[0])
    await user.keyboard('{Control>}a{/Control}184')
    await user.click(rgb[1])
    await user.keyboard('{Control>}a{/Control}40')
    await user.click(rgb[2])
    await user.keyboard('{Control>}a{/Control}40')
    getByText('Apply').click()

    expect(onSave).toHaveBeenCalledWith({
      fgcolor: '#b82828',
      bgcolor: '#ff0000',
    })
  })
})
