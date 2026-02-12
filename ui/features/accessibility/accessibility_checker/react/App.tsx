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

import {useState} from 'react'
import {QueryClientProvider} from '@tanstack/react-query'
import {View} from '@instructure/ui-view'

import {queryClient} from '@canvas/query'
import {AccessibilityCheckerApp} from './components/AccessibilityCheckerApp/AccessibilityCheckerApp'
import {AccessibilityCourseScan} from './components/AccessibilityCourseScan'
import {AccessibilityCheckerContext} from '../../shared/react/contexts/AccessibilityCheckerContext'
import {AccessibilityResourceScan} from '../../shared/react/types'
import {AccessibilityWizard} from './components/AccessibilityWizard'

export const App = () => {
  const [selectedItem, setSelectedItem] = useState<AccessibilityResourceScan | null>(null)
  const [isTrayOpen, setIsTrayOpen] = useState<boolean>(false)

  const scanDisabled = !!window.ENV.SCAN_DISABLED
  const courseId = window.ENV.current_context?.id

  if (!courseId) {
    return null
  }

  return (
    <View display="block">
      <AccessibilityCheckerContext.Provider
        value={{selectedItem, setSelectedItem, isTrayOpen, setIsTrayOpen}}
      >
        <QueryClientProvider client={queryClient}>
          <AccessibilityWizard />
          <AccessibilityCourseScan courseId={courseId} scanDisabled={scanDisabled}>
            <AccessibilityCheckerApp />
          </AccessibilityCourseScan>
        </QueryClientProvider>
      </AccessibilityCheckerContext.Provider>
    </View>
  )
}
