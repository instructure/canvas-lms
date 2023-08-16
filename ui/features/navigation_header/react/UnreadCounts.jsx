/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

//
// This component manages "unread count" badges on things external to the
// Navigation component. All it needs is:
//       targetEl: a DOM node to render the count into
//       dataUrl: the API endpoint to call to retrieve the unread count.
//                Its return object is expected to contain an `unread_count`
//                field with the numeric unread count
//
// ... and optionally:
//       srText: a function to return the text to be spoken by a screen
//               reader. It passes the unread count as argument.
//       onUpdate: a function to call when the count is updated.
//                 It passes the new unread count as argument.
//       onError: a function to call if the API call fails.
//                It passes the fetch error as argument. Defaults to just
//                issuing a console warning.
//       pollIntervalMs: how often to poll the API for an updated unread
//                       count. Defaults to 60000ms or one minute.  Use 0 to disable.
//       allowedAge: how old the saved unread count can be without hitting
//                   the API for a new value. Defaults to 1/2 the poll interval.
//       maxTries: how many API failures can occur in a row before we just give
//                 up entirely and stop updating. Defaults to 5.
//       pollNowPassback:  an optional function which, if provided, will be called
//                         once upon the first render. The function is expected to
//                         accept an argument which is itself a function, and can be
//                         called by the parent to force an update to the Unread badge.
//                         If that function is called with a numeric argument, the
//                         unread count is simply set to that; if it is not provided or
//                         undefined, it triggers an immediate poll of the dataUrl to
//                         (upon completion of the API call) update the badge with an
//                         updated value. Defaults to no action.
//       useSessionStorage: whether to use local browser session storage for
//       bool,default true  storing / retrieving unread counts before polling
//                          the Canvas API.

import React, {useRef, useState, useEffect, useCallback} from 'react'
import {createPortal} from 'react-dom'
import {any, bool, func, number, string} from 'prop-types'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('UnreadCounts')

const DEFAULT_POLL_INTERVAL = 120000

function storageKeyFor(url) {
  const m = url.match(/\/api\/v1\/(.*)\/unread_count/)
  const tag = (m ? m[1] : 'UNKNOWN').replace(/\//g, '_')
  return `unread_count_${window.ENV.current_user_id}_${tag}`
}

UnreadCounts.propTypes = {
  targetEl: any,
  onUpdate: func,
  onError: func,
  srText: func,
  dataUrl: string.isRequired,
  pollIntervalMs: number,
  allowedAge: number,
  maxTries: number,
  useSessionStorage: bool,
  pollNowPassback: func,
}

UnreadCounts.defaultProps = {
  onUpdate: Function.prototype,
  onError: msg => {
    // eslint-disable-next-line no-console
    console.warn(`Error fetching unread count: ${msg}`)
  },
  srText: count => I18n.t('%{count} unread.', {count}),
  pollIntervalMs: DEFAULT_POLL_INTERVAL,
  allowedAge: DEFAULT_POLL_INTERVAL / 2,
  maxTries: 5,
  useSessionStorage: true,
}

export default function UnreadCounts(props) {
  const {
    targetEl,
    onUpdate,
    onError,
    srText,
    dataUrl,
    pollIntervalMs,
    allowedAge,
    maxTries,
    useSessionStorage,
    pollNowPassback,
  } = props
  const syncState = useRef({msUntilFirstPoll: 0, savedChecked: false})
  const [count, setCount] = useState(NaN) // want to be sure to update at least once
  let error = null

  // Can we do anything at all?“
  function ableToRun() {
    if (!targetEl) return false
    if (!window.ENV.current_user_id) return false
    if (window.ENV.current_user && window.ENV.current_user.fake_student) return false
    return true
  }

  function updateParent(n) {
    if (typeof onUpdate === 'function') onUpdate(n)
  }

  // set the unread count state on a change, and also update the saved session
  // storage if we are using it
  function setUnreadCount(unreadCount) {
    setCount(unreadCount)
    updateParent(unreadCount)
    if (!useSessionStorage) return
    try {
      const savedState = JSON.stringify({
        updatedAt: +new Date(),
        unreadCount,
      })
      sessionStorage.setItem(storageKeyFor(dataUrl), savedState)
    } catch (_ex) {
      // error in setting storage, no biggie, ignore
    }
  }

  function startPolling() {
    let timerId = null
    let attempts = 0

    function cleanup() {
      if (timerId) clearTimeout(timerId)
    }

    async function getData() {
      try {
        const result = await fetch(dataUrl, defaultFetchOptions)
        const {unread_count: cnt} = await result.json()
        const unreadCount = typeof cnt === 'number' ? cnt : parseInt(cnt, 10)
        setUnreadCount(unreadCount)
        attempts = 0
        error = null
      } catch (e) {
        error = e
      }
    }

    async function poll(force) {
      // if we get here when the page is hidden, don't actually fetch it now, wait until the page is refocused
      if (document.hidden && !force) {
        document.addEventListener('visibilitychange', poll, {once: true})
        return
      }

      await getData()
      attempts += 1
      if (attempts < maxTries && pollIntervalMs > 0)
        timerId = setTimeout(poll, attempts * pollIntervalMs)
      if (error) onError(`URL=${dataUrl} error text=${error.message}`)
    }

    if (ableToRun()) {
      // Arrange to tell our parent how to force us to update, if they want
      if (pollNowPassback)
        pollNowPassback(function (overrideCount) {
          if (typeof overrideCount === 'undefined') {
            cleanup()
            poll(true)
          } else if (typeof overrideCount === 'number') {
            setUnreadCount(overrideCount)
          } else {
            throw new TypeError('Argument to the poll now callback, if present, must be numeric')
          }
        })
      const delay = syncState.current.msUntilFirstPoll
      // If polling is disabled, it's also fine to just use the cached value
      if (delay > 0) {
        if (pollIntervalMs > 0) {
          timerId = setTimeout(poll, delay)
        }
      } else {
        poll()
      }
    }

    return cleanup
  }

  const checkSavedValue = useCallback(() => {
    // Get some data from saved history and use it if we can before we start
    // polling the API. If we do use it, arrange to poll the API only when
    // the saved value ages out.
    const savedJson = sessionStorage.getItem(storageKeyFor(dataUrl))
    if (savedJson && ableToRun()) {
      const saved = JSON.parse(savedJson)
      const msSinceLastUpdate = new Date() - saved.updatedAt
      if (msSinceLastUpdate < allowedAge) {
        if (count !== saved.unreadCount) {
          setUnreadCount(saved.unreadCount)
          updateParent(saved.unreadCount)
          syncState.current.msUntilFirstPoll = allowedAge - msSinceLastUpdate
        }
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [allowedAge, count, dataUrl])

  useEffect(() => {
    // If we haven't started polling yet, see if we can use a saved value
    if (useSessionStorage && !syncState.current.savedChecked) {
      checkSavedValue()
      syncState.current.savedChecked = true
    }
  }, [useSessionStorage, checkSavedValue])

  // deps is the empty array because we want to fire off the polling exactly once
  useEffect(startPolling, [])

  if (!count) return createPortal(null, targetEl)

  return createPortal(
    <>
      <ScreenReaderContent>{srText(count)}</ScreenReaderContent>
      <PresentationContent>{count}</PresentationContent>
    </>,
    targetEl
  )
}
