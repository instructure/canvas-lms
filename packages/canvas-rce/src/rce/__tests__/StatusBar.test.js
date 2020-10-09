/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import '@testing-library/jest-dom/extend-expect'
import {render, fireEvent} from '@testing-library/react'
import keycode from 'keycode'
import StatusBar from '../StatusBar'

function renderStatusBar(overrideProps) {
  return render(
    <StatusBar
      onToggleHtml={() => {}}
      path={[]}
      wordCount={0}
      isHtmlView={false}
      onResize={() => {}}
      onKBShortcutModalOpen={() => {}}
      onA11yChecker={() => {}}
      {...overrideProps}
    />
  )
}

describe('RCE StatusBar', () => {
  it('calls callback when clicking kb shortcut button', () => {
    const onkbcallback = jest.fn()
    const {getByText} = renderStatusBar({onKBShortcutModalOpen: onkbcallback})
    const kbBtn = getByText('View keyboard shortcuts')
    kbBtn.click()
    expect(onkbcallback).toHaveBeenCalled()
  })

  describe('in WYSIWYG mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar()
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(5)

      buttons[0].focus()
      expect(document.activeElement).toBe(buttons[0])
      // wraps to the right
      for (let i = 1; i <= buttons.length; ++i) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.right})
        expect(document.activeElement).toBe(buttons[i % buttons.length])
      }
      expect(document.activeElement).toBe(buttons[0]) // back to the beginning
    })

    it('cycles focus with left arrow keys', async () => {
      const {container, getByTestId} = renderStatusBar()
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(5)

      buttons[4].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let i = 1; i <= buttons.length; ++i) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(
          buttons[(buttons.length - 1 - i + buttons.length) % buttons.length]
        )
      }
    })
  })

  describe('in HTML mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar({isHtmlView: true})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(2)

      buttons[0].focus()
      expect(document.activeElement).toBe(buttons[0])
      // wraps to the right
      for (let i = 1; i <= buttons.length; ++i) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.right})
        expect(document.activeElement).toBe(buttons[i % buttons.length])
      }
      expect(document.activeElement).toBe(buttons[0]) // back to the beginning
    })

    it('cycles focus with left arrow keys', async () => {
      const {container, getByTestId} = renderStatusBar({isHtmlView: true})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(2)

      buttons[buttons.length - 1].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let focusedButton = buttons.length - 1; focusedButton > 0; --focusedButton) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(buttons[focusedButton - 1])
      }
      fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
    })
  })

  it('calls the callback when clicking the a11y checker button', () => {
    const onA11yCallback = jest.fn()
    const {getByText} = renderStatusBar({onA11yChecker: onA11yCallback})
    const a11yButton = getByText('Accessibility Checker')
    a11yButton.click()
    expect(onA11yCallback).toHaveBeenCalled()
  })
})
