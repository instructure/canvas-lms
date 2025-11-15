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

import {useCallback} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasTray from '@canvas/trays/react/Tray'
import AccessibilityIssuesContent from '../../../../shared/react/components/AccessibilityIssuesContent'
import {AccessibilityResourceScan} from '../../../../shared/react/types'

const I18n = createI18nScope('accessibility_checker')

export const AccessibilityWizard = ({
  selectedItem,
  isTrayOpen,
  setSelectedItem,
  setIsTrayOpen,
}: {
  selectedItem: AccessibilityResourceScan | null
  isTrayOpen: boolean
  setSelectedItem: (item: AccessibilityResourceScan | null) => void
  setIsTrayOpen: (isOpen: boolean) => void
}) => {
  const trayTitle = I18n.t('Accessibility Issues')

  const onDismiss = useCallback(() => {
    setSelectedItem(null)
    setIsTrayOpen(false)
  }, [setIsTrayOpen, setSelectedItem])

  return (
    <CanvasTray
      label={trayTitle}
      title={trayTitle}
      open={isTrayOpen}
      onDismiss={onDismiss}
      onClose={onDismiss}
      padding="0"
      headerPadding="small small 0 small"
      contentPadding="0"
      placement="end"
      size="regular"
      shouldCloseOnDocumentClick={false}
    >
      <>
        {selectedItem ? (
          <AccessibilityIssuesContent item={selectedItem} onClose={onDismiss} />
        ) : (
          <View margin="auto">
            <Spinner renderTitle={I18n.t('Loading accessibility issues...')} />
          </View>
        )}
      </>
    </CanvasTray>
  )
}
