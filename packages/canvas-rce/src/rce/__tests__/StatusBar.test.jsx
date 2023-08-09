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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {queryHelpers} from '@testing-library/dom'
import keycode from 'keycode'
import {FS_ENABLED} from '../../util/fullscreenHelpers'
import StatusBar, {WYSIWYG_VIEW, PRETTY_HTML_EDITOR_VIEW, RAW_HTML_EDITOR_VIEW} from '../StatusBar'

function defaultProps(props = {}) {
  return {
    id: 'sb1',
    onToggleHtml: () => {},
    path: [],
    wordCount: 0,
    editorView: WYSIWYG_VIEW,
    onResize: () => {},
    onKBShortcutModalOpen: () => {},
    onA11yChecker: () => {},
    onWordcountModalOpen: () => {},
    onFullscreen: () => {},
    onChangeView: () => {},
    ...props,
  }
}

function renderStatusBar(overrideProps) {
  const props = defaultProps()
  return render(<StatusBar {...props} {...overrideProps} />)
}

async function findDescribedByText(container) {
  const editBtn = queryHelpers.queryByAttribute('data-btn-id', container, 'rce-edit-btn')
  await waitFor(() => expect(editBtn.getAttribute('aria-describedby')).not.toBeNull())
  const descById = editBtn.getAttribute('aria-describedby')
  return document.getElementById(descById).textContent
}

describe('RCE StatusBar', () => {
  beforeEach(() => {
    document[FS_ENABLED] = true
  })

  it('calls callback when clicking kb shortcut button', () => {
    const onkbcallback = jest.fn()
    const {getByText} = renderStatusBar({onKBShortcutModalOpen: onkbcallback})
    const kbBtn = getByText('View keyboard shortcuts')
    kbBtn.click()
    expect(onkbcallback).toHaveBeenCalled()
  })

  it('calls callback when clicking wordcount button', () => {
    const onWordcountCallback = jest.fn()
    const {getByTestId} = renderStatusBar({onWordcountModalOpen: onWordcountCallback})
    const wordCountButton = getByTestId('status-bar-word-count').firstChild
    wordCountButton.click()
    expect(onWordcountCallback).toHaveBeenCalled()
  })

  it('displays all the buttons', () => {
    const {container} = renderStatusBar()
    expect(container.querySelector('[data-btn-id="rce-kbshortcut-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-a11y-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-wordcount-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-edit-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-fullscreen-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-resize-handle"]')).toBeInTheDocument()
  })

  it('omits fullscreen button when fullscreen is not enabled', () => {
    document[FS_ENABLED] = undefined
    const {container} = renderStatusBar()
    expect(container.querySelector('[data-btn-id="rce-kbshortcut-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-a11y-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-wordcount-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-edit-btn"]')).toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-fullscreen-btn"]')).not.toBeInTheDocument()
    expect(container.querySelector('[data-btn-id="rce-resize-handle"]')).toBeInTheDocument()
  })

  it('replaces fullscreen with exit fullscreen if RCE is fullscreen', () => {
    const {container, rerender} = renderStatusBar({rceIsFullscreen: false})
    expect(container.querySelector('[data-btn-id="rce-fullscreen-btn"]').textContent).toEqual(
      'Fullscreen'
    )
    rerender(<StatusBar {...defaultProps({rceIsFullscreen: true})} />)
    expect(container.querySelector('[data-btn-id="rce-fullscreen-btn"]').textContent).toEqual(
      'Exit Fullscreen'
    )
  })

  describe('in WYSIWYG mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar()
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(6)

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
      expect(buttons.length).toEqual(6)

      buttons[buttons.length - 1].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let focusedButton = buttons.length - 1; focusedButton >= 0; --focusedButton) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(
          buttons[(focusedButton - 1 + buttons.length) % buttons.length]
        )
      }
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
    })

    it('defaults to pretty html editor', async () => {
      const onChangeView = jest.fn()
      const {container, getByText} = renderStatusBar({
        onChangeView,
      })

      expect(await findDescribedByText(container)).toEqual(
        'The pretty html editor is not keyboard accessible. Press Shift O to open the raw html editor.'
      )
      expect(getByText('Switch to the html editor')).toBeInTheDocument()

      const editbtn = queryHelpers.queryByAttribute('data-btn-id', container, 'rce-edit-btn')
      fireEvent.click(editbtn)
      expect(onChangeView).toHaveBeenCalledWith(PRETTY_HTML_EDITOR_VIEW)
    })

    it('prefers raw html editor if specified', async () => {
      const onChangeView = jest.fn()
      const {container, getByText} = renderStatusBar({
        preferredHtmlEditor: RAW_HTML_EDITOR_VIEW,
        onChangeView,
      })

      expect(await findDescribedByText(container)).toEqual(
        'Shift-O to open the pretty html editor.'
      )
      expect(getByText('Switch to the html editor')).toBeInTheDocument()

      const editbtn = queryHelpers.queryByAttribute('data-btn-id', container, 'rce-edit-btn')
      fireEvent.click(editbtn)
      expect(onChangeView).toHaveBeenCalledWith(RAW_HTML_EDITOR_VIEW)
    })

    it('a11y checker start with no notifications', () => {
      const {getByTitle} = renderStatusBar(defaultProps())
      const a11yButton = getByTitle('Accessibility Checker')
      const sibling = a11yButton.parentElement.children[1]
      expect(sibling.id.includes('Badge')).toBeFalsy()
    })

    it('a11y checker start set a notification count', () => {
      const props = defaultProps({
        a11yErrorsCount: 5,
      })
      const {rerender, getByTitle} = renderStatusBar(props)
      const a11yButton = getByTitle('Accessibility Checker')
      const notificationBadge = a11yButton.parentElement.children[1]
      expect(notificationBadge.id.includes('Badge')).toBeTruthy()
      expect(notificationBadge.textContent).toEqual('5')
      rerender(<StatusBar {...props} a11yErrorsCount={10} />)
      expect(notificationBadge.textContent).toEqual('10')
    })

    it('a11y checker set max notifications count', () => {
      const props = defaultProps({
        a11yErrorsCount: 999,
      })
      const {getByTitle} = renderStatusBar(props)
      const a11yButton = getByTitle('Accessibility Checker')
      const notificationBadge = a11yButton.parentElement.children[1]
      expect(notificationBadge.id.includes('Badge')).toBeTruthy()
      expect(notificationBadge.textContent).toEqual('99 +')
    })
  })

  describe('in raw HTML mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar({editorView: RAW_HTML_EDITOR_VIEW})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('[tabindex]')
      expect(buttons.length).toEqual(3)

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
      const {container, getByTestId} = renderStatusBar({editorView: RAW_HTML_EDITOR_VIEW})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('[tabindex]')
      expect(buttons.length).toEqual(3)

      buttons[buttons.length - 1].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let focusedButton = buttons.length - 1; focusedButton >= 0; --focusedButton) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(
          buttons[(focusedButton - 1 + buttons.length) % buttons.length]
        )
      }
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
    })
  })

  describe('in pretty HTML mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar({
        editorView: PRETTY_HTML_EDITOR_VIEW,
      })
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('[tabindex]')
      expect(buttons.length).toEqual(4)

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
      const {container, getByTestId} = renderStatusBar({
        editorView: PRETTY_HTML_EDITOR_VIEW,
      })
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('[tabindex]')
      expect(buttons.length).toEqual(4)

      buttons[buttons.length - 1].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let focusedButton = buttons.length - 1; focusedButton >= 0; --focusedButton) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(
          buttons[(focusedButton - 1 + buttons.length) % buttons.length]
        )
      }
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
    })
  })

  describe('in readonly mode', () => {
    it('cycles focus with right arrow keys', () => {
      const {container, getByTestId} = renderStatusBar({readOnly: true})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(3)

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
      const {container, getByTestId} = renderStatusBar({readOnly: true})
      const statusbar = getByTestId('RCEStatusBar')
      const buttons = container.querySelectorAll('button, *[tabindex]')
      expect(buttons.length).toEqual(3)

      buttons[buttons.length - 1].focus()
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
      // wraps to the left
      for (let focusedButton = buttons.length - 1; focusedButton >= 0; --focusedButton) {
        fireEvent.keyDown(statusbar, {keyCode: keycode.codes.left})
        expect(document.activeElement).toBe(
          buttons[(focusedButton - 1 + buttons.length) % buttons.length]
        )
      }
      expect(document.activeElement).toBe(buttons[buttons.length - 1])
    })
  })

  describe('default focus button', () => {
    it('shifts button when entering edit mode', () => {
      const {container, rerender} = renderStatusBar({editorView: WYSIWYG_VIEW})

      const kbshortcutBtn = container.querySelector('[data-btn-id="rce-kbshortcut-btn"]')
      expect(container.querySelector('[tabindex="0"]')).toBe(kbshortcutBtn)

      rerender(
        <StatusBar
          {...defaultProps({
            onToggleHtml: () => {},
            path: [],
            wordCount: 0,
            editorView: RAW_HTML_EDITOR_VIEW,
            onResize: () => {},
            onKBShortcutModalOpen: () => {},
            onA11yChecker: () => {},
          })}
        />
      )

      const editBtn = container.querySelector('[data-btn-id="rce-edit-btn"]')
      expect(container.querySelector('[tabindex="0"]')).toBe(editBtn)
    })
  })

  it('calls the callback when clicking the a11y checker button', () => {
    const onA11yCallback = jest.fn()
    const {getByText} = renderStatusBar({onA11yChecker: onA11yCallback})
    const a11yButton = getByText('Accessibility Checker')
    a11yButton.click()
    expect(onA11yCallback).toHaveBeenCalled()
  })

  describe('disabledPlugins', () => {
    it('does not show the ally checker button when the plugin is disabled', () => {
      const {queryByRole} = renderStatusBar({disabledPlugins: ['ally_checker']})
      const allyCheckerBtn = queryByRole('button', {name: /accessibility checker/i})
      expect(allyCheckerBtn).not.toBeInTheDocument()
    })

    it('does not show the wordcount button when the plugin is disabled', () => {
      const {queryByRole} = renderStatusBar({disabledPlugins: ['instructure_wordcount']})
      const wordCountBtn = queryByRole('button', {name: /0 words/i})
      expect(wordCountBtn).not.toBeInTheDocument()
    })

    it('does not show the html view button when the plugin is disabled', () => {
      const {queryByRole} = renderStatusBar({disabledPlugins: ['instructure_html_view']})
      const htmlViewBtn = queryByRole('button', {name: /switch to the html editor/i})
      expect(htmlViewBtn).not.toBeInTheDocument()
    })

    it('does not show the fullscreen button when the plugin is disabled', () => {
      const {queryByRole} = renderStatusBar({disabledPlugins: ['instructure_fullscreen']})
      const fullscreenBtn = queryByRole('button', {name: /fullscreen/i})
      expect(fullscreenBtn).not.toBeInTheDocument()
    })
  })
})
