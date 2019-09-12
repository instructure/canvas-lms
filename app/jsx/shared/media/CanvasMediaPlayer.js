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
import {string} from 'prop-types'
import LoadingIndicator from '../../assignments_2/shared/LoadingIndicator'
import React, {useEffect, useRef, useState} from 'react'
import {VideoPlayer} from '@instructure/ui-media-player'
import {asJson, defaultFetchOptions} from '@instructure/js-utils'

export default function CanvasMediaPlayer(props) {
  const [media_sources, setMedia_sources] = useState(props.media_sources)
  const [retryTimerId, setRetryTimerId] = useState(0)
  const containerRef = useRef(null)
  const videoPlayerRef = useRef(null)
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
  }, [retryTimerId])

  useEffect(() => {
    if(videoPlayerRef.current) {
      const player = containerRef.current.querySelector('video')
      if(player) {
        if (player.loadedmetadata || player.readyState >= 1) {
          sizeVideoPlayer(player)
        } else {
          player.addEventListener('loadedmetadata', () => sizeVideoPlayer(player))
        }
      }
    }
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

  function sizeVideoPlayer(player) {
    const videoPlayerContainer = myIframeRef.current
    if(videoPlayerContainer) {
      const width = player.videoWidth
      const height = player.videoHeight
      // key off width, because we know it's initially layed out landscape
      // just wide enough for the controls to fit
      const minSideLength = videoPlayerContainer.clientWidth
      const w = Math.min(width, minSideLength)
      videoPlayerContainer.style.width = `${w}px`
      videoPlayerContainer.style.height = `${Math.round(w/width * height)}px`
    }
  }

  return (
    <div ref={containerRef}>
      {media_sources.length ?
        <VideoPlayer
          sources={media_sources}
          ref={videoPlayerRef}
          controls={(VPC) => {
            return (
              <VPC>
                <VPC.PlayPauseButton />
                <VPC.Timebar />
                <VPC.Volume />
                <VPC.PlaybackSpeed />
                <VPC.TrackChooser />
                <VPC.SourceChooser />
                {document.fullscreenEnabled && <VPC.FullScreenButton />}
              </VPC>
            )
          }}
        /> :
        <LoadingIndicator />}
    </div>
  )
}

CanvasMediaPlayer.propTypes = {
  media_id: string.isRequired,
  media_sources: VideoPlayer.propTypes.sources
}

CanvasMediaPlayer.defaultProps = {
  media_sources: []
}