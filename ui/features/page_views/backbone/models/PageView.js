/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import Backbone from '@canvas/backbone'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as TextHelper from '@canvas/util/TextHelper'

const I18n = useI18nScope('modelsPageView')

function parseUserAgentString(userAgent) {
  userAgent = (userAgent || '').toLowerCase()
  const data = {
    version: (userAgent.match(/.+(?:me|ox|it|ra|er|rv|dg|version)[\/: ]([\d.]+)/) || [0, null])[1],
    edge: /edg[^e]/.test(userAgent),
    chrome: /chrome/.test(userAgent) && !/edg[^e]/.test(userAgent),
    safari: /webkit/.test(userAgent),
    opera: /opera/.test(userAgent),
    firefox: /firefox/.test(userAgent),
    mozilla: /mozilla/.test(userAgent) && !/(compatible|webkit)/.test(userAgent),
    speedgrader: /speedgrader/.test(userAgent),
  }
  let browser = null
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
    browser = I18n.t('browsers.unrecognized', 'Unrecognized Browser')
  } else if (data.version) {
    data.version = data.version.split(/\./).slice(0, 2).join('.')
    browser = `${browser} ${data.version}`
  }
  return browser
}

export default class PageView extends Backbone.Model {
  isLinkable() {
    const method = this.get('http_method')
    if (method == null) return true
    return method === 'get'
  }

  summarizedUserAgent() {
    return this.get('app_name') || parseUserAgentString(this.get('user_agent'))
  }

  readableInteractionTime() {
    const seconds = this.get('interaction_seconds')
    if (seconds > 5) {
      return Math.round(seconds)
    } else {
      return '--'
    }
  }

  truncatedURL() {
    return TextHelper.truncateText(this.get('url'), {max: 90})
  }
}

PageView.prototype.computedAttributes = [
  'summarizedUserAgent',
  'readableInteractionTime',
  'truncatedURL',
  'isLinkable',
]
