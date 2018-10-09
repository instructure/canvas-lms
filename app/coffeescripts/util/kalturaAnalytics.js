//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import _ from 'underscore'
import 'jquery.cookie'

// A class to setup kaltura analytics listeners on a mediaElement player
// for a specific video being played
// As events are created they are sent to kaltura's analytics api
class KalturaAnalytics {
  constructor(mediaId, mediaElement, pluginSettings) {
    this.queueAnalyticEvent = this.queueAnalyticEvent.bind(this)
    this.ensureAnalyticSession = this.ensureAnalyticSession.bind(this)
    this.generateApiUrl = this.generateApiUrl.bind(this)
    this.setupApiIframes = this.setupApiIframes.bind(this)
    this.queueApiCall = this.queueApiCall.bind(this)
    this.addListeners = this.addListeners.bind(this)
    this.mediaId = mediaId
    this.mediaElement = mediaElement
    this.pluginSettings = pluginSettings
    this.ensureAnalyticSession()
    this.generateApiUrl()

    this.defaultData = {
      service: 'stats',
      action: 'collect',
      'event:entryId': this.mediaId,
      'event:sessionId': this.kaSession,
      'event:isFirstInSession': 'false',
      'event:objectType': 'KalturaStatsEvent',
      'event:partnerId': this.pluginSettings.partner_id,
      'event:uiconfId': this.pluginSettings.kcw_ui_conf,
      'event:queryStringReferrer': window.location.href
    }
  }

  // Builds the url to send the analytic event and adds it to the processing queue
  queueAnalyticEvent(eventId) {
    const data = _.clone(this.defaultData)
    data['event:eventType'] = eventId
    data['event:duration'] = this.mediaElement.duration
    data['event:currentPoint'] = parseInt(this.mediaElement.currentTime * 1000)
    data['event:eventTimestamp'] = new Date().getTime()

    return this.queueApiCall(this.apiUrl + $.param(data))
  }

  // kaltura expects a persistent analytic session token for the user
  // this generates a simple session id for analytic purposes
  // no session/authentication is associated with this token
  ensureAnalyticSession() {
    this.kaSession = $.cookie('kaltura_analytic_tracker', undefined, {path: '/'})
    if (!this.kaSession) {
      this.kaSession = (
        Math.random().toString(16) +
        Math.random().toString(16) +
        Math.random().toString(16)
      ).replace(/\./g, '')
      return $.cookie('kaltura_analytic_tracker', this.kaSession, {path: '/'})
    }
  }

  // pulls the kaltura domain from the plugin settins and sets up the base
  // url for sending analytics events
  generateApiUrl() {
    let domain
    if (window.location.protocol === 'http:') {
      domain = `http://${this.pluginSettings.domain}`
    } else {
      domain = `https://${this.pluginSettings.domain}`
    }

    return (this.apiUrl = `${domain}/api_v3/index.php?`)
  }

  // Since the analytic call is a cross-domain call, set the url in an iFrame
  setupApiIframes(count) {
    this.qIndex = 0
    this.iframes = []
    for (let i = 0, end = count - 1, asc = end >= 0; asc ? i <= end : i >= end; asc ? i++ : i--) {
      const iframe = document.createElement('iframe')
      $(iframe).addClass('hidden kaltura-analytics')
      $(document.body).append($(iframe))

      // there is no reliable way to know when a remote url has loaded in an
      // iframe, so just send them every 4 seconds
      const queue = []
      const f = ((iframe, queue) =>
        function() {
          let url
          if ((url = queue.shift())) {
            return (iframe.src = url)
          }
        })(iframe, queue)
      this.iframes[i] = {iframe, queue, pinger: _.throttle(f, 4000)}
    }
    return this.iframes
  }

  queueApiCall(url) {
    if (!this.iframes) {
      this.setupApiIframes(this.pluginSettings.parallel_api_calls || 3)
    }
    this.iframes[this.qIndex].queue.push(url)
    this.iframes[this.qIndex].pinger()
    this.qIndex = (this.qIndex + 1) % this.iframes.length
    return this.qIndex
  }

  // Adds event listenrs to the mediaElement player
  //
  // Tracks events for widget loaded, play, replay, media loaded, seek, buffer
  // open full screen, close full screen, and play progress
  addListeners() {
    this.queueAnalyticEvent(1) // widget loaded

    this.mediaElement.addEventListener('play', () => {
      this.mediaElement.pauseObserved = false
      this.mediaElement.endedObserved = false
      if (this.mediaElement.endedOnce) {
        this.queueAnalyticEvent(mediaId, 16) // Replay
        this.mediaElement.endedOnce = false
      }
      return this.queueAnalyticEvent(3)
    }) // Play

    this.mediaElement.addEventListener('canplay', () => this.queueAnalyticEvent(2)) // media loaded

    this.mediaElement.addEventListener('seeked', () => {
      if (this.mediaElement.endedObserved) return
      return this.queueAnalyticEvent(17)
    }) // 'seek'

    this.mediaElement.addEventListener('pause', () => {
      if (this.mediaElement.pauseObserved) return
      return (this.mediaElement.pauseObserved = true)
    })

    // first time loaded
    this.mediaElement.addEventListener('progress', () => {
      if (!this.mediaElement.endedOnce) {
        return this.queueAnalyticEvent(12)
      }
    }) // 'progress / buffering'

    let _lastTime = 0
    let _isFullScreen = false
    return this.mediaElement.addEventListener(
      'playing',
      e => {
        if (this.mediaElement.listeningToPlaying) return

        const interval = setInterval(() => {
          if (
            this.mediaElement.paused ||
            isNaN(this.mediaElement.duration) ||
            !this.mediaElement.duration
          )
            return

          if (this.mediaElement.isFullScreen !== _isFullScreen) {
            if (!_isFullScreen) {
              this.queueAnalyticEvent(14) // open full screen
            } else {
              this.queueAnalyticEvent(15) // close full screen
            }
            _isFullScreen = this.mediaElement.isFullScreen
          }

          const stopPoints = [
            0.25 * this.mediaElement.duration,
            0.5 * this.mediaElement.duration,
            0.75 * this.mediaElement.duration,
            0.98 * this.mediaElement.duration // :)
          ]
          const {currentTime} = this.mediaElement
          if (!isNaN(currentTime) && currentTime > 0) {
            let j = stopPoints.length - 1

            while (j >= 0) {
              const cueTime = stopPoints[j]
              if (cueTime > _lastTime && cueTime <= currentTime) {
                if (j === 0) {
                  this.queueAnalyticEvent(4) // play reached 25
                } else if (j === 1) {
                  this.queueAnalyticEvent(5) // play reached 50
                } else if (j === 2) {
                  this.queueAnalyticEvent(6) // play reached 75
                } else if (j === 3) {
                  this.queueAnalyticEvent(7) // play reached "100"
                }
              }
              --j
            }
            return (_lastTime = currentTime)
          }
        }, 50)
        return (this.mediaElement.listeningToPlaying = true)
      },
      false
    )
  }
}

export default function(mediaId, mediaElement, pluginSettings) {
  if (pluginSettings && pluginSettings.do_analytics) {
    const ka = new KalturaAnalytics(mediaId, mediaElement, pluginSettings)
    ka.addListeners()
    return ka
  }
}
