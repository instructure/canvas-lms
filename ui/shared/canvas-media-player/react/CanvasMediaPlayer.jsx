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
import {bool, number, oneOf, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {LoadingIndicator, isAudio, sizeMediaPlayer} from '@instructure/canvas-media'
import {MediaPlayer} from '@instructure/ui-media-player'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {asJson, defaultFetchOptions} from '@canvas/util/xhr'

const I18n = useI18nScope('CanvasMediaPlayer')

const byBitrate = (a, b) => parseInt(a.bitrate, 10) - parseInt(b.bitrate, 10)

const liveRegion = () => window.top.document.getElementById('flash_screenreader_holder')

// It can take a while for notorious to process a newly uploaded video
// Each attempt to get the media_sources is 2**n seconds after the previous attempt
// so we'll keep at it for about an hour (2**(MAX_RETRY_ATTEMPTS+1)/60 minutes) as long as there's no network error.
const DEFAULT_MAX_RETRY_ATTEMPTS = 11
const DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = 3

export function getAutoTrack(tracks) {
  if (!ENV.auto_show_cc) return undefined
  if (!tracks) return undefined
  let locale = ENV.locale || document.documentElement.getAttribute('lang') || 'en'
  // look for an exact match
  let auto_track = tracks.find(t => t.locale === locale)
  if (!auto_track) {
    // look for an exact match to the de-regionalized user locale
    locale = locale.replace(/-.*/, '')
    auto_track = tracks.find(t => t.locale === locale)
    if (!auto_track) {
      // look for any match to de-regionalized tracks
      auto_track = tracks.find(t => t.locale.replace(/-.*/, '') === locale)
    }
  }
  return auto_track?.locale
}
export default function CanvasMediaPlayer(props) {
  const sorted_sources = Array.isArray(props.media_sources)
    ? props.media_sources.sort(byBitrate)
    : props.media_sources
  const tracks = Array.isArray(props.media_tracks)
    ? props.media_tracks.map(t => ({locale: t.language, language: t.label, inherited: t.inherited}))
    : null
  const [media_sources, setMedia_sources] = useState(sorted_sources)
  const [media_tracks] = useState(tracks)
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
  const [auto_cc_track] = useState(getAutoTrack(tracks))

  const containerRef = useRef(null)
  const mediaPlayerRef = useRef(null)

  const boundingBox = useCallback(() => {
    const isFullscreen = document.fullscreenElement || document.webkitFullscreenElement
    const isEmbedded =
      window.frameElement?.tagName === 'IFRAME' ||
      window.location !== window.top.location ||
      !containerRef.current
    if (isFullscreen || isEmbedded) {
      return {
        width: window.innerWidth,
        height: window.innerHeight,
      }
    }

    // media_player_iframe_content.js includes a 16px top/bottom margin
    return {
      width: containerRef.current.clientWidth,
      height: Math.min(containerRef.current.clientHeight, window.innerHeight - 32),
    }
  }, [containerRef])

  const handleLoadedMetadata = useCallback(
    event => {
      const player = event.target
      const playerParent = containerRef.current
        ? containerRef.current.parentElement
        : window.frameElement
      setPlayerSize(
        player,
        props.type,
        boundingBox(),
        window.frameElement || playerParent,
        props.resizeContainer
      )
    },
    [boundingBox, props.resizeContainer, props.type]
  )

  const handlePlayerSize = useCallback(
    _event => {
      const player = window.document.body.querySelector('video')
      const playerParent = containerRef.current
      setPlayerSize(
        player,
        props.type,
        boundingBox(),
        window.frameElement || playerParent,
        props.resizeContainer
      )
    },
    [props.type, props.resizeContainer, boundingBox]
  )

  const fetchSources = useCallback(
    async function () {
      const url = props.attachment_id
        ? `/media_attachments/${props.attachment_id}/info`
        : `/media_objects/${props.media_id}/info`
      let resp
      try {
        setMediaObjNetworkErr(null)
        resp = await asJson(fetch(url, defaultFetchOptions()))
      } catch (e) {
        // eslint-disable-next-line no-console
        console.warn(`Error getting ${url}`, e.message)
        setMediaObjNetworkErr(e)
        return
      }
      if (resp?.media_sources?.length) {
        setMedia_sources(resp.media_sources.sort(byBitrate))
      } else {
        setRetryAttempt(retryAttempt + 1)
      }
    },
    [props.attachment_id, props.media_id, retryAttempt]
  )

  useEffect(() => {
    // if we just uploaded the media, notorious may still be processing it
    // and we don't have its media_sources yet
    let retryTimerId = 0
    if (!media_sources.length && retryAttempt <= MAX_RETRY_ATTEMPTS) {
      retryTimerId = setTimeout(() => {
        fetchSources()
      }, 2 ** retryAttempt * 1000)
    }

    return () => {
      clearTimeout(retryTimerId)
    }
  }, [retryAttempt, media_sources, MAX_RETRY_ATTEMPTS, fetchSources])

  useEffect(() => {
    // what I wanted to do was listen for fullscreenchange on the MediaPlayer's div,
    // but it doesn't have it's new size at the time the event is fired. It also
    // doesn't get a resize event when transitioning to/from fullscreen.
    window.addEventListener('resize', handlePlayerSize)
    return () => {
      window.removeEventListener('resize', handlePlayerSize)
    }
  }, [handlePlayerSize])

  const includeFullscreen =
    (document.fullscreenEnabled || document.webkitFullscreenEnabled) && props.type === 'video'

  function renderNoPlayer() {
    if (mediaObjNetworkErr) {
      if (props.is_attachment) {
        return (
          <Alert key="bepatientalert" variant="info" margin="x-small" liveRegion={liveRegion}>
            {I18n.t('Your media has been uploaded and will appear here after processing.')}
          </Alert>
        )
      } else {
        return (
          <Alert key="erralert" variant="error" margin="small" liveRegion={liveRegion}>
            {I18n.t('Failed retrieving media sources.')}
          </Alert>
        )
      }
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
          <Flex.Item margin="0 0 x-small 0" shouldGrow={true} shouldShrink={true}>
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
        <Alert key="loadingalert" variant="info" liveRegion={liveRegion} screenReaderOnly={true}>
          {I18n.t('Loading')}
        </Alert>
        <LoadingIndicator
          translatedTitle={I18n.t('Loading')}
          size={props.type === 'audio' ? 'x-small' : 'large'}
        />
      </>
    )
  }

  function getAriaLabel() {
    if (!props.aria_label) return

    // video
    if (props.type === 'video') {
      return I18n.t('Video player for %{label}', {label: props.aria_label})
    }

    // audio
    if (props.type === 'audio') {
      return I18n.t('Audio player for %{label}', {label: props.aria_label})
    }
  }

  return (
    <div
      style={{height: props.fluidHeight ? '100%' : 'auto'}}
      ref={containerRef}
      data-tracks={JSON.stringify(media_tracks)}
    >
      {media_sources.length ? (
        <MediaPlayer
          fluidHeight={props.fluidHeight}
          ref={mediaPlayerRef}
          sources={media_sources}
          tracks={props.media_tracks}
          hideFullScreen={!includeFullscreen}
          onLoadedMetadata={handleLoadedMetadata}
          captionPosition="bottom"
          autoShowCaption={auto_cc_track}
          label={getAriaLabel()}
        >
          {/*
            Adding this overlay gives us the right click menu
            for the iFrame instead of the right click menu
            for the media (which helps prevent people from
            downloading media)
          */}
          <MediaPlayer.Overlay />
        </MediaPlayer>
      ) : (
        renderNoPlayer()
      )}
    </div>
  )
}

export function setPlayerSize(player, type, boundingBox, playerContainer, resizeContainer = true) {
  const playerIsVisible = player.offsetWidth > 0 && player.offsetHeight > 0
  const {width, height} = sizeMediaPlayer(player, type, boundingBox)
  player.style.width = width
  player.style.height = height
  // player.style.margin = '0 auto' // TODO: remove with player v7
  player.classList.add(isAudio(type) ? 'audio-player' : 'video-player')

  // videos that are wide-and-short portrait need to shrink the parent
  if (
    playerIsVisible &&
    resizeContainer &&
    playerContainer &&
    player.videoWidth > player.videoHeight
  ) {
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

export function formatTracksForMediaPlayer(tracks) {
  return tracks.map(track => ({
    id: track.id,
    src: `/media_objects/${track.media_object_id}/media_tracks/${track.id}`,
    label: track.locale,
    type: track.kind,
    language: track.locale,
  }))
}

CanvasMediaPlayer.propTypes = {
  fluidHeight: bool,
  media_id: string.isRequired,
  media_sources: MediaPlayer.propTypes.sources,
  media_tracks: MediaPlayer.propTypes.tracks,
  resizeContainer: bool,
  type: oneOf(['audio', 'video']),
  MAX_RETRY_ATTEMPTS: number,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS: number,
  aria_label: string,
  is_attachment: bool,
  attachment_id: string,
}

CanvasMediaPlayer.defaultProps = {
  fluidHeight: false,
  media_sources: [],
  resizeContainer: true,
  type: 'video',
  MAX_RETRY_ATTEMPTS: DEFAULT_MAX_RETRY_ATTEMPTS,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS: DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS,
  aria_label: '',
  is_attachment: false,
  attachment_id: '',
}
