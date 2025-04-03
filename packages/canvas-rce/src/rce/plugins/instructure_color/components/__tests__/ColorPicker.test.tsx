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

const getPresetTooltip = (p: HTMLElement) => p.attributes.getNamedItem('aria-label')!.value

const DEFAULT_FONT_COLOR = '#273540'

const baseTabs = {
  foreground: {
    color: DEFAULT_FONT_COLOR,
    default: DEFAULT_FONT_COLOR,
  },
  background: {
    color: '#aaaaaa',
    default: '#00000000',
  },
  border: {
    color: DEFAULT_FONT_COLOR,
    default: DEFAULT_FONT_COLOR,
  },
  effectiveBgColor: '#ffffff',
}
const cloneBaseTabs = () => JSON.parse(JSON.stringify(baseTabs))

const renderComponent = (props = {}) => {
  return render(<ColorPicker tabs={baseTabs} onCancel={jest.fn()} onSave={jest.fn()} {...props} />)
}

describe('ColorPicker', () => {
  it('renders', () => {
    const {getAllByRole, getByText, queryByTestId} = renderComponent()

    const tabs = getAllByRole('tab')
    expect(tabs).toHaveLength(3)
    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background')
    expect(tabs[2]).toHaveTextContent('Border')
    expect(queryByTestId('color-contrast-summary')).toBeInTheDocument()
    expect(queryByTestId('color-contrast')).not.toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Apply')).toBeInTheDocument()
  })

  it('renders the given tabs', () => {
    const tabs = cloneBaseTabs()
    delete tabs.foreground
    const {getAllByRole} = renderComponent({tabs})

    const tabelems = getAllByRole('tab')
    expect(tabelems).toHaveLength(2)
    expect(tabelems[0]).toHaveTextContent('Background')
    expect(tabelems[1]).toHaveTextContent('Border')
  })

  it('enables the UI when a custom color is selected', () => {
    const tabs = cloneBaseTabs()
    delete tabs.foreground
    const {getAllByRole, getByTestId} = renderComponent({tabs})

    const radioButtons = getAllByRole('radio')
    radioButtons[1].click()
    expect(getByTestId('color-mixer')).toHaveAttribute('aria-disabled', 'false')
    expect(getByTestId('color-preset').querySelectorAll('[disabled]')).toHaveLength(0)
  })

  it('does show color contrast when given a foreground and effective background color', () => {
    const tabs = cloneBaseTabs()
    delete tabs.background
    delete tabs.border
    tabs.effectiveBgColor = '#ff0000'
    tabs.foreground.color = '#000000'
    const {getAllByRole, getByTestId} = renderComponent({tabs})

    const tabelems = getAllByRole('tab')
    expect(tabelems).toHaveLength(1)
    const contrastSummary = getByTestId('color-contrast-summary')
    expect(contrastSummary.textContent).toContain('PASS')
    contrastSummary.click()
    const constrast = getByTestId('color-contrast')
    expect(constrast.textContent).toContain('5.25:1')
  })

  it('does show color contrast when given a background and border color', () => {
    const tabs = cloneBaseTabs()
    delete tabs.foreground
    tabs.background.color = '#ffffff'
    tabs.border.color = '#000000'
    const {getAllByRole, getByTestId} = renderComponent({tabs})

    const tabelems = getAllByRole('tab')
    expect(tabelems).toHaveLength(2)
    const contrastSummary = getByTestId('color-contrast-summary')
    expect(contrastSummary.textContent).toContain('PASS')
    contrastSummary.click()
    const constrast = getByTestId('color-contrast')
    expect(constrast.textContent).toContain('21:1')
  })

  it('uses colors on the page for presets', () => {
    const tabs = cloneBaseTabs()
    delete tabs.foreground
    delete tabs.border
    tabs.background.color = '#ff0000'
    const {getByTestId} = renderComponent({tabs, colorsInUse: {background: ['#ababab', '#cdcdcd']}})

    const presets = getByTestId('color-preset').querySelectorAll('button')
    expect(presets).toHaveLength(3)
    expect(getPresetTooltip(presets[0])).toEqual('#ffffff')
    expect(getPresetTooltip(presets[1])).toEqual('#ababab')
    expect(getPresetTooltip(presets[2])).toEqual('#cdcdcd')
  })

  it('calls onCancel when the cancel button is clicked', () => {
    const onCancel = jest.fn()
    const {getByText} = renderComponent({onCancel})

    getByText('Cancel').click()
    expect(onCancel).toHaveBeenCalled()
  })

  it('calls onSave with the new colors when the apply button is clicked', async () => {
    const tabs = cloneBaseTabs()
    delete tabs.border
    tabs.foreground.color = '#111111'
    tabs.background.color = '#ff0000'
    const onSave = jest.fn()
    const {getByText, getByTestId} = renderComponent({tabs, onSave})

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
