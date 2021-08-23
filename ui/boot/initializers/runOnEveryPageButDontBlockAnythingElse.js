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

// code in this file is stuff that needs to run on every page but that should
// not block anything else from loading. It will be loaded by webpack as an
// async chunk so it will always be loaded eventually, but not necessarily before
// any other js_bundle code runs. and by moving it into an async chunk,
// the critical code to display a page will be executed sooner

import $ from 'jquery'
import preventDefault from 'prevent-default'

// modules that do their own thing on every page that simply need to be required
import '@canvas/media-comments'
import './activateReminderControls'
import '../../features/navigation_header/jquery/instructure'
import './injectAuthTokenIntoForms'
import './ujsLinks'
import './expandAdminLinkMenusOnClick'
import './activateElementToggler'
import './toggleICSuperToggleWidgetsOnEnterKeyEvent'
import './loadInlineMediaComments'
import './ping'
import './markBrokenImages'
import './activateLtiThumbnailLauncher'
import './sanitizeCSSOverflow'

// show and hide the courses vertical menu when the user clicks the hamburger button
// This now lives in the courses package for usage elsewhere, but it sometimes needs
// to work in places that don't load the courses bundle.
import {initialize} from '@canvas/courses/jquery/toggleCourseNav'

initialize()

if (ENV.page_view_update_url) import('./trackPageViews')

// preventDefault so we dont change the hash
// this will make nested apps that use the hash happy
$('#skip_navigation_link').on(
  'click',
  preventDefault(function() {
    $($(this).attr('href'))
      .attr('tabindex', -1)
      .focus()
  })
)
