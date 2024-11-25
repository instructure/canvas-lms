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
import {Editor} from '@craftjs/core'
import {render, screen} from '@testing-library/react'
import {ToolbarColor} from '../ToolbarColor'

const DEFAULT_FONT_COLOR = '#2d3b45'

const renderComponent = (props = {}) => {
  return render(
    <Editor enabled={false}>
      <ToolbarColor
        tabs={{background: '#fff', foreground: '#000'}}
        onChange={() => {}}
        {...props}
      />
    </Editor>
  )
}

describe('ToolbarColor', () => {
  it('renders the button', () => {
    const {getByText} = renderComponent()

    const button = getByText('Color').closest('button')

    expect(button).toBeInTheDocument()
  })

  it('renders the popup', () => {
    const {getAllByRole, getByText, getByTestId} = renderComponent({
      tabs: {background: '#fff', foreground: '#000', border: '#ff0000'},
    })
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs[0]).toHaveTextContent('Color')
    expect(tabs[1]).toHaveTextContent('Background')
    expect(tabs[2]).toHaveTextContent('Border')

    expect(getByText('Previously chosen colors')).toBeInTheDocument()
    expect(getByTestId('color-mixer')).toBeInTheDocument()
    expect(getByTestId('color-preset')).toBeInTheDocument()
    expect(getByTestId('color-contrast-summary')).toBeInTheDocument()
  })

  it('includes the background tab', () => {
    const {getAllByRole, getByText} = renderComponent({tabs: {background: '#fff'}})
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs.length).toBe(1)
    expect(tabs[0]).toHaveTextContent('Background')
  })

  it('includes the Border tab and omits the Color tab', () => {
    const {getAllByRole, getByText} = renderComponent({
      tabs: {background: '#fff', border: '#ff0000'},
    })
    const button = getByText('Color').closest('button') as HTMLButtonElement
    button.click()

    const tabs = getAllByRole('tab')
    expect(tabs.length).toBe(2)
    expect(tabs[0]).toHaveTextContent('Background')
    expect(tabs[1]).toHaveTextContent('Border')
  })

  it('includes the Color tab and omits the Border tab', () => {
    const {getAllByRole, getByText} = renderComponent({
      tabs: {foreground: '#000', background: '#fff'},
    })
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
    const {getByText} = renderComponent({
      tabs: {backgoound: '#fff', foreground: '#000'},
    })
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
      const {getAllByRole, getByText, getByDisplayValue} = renderComponent({
        tabs: {background: '#fff', foreground: '#aabbcc'},
      })

      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      expect(tabs[0]).toHaveAttribute('aria-selected', 'true')
      expect(getByText('Input field for red')).toBeInTheDocument()
      expect(getByDisplayValue(170)).toBeInTheDocument() // aa
      expect(getByDisplayValue(187)).toBeInTheDocument() // bb
      expect(getByDisplayValue(204)).toBeInTheDocument() // cc

      expect(getByText('Color Contrast')).toBeInTheDocument()
      expect(getByText('FAIL')).toBeInTheDocument()
    })

    it('does not show the contrast ratio if the background is transparent', () => {
      const {queryByTestId, getByText} = renderComponent({
        tabs: {background: 'transparent', foreground: '#aabbcc'},
      })

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
      const {getAllByRole, getByText} = renderComponent({
        tabs: {background: '#fff', foreground: '#000'},
      })
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      tabs[1].click()

      expect(tabs[1]).toHaveAttribute('aria-selected', 'true')
      expect(document.getElementById('background')).toBeInTheDocument()
    })

    it('renders the background tab panel', () => {
      const {getByText, getByDisplayValue, getByTestId} = renderComponent({
        tabs: {background: '#00000000', foreground: '#000'},
      })
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
      const {getByText, getByTestId} = renderComponent({
        tabs: {background: '#aabbcc', foreground: '#000'},
      })
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      const custom = screen.getByDisplayValue('custom')
      custom.click()

      const mixer = getByTestId('color-mixer')
      expect(mixer.querySelectorAll('[disabled]')).toHaveLength(0)
    })
  })

  describe('border tab', () => {
    it('switches to the border tab', () => {
      const {getAllByRole, getByText} = renderComponent({
        tabs: {background: '#fff', border: '#000'},
      })
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const tabs = getAllByRole('tab')

      tabs[1].click()

      expect(tabs[1]).toHaveAttribute('aria-selected', 'true')
      expect(document.getElementById('border')).toBeInTheDocument()
    })

    it('renders the border tab panel', () => {
      const {getByText, getByDisplayValue, queryByTestId} = renderComponent({
        tabs: {background: '#aabbcc', border: '#00000000'},
      })
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
      const {getByText, getByTestId} = renderComponent({
        tabs: {background: '#aabbcc', border: '#ff0000'},
      })
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()
      const tabs = screen.getAllByRole('tab')
      tabs[1].click()

      expect(getByTestId('color-contrast-summary')).toBeInTheDocument()
    })
  })

  describe('color contrast', () => {
    it('renders the color contrast', () => {
      const {getByText, getByTestId, queryByTestId} = renderComponent({
        tabs: {background: '#fff', foreground: '#000'},
      })
      const button = getByText('Color').closest('button') as HTMLButtonElement
      button.click()

      const toggle = getByTestId('color-contrast-summary')
      expect(toggle).toBeInTheDocument()
      expect(queryByTestId('color-contrast')).not.toBeInTheDocument()

      toggle.click()

      expect(queryByTestId('color-contrast')).toBeInTheDocument()
    })
  })
})
