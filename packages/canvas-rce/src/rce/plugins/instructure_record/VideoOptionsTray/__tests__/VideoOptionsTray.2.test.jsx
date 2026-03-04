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

import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import RCEGlobals from '../../../../../rce/RCEGlobals'
import RceApiSource from '../../../../../rcs/api'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'

import VideoOptionsTray from '..'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'

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

  describe('when rce_asr_captioning_improvements is enabled', () => {
    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        consolidated_media_player: true,
        rce_asr_captioning_improvements: true,
      })
    })

    it('renders "Player layout" as the dropdown label', () => {
      render(<VideoOptionsTray {...props} />)
      expect(screen.getByText('Player layout')).toBeInTheDocument()
      expect(screen.queryByText('Size')).not.toBeInTheDocument()
    })

    it('renders all player layout size options', async () => {
      render(<VideoOptionsTray {...props} />)
      fireEvent.click(screen.getByLabelText('Player layout'))
      expect(
        await screen.findByText('Small (400 x 273px)', {selector: '[role="option"]'}),
      ).toBeInTheDocument()
      expect(
        await screen.findByText('Medium (480 x 318px)', {selector: '[role="option"]'}),
      ).toBeInTheDocument()
      expect(
        await screen.findByText('Large (700 x 442px)', {selector: '[role="option"]'}),
      ).toBeInTheDocument()
      expect(
        await screen.findByText('Extra Large (850 x 357px)', {selector: '[role="option"]'}),
      ).toBeInTheDocument()
      expect(await screen.findByText('Custom', {selector: '[role="option"]'})).toBeInTheDocument()
    })

    it('does not show dimension hint below dropdown for fixed sizes', async () => {
      render(<VideoOptionsTray {...props} />)
      fireEvent.click(screen.getByLabelText('Player layout'))
      fireEvent.click(await screen.findByText('Large (700 x 442px)', {selector: '[role="option"]'}))
      expect(screen.queryByText('700 x 442px')).not.toBeInTheDocument()
    })

    it.each([
      ['Small (400 x 273px)', 400, 273],
      ['Medium (480 x 318px)', 480, 318],
      ['Large (700 x 442px)', 700, 442],
      ['Extra Large (850 x 357px)', 850, 357],
    ])('selecting %s saves correct dimensions', async (label, expectedWidth, expectedHeight) => {
      render(<VideoOptionsTray {...props} />)
      fireEvent.change(screen.getByPlaceholderText('Enter a media title'), {
        target: {value: 'A title'},
      })
      fireEvent.click(screen.getByLabelText('Player layout'))
      fireEvent.click(await screen.findByText(label, {selector: '[role="option"]'}))
      fireEvent.click(screen.getByText('Done'))
      await waitFor(() => {
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(expectedWidth)
        expect(appliedHeight).toEqual(expectedHeight)
      })
    })

    it.each([
      [400, 'Small (400 x 273px)'],
      [480, 'Medium (480 x 318px)'],
      [850, 'Extra Large (850 x 357px)'],
    ])('appliedWidth %i pre-selects %s on re-open', async (appliedWidth, expectedLabel) => {
      props.videoOptions.appliedWidth = appliedWidth
      render(<VideoOptionsTray {...props} />)
      fireEvent.click(screen.getByLabelText('Player layout'))
      expect(
        await screen.findByText(expectedLabel, {selector: '[role="option"][aria-selected="true"]'}),
      ).toBeInTheDocument()
    })

    it('shows minimum error message as 400 x 273px for below-minimum custom size', async () => {
      props.videoOptions.appliedWidth = 300
      props.videoOptions.appliedHeight = 200
      props.videoOptions.videoSize = 'custom'
      render(<VideoOptionsTray {...props} />)
      const message = await screen.findByTestId('message')
      expect(message.textContent).toContain('400 x 273px')
    })

    it('renders the Viewer Restrictions checkbox', () => {
      render(<VideoOptionsTray {...props} />)
      expect(screen.getByText('Viewer Restrictions')).toBeInTheDocument()
      expect(screen.getByText('Show Rolling Transcript')).toBeInTheDocument()
    })

    it('includes viewerRestrictions: { show_rolling_transcript: false } in onSave when none is pre-set', () => {
      render(<VideoOptionsTray {...props} />)
      fireEvent.change(screen.getByPlaceholderText('Enter a media title'), {
        target: {value: 'A title'},
      })
      fireEvent.click(screen.getByText('Done'))
      const [{viewerRestrictions}] = props.onSave.mock.calls[0]
      expect(viewerRestrictions).toEqual({ show_rolling_transcript: false })
    })

    it('includes viewerRestrictions with show_rolling_transcript when pre-set', () => {
      props.videoOptions.viewerRestrictions = {show_rolling_transcript: true}
      render(<VideoOptionsTray {...props} />)
      fireEvent.change(screen.getByPlaceholderText('Enter a media title'), {
        target: {value: 'A title'},
      })
      fireEvent.click(screen.getByText('Done'))
      const [{viewerRestrictions}] = props.onSave.mock.calls[0]
      expect(viewerRestrictions).toEqual({show_rolling_transcript: true})
    })

    describe('Custom layout formula', () => {
      it('derives height from width (no sidebar, <= 720)', async () => {
        props.videoOptions.appliedWidth = 400
        props.videoOptions.appliedHeight = 273
        render(<VideoOptionsTray {...props} />)
        fireEvent.click(screen.getByLabelText('Player layout'))
        fireEvent.click(await screen.findByText('Custom', {selector: '[role="option"]'}))
        fireEvent.change(screen.getByPlaceholderText('Enter a media title'), {
          target: {value: 'A title'},
        })
        fireEvent.click(screen.getByText('Done'))
        await waitFor(() => {
          const [{appliedWidth, appliedHeight}] = props.onSave.mock.calls[0]
          expect(appliedWidth).toEqual(400)
          expect(appliedHeight).toEqual(273)
        })
      })

      it('derives height from width (sidebar, > 720)', async () => {
        props.videoOptions.appliedWidth = 1032
        props.videoOptions.appliedHeight = 460
        render(<VideoOptionsTray {...props} />)
        fireEvent.click(screen.getByLabelText('Player layout'))
        fireEvent.click(await screen.findByText('Custom', {selector: '[role="option"]'}))
        fireEvent.change(screen.getByPlaceholderText('Enter a media title'), {
          target: {value: 'A title'},
        })
        fireEvent.click(screen.getByText('Done'))
        await waitFor(() => {
          const [{appliedWidth, appliedHeight}] = props.onSave.mock.calls[0]
          expect(appliedWidth).toEqual(1032)
          expect(appliedHeight).toEqual(460)
        })
      })
    })
  })

  describe('when rce_asr_captioning_improvements is disabled', () => {
    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        consolidated_media_player: true,
        rce_asr_captioning_improvements: false,
      })
    })

    it('renders "Size" as the dropdown label', () => {
      render(<VideoOptionsTray {...props} />)
      expect(screen.getByText('Size')).toBeInTheDocument()
      expect(screen.queryByText('Player layout')).not.toBeInTheDocument()
    })

    it('does not include "Extra Large" in the size options', async () => {
      render(<VideoOptionsTray {...props} />)
      fireEvent.click(screen.getByRole('combobox'))
      await screen.findByText('Small', {selector: '[role="option"]'})
      expect(screen.queryByText(/Extra Large/)).not.toBeInTheDocument()
    })

    it('does not render the Viewer Restrictions checkbox', () => {
      render(<VideoOptionsTray {...props} />)
      expect(screen.queryByText('Viewer Restrictions')).not.toBeInTheDocument()
    })
  })

  describe('"Done" button', () => {
    const expectNoTooltip = () => {
      fireEvent.mouseEnter(tray.$doneButton)
      expect(screen.queryByText('Unsaved changes will be lost.')).not.toBeInTheDocument()
    }

    const renderLoadedComponent = async () => {
      renderComponent()
      await waitFor(() => {
        expect(tray.$titleTextField).toBeInTheDocument()
      })
    }

    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({rce_asr_captioning_improvements: true})
    })

    describe("doesn't show tooltip", () => {
      it('by default', async () => {
        await renderLoadedComponent()
        expectNoTooltip()
      })

      describe('with manual captions', () => {
        it('if there are no changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          expectNoTooltip()
        })

        it('if changes are cancelled', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          fireEvent.click(tray.$manualCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('Catalan'))
          fireEvent.click(tray.$manualCaptionsCancelButton)
          expectNoTooltip()
        })
      })

      describe('with automatic captions', () => {
        it('if there are no changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          expectNoTooltip()
        })

        it('if changes are cancelled', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          fireEvent.click(tray.$automaticCaptionsCancelButton)
          expectNoTooltip()
        })

        it('if changes are applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          fireEvent.click(tray.$automaticCaptionsRequestButton)
          expectNoTooltip()
        })
      })
    })

    describe('shows tooltip', () => {
      const expectTooltip = () => {
        fireEvent.mouseEnter(tray.$doneButton)
        expect(screen.getByText('Unsaved changes will be lost.')).toBeInTheDocument()
      }

      describe('with manual captions', () => {
        it('if there are changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          fireEvent.click(tray.$manualCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('Catalan'))
          expectTooltip()
        })
      })

      describe('with automatic captions', () => {
        it('if there are changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          expectTooltip()
        })
      })
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
