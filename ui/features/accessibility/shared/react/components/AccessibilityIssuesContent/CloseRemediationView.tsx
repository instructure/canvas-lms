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

import React, {useState} from 'react'
import {useMutation} from '@tanstack/react-query'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconCompleteSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AccessibilityResourceScan} from '../../types'
import {useAccessibilityScansFetchUtils} from '../../hooks/useAccessibilityScansFetchUtils'
import {NextResource} from '../../stores/AccessibilityScansStore'

const I18n = createI18nScope('accessibility_checker')

interface CloseRemediationViewProps {
  scan: AccessibilityResourceScan
  onBack: () => void
  nextResource: NextResource
  onClose: () => void
  handleNextResource: () => void
}

const CloseRemediationView: React.FC<CloseRemediationViewProps> = ({
  scan,
  onBack,
  nextResource,
  onClose,
  handleNextResource,
}) => {
  const [isClosed, setIsClosed] = useState(false)
  const {doFetchAccessibilityScanData, doFetchAccessibilityIssuesSummary} =
    useAccessibilityScansFetchUtils()

  const closeRemediationMutation = useMutation({
    mutationFn: async () => {
      const {json, response} = await doFetchApi({
        path: `/courses/${scan.courseId}/accessibility/resource_scan/${scan.id}/close_issues`,
        method: 'PATCH',
        body: {close: true},
      })

      if (!response.ok) {
        throw new Error(I18n.t('Failed to close remediation'))
      }

      return json
    },
    onSuccess: () => {
      showFlashAlert({
        message: I18n.t('Remediation closed successfully'),
        type: 'success',
      })

      setIsClosed(true)

      doFetchAccessibilityScanData({})
      doFetchAccessibilityIssuesSummary({})
    },
    onError: (error: Error) => {
      showFlashAlert({
        message: error.message || I18n.t('Failed to close remediation'),
        type: 'error',
      })
    },
  })

  const handleCloseRemediation = () => {
    if (closeRemediationMutation.isPending) return
    closeRemediationMutation.mutate()
  }
  return (
    <Flex as="div" direction="column" height="100%" width="100%">
      <Flex.Item shouldGrow={true} overflowY="auto">
        <View position="relative" width="100%">
          <View as="div" padding="medium">
            {closeRemediationMutation.isPending && (
              <ScreenReaderContent aria-live="polite" aria-atomic="true">
                {I18n.t('Closing remediation, please wait...')}
              </ScreenReaderContent>
            )}
            <Heading level="h2" margin="0 0 small 0">
              {I18n.t('%{count} outstanding issues remaining', {count: scan.issueCount})}
            </Heading>
            <View as="div" margin="medium 0">
              <Text>
                {I18n.t(
                  "There are accessibility issues on this resource that haven't been resolved.",
                )}
              </Text>
            </View>
            <View as="div" margin="medium 0">
              <Text>
                {I18n.t(
                  "If you've determined that no further remediation is planned for this resource, you can close accessibility remediation and exclude the remaining issues from statistics. If you edit this resource, it will be reopened.",
                )}
              </Text>
            </View>
            <View as="div" margin="medium 0 0 0">
              {isClosed ? (
                <Flex gap="small" alignItems="center">
                  <Flex.Item>
                    <IconCompleteSolid color="success" />
                  </Flex.Item>
                  <Flex.Item>
                    <Text>{I18n.t('Remediation closed.')}</Text>
                  </Flex.Item>
                </Flex>
              ) : (
                <Button
                  color="primary"
                  onClick={handleCloseRemediation}
                  disabled={closeRemediationMutation.isPending}
                >
                  {I18n.t('Close remediation')}
                </Button>
              )}
            </View>
          </View>
        </View>
      </Flex.Item>
      <View as="div" position="sticky" insetBlockEnd="0" style={{zIndex: 10}}>
        <View as="footer" background="secondary">
          <Flex justifyItems="space-between" alignItems="center" padding="small">
            <Flex.Item>
              {!isClosed && <Button onClick={onBack}>{I18n.t('Back to start')}</Button>}
            </Flex.Item>
            <Flex.Item>
              <Button color="primary" onClick={handleNextResource}>
                {I18n.t('Next resource')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>
      </View>
    </Flex>
  )
}

export default CloseRemediationView
