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
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {oneOf, string} from 'prop-types'
import I18n from 'i18n!CanvasMediaPlayer'
import {LoadingIndicator, isAudio, sizeMediaPlayer} from '@instructure/canvas-media'
import {VideoPlayer} from '@instructure/ui-media-player'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-layout'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

const byBitrate = (a, b) => parseInt(a.bitrate, 10) - parseInt(b.bitrate, 10)
const MAX_ATTEMPTS = 5

// !!!!
// ALERT: The resize handling code here assumes CanvasMediaPlayer fills 100% of its
// parent window, which is true when rendered from media_player_iframe_content.js
// The reason we need to handle resize is to letterbox vertical videos, or the bar
// of controls get clipped. When @instructure/ui-media-player supports letterboxing
// videos (which is in their work play), the resizing code here can probably be removed.
// !!!

export default function CanvasMediaPlayer(props) {
  const sorted_sources = Array.isArray(props.media_sources)
    ? props.media_sources.sort(byBitrate)
    : props.media_sources
  const [media_sources, setMedia_sources] = useState(sorted_sources)
  const [retryTimerId, setRetryTimerId] = useState(0)
  const [retryAttempt, setRetryAttempt] = useState(0)
  const containerRef = useRef(null)
  const myIframeRef = useRef(null)
  const mediaPlayerRef = useRef(null)

  const handleLoadedMetadata = useCallback(
    event => {
      const player = event.target
      setPlayerSize(player, props.type, {width: window.innerWidth, height: window.innerHeight})
    },
    [props.type]
  )

  const handlePlayerSize = useCallback(
    _event => {
      const player = window.document.body.querySelector('video')
      setPlayerSize(player, props.type, {width: window.innerWidth, height: window.innerHeight})
    },
    [props.type]
  )

  useEffect(() => {
    myIframeRef.current = [...window.parent.document.getElementsByTagName('iframe')].find(
      el => el.contentWindow === window
    )
  }, [])

  useEffect(() => {
    if (!props.media_sources.length && retryAttempt < MAX_ATTEMPTS) {
      fetchSources()
    }

    return () => {
      clearTimeout(retryTimerId)
    }
    // The way this function is setup seems to break things when more exhaustive
    // deps are put in here.  We should investigate more in the future.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [retryAttempt])

  // when we go to ui-media-player v7, <MediaPlayer> can listen for onLoadedMetedata
  // but for now, it doesn't.
  useEffect(() => {
    const player = containerRef.current.querySelector('video')
    if (player) {
      if (player.loadedmetadata || player.readyState >= 1) {
        handlePlayerSize()
      } else {
        player.addEventListener('loadedmetadata', handleLoadedMetadata)
        return () => {
          player.removeEventListener('loadedmetadata', handleLoadedMetadata)
        }
      }
    }
  }, [handlePlayerSize, handleLoadedMetadata])

  useEffect(() => {
    // what I wanted to do was listen for fullscreenchange on the MediaPlayer's div,
    // but it doesn't have it's new size at the time the event is fired. It also
    // doesn't get a resize event when transitioning to/from fullscreen.
    window.addEventListener('resize', handlePlayerSize)
    return () => {
      window.removeEventListener('resize', handlePlayerSize)
    }
  }, [handlePlayerSize])

  async function fetchSources() {
    const url = `/media_objects/${props.media_id}/info`
    let resp
    try {
      resp = await asJson(fetch(url, defaultFetchOptions))
    } catch (e) {
      // if there is a network error, just ignore and retry
    }
    if (resp && resp.media_sources && resp.media_sources.length) {
      setMedia_sources(resp.media_sources.sort(byBitrate))
    } else {
      // they're not present yet, try again in a little bit
      let tid = 0
      const nextAttempt = retryAttempt + 1
      if (nextAttempt < MAX_ATTEMPTS) {
        tid = setTimeout(() => {
          setRetryAttempt(nextAttempt)
        }, 2 ** retryAttempt * 1000)
      } else {
        setRetryAttempt(nextAttempt)
      }
      setRetryTimerId(tid)
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

  function renderNoPlayer() {
    if (retryAttempt < MAX_ATTEMPTS) {
      return (
        <LoadingIndicator
          translatedTitle={I18n.t('Loading')}
          size={props.type === 'audio' ? 'x-small' : 'large'}
        />
      )
    }
    return (
      <Alert variant="error" margin="small">
        {I18n.t('Failed retrieving media source')}
      </Alert>
    )
  }

  return (
    <div ref={containerRef}>
      {media_sources.length ? (
        <VideoPlayer
          ref={mediaPlayerRef}
          sources={media_sources}
          tracks={props.media_tracks}
          controls={renderControls}
        />
      ) : (
        renderNoPlayer()
      )}
    </div>
  )
}

function setPlayerSize(player, type, boundingBox) {
  const {width, height} = sizeMediaPlayer(player, type, boundingBox)
  player.style.width = width
  player.style.height = height
  player.style.margin = '0 auto' // TODO: remove with player v7
  player.classList.add(isAudio(type) ? 'audio-player' : 'video-player')
}

CanvasMediaPlayer.propTypes = {
  media_id: string.isRequired,
  media_sources: VideoPlayer.propTypes.sources,
  media_tracks: VideoPlayer.propTypes.tracks,
  type: oneOf(['audio', 'video'])
}

CanvasMediaPlayer.defaultProps = {
  media_sources: [],
  type: 'video'
}
