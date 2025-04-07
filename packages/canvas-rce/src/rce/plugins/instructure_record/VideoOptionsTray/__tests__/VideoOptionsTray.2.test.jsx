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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'

import VideoOptionsTray from '..'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import RceApiSource from '../../../../../rcs/api'
import RCEGlobals from '../../../../../rce/RCEGlobals'

jest.useFakeTimers()

describe('RCE "Videos" Plugin > VideoOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    createLiveRegion()

    props = {
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
      requestSubtitlesFromIframe: jest.fn(),
      videoOptions: {
        $element: null,
        appliedHeight: 180,
        appliedWidth: 320,
        id: 'm-video-id',
        naturalHeight: 730,
        naturalWidth: 1280,
        source: {},
        titleText: '',
        tracks: [{locale: 'en', inherited: false}],
        type: 'video-embed',
        videoSize: 'medium',
        usePercentageUnits: false,
      },
      trayProps: {
        host: 'localhost:3001',
        jwt: 'someuglyvalue',
      },
    }
  })

  afterEach(() => {
    removeLiveRegion()
    jest.resetAllMocks()
  })

  function renderComponent() {
    render(<VideoOptionsTray {...props} />)
    tray = VideoOptionsTrayDriver.find()
  }

  describe('requestSubtitlesFromIframe', () => {
    it('is not called when subtitles are present', () => {
      renderComponent()
      expect(props.requestSubtitlesFromIframe).not.toHaveBeenCalled()
    })

    it('is called when no subtitles present', () => {
      props.videoOptions.tracks = null
      renderComponent()
      expect(props.requestSubtitlesFromIframe).toHaveBeenCalledTimes(1)
    })
  })

  describe('when clicked', () => {
    beforeEach(() => {
      renderComponent()
      tray.setTitleText('A turtle in a party suit.')
    })

    it('prevents the default click handler', () => {
      const preventDefault = jest.fn()
      // Override preventDefault before event reaches image
      tray.$doneButton.addEventListener(
        'click',
        event => {
          Object.assign(event, {preventDefault})
        },
        true,
      )
      tray.$doneButton.click()
      expect(preventDefault).toHaveBeenCalledTimes(1)
    })

    it('calls the .onSave prop', () => {
      tray.$doneButton.click()
      expect(props.onSave).toHaveBeenCalledTimes(1)
    })

    describe('when calling the .onSave prop', () => {
      it('includes the Title Text', () => {
        tray.setTitleText('A turtle in a party suit.')
        tray.$doneButton.click()
        const [{titleText}] = props.onSave.mock.calls[0]
        expect(titleText).toEqual('A turtle in a party suit.')
      })

      it('includes the "Display As" setting', () => {
        tray.setDisplayAs('link')
        tray.$doneButton.click()
        const [{displayAs}] = props.onSave.mock.calls[0]
        expect(displayAs).toEqual('link')
      })

      it('includes the size to be applied', async () => {
        await tray.setSize('Large')
        tray.$doneButton.click()
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(400)
        const expectedHt = Math.round(
          (props.videoOptions.naturalHeight / props.videoOptions.naturalWidth) * 400,
        )
        expect(appliedHeight).toEqual(expectedHt)
      })
    })
  })

  describe('when the consolidated media player flag is enabled', () => {
    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({consolidated_media_player: true})
    })

    afterAll(() => {
      jest.restoreAllMocks()
    })

    it('includes the size to be applied for Small', async () => {
      render(<VideoOptionsTray {...props} />)
      const titleInput = screen.getByRole('textbox')
      fireEvent.change(titleInput, {target: {value: 'A turtle in a party suit.'}})
      const sizeSelect = screen.getByRole('combobox')
      fireEvent.click(sizeSelect)
      const smallOption = await screen.findByRole('option', {name: /small/i})
      fireEvent.click(smallOption)
      const doneButton = screen.getByRole('button', {name: /done/i})
      fireEvent.click(doneButton)
      await waitFor(() => {
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(320)
        expect(appliedHeight).toEqual(254)
      })
    })

    it('includes the size to be applied for Medium', async () => {
      render(<VideoOptionsTray {...props} />)
      const titleInput = screen.getByRole('textbox')
      fireEvent.change(titleInput, {target: {value: 'A turtle in a party suit.'}})
      const sizeSelect = screen.getByRole('combobox')
      fireEvent.click(sizeSelect)
      const smallOption = await screen.findByRole('option', {name: /medium/i})
      fireEvent.click(smallOption)
      const doneButton = screen.getByRole('button', {name: /done/i})
      fireEvent.click(doneButton)
      await waitFor(() => {
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(480)
        expect(appliedHeight).toEqual(300)
      })
    })

    it('includes the size to be applied for Large', async () => {
      render(<VideoOptionsTray {...props} />)
      const titleInput = screen.getByRole('textbox')
      fireEvent.change(titleInput, {target: {value: 'A turtle in a party suit.'}})
      const sizeSelect = screen.getByRole('combobox')
      fireEvent.click(sizeSelect)
      const smallOption = await screen.findByRole('option', {name: /large/i})
      fireEvent.click(smallOption)
      const doneButton = screen.getByRole('button', {name: /done/i})
      fireEvent.click(doneButton)
      await waitFor(() => {
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(700)
        expect(appliedHeight).toEqual(441)
      })
    })
  })

  describe('Attachment Media Options Tray', () => {
    it('does not have closed caption controls or title input for locked attachments', async () => {
      const getFileMock = jest.spyOn(RceApiSource.prototype, 'getFile').mockImplementation(() => {
        return Promise.resolve({
          id: '10',
          is_master_course_child_content: true,
          restricted_by_master_course: true,
        })
      })
      props.videoOptions = {attachmentId: 10}
      renderComponent()
      await waitFor(() => {
        expect(getFileMock).toHaveBeenCalled()
      })
      expect(tray.$closedCaptionPanel).not.toBeInTheDocument()
      expect(tray.$titleTextField).not.toBeInTheDocument()
    })

    it('shows closed caption controls and title input for unlocked attachments', async () => {
      const getFileMock = jest.spyOn(RceApiSource.prototype, 'getFile').mockImplementation(() => {
        return Promise.resolve({
          id: '10',
          is_master_course_master_content: true,
          restricted_by_master_course: true,
        })
      })
      props.videoOptions = {attachmentId: 10}
      renderComponent()
      await waitFor(() => {
        expect(getFileMock).toHaveBeenCalled()
      })
      expect(tray.$closedCaptionPanel).toBeInTheDocument()
      expect(tray.$titleTextField).toBeInTheDocument()
    })
  })

  describe('Studio Media Options Tray', () => {
    beforeEach(() => {
      props.studioOptions = {
        resizable: true,
        convertibleToLink: true,
      }
    })

    it('is labeled correctly', () => {
      const {getByLabelText} = render(<VideoOptionsTray {...props} />)
      expect(getByLabelText('Studio Media Options Tray')).toBeInTheDocument()
    })

    it('has the correct heading', () => {
      const {getByText} = render(<VideoOptionsTray {...props} />)
      expect(getByText('Studio Media Options')).toBeInTheDocument()
    })

    it('has a "Media Title" field', () => {
      const {getByText} = render(<VideoOptionsTray {...props} />)
      expect(getByText('Media Title')).toBeInTheDocument()
    })

    it('does not have closed caption controls', () => {
      const {queryByText} = render(<VideoOptionsTray {...props} />)
      expect(queryByText('Closed Captions/Subtitles')).not.toBeInTheDocument()
    })

    describe('when resizable is false', () => {
      beforeEach(() => {
        props.studioOptions.resizable = false
      })

      it('does not have size controls', () => {
        const {queryByText} = render(<VideoOptionsTray {...props} />)
        expect(queryByText('Size')).not.toBeInTheDocument()
      })
    })

    describe('when convertibleToLink is false', () => {
      beforeEach(() => {
        props.studioOptions.convertibleToLink = false
      })

      it('does not have display controls', () => {
        const {queryByText} = render(<VideoOptionsTray {...props} />)
        expect(queryByText('Display Options')).not.toBeInTheDocument()
      })
    })
  })
})
