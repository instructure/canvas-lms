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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Alert} from '@instructure/ui-alerts'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {usePeerReviewConfiguration} from '../graphql/hooks/usePeerReviewConfiguration'

const I18n = createI18nScope('peer_review_configuration_tray')

export interface PeerReviewConfigurationTrayProps {
  assignmentId: string
  isTrayOpen: boolean
  closeTray: () => void
}

export const PeerReviewConfigurationTray = ({
  assignmentId,
  isTrayOpen,
  closeTray,
}: PeerReviewConfigurationTrayProps) => {
  const {hasGroupCategory, peerReviews, peerReviewSubAssignment, loading, error} =
    usePeerReviewConfiguration(assignmentId)

  const renderConfigRow = (label: string, value: string | number) => (
    <Flex as="div" padding="x-small 0">
      <Flex.Item width="10rem">
        <Text weight="bold">{label}</Text>
      </Flex.Item>
      <Flex.Item>
        <Text>{value}</Text>
      </Flex.Item>
    </Flex>
  )

  const renderContent = () => {
    if (loading) {
      return (
        <Flex direction="column" alignItems="center" padding="large">
          <Spinner
            renderTitle={I18n.t('Loading peer review configuration')}
            data-testid="peer-review-config-loading-spinner"
          />
        </Flex>
      )
    }

    if (error) {
      return (
        <View as="div" padding="medium">
          <Alert
            variant="error"
            renderCloseButtonLabel={I18n.t('Close error alert')}
            margin="0"
            data-testid="peer-review-config-error-alert"
          >
            {I18n.t('An error occurred while loading the peer review configuration')}
          </Alert>
        </View>
      )
    }

    // In case there is a race condition and peer review gets disabled when the page loads
    if (!peerReviews || !peerReviewSubAssignment) {
      return (
        <View as="div" padding="medium">
          <Text>{I18n.t('This assignment is not configured for peer review')}</Text>
        </View>
      )
    }

    const totalPoints = peerReviewSubAssignment.pointsPossible || 0
    const pointsPerReview = totalPoints / peerReviews.count

    return (
      <View as="div" padding="0 medium medium medium">
        {renderConfigRow(I18n.t('Reviews Required'), peerReviews.count)}
        {renderConfigRow(I18n.t('Points Per Review'), pointsPerReview)}
        {renderConfigRow(I18n.t('Total Points'), totalPoints)}
        {renderConfigRow(
          I18n.t('Across Sections'),
          peerReviews.acrossSections ? I18n.t('Allowed') : I18n.t('Not allowed'),
        )}
        {hasGroupCategory &&
          renderConfigRow(
            I18n.t('Within Groups'),
            peerReviews.intraReviews ? I18n.t('Allowed') : I18n.t('Not allowed'),
          )}
        {renderConfigRow(
          I18n.t('Submission Req'),
          peerReviews.submissionRequired ? I18n.t('Required') : I18n.t('Not required'),
        )}
        {renderConfigRow(
          I18n.t('Anonymity'),
          peerReviews.anonymousReviews ? I18n.t('Anonymous') : I18n.t('Not anonymous'),
        )}
      </View>
    )
  }

  return (
    <Tray
      label={I18n.t('Peer Review')}
      open={isTrayOpen}
      onDismiss={closeTray}
      placement="end"
      data-testid="peer-review-configuration-tray"
    >
      <Flex direction="column">
        <Flex.Item>
          <Flex as="div" padding="medium">
            <Flex.Item shouldGrow shouldShrink>
              <Heading level="h3" as="h2">
                {I18n.t('Peer Review')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                data-testid="peer-review-config-tray-close-button"
                placement="end"
                offset="medium"
                screenReaderLabel={I18n.t('Close Peer Review Configuration Tray')}
                size="small"
                onClick={closeTray}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item>{renderContent()}</Flex.Item>
      </Flex>
    </Tray>
  )
}
