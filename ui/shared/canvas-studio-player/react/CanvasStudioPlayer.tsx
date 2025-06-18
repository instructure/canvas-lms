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
import React, {CSSProperties, useCallback, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  captionLanguageForLocale,
  LoadingIndicator,
  sizeMediaPlayer,
} from '@instructure/canvas-media'
import {CaptionMetaData, StudioPlayer} from '@instructure/studio-player'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import getCookie from '@instructure/get-cookie'
import {asJson, defaultFetchOptions} from '@canvas/util/xhr'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {type MediaSource} from 'api'
import {type MediaInfo, MediaTrack} from './types'

declare const ENV: GlobalEnv & {
  locale?: string
  MAX_MEDIA_SOURCE_RETRY_ATTEMPTS?: number
  SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS?: number
}

const I18n = createI18nScope('CanvasMediaPlayer')

const byBitrate = (a: {bitrate: number}, b: {bitrate: number}) => a.bitrate - b.bitrate

const liveRegion = () => window?.top?.document.getElementById('flash_screenreader_holder')

type CanvasMediaSource = MediaSource & {
  bitrate: string
}

const convertMediaSource = (source: CanvasMediaSource) => {
  return {
    src: source.url,
    type: source.content_type as any,
    width: parseInt(source.width) ?? undefined,
    height: parseInt(source.height) ?? undefined,
    bitrate: parseInt(source.bitrate) ?? undefined,
  }
}

const convertAndSortMediaSources = (sources: CanvasMediaSource[] | string) => {
  if (!Array.isArray(sources)) {
    return sources
  }
  return sources.map(convertMediaSource).sort(byBitrate)
}

const convertMediaTracksIfNeeded = (
  tracks: MediaTrack[] | CaptionMetaData[],
): CaptionMetaData[] => {
  return tracks.map(track => {
    if ('src' in track) return track
    return {
      locale: track.locale,
      language: captionLanguageForLocale(track.locale),
      inherited: track.inherited,
      label: captionLanguageForLocale(track.locale),
      src: track.url,
      type: 'srt',
    }
  })
}

// It can take a while for notorious to process a newly uploaded video
// Each attempt to get the media_sources is 2**n seconds after the previous attempt
// so we'll keep at it for about an hour (2**(MAX_RETRY_ATTEMPTS+1)/60 minutes) as long as there's no network error.
const DEFAULT_MAX_RETRY_ATTEMPTS = 11
const DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = 3

interface BaseCanvasStudioPlayerProps {
  // TODO: we've asked studio to export definitions for PlayerSrc
  media_sources?: string | any[]
  media_tracks?: MediaTrack[] | CaptionMetaData[]
  type?: 'audio' | 'video'
  MAX_RETRY_ATTEMPTS?: number
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS?: number
  aria_label?: string
  is_attachment?: boolean
  show_loader?: boolean
  maxHeight?: null | string
  mediaFetchCallback?: (mediaInfo: MediaInfo) => void
  explicitSize?: {width: number | string; height: number | string}
  hideUploadCaptions?: boolean
  isInverseVariant?: boolean
}

type CanvasStudioPropsWithMediaIdOrAttachmentId =
  | (BaseCanvasStudioPlayerProps & {media_id: string; attachment_id?: undefined})
  | (BaseCanvasStudioPlayerProps & {media_id?: undefined; attachment_id: string})
  | (BaseCanvasStudioPlayerProps & {media_id: string; attachment_id: string})

// The main difference between CanvasMediaPlayer and CanvasStudioPlayer
// besides the media package we use
// is that here we manage player size in state, instead of directly changing the DOM
export default function CanvasStudioPlayer({
  media_id,
  media_sources = [],
  media_tracks: media_captions,
  type = 'video',
  MAX_RETRY_ATTEMPTS = DEFAULT_MAX_RETRY_ATTEMPTS,
  SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS = DEFAULT_SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS,
  aria_label = '',
  is_attachment = false,
  attachment_id = '',
  show_loader = false,
  explicitSize,
  hideUploadCaptions = false,
  isInverseVariant = false,
}: CanvasStudioPropsWithMediaIdOrAttachmentId) {
  const [mediaId, setMediaId] = useState(media_id)
  const captions: CaptionMetaData[] | undefined = Array.isArray(media_captions)
    ? convertMediaTracksIfNeeded(media_captions)
    : undefined
  const [mediaSources, setMediaSources] = useState(() => convertAndSortMediaSources(media_sources))
  const [mediaCaptions, setMediaCaptions] = useState<CaptionMetaData[] | undefined>(captions)
  const [retryAttempt, setRetryAttempt] = useState(0)
  const [mediaObjNetworkErr, setMediaObjNetworkErr] = useState(null)
  const [containerWidth, setContainerWidth] = useState(explicitSize?.width || 0)
  const [containerHeight, setContainerHeight] = useState(explicitSize?.height || 0)
  const [isLoading, setIsLoading] = useState(true)
  const [canAddCaptions, setCanAddCaptions] = useState(false)
  // the ability to set these makes testing easier
  // hint: set these values in a conditional breakpoint in
  // media_player_iframe_content.js where the CanvasStudioPlayer is rendered
  // for example:
  // ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS=2, ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS=4, 0
  const retryAttempts = ENV.MAX_MEDIA_SOURCE_RETRY_ATTEMPTS || MAX_RETRY_ATTEMPTS
  const showBePatientMsgAfterAttempts =
    ENV.SHOW_MEDIA_SOURCE_BE_PATIENT_MSG_AFTER_ATTEMPTS || SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS
  const containerRef = useRef<any>(null)

  function isEmbedded(): boolean {
    return (
      window.frameElement?.tagName === 'IFRAME' ||
      window.location !== window?.top?.location ||
      !containerRef.current
    )
  }

  const boundingBox = useCallback(() => {
    const isFullscreen = document.fullscreenElement || document.webkitFullscreenElement
    if (isFullscreen || isEmbedded()) {
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
      if (explicitSize) {
        return
      }

      const updateContainerSize = (width: number, height: number) => {
        setContainerWidth(width)
        setContainerHeight(height)
      }

      const boundingBoxDimensions = boundingBox()

      if (isEmbedded()) {
        updateContainerSize(boundingBoxDimensions.width, boundingBoxDimensions.height)
      } else if (Array.isArray(mediaSources)) {
        const player = {
          videoHeight: mediaSources[0]?.height || 0,
          videoWidth: mediaSources[0]?.width || 0,
        }
        const {width, height} = sizeMediaPlayer(player, type, boundingBoxDimensions)
        updateContainerSize(width, height)
      }
    },
    [type, boundingBox, mediaSources, explicitSize],
  )

  const fetchSources = useCallback(
    async function () {
      const url = attachment_id
        ? `/media_attachments/${attachment_id}/info`
        : `/media_objects/${mediaId}/info`
      let resp
      try {
        setIsLoading(true)
        setMediaObjNetworkErr(null)
        resp = await asJson(fetch(url, defaultFetchOptions()))
      } catch (e: any) {
        console.warn(`Error getting ${url}`, e.message)
        setMediaObjNetworkErr(e)
        setIsLoading(false)
        return
      }
      if (resp?.media_id && !mediaId) {
        setMediaId(resp.media_id)
      }
      if (typeof resp?.can_add_captions === 'boolean') {
        setCanAddCaptions(resp.can_add_captions)
      }
      if (resp?.media_sources?.length) {
        setMediaSources(convertAndSortMediaSources(resp.media_sources))
        if (!media_captions) {
          setMediaCaptions(convertMediaTracksIfNeeded(resp.media_tracks))
        }
        setIsLoading(false)
      } else {
        setRetryAttempt(retryAttempt + 1)
      }
    },
    [attachment_id, mediaId, retryAttempt, media_captions],
  )

  const deleteCaption = useCallback(async (caption: CaptionMetaData) => {
    const confirmed = confirm(I18n.t('Are you sure you want to delete this track?'))
    if (!confirmed) {
      return
    }

    await fetch(caption.src, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': getCookie('_csrf_token'),
      },
    })
    setMediaCaptions(prev => prev?.filter(c => c.src !== caption.src))
  }, [])

  useEffect(() => {
    // if we just uploaded the media, notorious may still be processing it
    // and we don't have its media_sources yet
    let retryTimerId = 0
    if (!mediaSources.length && retryAttempt <= retryAttempts) {
      retryTimerId = window.setTimeout(
        () => {
          fetchSources()
        },
        2 ** retryAttempt * 1000,
      )
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
            'Giving up on retrieving media sources. This issue will probably resolve itself eventually.',
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
        <Alert
          key="loadingalert"
          variant="info"
          liveRegion={() => liveRegion() as Element}
          screenReaderOnly={!!liveRegion()}
        >
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
    handlePlayerSize({})
  }, [mediaSources, type, boundingBox, handlePlayerSize])

  function renderLoader() {
    if (retryAttempt >= showBePatientMsgAfterAttempts) {
      setIsLoading(false)
      return
    }
    return <Spinner renderTitle={I18n.t('Loading media')} size="small" margin="small" />
  }

  const containerStyle: Partial<CSSProperties> = {
    height: containerHeight,
    width: containerWidth,
    // in a modal of variant "inverse" some menu labels get white text
    // which makes them invisible
    color: isInverseVariant ? '#000000' : undefined,
  }

  const hideCaptionButtons = hideUploadCaptions || !canAddCaptions

  return (
    <>
      {isLoading && show_loader ? (
        renderLoader()
      ) : (
        <div
          data-testid={'canvas-studio-player'}
          style={containerStyle}
          ref={containerRef}
          data-captions={JSON.stringify(mediaCaptions)}
        >
          {mediaSources.length ? (
            <StudioPlayer
              src={mediaSources}
              captions={mediaCaptions}
              hideFullScreen={!includeFullscreen}
              title={getAriaLabel()}
              onCaptionsDelete={hideCaptionButtons ? undefined : deleteCaption}
              kebabMenuElements={
                hideCaptionButtons
                  ? undefined
                  : [
                      {
                        id: 'upload-cc',
                        text: I18n.t('Upload Captions'),
                        icon: 'transcript',
                        onClick: () => {
                          const src = Array.isArray(mediaSources)
                            ? mediaSources[0].src
                            : mediaSources
                          import('../../mediaelement/UploadMediaTrackForm').then(
                            ({default: UploadMediaTrackForm}) => {
                              new UploadMediaTrackForm(
                                mediaId,
                                src,
                                attachment_id as any,
                                false,
                                99000,
                              )
                            },
                          )
                        },
                      },
                    ]
              }
            />
          ) : (
            renderNoPlayer()
          )}
        </div>
      )}
    </>
  )
}
