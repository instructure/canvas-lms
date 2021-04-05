//
// Copyright (C) 2012 - present Instructure, Inc.
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
import {trackEvent} from '@canvas/google-analytics'

// #
// Track click events to google analytics with HTML
//
//   <a
//     data-track-category="some category"
//     data-track-label="some label"
//     data-track-action="some action"
//     data-track-value="some value"
//   >click here</a>
$('body').on('click', '[data-track-category]', function() {
  const {trackCategory, trackLabel, trackAction, trackValue} = $(this).data()
  trackEvent(trackCategory, trackAction, trackLabel, trackValue)
})
