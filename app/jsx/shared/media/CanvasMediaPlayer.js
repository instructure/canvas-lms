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
import React, {useEffect, useRef, useState} from 'react'
import {oneOf, string} from 'prop-types'
import I18n from 'i18n!CanvasMediaPlayer'
import LoadingIndicator from '@instructure/canvas-media/lib/shared/LoadingIndicator'
import {VideoPlayer} from '@instructure/ui-media-player'
import {View} from '@instructure/ui-layout'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

export default function CanvasMediaPlayer(props) {
  const [media_sources, setMedia_sources] = useState(props.media_sources)
  const [retryTimerId, setRetryTimerId] = useState(0)
  const containerRef = useRef(null)
  const myIframeRef = useRef(null)

  useEffect(() => {
    myIframeRef.current = [...window.parent.document.getElementsByTagName('iframe')].find(
      el => el.contentWindow === window
    )
  }, [])

  useEffect(() => {
    if (!props.media_sources.length) {
      fetchSources()
    }

    return () => {
      clearTimeout(retryTimerId)
    }
    // The way this function is setup seems to break things when more exhaustive
    // deps are put in here.  We should investigate more in the future.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [retryTimerId])

  useEffect(() => {
    const player = containerRef.current.querySelector('video')
    if (player) {
      if (player.loadedmetadata || player.readyState >= 1) {
        setMediaPlayerSize(player)
      } else {
        player.addEventListener('loadedmetadata', () => setMediaPlayerSize(player))
      }
    }
    // The way this function is setup seems to break things when more exhaustive
    // deps are put in here.  We should investigate more in the future.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [media_sources.length])

  async function fetchSources() {
    const url = `/media_objects/${props.media_id}/info`
    let resp
    try {
      resp = await asJson(fetch(url, defaultFetchOptions))
    } catch (e) {
      // if there is a network error, just ignore and retry
    }
    if (resp && resp.media_sources && resp.media_sources.length) {
      setMedia_sources(resp.media_sources)
    } else {
      // if they're not present yet, try again in a little bit
      await new Promise(resolve => {
        const tid = setTimeout(resolve, 1000)
        setRetryTimerId(tid)
      })
    }
  }

  function setMediaPlayerSize(player) {
    const playerContainer = myIframeRef.current
    if (playerContainer) {
      const {width, height} = sizeMediaPlayer(player, props.type, playerContainer)
      playerContainer.style.width = width
      playerContainer.style.height = height
      if (props.type === 'audio') {
        player.style.height = height
      }

      const playerContainerContainer = playerContainer.parentElement // tinymce adds this
      if (
        playerContainerContainer &&
        playerContainerContainer.classList.contains('mce-preview-object') &&
        playerContainerContainer.classList.contains('mce-object-iframe')
      ) {
        // we're in the RCE
        playerContainerContainer.style.width = width
        playerContainerContainer.style.height = height
      }
    }
  }

  function renderControls(VPC) {
    if (props.type === 'audio') {
      return (
        <VPC>
          <VPC.PlayPauseButton />
          <VPC.Timebar />
          <VPC.Volume />
          <VPC.PlaybackSpeed />
          <VPC.TrackChooser />
        </VPC>
      )
    }

    // TODO: when the fullscreen button is missing, the source chooser button is up against
    // the right edge of the frame. When its popup menu is opened, the outset focus ring
    // extends beyond the container's edge, causing a horiz. scrollbar, which steals vert.
    // space and causes a vert. scrollbar, and this oscillates.
    // remove the containing View when this jitter is fixed
    return (
      <VPC>
        <VPC.PlayPauseButton />
        <VPC.Timebar />
        <VPC.Volume />
        <VPC.PlaybackSpeed />
        <VPC.TrackChooser />
        {media_sources.length > 1 && (
          <View margin={includeFullscreen ? '0 0 0 xx-small' : '0 xx-small'}>
            <VPC.SourceChooser sources={media_sources} />
          </View>
        )}
        {includeFullscreen && <VPC.FullScreenButton />}
      </VPC>
    )
  }

  const includeFullscreen = document.fullscreenEnabled && props.type === 'video'

  return (
    <div ref={containerRef}>
      {media_sources.length ? (
        <VideoPlayer sources={media_sources} controls={renderControls} />
      ) : (
        <LoadingIndicator
          translatedTitle={I18n.t('Loading')}
          size={props.type === 'audio' ? 'x-small' : 'large'}
        />
      )}
    </div>
  )
}

export function sizeMediaPlayer(player, type, playerContainer) {
  if (type === 'audio') {
    return {width: '300px', height: '3rem'}
  }

  const width = player.videoWidth
  const height = player.videoHeight
  if (width > 0) {
    // key off width, because we know it's initially layed out landscape
    // just wide enough for the controls to fit
    const minSideLength = playerContainer.clientWidth
    const w = Math.min(width, minSideLength)

    return {width: `${w}px`, height: `${Math.round((w / width) * height)}px`}
  }
  return {}
}

CanvasMediaPlayer.propTypes = {
  media_id: string.isRequired,
  media_sources: VideoPlayer.propTypes.sources,
  type: oneOf(['audio', 'video'])
}

CanvasMediaPlayer.defaultProps = {
  media_sources: [],
  type: 'video'
}
