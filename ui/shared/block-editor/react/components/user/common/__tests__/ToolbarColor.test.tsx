// @ts-nocheck
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ToolbarColor} from '../ToolbarColor'

const user = userEvent.setup()

const DEFAULT_FONT_COLOR = '#2D3B45'

describe('ToolbarColor', () => {
  it('renders the button', () => {
    const {getByText} = render(
      <ToolbarColor tabs={{background: '#fff', foreground: '#000'}} onChange={jest.fn()} />
    )

    const button = getByText('Color').closest('button')

    expect(button).toBeInTheDocument()
  })

  it('renders the popup', () => {
    const {getAllByRole, getByText, getByTestId} = render(
      <ToolbarColor
        tabs={{background: '#fff', foreground: '#000', border: '#ff0000'}}
        onChange={jest.fn()}
      />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background')
    expect(tabs[2]).toHaveTextContent('Border')

    expect(getByText('Previously chosen colors')).toBeInTheDocument()
    expect(getByTestId('color-mixer')).toBeInTheDocument()
    expect(getByTestId('color-preset')).toBeInTheDocument()
    expect(getByTestId('color-contrast')).toBeInTheDocument()
  })

  it('includes the background tab', () => {
    const {getAllByRole, getByText} = render(
      <ToolbarColor tabs={{background: '#fff'}} onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs.length).toBe(1)
    expect(tabs[0]).toHaveTextContent('Background')
  })

  it('includes the Border tab and omits the Color tab', () => {
    const {getAllByRole, getByText} = render(
      <ToolbarColor tabs={{background: '#fff', border: '#ff0000'}} onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs.length).toBe(2)
    expect(tabs[0]).toHaveTextContent('Background')
    expect(tabs[1]).toHaveTextContent('Border')
  })

  it('includes the Color tab and omits the Border tab', () => {
    const {getAllByRole, getByText} = render(
      <ToolbarColor tabs={{foreground: '#000', background: '#fff'}} onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs.length).toBe(2)
    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background')
  })

  it('includes the default foreground color', () => {
    window.getComputedStyle = jest.fn().mockReturnValue({
      getPropertyValue: jest.fn().mockReturnValue(DEFAULT_FONT_COLOR),
    })
    const {getByText} = render(
      <ToolbarColor tabs={{backgoound: '#fff', foreground: '#000'}} onChange={jest.fn()} />
    )
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const c1 = document.getElementById(
      // @ts-expect-error
      document
        .getElementById('foreground')
        ?.querySelectorAll('button')[0]
        ?.getAttribute('aria-describedby')
    )
    expect(c1).toHaveTextContent(DEFAULT_FONT_COLOR)
  })

  describe('color tab', () => {
    it('renders the color tab panel', () => {
      const {getAllByRole, getByText, getByDisplayValue} = render(
        <ToolbarColor tabs={{background: '#fff', foreground: '#aabbcc'}} onChange={jest.fn()} />
      )

      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      expect(tabs[0]).toHaveAttribute('aria-selected', 'true')
      expect(getByText('Input field for red')).toBeInTheDocument()
      expect(getByDisplayValue(170)).toBeInTheDocument() // aa
      expect(getByDisplayValue(187)).toBeInTheDocument() // bb
      expect(getByDisplayValue(204)).toBeInTheDocument() // cc

      expect(getByText('Color Contrast Ratio')).toBeInTheDocument()
      expect(getByText('1.96:1')).toBeInTheDocument()
    })

    it('does not show the contrast ratio if the background is transparent', () => {
      const {queryByTestId, getByText} = render(
        <ToolbarColor
          tabs={{background: 'transparent', foreground: '#aabbcc'}}
          onChange={jest.fn()}
        />
      )

      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      expect(queryByTestId('color-contrast')).not.toBeInTheDocument()
    })
  })

  describe('background tab', () => {
    beforeEach(() => {
      window.getComputedStyle = jest.fn().mockReturnValue({
        getPropertyValue: jest.fn().mockReturnValue(DEFAULT_FONT_COLOR),
      })
    })

    it('switches to the background tab', () => {
      const {getAllByRole, getByText} = render(
        <ToolbarColor tabs={{background: '#fff', foreground: '#000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      tabs[1].click()

      expect(tabs[1]).toHaveAttribute('aria-selected', 'true')
      expect(document.getElementById('background')).toBeInTheDocument()
    })

    it('renders the background tab panel', () => {
      const {getByText, getByDisplayValue, getByTestId} = render(
        <ToolbarColor tabs={{background: '#00000000', foreground: '#000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      expect(getByDisplayValue('none')).toBeInTheDocument()
      expect(getByDisplayValue('custom')).toBeInTheDocument()
      expect(getByDisplayValue('none')).toBeChecked()

      const mixer = getByTestId('color-mixer')
      // mixer, color slider, r, g, and b inputs
      expect(mixer.querySelectorAll('[disabled]')).toHaveLength(5)
    })

    it('enables the mixer when custom color is selectd', () => {
      const {getByText, getByTestId} = render(
        <ToolbarColor tabs={{background: '#aabbcc', foreground: '#000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      const custom = screen.getByDisplayValue('custom')
      custom.click()

      const mixer = getByTestId('color-mixer')
      expect(mixer.querySelectorAll('[disabled]')).toHaveLength(0)
    })

    // this works for any tab, but testing in the background tab
    it.skip('adds selected colors to the preset', async () => {
      // the expect(onchange).toHaveBeenCalledWith is flakey
      const onchange = jest.fn()
      const {getByText, getByTestId, getByDisplayValue, rerender} = render(
        <ToolbarColor
          tabs={{background: '#aabbcc', foreground: DEFAULT_FONT_COLOR}}
          onChange={onchange}
        />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()
      const custom = screen.getByDisplayValue('custom')
      custom.click()

      let preset = getByTestId('color-preset')
      expect(preset.querySelectorAll('button')).toHaveLength(2)

      let presets = preset.querySelectorAll('button')
      expect(presets).toHaveLength(2)

      expect(
        document.getElementById(presets[0].getAttribute('aria-describedby'))
      ).toHaveTextContent(DEFAULT_FONT_COLOR)

      expect(
        document.getElementById(presets[1].getAttribute('aria-describedby'))
      ).toHaveTextContent('#FFFFFF')

      await user.dblClick(getByDisplayValue(187).closest('input'))
      await user.keyboard('0')

      getByText('Apply').closest('button').click()

      expect(onchange).toHaveBeenCalledWith({
        bgcolor: '#AA00CCFF',
        fgcolor: '#2D3B45FF',
        bordercolor: undefined,
      })

      rerender(
        <ToolbarColor tabs={{background: '#aa00cc', foreground: '#000'}} onChange={jest.fn()} />
      )
      getByText('Color').closest('button').click()
      screen.getAllByRole('tab')[1].click()

      preset = getByTestId('color-preset')
      presets = preset.querySelectorAll('button')
      expect(presets).toHaveLength(3)

      expect(
        document.getElementById(presets[0].getAttribute('aria-describedby')).textContent
      ).toEqual(DEFAULT_FONT_COLOR)
      expect(
        document.getElementById(presets[1].getAttribute('aria-describedby')).textContent
      ).toEqual('#FFFFFF')
      expect(
        document.getElementById(presets[2].getAttribute('aria-describedby')).textContent
      ).toEqual('#AA00CCFF')
    })
  })

  describe('border tab', () => {
    it('switches to the border tab', () => {
      const {getAllByRole, getByText} = render(
        <ToolbarColor tabs={{background: '#fff', border: '#000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      tabs[1].click()

      expect(tabs[1]).toHaveAttribute('aria-selected', 'true')
      expect(document.getElementById('border')).toBeInTheDocument()
    })

    it('renders the border tab panel', () => {
      const {getByText, getByDisplayValue, queryByTestId} = render(
        <ToolbarColor tabs={{background: '#aabbcc', border: '#00000000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      expect(getByDisplayValue('none')).toBeInTheDocument()
      expect(getByDisplayValue('custom')).toBeInTheDocument()
      expect(getByDisplayValue('none')).toBeChecked()

      expect(queryByTestId('color-mixer')).toBeInTheDocument()
      expect(queryByTestId('color-preset')).toBeInTheDocument()
      expect(queryByTestId('color-contrast')).not.toBeInTheDocument()
    })

    it('renders color contrast when it and the background are not transparent', () => {
      const {getByText, getByTestId} = render(
        <ToolbarColor tabs={{background: '#aabbcc', border: '#ff0000'}} onChange={jest.fn()} />
      )
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      expect(getByTestId('color-contrast')).toBeInTheDocument()
    })
  })
})
