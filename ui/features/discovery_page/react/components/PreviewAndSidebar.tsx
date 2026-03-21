/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {useRef} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-themes'
import type {PreviewAndSidebarProps} from '../types'

const I18n = createI18nScope('discovery_page')

const BORDER_COLOR = canvas.colors.ui.lineDivider

const breakpoints = {
  tablet: {minWidth: canvas.breakpoints.tablet}, // 48em (768px)
  desktop: {minWidth: canvas.breakpoints.desktop}, // 64em (1024px)
  xLarge: {minWidth: canvas.breakpoints.xLarge}, // 75em (1200px)
}

const SIDEBAR_WIDTHS = {
  default: 320,
  desktop: 480,
  xLarge: 640,
}

export function PreviewAndSidebar({previewUrl, children, iframeRef}: PreviewAndSidebarProps) {
  const internalIframeRef = useRef<HTMLIFrameElement>(null)
  const frameRef = iframeRef || internalIframeRef
  // <Responsive> renders its own <div> with display="block", which doesn’t
  // stretch inside a flex parent. There’s no style/height prop, so we set
  // height and width imperatively via elementRef
  const setResponsiveRef = (el: HTMLDivElement | null) => {
    if (!el) return
    el.style.height = '100%'
    el.style.width = '100%'
  }

  return (
    <Responsive match="element" query={breakpoints} elementRef={setResponsiveRef}>
      {(_props, matches) => {
        const isTablet = matches?.includes('tablet') || false
        const isDesktop = matches?.includes('desktop') || false
        const isXLarge = matches?.includes('xLarge') || false

        let sidebarWidth = SIDEBAR_WIDTHS.default
        if (isXLarge) {
          sidebarWidth = SIDEBAR_WIDTHS.xLarge
        } else if (isDesktop) {
          sidebarWidth = SIDEBAR_WIDTHS.desktop
        }

        const direction = isTablet ? 'row' : 'column'

        return (
          <Flex
            alignItems="stretch"
            as="div"
            direction={direction}
            height="100%"
            width="100%"
            wrap="no-wrap"
          >
            <Flex.Item as="div" shouldGrow shouldShrink>
              <div style={{height: isTablet ? '100%' : '50vh', minWidth: 0, minHeight: 0}}>
                <iframe
                  ref={frameRef}
                  data-testid="preview-iframe"
                  src={previewUrl}
                  style={{width: '100%', height: '100%', border: 'none', display: 'block'}}
                  title={I18n.t('Service Preview')}
                />
              </div>
            </Flex.Item>

            <Flex.Item
              as="div"
              shouldGrow={false}
              shouldShrink={false}
              size={isTablet ? `${sidebarWidth}px` : 'auto'}
            >
              <div
                style={{
                  borderLeft: isTablet ? `1px solid ${BORDER_COLOR}` : 'none',
                  borderTop: isTablet ? 'none' : `1px solid ${BORDER_COLOR}`,
                  boxSizing: 'border-box',
                  height: isTablet ? '100%' : '50vh',
                  minWidth: 0,
                  overflowY: 'auto',
                  padding: '1rem',
                  width: '100%',
                }}
              >
                {children}
              </div>
            </Flex.Item>
          </Flex>
        )
      }}
    </Responsive>
  )
}
