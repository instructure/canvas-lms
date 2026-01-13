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
import {useMutation} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine, IconCompleteLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AccessibilityResourceScan, ScanWorkflowState} from '../../../../../shared/react/types'
import {useAccessibilityScansFetchUtils} from '../../../../../shared/react/hooks/useAccessibilityScansFetchUtils'
import {useAccessibilityScansStore} from '../../../../../shared/react/stores/AccessibilityScansStore'
import {CloseRemediationModal, shouldShowCloseRemediationModal} from './CloseRemediationModal'

const I18n = createI18nScope('accessibility_checker')

interface ActionsMenuCellProps {
  scan: AccessibilityResourceScan
}

export const ActionsMenuCell = ({scan}: ActionsMenuCellProps) => {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const {doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary} =
    useAccessibilityScansFetchUtils()
  const isCloseIssuesEnabled = useAccessibilityScansStore(state => state.isCloseIssuesEnabled)

  const isClosed = Boolean(scan.closedAt?.trim())
  const hasIssues = scan.issueCount > 0

  const closeRemediationMutation = useMutation({
    mutationFn: async ({close}: {close: boolean}) => {
      const {json, response} = await doFetchApi({
        path: `/courses/${scan.courseId}/accessibility/resource_scan/${scan.id}/close_issues`,
        method: 'PATCH',
        body: {close},
      })

      if (!response.ok) {
        throw new Error(I18n.t('Failed to update remediation status'))
      }

      return json
    },
    onSuccess: (_data, {close}) => {
      if (close) {
        if (!shouldShowCloseRemediationModal()) {
          showFlashAlert({
            message: I18n.t('Remediation closed successfully'),
            type: 'success',
          })
          doFetchAccessibilityScanData({})
          doFetchAccessibilityIssuesSummary({})
        } else {
          setIsModalOpen(true)
        }
      } else {
        showFlashAlert({
          message: I18n.t('Remediation reopened and resource re-scanned'),
          type: 'success',
        })
        doFetchAccessibilityScanData({})
        doFetchAccessibilityIssuesSummary({})
      }
    },
    onError: (error: Error) => {
      showFlashAlert({
        message: error.message || I18n.t('Failed to update remediation status'),
        type: 'error',
      })
    },
  })

  // Hide the entire component if feature flag is disabled
  if (!isCloseIssuesEnabled) {
    return null
  }

  if (scan.workflowState !== ScanWorkflowState.Completed) {
    return null
  }

  if (!isClosed && !hasIssues) {
    return null
  }

  const handleCloseModal = () => {
    setIsModalOpen(false)
    doFetchAccessibilityScanData({})
    doFetchAccessibilityIssuesSummary({})
  }

  const handleCloseRemediation = () => {
    if (closeRemediationMutation.isPending) return
    closeRemediationMutation.mutate({close: true})
  }

  const handleReopenRemediation = () => {
    if (closeRemediationMutation.isPending) return
    closeRemediationMutation.mutate({close: false})
  }

  return (
    <>
      {closeRemediationMutation.isPending && (
        <ScreenReaderContent aria-live="polite" aria-atomic="true">
          {isClosed
            ? I18n.t('Reopening remediation, please wait...')
            : I18n.t('Closing remediation, please wait...')}
        </ScreenReaderContent>
      )}
      <Menu
        placement="bottom end"
        trigger={
          <IconButton
            screenReaderLabel={I18n.t('Actions for %{name}', {name: scan.resourceName})}
            size="small"
            withBackground={false}
            withBorder={false}
            data-testid="actions-menu-button"
          >
            <IconMoreLine />
          </IconButton>
        }
      >
        <Menu.Separator
          themeOverride={{
            background: 'transparent',
            height: '0.5rem',
          }}
        />
        {isClosed ? (
          <Menu.Item
            onSelect={handleReopenRemediation}
            disabled={closeRemediationMutation.isPending}
          >
            <Flex gap="small" alignItems="center" padding="none x-large none x-small">
              <Flex.Item size="small">
                <IconCompleteLine size="x-small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="small">{I18n.t('Reopen remediation')}</Text>
              </Flex.Item>
            </Flex>
          </Menu.Item>
        ) : (
          <Menu.Item
            onSelect={handleCloseRemediation}
            disabled={closeRemediationMutation.isPending}
          >
            <Flex gap="small" alignItems="center" padding="none x-large none x-small">
              <Flex.Item size="small">
                <IconCompleteLine size="x-small" />
              </Flex.Item>
              <Flex.Item>
                <Text size="small">{I18n.t('Close remediation')}</Text>
              </Flex.Item>
            </Flex>
          </Menu.Item>
        )}
        <Menu.Separator
          themeOverride={{
            background: 'transparent',
            height: '0.5rem',
          }}
        />
      </Menu>
      <CloseRemediationModal
        isOpen={isModalOpen}
        scan={scan}
        onClose={handleCloseModal}
        onReopen={handleReopenRemediation}
      />
    </>
  )
}
