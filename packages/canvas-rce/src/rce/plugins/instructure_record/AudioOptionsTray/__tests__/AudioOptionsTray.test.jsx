/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {trackPendoEvent} from '@instructure/canvas-media'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import React from 'react'
import RCEGlobals from '../../../../../rce/RCEGlobals'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import AudioOptionsTray from '..'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'

jest.mock('@instructure/canvas-media', () => ({
  ...jest.requireActual('@instructure/canvas-media'),
  trackPendoEvent: jest.fn(),
}))

function getProps({audioOptions: audioOverrides, ...overrides} = {}) {
  return {
    onRequestClose: jest.fn(),
    onSave: jest.fn(),
    open: true,
    requestSubtitlesFromIframe: jest.fn(),
    audioOptions: {
      id: 'm-audio-id',
      titleText: 'Audio player',
      tracks: [{locale: 'en', inherited: false}],
      containerDimensions: {width: 400, height: 273},
      ...audioOverrides,
    },
    trayProps: {
      host: 'localhost:3001',
      jwt: 'someuglyvalue',
    },
    ...overrides,
  }
}

describe('RCE "Audios" Plugin > AudioOptionsTray', () => {
  let tray

  beforeEach(() => {
    createLiveRegion()
  })

  afterEach(() => {
    removeLiveRegion()
  })

  function renderComponent(overrides) {
    const props = getProps(overrides)
    render(<AudioOptionsTray {...props} />)
    tray = AudioOptionsTrayDriver.find()
    return props
  }

  it('is optionally rendered open', () => {
    renderComponent({open: true})
    expect(tray).not.toBeNull()
  })

  it('is optionally rendered closed', () => {
    renderComponent({open: false})
    expect(tray).toBeNull()
  })

  it('is labeled with "Audio Options Tray"', () => {
    renderComponent()
    expect(tray.label).toEqual('Audio Options Tray')
  })

  it('when clicked calls the .onSave prop', () => {
    const props = renderComponent()
    tray.$doneButton.click()
    expect(props.onSave).toHaveBeenCalledTimes(1)
  })

  describe('requestSubtitlesFromIframe', () => {
    it('is not called when subtitles are present', () => {
      const props = renderComponent()
      expect(props.requestSubtitlesFromIframe).not.toHaveBeenCalled()
    })

    it('is called when no subtitles present', () => {
      const props = renderComponent({audioOptions: {tracks: null}})
      expect(props.requestSubtitlesFromIframe).toHaveBeenCalledTimes(1)
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
        expect(tray.$manualCaptionsAddNewButton).toBeInTheDocument()
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

  describe('when rce_asr_captioning_improvements is enabled', () => {
    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })
    })

    it('renders "Player layout" as the dropdown label', () => {
      renderComponent()
      expect(screen.getByText('Player layout')).toBeInTheDocument()
      expect(screen.queryByText('Size')).not.toBeInTheDocument()
    })

    it('renders all player layout size options', async () => {
      renderComponent()
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

    it('links the 720px helper text to the dropdown via aria-describedby', () => {
      renderComponent()
      const input = screen.getByLabelText('Player layout')
      const helperId = 'audio-options-tray-size-helper-text'
      expect(input.getAttribute('aria-describedby')).toContain(helperId)
    })

    it.each([
      ['Small (400 x 273px)', 400, 273],
      ['Medium (480 x 318px)', 480, 318],
      ['Large (700 x 442px)', 700, 442],
      ['Extra Large (850 x 357px)', 850, 357],
    ])('selecting %s saves correct dimensions', async (label, expectedWidth, expectedHeight) => {
      const props = renderComponent()
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
    ])('appliedWidth %i pre-selects %s on re-open', async (width, expectedLabel) => {
      renderComponent({audioOptions: {containerDimensions: {width, height: 300}}})
      fireEvent.click(screen.getByLabelText('Player layout'))
      expect(
        await screen.findByText(expectedLabel, {selector: '[role="option"][aria-selected="true"]'}),
      ).toBeInTheDocument()
    })

    it('shows minimum error message as 320 x 228px for below-minimum custom size', async () => {
      renderComponent({audioOptions: {containerDimensions: {width: 300, height: 200}}})
      const message = await screen.findByTestId('message')
      expect(message.textContent).toContain('320 x 228px')
    })

    describe('Custom layout formula', () => {
      it('derives height from width (no sidebar, <= 720)', async () => {
        const props = renderComponent({
          audioOptions: {containerDimensions: {width: 400, height: 273}},
        })
        fireEvent.click(screen.getByLabelText('Player layout'))
        fireEvent.click(await screen.findByText('Custom', {selector: '[role="option"]'}))
        fireEvent.click(screen.getByText('Done'))
        await waitFor(() => {
          const [{appliedWidth, appliedHeight}] = props.onSave.mock.calls[0]
          expect(appliedWidth).toEqual(400)
          expect(appliedHeight).toEqual(273)
        })
      })

      it('derives height from width (sidebar, > 720)', async () => {
        const props = renderComponent({
          audioOptions: {containerDimensions: {width: 1032, height: 460}},
        })
        fireEvent.click(screen.getByLabelText('Player layout'))
        fireEvent.click(await screen.findByText('Custom', {selector: '[role="option"]'}))
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
        rce_asr_captioning_improvements: false,
      })
    })

    it('does not render "Player layout" section', () => {
      renderComponent()
      expect(screen.queryByText('Player layout')).not.toBeInTheDocument()
    })
  })

  describe('Pendo analytics', () => {
    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({rce_asr_captioning_improvements: true})
      trackPendoEvent.mockClear()
    })

    it('tracks canvas_media_options_opened when opened', () => {
      renderComponent()
      expect(trackPendoEvent).toHaveBeenCalledWith('canvas_media_options_opened', {
        entry_point: 'quick_menu',
        media_kind: 'audio',
      })
    })

    it('does not track when flag is disabled', () => {
      jest
        .spyOn(RCEGlobals, 'getFeatures')
        .mockReturnValue({rce_asr_captioning_improvements: false})
      renderComponent()
      expect(trackPendoEvent).not.toHaveBeenCalled()
    })
  })
})
