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
import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {LoadingIndicator, sizeMediaPlayer} from '@instructure/canvas-media'
import {StudioPlayer} from '@instructure/studio-player'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {asJson, defaultFetchOptions} from '@canvas/util/xhr'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv & {
  locale?: string
  MAX_MEDIA_SOURCE_RETRY_ATTEMPTS?: number
  SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS?: number
}

const I18n = createI18nScope('CanvasMediaPlayer')

const byBitrate = (a: {bitrate: string}, b: {bitrate: string}) =>
  parseInt(a.bitrate, 10) - parseInt(b.bitrate, 10)

const liveRegion = () => window?.top?.document.getElementById('flash_screenreader_holder')

// It can take a while for notorious to process a newly uploaded video
// Each attempt to get the media_sources is 2**n seconds after the previous attempt
// so we'll keep at it for about an hour (2**(MAX_RETRY_ATTEMPTS+1)/60 minutes) as long as there's no network error.
const DEFAULT_MAX_RETRY_ATTEMPTS = 11
const DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = 3

interface CanvasStudioPlayerProps {
  media_id: string
  // TODO: we've asked studio to export definitions for PlayerSrc and CaptionMetaData
  media_sources?: any[]
  media_tracks?: any[]
  type?: 'audio' | 'video'
  MAX_RETRY_ATTEMPTS?: number
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS?: number
  aria_label?: string
  is_attachment?: boolean
  attachment_id?: string
}

// The main difference between CanvasMediaPlayer and CanvasStudioPlayer
// besides the media package we use
// is that here we manage player size in state, instead of directly changing the DOM
export default function CanvasStudioPlayer({
  media_id,
  media_sources = [],
  media_tracks,
  type = 'video',
  MAX_RETRY_ATTEMPTS = DEFAULT_MAX_RETRY_ATTEMPTS,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS,
  aria_label = '',
  is_attachment = false,
  attachment_id = '',
}: CanvasStudioPlayerProps) {
  const sorted_sources = Array.isArray(media_sources)
    ? media_sources.sort(byBitrate)
    : media_sources
  const tracks = Array.isArray(media_tracks)
    ? media_tracks.map(t => ({
        locale: t.language,
        language: t.label,
        inherited: t.inherited,
        label: t.label,
        src: t.src,
      }))
    : undefined
  const [mediaSources, setMediaSources] = useState(sorted_sources)
  const [mediaTracks] = useState(tracks)
  const [retryAttempt, setRetryAttempt] = useState(0)
  const [mediaObjNetworkErr, setMediaObjNetworkErr] = useState(null)
  const [containerWidth, setContainerWidth] = useState(0)
  const [containerHeight, setContainerHeight] = useState(0)
  // the ability to set these makes testing easier
  // hint: set these values in a conditional breakpoint in
  // media_player_iframe_content.js where the CanvasStudioPlayer is rendered
  // for example:
  // ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS=2, ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS=4, 0
  const retryAttempts = ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS || MAX_RETRY_ATTEMPTS
  const showBePatientMsgAfterAttempts =
    ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS || SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS

  const containerRef = useRef<any>(null)

  const boundingBox = useCallback(() => {
    // @ts-expect-error
    const isFullscreen = document.fullscreenElement || document.webkitFullscreenElement
    const isEmbedded =
      window.frameElement?.tagName === 'IFRAME' ||
      window.location !== window?.top?.location ||
      !containerRef.current
    if (isFullscreen || isEmbedded) {
      return {
        width: window.innerWidth,
        height: window.innerHeight,
      }
    }

    // media_player_iframe_content.js includes a 16px top/bottom margin
    return {
      width: containerRef?.current?.clientWidth,
      height: Math.min(containerRef.current.clientHeight, window.innerHeight - 32),
    }
  }, [containerRef])

  const handlePlayerSize = useCallback(
    (_event: any) => {
      const player = window.document.body.querySelector('video')
      const {width, height} = sizeMediaPlayer(player, type, boundingBox())
      setContainerHeight(height)
      setContainerWidth(width)
    },
    [type, boundingBox]
  )

  const fetchSources = useCallback(
    async function () {
      const url = attachment_id
        ? `/media_attachments/${attachment_id}/info`
        : `/media_objects/${media_id}/info`
      let resp
      try {
        setMediaObjNetworkErr(null)
        resp = await asJson(fetch(url, defaultFetchOptions()))
      } catch (e: any) {
         
        console.warn(`Error getting ${url}`, e.message)
        setMediaObjNetworkErr(e)
        return
      }
      if (resp?.media_sources?.length) {
        setMediaSources(resp.media_sources.sort(byBitrate))
      } else {
        setRetryAttempt(retryAttempt + 1)
      }
    },
    [attachment_id, media_id, retryAttempt]
  )

  useEffect(() => {
    // if we just uploaded the media, notorious may still be processing it
    // and we don't have its media_sources yet
    let retryTimerId = 0
    if (!mediaSources.length && retryAttempt <= retryAttempts) {
      retryTimerId = window.setTimeout(() => {
        fetchSources()
      }, 2 ** retryAttempt * 1000)
    }

    return () => {
      clearTimeout(retryTimerId)
    }
  }, [retryAttempt, mediaSources, retryAttempts, fetchSources])

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
    // @ts-expect-error
    (document.fullscreenEnabled || document.webkitFullscreenEnabled) && type === 'video'

  function renderNoPlayer() {
    if (mediaObjNetworkErr) {
      if (is_attachment) {
        return (
          // @ts-expect-error
          <Alert key="bepatientalert" variant="info" margin="x-small" liveRegion={liveRegion}>
            {I18n.t('Your media has been uploaded and will appear here after processing.')}
          </Alert>
        )
      } else {
        return (
          // @ts-expect-error
          <Alert key="erralert" variant="error" margin="small" liveRegion={liveRegion}>
            {I18n.t('Failed retrieving media sources.')}
          </Alert>
        )
      }
    }
    if (retryAttempt >= retryAttempts) {
      // this should be very rare
      return (
        // @ts-expect-error
        <Alert key="giveupalert" variant="info" margin="x-small" liveRegion={liveRegion}>
          {I18n.t(
            'Giving up on retrieving media sources. This issue will probably resolve itself eventually.'
          )}
        </Alert>
      )
    }
    if (retryAttempt >= showBePatientMsgAfterAttempts) {
      return (
        <Flex margin="xx-small" justifyItems="space-between">
          <Flex.Item margin="0 0 x-small 0" shouldGrow={true} shouldShrink={true}>
            {/* @ts-expect-error */}
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
        {/* @ts-expect-error */}
        <Alert key="loadingalert" variant="info" liveRegion={liveRegion} screenReaderOnly={true}>
          {I18n.t('Loading')}
        </Alert>
        <LoadingIndicator
          translatedTitle={I18n.t('Loading')}
          size={type === 'audio' ? 'x-small' : 'large'}
        />
      </>
    )
  }

  function getAriaLabel() {
    if (!aria_label) return

    // video
    if (type === 'video') {
      return I18n.t('Video player for %{label}', {label: aria_label})
    }

    // audio
    if (type === 'audio') {
      return I18n.t('Audio player for %{label}', {label: aria_label})
    }
  }

  useEffect(() => {
    if (mediaSources.length) {
      const player = {
        videoHeight: mediaSources[0].height,
        videoWidth: mediaSources[0].width,
      }
      const {width, height} = sizeMediaPlayer(player, type, boundingBox())
      setContainerWidth(width)
      setContainerHeight(height)
    }
  }, [mediaSources, type, boundingBox])

  return (
    <div
      style={{height: containerHeight, width: containerWidth}}
      ref={containerRef}
      data-tracks={JSON.stringify(mediaTracks)}
    >
      {mediaSources.length ? (
        <StudioPlayer
          src={mediaSources}
          captions={mediaTracks}
          hideFullScreen={!includeFullscreen}
          title={getAriaLabel()}
        />
      ) : (
        renderNoPlayer()
      )}
    </div>
  )
}

export function formatTracksForMediaPlayer(tracks: any[]) {
  return tracks.map((track: {id: any; media_object_id: any; locale: any; kind: any}) => ({
    id: track.id,
    src: `/media_objects/${track.media_object_id}/media_tracks/${track.id}`,
    label: track.locale,
    type: track.kind,
    language: track.locale,
  }))
}
