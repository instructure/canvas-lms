/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import ready from '@instructure/ready'
import {createRoot} from 'react-dom/client'
import {Main} from './react/Main'

ready(() => {
  $('#course_details_tabs').on('tabscreate tabsactivate', (_event, ui) => {
    const selectedTab = ui.tab || ui.newTab
    const tabId = $(selectedTab).find('a').attr('id')
    const app = <Main />
    if (tabId === 'tab-canvas-career-link') {
      const element = document.getElementById('tab-canvas-career') as HTMLElement
      const root = createRoot(element)
      root.render(app)
    } else {
      const element = document.getElementById('tab-canvas-career')
      if (element) {
        const root = createRoot(element)
        root.unmount()
      }
    }
  })
})
