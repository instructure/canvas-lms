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
import {number, oneOf, string} from 'prop-types'
import I18n from 'i18n!CanvasMediaPlayer'
import {LoadingIndicator, isAudio, sizeMediaPlayer} from '@instructure/canvas-media'
import {VideoPlayer} from '@instructure/ui-media-player'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-layout'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

const byBitrate = (a, b) => parseInt(a.bitrate, 10) - parseInt(b.bitrate, 10)

const liveRegion = () => window.top.document.getElementById('flash_screenreader_holder')

// It can take a while for notorious to process a newly uploaded video
// Each attempt to get the media_sources is 2**n seconds after the previous attempt
// so we'll keep at it for about an hour (2**(MAX_RETRY_ATTEMPTS+1)/60 minutes) as long as there's no network error.
const DEFAULT_MAX_RETRY_ATTEMPTS = 11
const DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = 3

export default function CanvasMediaPlayer(props) {
  const sorted_sources = Array.isArray(props.media_sources)
    ? props.media_sources.sort(byBitrate)
    : props.media_sources
  const [media_sources, setMedia_sources] = useState(sorted_sources)
  const [retryTimerId, setRetryTimerId] = useState(0)
  const [retryAttempt, setRetryAttempt] = useState(0)
  const [mediaObjNetworkErr, setMediaObjNetworkErr] = useState(null)
  // the ability to set these makes testing easier
  // hint: set these values in a conditional breakpoint in
  // media_player_iframe_content.js where the CanvasMediaPlayer is rendered
  // for example:
  // ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS=2, ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS=4, 0
  const [MAX_RETRY_ATTEMPTS] = useState(
    ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS || props.MAX_RETRY_ATTEMPTS
  )
  const [SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS] = useState(
    ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS || props.SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS
  )

  const containerRef = useRef(null)
  const mediaPlayerRef = useRef(null)

  function boundingBox() {
    if (window.frameElement?.tagName === 'IFRAME' || !containerRef.current) {
      return {width: window.innerWidth, height: window.innerHeight}
    } else if (document.fullscreenElement) {
      return {
        width: document.fullscreenElement.clientWidth,
        height: document.fullscreenElement.clientHeight
      }
    } else {
      // media_player_iframe_content.js includes a 16px top/bottom margin
      return {
        width: containerRef.current.clientWidth,
        height: Math.min(containerRef.current.clientHeight, window.innerHeight - 32)
      }
    }
  }

  const handleLoadedMetadata = useCallback(
    event => {
      const player = event.target
      const playerParent = containerRef.current
        ? containerRef.current.parentElement
        : window.frameElement
      setPlayerSize(player, props.type, boundingBox(), window.frameElement || playerParent)
    },
    [props.type]
  )

  const handlePlayerSize = useCallback(
    _event => {
      const player = window.document.body.querySelector('video')
      setPlayerSize(player, props.type, boundingBox(), null)
    },
    [props.type]
  )

  useEffect(() => {
    if (!props.media_sources.length && retryAttempt <= MAX_RETRY_ATTEMPTS) {
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
      setMediaObjNetworkErr(null)
      resp = await asJson(fetch(url, defaultFetchOptions))
    } catch (e) {
      // eslint-disable-next-line no-console
      console.warn(`Error getting ${url}`, e.message)
      setMediaObjNetworkErr(e)
      return
    }
    if (resp && resp.media_sources && resp.media_sources.length) {
      setMedia_sources(resp.media_sources.sort(byBitrate))
    } else {
      // they're not present yet, try again in a little bit
      let tid = 0
      const nextAttempt = retryAttempt + 1
      if (nextAttempt < MAX_RETRY_ATTEMPTS) {
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
    if (mediaObjNetworkErr) {
      return (
        <Alert key="erralert" variant="error" margin="small" liveRegion={liveRegion}>
          {I18n.t('Failed retrieving media sources.')}
        </Alert>
      )
    }
    if (retryAttempt >= MAX_RETRY_ATTEMPTS) {
      // this should be very rare
      return (
        <Alert key="giveupalert" variant="info" margin="x-small" liveRegion={liveRegion}>
          {I18n.t(
            'Giving up on retrieving media sources. This issue will probably resolve itself eventually.'
          )}
        </Alert>
      )
    }
    if (retryAttempt >= SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS) {
      return (
        <Flex margin="xx-small" justifyItems="space-between">
          <Flex.Item margin="0 0 x-small 0" shouldGrow shouldShrink>
            <Alert key="bepatientalert" variant="info" margin="x-small" liveRegion={liveRegion}>
              {I18n.t('Your media has been uploaded and will appear here after processing.')}
            </Alert>
          </Flex.Item>
          <Flex.Item shouldGrow={false} shouldShrink={false} margin="0 x-small 0 0">
            <Spinner renderTitle={() => I18n.t('Loading')} size="small" />
          </Flex.Item>
        </Flex>
      )
    }
    return (
      <>
        <Alert key="loadingalert" variant="info" liveRegion={liveRegion} screenReaderOnly>
          {I18n.t('Loading')}
        </Alert>
        <LoadingIndicator
          translatedTitle={I18n.t('Loading')}
          size={props.type === 'audio' ? 'x-small' : 'large'}
        />
      </>
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

export function setPlayerSize(player, type, boundingBox, playerContainer) {
  const {width, height} = sizeMediaPlayer(player, type, boundingBox, !!document.fullscreenElement)
  player.style.width = width
  player.style.height = height
  player.style.margin = '0 auto' // TODO: remove with player v7
  player.classList.add(isAudio(type) ? 'audio-player' : 'video-player')

  // videos that are wide-and-short portrait need to shrink the parent
  if (playerContainer && player.videoWidth > player.videoHeight) {
    playerContainer.style.width = width
    playerContainer.style.height = height

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

CanvasMediaPlayer.propTypes = {
  media_id: string.isRequired,
  media_sources: VideoPlayer.propTypes.sources,
  media_tracks: VideoPlayer.propTypes.tracks,
  type: oneOf(['audio', 'video']),
  MAX_RETRY_ATTEMPTS: number,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS: number
}

CanvasMediaPlayer.defaultProps = {
  media_sources: [],
  type: 'video',
  MAX_RETRY_ATTEMPTS: DEFAULT_MAX_RETRY_ATTEMPTS,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS: DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS
}
