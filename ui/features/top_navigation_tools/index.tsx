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

import {useScope as createI18nScope} from '@canvas/i18n'
import React from 'react'
import {legacyRender} from '@canvas/react'
import ready from '@instructure/ready'
import ContentTypeExternalToolDrawer from '@canvas/trays/react/ContentTypeExternalToolDrawer'
import {TopNavigationTools, MobileTopNavigationTools} from './react/TopNavigationTools'
import type {Tool} from '@canvas/global/env/EnvCommon'
import iframeAllowances from '@canvas/external-apps/iframeAllowances'

const I18n = createI18nScope('common')

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
    legacyRender(
      <ContentTypeExternalToolDrawer
        tool={selectedTool}
        // @ts-expect-error
        pageContent={canvasApplicationBody}
        pageContentTitle={I18n.t('Canvas LMS')}
        pageContentMinWidth="40rem"
        // @ts-expect-error
        pageContentHeight={window.innerHeight}
        trayPlacement="end"
        onDismiss={handleDismissToolDrawer}
        onResize={handleResize}
        open={!!selectedTool}
        iframeAllowances={iframeAllowances()}
      />,
      drawerLayoutMountPoint,
    )
  }

  function renderTopNavigationTools(): void {
    legacyRender(
      <TopNavigationTools tools={ENV.top_navigation_tools} handleToolLaunch={handleToolLaunch} />,
      topNavToolsMountPoint,
    )

    if (mobileTopNavToolsMountPoint) {
      legacyRender(
        <MobileTopNavigationTools
          tools={ENV.top_navigation_tools}
          handleToolLaunch={handleToolLaunch}
        />,
        mobileTopNavToolsMountPoint,
      )
    }
  }

  if (drawerLayoutMountPoint && topNavToolsMountPoint && canvasApplicationBody) {
    renderExternalToolDrawer()
    renderTopNavigationTools()
  }

  /*
   * Fix for href="#" scroll-to-top behavior when top_navigation_placement feature is enabled.
   *
   * When top_navigation is on, the HTML element gets a fixed height and the actual
   * scrollable area becomes #drawer-layout-content. The browser's natural href="#"
   * behavior tries to scroll the document, but since HTML can't scroll, it fails.
   * This fix detects the layout mode and redirects the scroll to the correct container.
   */
  document.addEventListener(
    'click',
    function (e) {
      if (!(e.target instanceof Element)) return
      const link = e.target.closest('a[href="#"]')
      if (link && link.getAttribute('href') === '#') {
        const htmlCanScroll =
          document.documentElement.scrollHeight > document.documentElement.clientHeight

        if (!htmlCanScroll) {
          const drawerContent = document.querySelector('#drawer-layout-content')
          if (drawerContent && drawerContent.scrollTop > 0) {
            e.preventDefault()
            drawerContent.scrollTo({top: 0})
          }
        }
      }
    },
    {capture: true},
  )
})
