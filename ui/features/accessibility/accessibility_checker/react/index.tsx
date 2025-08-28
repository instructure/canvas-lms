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

import ErrorBoundary from '@canvas/error-boundary'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import React from 'react'
import {AccessibilityCheckerApp} from './components/AccessibilityCheckerApp/AccessibilityCheckerApp'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityChecker: React.FC = () => {
  return (
    <ErrorBoundary
      errorComponent={
        <Flex>
          <Flex.Item>
            <Heading>{I18n.t('Error Loading Accessibility Checker')}</Heading>
          </Flex.Item>
          <Flex.Item>
            <Alert variant="error" renderCloseButtonLabel="Close" margin="small 0">
              {I18n.t(
                'An error occurred while loading the accessibility checker. Please try again later.',
              )}
            </Alert>
          </Flex.Item>
        </Flex>
      }
    >
      <AccessibilityCheckerApp />
    </ErrorBoundary>
  )
}
