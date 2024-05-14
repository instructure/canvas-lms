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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import ready from '@instructure/ready'
import ContentTypeExternalToolDrawer from '@canvas/trays/react/ContentTypeExternalToolDrawer'
import {TopNavigationTools, MobileTopNavigationTools} from './react/TopNavigationTools'
import type {Tool} from '@canvas/global/env/EnvCommon'

const I18n = useI18nScope('common')

ready(() => {
  const drawerLayoutMountPoint = document.getElementById('drawer-layout-mount-point')
  const topNavToolsMountPoint = document.getElementById('top-nav-tools-mount-point')
  const mobileTopNavToolsMountPoint = document.getElementById('mobile-top-nav-tools-mount-point')
  const canvasApplicationBody = document.getElementById('application')
  let selectedTool: Tool | null = null

  function handleDismissToolDrawer(): void {
    selectedTool = null
    renderExternalToolDrawer()
  }

  function handleToolLaunch(tool: Tool): void {
    selectedTool = tool
    selectedTool.placement = 'top_navigation'
    renderExternalToolDrawer()
  }

  function handleResize(): void {
    renderExternalToolDrawer()
  }

  function renderExternalToolDrawer(): void {
    ReactDOM.render(
      <ContentTypeExternalToolDrawer
        tool={selectedTool}
        pageContent={canvasApplicationBody}
        pageContentTitle={I18n.t('Canvas LMS')}
        pageContentMinWidth="40rem"
        pageContentHeight={window.innerHeight}
        trayPlacement="end"
        onDismiss={handleDismissToolDrawer}
        onResize={handleResize}
        open={!!selectedTool}
      />,
      drawerLayoutMountPoint
    )
  }

  function renderTopNavigationTools(): void {
    ReactDOM.render(
      <TopNavigationTools tools={ENV.top_navigation_tools} handleToolLaunch={handleToolLaunch} />,
      topNavToolsMountPoint
    )

    if (mobileTopNavToolsMountPoint) {
      ReactDOM.render(
        <MobileTopNavigationTools
          tools={ENV.top_navigation_tools}
          handleToolLaunch={handleToolLaunch}
        />,
        mobileTopNavToolsMountPoint
      )
    }
  }

  if (drawerLayoutMountPoint && topNavToolsMountPoint && canvasApplicationBody) {
    renderExternalToolDrawer()
    renderTopNavigationTools()
  }
})
