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

const handler = data => {
  let context = ENV.context_asset_string.replace('_', 's/')
  if (!(context.startsWith('account') || context.startsWith('course'))) {
    context = 'accounts/' + ENV.DOMAIN_ROOT_ACCOUNT_ID
  }

  const tool_launch_url = new URL(data)
  tool_launch_url.searchParams.append('full_win_launch_requested', '1')
  // xsslint safeString.property window.location
  tool_launch_url.searchParams.append('platform_redirect_url', window.location)

  const launch_url = `${
    window.location.origin
  }/${context}/external_tools/retrieve?display=borderless&url=${encodeURIComponent(
    tool_launch_url.toString()
  )}`
  window.location.assign(launch_url)
}

export default handler
