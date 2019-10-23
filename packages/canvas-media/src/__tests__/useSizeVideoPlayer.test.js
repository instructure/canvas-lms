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
import {render} from '@testing-library/react'
import useSizeVideoPlayer, {
  sizeVideoPlayer,
  DEFAULT_VIDEO_PLAYER_SIZE,
  DEFUALT_AUDIO_PLAYER_SIZE
} from '../useSizeVideoPlayer'

function TestComponent(props) {
  const {playerWidth, playerHeight} = useSizeVideoPlayer(
    props.theFile,
    props.parentPanelRef,
    props.isLoading
  )
  return (
    <pre>
      <span>width={playerWidth}</span>
      <span>height={`${playerHeight}`}</span>
    </pre>
  )
}

function renderTestComponent(theFile, parentPanelRef, isLoading) {
  return render(
    <TestComponent theFile={theFile} parentPanelRef={parentPanelRef} isLoading={isLoading} />
  )
}

function makeFauxParentPanel(
  vwidth = DEFAULT_VIDEO_PLAYER_SIZE.width,
  vheight = DEFAULT_VIDEO_PLAYER_SIZE.height
) {
  return {
    clientWidth: 1000,
    querySelector: () => ({
      loadedmetadata: true,
      videoWidth: vwidth,
      videoHeight: vheight,
      style: {
        height: undefined
      }
    })
  }
}

describe('useSizeVideoPlayer hook', () => {
  describe('hook returns', () => {
    it('returns defaults if no file', () => {
      const {getByText} = renderTestComponent(null, {current: makeFauxParentPanel()})
      expect(getByText(`width=${DEFAULT_VIDEO_PLAYER_SIZE.width}`)).toBeInTheDocument()
      expect(getByText(`height=${DEFAULT_VIDEO_PLAYER_SIZE.height}`)).toBeInTheDocument()
    })

    it('returns defaults if no parent', () => {
      const {getByText} = renderTestComponent({type: 'video'}, {current: null})
      expect(getByText(`width=${DEFAULT_VIDEO_PLAYER_SIZE.width}`)).toBeInTheDocument()
      expect(getByText(`height=${DEFAULT_VIDEO_PLAYER_SIZE.height}`)).toBeInTheDocument()
    })

    it('returns .75 parent width', () => {
      const {getByText} = renderTestComponent({type: 'video'}, {current: makeFauxParentPanel()})
      expect(getByText('width=750px')).toBeInTheDocument()
      expect(getByText(`height=${undefined}`)).toBeInTheDocument()
    })

    it('returns fixed size for audio', () => {
      const {getByText} = renderTestComponent({type: 'audio'}, {current: makeFauxParentPanel()})
      expect(getByText(`width=${DEFUALT_AUDIO_PLAYER_SIZE.width}`)).toBeInTheDocument()
      expect(getByText(`height=${DEFUALT_AUDIO_PLAYER_SIZE.height}`)).toBeInTheDocument()
    })
  })

  describe('sizeVideoPlayer', () => {
    it('scales a landscape video', () => {
      const player = {
        videoWidth: 200,
        videoHeight: 100
      }
      const width = sizeVideoPlayer(player, 300)
      expect(width).toBe('300px')
    })

    it('scales a portrait video', () => {
      const player = {
        videoWidth: 100,
        videoHeight: 200
      }
      const width = sizeVideoPlayer(player, 300)
      expect(width).toBe('150px')
    })

    it('scales a square video', () => {
      const player = {
        videoWidth: 200,
        videoHeight: 200
      }
      const width = sizeVideoPlayer(player, 300)
      expect(width).toBe('300px')
    })
  })
})
