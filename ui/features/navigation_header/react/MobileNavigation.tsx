/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {useState, useEffect, useRef} from 'react'
import $ from 'jquery'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

declare global {
  interface Window {
    openBPSidebar: () => void
  }
}

const I18n = useI18nScope('MobileNavigation')

const MobileContextMenu = React.lazy(() => import('./MobileContextMenu'))
const MobileGlobalMenu = React.lazy(() => import('./MobileGlobalMenu'))

interface DesktopNavComponentProp {
  ensureLoaded: () => void
  state: object
}

type MobileNavigationProps = {
  DesktopNavComponent: DesktopNavComponentProp
}

const MobileNavigation: React.FC<MobileNavigationProps> = ({DesktopNavComponent}) => {
  const [globalNavIsOpen, setGlobalNavIsOpen] = useState(false)
  const contextNavIsOpen = useRef(false)

  useEffect(() => {
    $('.mobile-header-hamburger').on('touchstart click', event => {
      event.preventDefault()
      setGlobalNavIsOpen(true)
    })

    $('.mobile-header-blueprint-button').on('touchstart click', () => {
      window.openBPSidebar()
    })

    const arrowIcon = document.getElementById('mobileHeaderArrowIcon')
    const mobileContextNavContainer = document.getElementById('mobileContextNavContainer')
    $('.mobile-header-title.expandable, .mobile-header-arrow').on('touchstart click', event => {
      event.preventDefault()
      contextNavIsOpen.current = !contextNavIsOpen.current

      // gotta do some manual dom manip for the non-react arrow/close icon
      if (arrowIcon) {
        arrowIcon.className = contextNavIsOpen.current ? 'icon-x' : 'icon-arrow-open-down'
      }

      if (mobileContextNavContainer) {
        // @ts-expect-error
        mobileContextNavContainer.setAttribute('aria-expanded', contextNavIsOpen.current)
      }
    })
  }, [])

  const spinner = (
    <View display="block" textAlign="center">
      <Spinner size="large" margin="large auto" renderTitle={() => I18n.t('...Loading')} />
    </View>
  )

  return (
    <>
      {globalNavIsOpen && (
        <Tray
          size="large"
          label={I18n.t('Global Navigation')}
          open={globalNavIsOpen}
          onDismiss={() => setGlobalNavIsOpen(false)}
          shouldCloseOnDocumentClick={true}
        >
          {globalNavIsOpen && (
            <React.Suspense fallback={spinner}>
              <MobileGlobalMenu
                // @ts-expect-error
                DesktopNavComponent={DesktopNavComponent}
                onDismiss={() => setGlobalNavIsOpen(false)}
              />
            </React.Suspense>
          )}
        </Tray>
      )}
      {contextNavIsOpen.current && (
        <React.Suspense fallback={spinner}>
          <MobileContextMenu spinner={spinner} />
        </React.Suspense>
      )}
    </>
  )
}

export default MobileNavigation
