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
import {ltiState} from '../messages'

const parseData = data => {
  const defaults = {
    display: 'borderless',
    launchType: 'same_window',
    launchOptions: {},
  }
  if (typeof data === 'string') {
    return {
      url: data,
      ...defaults,
    }
  } else if (typeof data === 'object' && !(data instanceof Array)) {
    if (!data.url) {
      throw new Error('message must contain a `url` property')
    }
    return {
      ...defaults,
      ...data,
    }
  } else {
    throw new Error('message contents must either be a string or an object')
  }
}

const buildLaunchUrl = (messageUrl, placement, display) => {
  let context = ENV.context_asset_string.replace('_', 's/')
  if (!(context.startsWith('account') || context.startsWith('course'))) {
    context = 'accounts/' + ENV.DOMAIN_ROOT_ACCOUNT_ID
  }
  const baseUrl = `${window.location.origin}/${context}/external_tools/retrieve?display=${display}`

  const toolLaunchUrl = new URL(messageUrl)
  const clientId = toolLaunchUrl.searchParams.get('client_id')
  const clientIdParam = clientId ? `&client_id=${clientId}` : ''
  const placementParam = placement ? `&placement=${placement}` : ''

  const assignmentId = toolLaunchUrl.searchParams.get('assignment_id')
  const assignmentParam = assignmentId ? `&assignment_id=${assignmentId}` : ''

  // xsslint safeString.property window.location
  toolLaunchUrl.searchParams.append('platform_redirect_url', window.location)
  toolLaunchUrl.searchParams.append('full_win_launch_requested', '1')
  const encodedToolLaunchUrl = encodeURIComponent(toolLaunchUrl.toString())

  return `${baseUrl}&url=${encodedToolLaunchUrl}${clientIdParam}${placementParam}${assignmentParam}`
}

const handler = ({message}) => {
  const {url, launchType, launchOptions, placement, display} = parseData(message.data)
  const launchUrl = buildLaunchUrl(url, placement, display)

  let proxy
  switch (launchType) {
    case 'popup': {
      const width = launchOptions.width || 800
      const height = launchOptions.height || 600
      proxy = window.open(
        launchUrl,
        'popupLaunch',
        `toolbar=no,menubar=no,location=no,status=no,resizable,scrollbars,width=${width},height=${height}`
      )
      break
    }
    case 'new_window': {
      proxy = window.open(launchUrl, 'newWindowLaunch')
      break
    }
    case 'same_window': {
      window.location.assign(launchUrl)
      break
    }
    default: {
      throw new Error("unknown launchType, must be 'popup', 'new_window', 'same_window'")
    }
  }

  // keep a reference to close later
  ltiState.fullWindowProxy = proxy
}

export default handler
