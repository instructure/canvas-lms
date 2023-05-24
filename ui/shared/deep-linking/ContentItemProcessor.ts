/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import $ from 'jquery'
import {ltiState} from '@canvas/lti/jquery/messages'
import {DeepLinkResponse} from './DeepLinkResponse'

const loggingEnabled = () => {
  return ENV && ENV.DEEP_LINKING_LOGGING
}

export const contentItemProcessorPrechecks = (response: DeepLinkResponse) => {
  if (response.errormsg) {
    $.flashError(response.errormsg)
  }

  if (response.msg) {
    $.flashMessage(response.msg)
  }
  if (loggingEnabled()) {
    if (response.errorlog) {
      // eslint-disable-next-line no-console
      console.error(response.errorlog)
    }

    if (response.log) {
      // eslint-disable-next-line no-console
      console.log(response.log)
    }
  }

  if (ltiState?.fullWindowProxy) {
    ltiState.fullWindowProxy.close()
  }
}
