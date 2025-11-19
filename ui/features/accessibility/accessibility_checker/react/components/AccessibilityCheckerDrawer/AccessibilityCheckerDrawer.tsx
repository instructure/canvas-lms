/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useCallback, useEffect, useRef, useState} from 'react'
import ReactDOM from 'react-dom/client'

import {DrawerLayout} from '@instructure/ui-drawer-layout'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

import AccessibilityIssuesContent from '../../../../shared/react/components/AccessibilityIssuesContent'
import {AccessibilityCheckerContext} from '../../../../shared/react/contexts/AccessibilityCheckerContext'
import {AccessibilityResourceScan} from '../../../../shared/react/types'
import {CourseScan} from '../AccessibilityScanWrapper'
import {AccessibilityCheckerApp} from '../AccessibilityCheckerApp/AccessibilityCheckerApp'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'

const I18n = createI18nScope('accessibility_checker')

interface AccessibilityCheckerDrawerProps {
  pageContent: HTMLElement
  container: HTMLElement
  courseId: string
  scanDisabled: boolean
}

// Based on ContentTypeExternalToolDrawer from ui/shared/trays/react/ContentTypeExternalToolDrawer.tsx
export default function AccessibilityCheckerDrawer({
  pageContent,
  container,
  courseId,
  scanDisabled,
}: AccessibilityCheckerDrawerProps) {
  const pageContentRef = useRef<HTMLDivElement>(null)
  const [selectedItem, setSelectedItem] = useState<AccessibilityResourceScan | null>(null)
  const [isTrayOpen, setIsTrayOpen] = useState<boolean>(false)

  const onDismiss = useCallback(() => {
    setSelectedItem(null)
    setIsTrayOpen(false)
  }, [setIsTrayOpen])

  useEffect(
    // Setup DrawerLayout content
    () => {
      // Appends pageContent to DrawerLayout.Content
      if (!container || !pageContentRef.current) {
        return
      }
      pageContentRef.current.appendChild(pageContent)

      const root = ReactDOM.createRoot(container)
      root.render(
        <AccessibilityCheckerContext.Provider
          value={{selectedItem, setSelectedItem, isTrayOpen, setIsTrayOpen}}
        >
          <QueryClientProvider client={queryClient}>
            <CourseScan courseId={courseId} scanDisabled={scanDisabled}>
              <AccessibilityCheckerApp />
            </CourseScan>
          </QueryClientProvider>
        </AccessibilityCheckerContext.Provider>,
      )
    },
    [],
  )

  return (
    <View display="block">
      <DrawerLayout>
        <DrawerLayout.Content label={I18n.t('Canvas LMS')}>
          <div ref={pageContentRef} />
        </DrawerLayout.Content>
        <DrawerLayout.Tray
          label={
            selectedItem
              ? `${selectedItem.resourceName} - ${I18n.t('Accessibility Issues')}`
              : I18n.t('Accessibility Issues')
          }
          open={isTrayOpen}
          placement="end"
          shouldCloseOnDocumentClick={false}
        >
          <AccessibilityCheckerContext.Provider
            value={{selectedItem, setSelectedItem, isTrayOpen, setIsTrayOpen}}
          >
            <View width="30em" height="100%" display="flex">
              {selectedItem ? (
                <AccessibilityIssuesContent item={selectedItem} onClose={onDismiss} />
              ) : (
                <View margin="auto">
                  <Spinner renderTitle={I18n.t('Loading accessibility issues...')} />
                </View>
              )}
            </View>
          </AccessibilityCheckerContext.Provider>
        </DrawerLayout.Tray>
      </DrawerLayout>
    </View>
  )
}
