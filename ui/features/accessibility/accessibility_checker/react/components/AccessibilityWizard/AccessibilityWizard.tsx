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

import {canvasThemeLocal} from '@instructure/ui-themes'
import {useCallback} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {useScope as createI18nScope} from '@canvas/i18n'
import AccessibilityIssuesContent from '../../../../shared/react/components/AccessibilityIssuesContent'
import {useAccessibilityCheckerContext} from '../../../../shared/react/hooks/useAccessibilityCheckerContext'
import {WizardHeader} from './WizardHeader/WizardHeader'
import {WizardErrorBoundary} from './WizardErrorBoundary/WizardErrorBoundary'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityWizard = () => {
  const {selectedItem, setSelectedItem, setIsTrayOpen, isTrayOpen} =
    useAccessibilityCheckerContext()

  const trayTitle = selectedItem?.resourceName ?? ''

  const onDismiss = useCallback(() => {
    setSelectedItem(null)
    setIsTrayOpen(false)
  }, [setIsTrayOpen, setSelectedItem])

  return (
    <Tray
      label={trayTitle}
      open={isTrayOpen}
      onDismiss={onDismiss}
      onClose={onDismiss}
      placement="end"
      size="regular"
    >
      <View
        as="div"
        padding="0"
        position="absolute"
        insetBlockStart="0"
        insetBlockEnd="0"
        insetInlineStart="0"
        insetInlineEnd="0"
      >
        <Flex direction="column" width="100%" height="100%">
          <View
            as="div"
            position="sticky"
            insetBlockStart="0"
            padding="medium small mediumSmall small"
            elementRef={(el: Element | null) => {
              if (el instanceof HTMLElement) {
                el.style.zIndex = '10'
                el.style.background = canvasThemeLocal.colors.contrasts.white1010
                el.style.borderBottom = `1px solid ${canvasThemeLocal.colors.contrasts.grey1214}`
              }
            }}
          >
            <WizardHeader title={trayTitle} onDismiss={onDismiss} />
          </View>
          <View as="div" width="100%" height="100%">
            <WizardErrorBoundary>
              {selectedItem ? (
                <AccessibilityIssuesContent item={selectedItem} onClose={onDismiss} />
              ) : (
                <View margin="auto">
                  <Spinner renderTitle={I18n.t('Loading accessibility issues...')} />
                </View>
              )}
            </WizardErrorBoundary>
          </View>
        </Flex>
      </View>
    </Tray>
  )
}
