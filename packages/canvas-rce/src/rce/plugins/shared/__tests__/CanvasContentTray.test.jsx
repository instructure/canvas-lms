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
import {act, render, waitFor, waitForElementToBeRemoved, fireEvent} from '@testing-library/react'

import bridge from '../../../../bridge'
import * as fakeSource from '../../../../rcs/fake'
import initialState from '../../../../sidebar/store/initialState'
import sidebarHandlers from '../../../../sidebar/containers/sidebarHandlers'
import CanvasContentTray from '../CanvasContentTray'
import {LinkDisplay} from '../LinkDisplay'
import {destroyContainer} from '../../../../common/FlashAlert'

jest.useFakeTimers()
jest.mock('../../../../canvasFileBrowser/FileBrowser', () => {
  return jest.fn(() => 'Files Browser')
})
jest.mock('../ContentSelection', () => ({
  getLinkContentFromEditor: jest.fn().mockReturnValue({
    fileName: 'some filename',
    contentType: 'wikiPages',
    url: '/pages',
    published: true,
    text: 'some text',
  }),
}))
jest.mock('../../../../bridge', () => {
  const original = jest.requireActual('../../../../bridge')
  original.default.insertLink = jest.fn()
  return original
})
jest.mock('../LinkDisplay', () => ({
  LinkDisplay: jest.fn(() => <div data-testid="LinkDisplay" />),
}))

const storeInitialState = {
  ...initialState({
    contextId: '1201',
    contextType: 'course',
    canvasOrigin: 'http://canvas:3000',
    jwt: 'xyzzy',
    host: 'http://canvas.rcs:3001',
    refreshToken: () => {},
  }),
  ...sidebarHandlers(() => {}),
  onFileSelect: () => {},
  onLinkClick: () => {},
  onImageEmbed: () => {},
  onMediaEmbed: () => {},
}

describe('RCE Plugins > CanvasContentTray', () => {
  let component
  let props
  const editor = {id: 'editor_id'}

  function getProps(override = {}) {
    props = {
      bridge,
      editor,
      containingContext: {contextType: 'course', contextId: '1201', userId: '17'},
      contextId: storeInitialState.contextId,
      contextType: storeInitialState.contextType,
      source: fakeSource,
      themeUrl: 'http://localhost/tinymce-theme.swf',
      storeProps: storeInitialState,
      canvasOrigin: 'http://canvas:3000',
      ...override,
    }
    return props
  }

  function renderComponent(trayprops) {
    getProps(trayprops)
    props.bridge.focusEditor(editor)
    component = render(<CanvasContentTray {...props} />)
  }

  function getTray() {
    const $tray = component.queryByRole('dialog')
    if ($tray) {
      return $tray
    }
    throw new Error('not mounted')
  }

  async function showTrayForPlugin(plugin) {
    await waitFor(() => {
      if (typeof props.bridge.showTrayForPlugin !== 'function') {
        throw new Error('showTrayForPlugin not here yet')
      }
    })
    act(() => {
      props.bridge.showTrayForPlugin(plugin, 'editor_id')
    })
    await waitFor(getTray, {timeout: 19500})
  }

  function getTrayLabel() {
    return getTray().getAttribute('aria-label')
  }

  it('clears search string on tray close', async () => {
    const mockOnChangeSearchString = jest.fn()
    renderComponent(
      getProps({storeProps: {...storeInitialState, onChangeSearchString: mockOnChangeSearchString}})
    )
    await showTrayForPlugin('links')
    const close = await component.findByTestId('CloseButton_ContentTray')
    const closeButton = close.querySelector('button')
    closeButton.focus()
    closeButton.click()
    await waitForElementToBeRemoved(() => component.queryByTestId('CanvasContentTray'))
    expect(mockOnChangeSearchString).toHaveBeenLastCalledWith('')
  })

  describe('Edit Course Links Tray', () => {
    beforeEach(async () => {
      renderComponent()
      await showTrayForPlugin('course_link_edit')
    })

    afterEach(() => {
      destroyContainer()
    })

    it('is labeled with "Edit Course Link"', async () => {
      await waitFor(() => {
        const header = getTray().querySelector('[data-cid="Heading"]').textContent
        expect(header).toEqual('Edit Course Link')
      })
    })

    it('renders the LinkDisplay Component', async () => {
      await waitFor(() => {
        expect(component.getByTestId('LinkDisplay')).toBeInTheDocument()
      })
    })

    it('replaces the old link when the Replace button is clicked', async () => {
      const button = await component.findByTestId('replace-link-button')
      fireEvent.click(button)
      await waitFor(() => {
        expect(bridge.insertLink).toHaveBeenCalledWith({
          forceRename: true,
          href: '/pages',
          text: 'some text',
          title: 'some filename',
          type: 'wikiPages',
          published: true,
        })
      })
    })

    it('sets placeholder to the current link title', async () => {
      await waitFor(() => {
        expect(LinkDisplay).toHaveBeenCalledWith(
          expect.objectContaining({placeholderText: 'some filename'}),
          {}
        )
      })
    })

    it('creates a SR alert when the link is updated', async () => {
      const button = await component.findByTestId('replace-link-button')
      fireEvent.click(button)
      const linkButton = await component.findAllByText('Updated link')
      expect(linkButton.length).toBeGreaterThan(0)
    })
  })

  describe('Tray Label in course context', () => {
    beforeEach(() => {
      renderComponent()
    })

    // course
    it('is labeled with "Course Links" when using the "links" content type', async () => {
      await showTrayForPlugin('links')
      expect(getTrayLabel()).toEqual('Course Links')
    })

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

    it('is labeled with "Icon Maker Icons" when using the "list_icon_maker_icons" content type', async () => {
      await showTrayForPlugin('list_icon_maker_icons')
      expect(getTrayLabel()).toEqual('Icon Maker Icons')
    })
  })

  describe('Tray Label in group context', () => {
    beforeEach(() => {
      renderComponent({contextType: 'group'})
    })

    it('is labeled with "Group Links" when using the "links" content type', async () => {
      await showTrayForPlugin('links')
      expect(getTrayLabel()).toEqual('Group Links')
    })

    it('is labeled with "Group Images" when using the "images" content type', async () => {
      await showTrayForPlugin('group_images')
      expect(getTrayLabel()).toEqual('Group Images')
    })

    it('is labeled with "Group Media" when using the "media" content type', async () => {
      await showTrayForPlugin('group_media')
      expect(getTrayLabel()).toEqual('Group Media')
    })

    it('is labeled with "Group Documents" when using the "group_documents" content type', async () => {
      await showTrayForPlugin('group_documents')
      expect(getTrayLabel()).toEqual('Group Documents')
    })
  })

  describe('content panel', () => {
    beforeEach(() => {
      renderComponent()
    })
    it('is the links panel for links content types', async () => {
      await showTrayForPlugin('links')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-LinksPanel')).toBeInTheDocument()
      )
    })

    it('is the documents panel for document content types', async () => {
      await showTrayForPlugin('course_documents')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-DocumentsPanel')).toBeInTheDocument()
      )
    })

    it('is the images panel for image content types', async () => {
      await showTrayForPlugin('course_images')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
      )
    })

    it('is the images panel for icon maker content types', async () => {
      await showTrayForPlugin('list_icon_maker_icons')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
      )
    })

    it('is the media panel for media content types', async () => {
      await showTrayForPlugin('course_media')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-MediaPanel')).toBeInTheDocument()
      )
    })

    it('is the file browser for the all content type', async () => {
      await showTrayForPlugin('all')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-FilesPanel')).toBeInTheDocument()
      )
    })
  })

  describe('focus', () => {
    beforeEach(() => {
      renderComponent()
    })

    it('is set on tinymce after tray closes if focus was on the tray', async () => {
      const mockFocus = jest.fn()
      props.bridge.focusActiveEditor = mockFocus

      await showTrayForPlugin('links')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-LinksPanel')).toBeInTheDocument()
      )

      const closeBtn = component.getByTestId('CloseButton_ContentTray').querySelector('button')
      closeBtn.focus()
      closeBtn.click()
      // immediately after being asked to close, INSTUI Tray removes role='dialog' and
      // adds aria-hidden='true', so the getTray() function above does not work
      await waitForElementToBeRemoved(() => component.queryByTestId('CanvasContentTray'))

      expect(mockFocus).toHaveBeenCalledWith(false)
    })

    it('is not set on tinymce after tray closes if focus was elsewhere', async () => {
      const mockFocus = jest.fn()
      props.bridge.focusActiveEditor = mockFocus

      await showTrayForPlugin('links')
      await waitFor(() =>
        expect(component.getByTestId('instructure_links-LinksPanel')).toBeInTheDocument()
      )

      act(() => props.bridge.hideTrays())
      // immediately after being asked to close, INSTUI Tray removes role='dialog' and
      // adds aria-hidden='true', so the getTray() function above does not work
      await waitForElementToBeRemoved(() => component.queryByTestId('CanvasContentTray'))

      expect(mockFocus).not.toHaveBeenCalled()
    })
  })
})
