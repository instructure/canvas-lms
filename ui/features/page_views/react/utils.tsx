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

import React from 'react'
import {useScope as i18nScope} from '@canvas/i18n'
import {Link} from '@instructure/ui-link'
import {IconCheckDarkSolid} from '@instructure/ui-icons'
import * as TextHelper from '@canvas/util/TextHelper'

type HourParts = {
  hours: number
  minutes: number
  seconds: number
}

// as returned from API call
export type APIPageView = {
  id: string
  app_name: string | null
  http_method: string | null
  url: string
  created_at: string
  participated: boolean | null
  interaction_seconds: number
  user_agent: string
}

// as displayed in the table
export type PageView = {
  id: string
  url: JSX.Element | string
  createdAt: Date
  participated: JSX.Element | null
  interactionSeconds: string
  rawUserAgentString: string
  userAgent: string
}

const I18n = i18nScope('page_views')

function parseUserAgentString(userAgent: string): string {
  userAgent = (userAgent || '').toLowerCase()
  const data = {
    version: (userAgent.match(/.+(?:me|ox|it|ra|er|rv|dg|version)[/: ]([\d.]+)/) || [0, null])[1],
    edge: /edg[^e]/.test(userAgent),
    chrome: /chrome/.test(userAgent) && !/edg[^e]/.test(userAgent),
    safari: /webkit/.test(userAgent),
    opera: /opera/.test(userAgent),
    firefox: /firefox/.test(userAgent),
    mozilla: /mozilla/.test(userAgent) && !/(compatible|webkit)/.test(userAgent),
    speedgrader: /speedgrader/.test(userAgent),
  }
  let browser: string = ''
  if (data.edge) {
    browser = 'Edge'
  } else if (data.chrome) {
    browser = 'Chrome'
  } else if (data.safari) {
    browser = 'Safari'
  } else if (data.opera) {
    browser = 'Opera'
  } else if (data.firefox) {
    browser = 'Firefox'
  } else if (data.mozilla) {
    browser = 'Mozilla'
  } else if (data.speedgrader) {
    browser = 'SpeedGrader for iPad'
  }
  if (!browser) {
    browser = I18n.t('Unrecognized Browser')
  } else if (data.version) {
    data.version = data.version.split(/\./).slice(0, 2).join('.')
    browser = `${browser} ${data.version}`
  }
  return browser
}

export function formatURL(view: APIPageView): JSX.Element | string {
  const name = TextHelper.truncateText(view.url, {max: 90})
  const isLinkable = view.http_method === null || view.http_method === 'get'
  if (isLinkable) return <Link href={view.url}>{name}</Link>
  return name
}

export function formatUserAgent(view: APIPageView): string {
  if (view.app_name) return view.app_name
  return parseUserAgentString(view.user_agent)
}

function hourParts(secs: number): HourParts {
  const hours = Math.floor(secs / 3600)
  const minutes = Math.floor((secs % 3600) / 60)
  const seconds = Math.round(secs % 60) // Intl.DurationFormat needs integer values

  return {hours, minutes, seconds}
}

export function formatParticipated({participated}: APIPageView): JSX.Element | null {
  return participated ? <IconCheckDarkSolid color="success" /> : null
}

// TS doesn't know about Intl.DurationFormat yet hence the expect-error notations below
export function formatInteractionTime({interaction_seconds: time}: APIPageView): string {
  if (time <= 5) return '—'
  const timeArr = hourParts(time)
  // Not all our supported browsers implement Intl.DurationFormat yet
  // @ts-expect-error
  if (typeof Intl.DurationFormat === 'undefined') {
    const pad = (n: number) => String(n).padStart(2, '0')

    if (timeArr.hours > 0) return `${timeArr.hours}:${pad(timeArr.minutes)}:${pad(timeArr.seconds)}`
    if (timeArr.minutes > 0) return `${timeArr.minutes}:${pad(timeArr.seconds)}`
    return String(timeArr.seconds)
  }
  const locales = ENV.LOCALES || navigator.languages || ['en-US']
  // @ts-expect-error
  const duration = new Intl.DurationFormat(locales, {style: 'narrow'})
  return duration.format(timeArr)
}
