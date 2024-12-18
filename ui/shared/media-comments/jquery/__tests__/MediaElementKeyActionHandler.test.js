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

import $ from 'jquery'
import 'jquery-migrate'
import MediaElementKeyActionHandler from '../MediaElementKeyActionHandler'

describe('MediaElementKeyActionHandler', () => {
  let handler
  let fakeMejs
  let fakePlayer
  let fakeMedia
  let fakeEvent
  let $target
  const KeyCodes = MediaElementKeyActionHandler.keyCodes
  const seekInterval = 5
  const jumpInterval = 10

  beforeEach(() => {
    $target = $('<div data-testid="control-element">')
    fakeMejs = {
      MediaFeatures: {
        hasTrueNativeFullScreen: false,
        isFirefox: false,
      },
    }
    fakeEvent = {
      target: $target[0],
      keyCode: KeyCodes.ENTER,
      preventDefault: jest.fn(),
    }
    fakeMedia = {
      currentTime: 0,
      duration: 100,
      paused: true,
      pause: jest.fn(),
      play: jest.fn(),
      setCurrentTime: jest.fn(),
      setVolume: jest.fn(),
      volume: 0.5,
    }
    fakePlayer = {
      exitFullScreen: jest.fn(),
      isFullScreen: false,
      media: {
        muted: false,
      },
      options: {
        defaultSeekBackwardInterval: jest.fn().mockReturnValue(seekInterval),
        defaultSeekForwardInterval: jest.fn().mockReturnValue(seekInterval),
        defaultJumpBackwardInterval: jest.fn().mockReturnValue(jumpInterval),
        defaultJumpForwardInterval: jest.fn().mockReturnValue(jumpInterval),
      },
      setMuted: jest.fn(),
    }

    handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('event handlers', () => {
    it('handles captions', () => {
      expect(handler.captionsHandler).toBeDefined()
    })

    it('handles fullscreen', () => {
      expect(handler.fullscreenHandler).toBeDefined()
    })

    it('handles play/pause', () => {
      expect(handler.playpauseHandler).toBeDefined()
    })

    it('handles progress', () => {
      expect(handler.progressHandler).toBeDefined()
    })

    it('handles source', () => {
      expect(handler.sourceHandler).toBeDefined()
    })

    it('handles speed', () => {
      expect(handler.speedHandler).toBeDefined()
    })

    it('handles volume', () => {
      expect(handler.volumeHandler).toBeDefined()
    })
  })

  describe('handlerKey', () => {
    it('returns the matching key based on where the event occurred', () => {
      jest.spyOn(handler, '_targetControl').mockReturnValue(['found'])
      handler._targetControl.mockReturnValueOnce(['found'])
      expect(handler.handlerKey()).toBe('captions')
    })

    it('returns the player key if no controls were the target', () => {
      jest.spyOn(handler, '_targetControl').mockReturnValue([])
      expect(handler.handlerKey()).toBe('player')
    })
  })

  describe('dispatch', () => {
    it('prevents default event behavior', () => {
      handler.dispatch()
      expect(fakeEvent.preventDefault).toHaveBeenCalled()
    })
  })

  describe('captionsHandler', () => {
    it('returns undefined', () => {
      expect(handler.captionsHandler()).toBeUndefined()
    })
  })

  describe('fullscreenHandler', () => {
    beforeEach(() => {
      $target[0].click = jest.fn()
    })

    it('simulates a click event when SPACE is pressed', () => {
      fakeEvent.keyCode = KeyCodes.SPACE
      handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
      handler.fullscreenHandler()
      expect($target[0].click).toHaveBeenCalled()
    })

    it('does nothing when SPACE is pressed in Firefox', () => {
      fakeEvent.keyCode = KeyCodes.SPACE
      fakeMejs.MediaFeatures.isFirefox = true
      handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
      handler.fullscreenHandler()
      expect($target[0].click).not.toHaveBeenCalled()
    })

    it('simulates a click event when ENTER is pressed', () => {
      fakeEvent.keyCode = KeyCodes.ENTER
      handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
      handler.fullscreenHandler()
      expect($target[0].click).toHaveBeenCalled()
    })

    it('exits fullscreen when ESC key is pressed in fullscreen mode', () => {
      fakeEvent.keyCode = KeyCodes.ESC
      fakePlayer.isFullScreen = true
      handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
      handler.fullscreenHandler()
      expect(fakePlayer.exitFullScreen).toHaveBeenCalled()
    })

    it('does nothing when other keys are pressed', () => {
      fakeEvent.keyCode = KeyCodes.UP
      expect(handler.fullscreenHandler()).toBeUndefined()
    })
  })

  describe('playpauseHandler', () => {
    it('rewinds when left key is pressed', () => {
      const previousTime = fakeMedia.duration / 2
      fakeMedia.currentTime = previousTime
      fakeEvent.keyCode = KeyCodes.LEFT
      handler = new MediaElementKeyActionHandler(fakeMejs, fakePlayer, fakeMedia, fakeEvent)
      handler.playpauseHandler()
      expect(fakeMedia.setCurrentTime).toHaveBeenCalledWith(previousTime - seekInterval)
    })
  })
})
