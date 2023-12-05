/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import type {LtiMessageHandler} from '../lti_message_handler'

const fetchWindowSize: LtiMessageHandler = ({responseMessages}) => {
  responseMessages.sendResponse({
    height: window.innerHeight,
    width: window.innerWidth,
    offset: $('.tool_content_wrapper').offset(),
    footer: $('#fixed_bottom').height() || 0,
    scrollY: window.scrollY,
  })
  return true
}

export default fetchWindowSize
