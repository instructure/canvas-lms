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
import {act, render, wait, waitForElementToBeRemoved} from '@testing-library/react'

import Bridge from '../../../../bridge/Bridge'
import * as fakeSource from '../../../../sidebar/sources/fake'
import CanvasContentTray from '../CanvasContentTray'

describe('RCE Plugins > CanvasContentTray', () => {
  let component
  let props

  function getProps(override = {}) {
    props = {
      bridge: new Bridge(),
      containingContext: {type: 'course', contextId: '1201', userId: '17'},
      contextId: '1201',
      contextType: 'course',
      source: fakeSource,
      themeUrl: 'http://localhost/tinymce-theme.swf',
      ...override
    }
    return props
  }

  beforeEach(() => {
    jest.setTimeout(20000)
  })

  function renderComponent(trayprops) {
    component = render(<CanvasContentTray {...getProps(trayprops)} />)
  }

  function getTray() {
    const $tray = component.queryByRole('dialog')
    if ($tray) {
      return $tray
    }
    throw new Error('not mounted')
  }

  async function showTrayForPlugin(plugin) {
    act(() => {
      props.bridge.controller.showTrayForPlugin(plugin)
    })
    await wait(getTray, {timeout: 19500})
  }

  function getTrayLabel() {
    return getTray().getAttribute('aria-label')
  }

  describe('Tray Label', () => {
    beforeEach(() => {
      renderComponent()
    })

    it('is labeled with "Course Links" when using the "links" content type', async () => {
      await showTrayForPlugin('links')
      expect(getTrayLabel()).toEqual('Course Links')
    })

    // course
    it('is labeled with "Course Images" when using the "images" content type', async () => {
      await showTrayForPlugin('course_images')
      expect(getTrayLabel()).toEqual('Course Images')
    })

    it('is labeled with "Course Media" when using the "media" content type', async () => {
      await showTrayForPlugin('course_media')
      expect(getTrayLabel()).toEqual('Course Media')
    })

    it('is labeled with "Course Documents" when using the "course_documents" content type', async () => {
      await showTrayForPlugin('course_documents')
      expect(getTrayLabel()).toEqual('Course Documents')
    })

    // user
    it('is labeled with "User Images" when using the "user_images" content type', async () => {
      await showTrayForPlugin('user_images')
      expect(getTrayLabel()).toEqual('User Images')
    })

    it('is labeled with "User Media" when using the "user_media" content type', async () => {
      await showTrayForPlugin('user_media')
      expect(getTrayLabel()).toEqual('User Media')
    })

    it('is labeled with "User Documents" when using the "user_documents" content type', async () => {
      await showTrayForPlugin('user_documents')
      expect(getTrayLabel()).toEqual('User Documents')
    })
  })

  describe('content panel', () => {
    beforeEach(() => {
      renderComponent()
    })
    it('is the links panel for links content types', async () => {
      await showTrayForPlugin('links')
      expect(component.getByTestId('instructure_links-LinksPanel')).toBeInTheDocument()
    })

    it('is the documents panel for document content types', async () => {
      await showTrayForPlugin('course_documents')
      expect(component.getByTestId('instructure_links-DocumentsPanel')).toBeInTheDocument()
    })

    it('is the images panel for image content types', async () => {
      await showTrayForPlugin('course_images')
      expect(component.getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
    })

    it('is the media panel for media content types', async () => {
      await showTrayForPlugin('course_media')
      expect(component.getByTestId('instructure_links-MediaPanel')).toBeInTheDocument()
    })
  })

  describe('focus', () => {
    beforeEach(() => {
      renderComponent()
    })

    it('is set on tinymce after tray closes', async () => {
      const mockFocus = jest.fn()
      props.bridge.focusActiveEditor = mockFocus

      await showTrayForPlugin('links')
      expect(component.getByTestId('CanvasContentTray')).toBeInTheDocument()

      const closeBtn = component.getByText('Close')
      closeBtn.click()
      // immediatly after being asked to close, INSTUI Tray removes role='dialog' and
      // adds aria-hidden='true', so the getTray() function above does not work
      await waitForElementToBeRemoved(() => component.queryByTestId('CanvasContentTray'))

      expect(mockFocus).toHaveBeenCalledWith(false)
    })
  })
})
