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
import {Alert} from '@instructure/ui-alerts'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {
  CONVERSION_JOB_COMPLETE,
  CONVERSION_JOB_FAILED,
  type ConversionAction,
  type ConversionJobState,
} from '../graphql/hooks/useConvertAllocations'

const I18n = createI18nScope('peer_review_allocation_rules_tray')

interface AllocationConverterMessageProps {
  hasLegacyAllocations: boolean
  conversionJobState: ConversionJobState
  conversionJobError: string | null
  conversionAction: ConversionAction
  isConversionInProgress: boolean
  launchConversion: () => void
  launchDeletion: () => void
}

function AllocationConverterMessage({
  hasLegacyAllocations,
  conversionJobState,
  conversionJobError,
  conversionAction,
  isConversionInProgress,
  launchConversion,
  launchDeletion,
}: AllocationConverterMessageProps) {
  if (!hasLegacyAllocations || conversionJobState === CONVERSION_JOB_COMPLETE) {
    return null
  }

  if (conversionJobState === CONVERSION_JOB_FAILED) {
    const defaultError =
      conversionAction === 'delete'
        ? I18n.t('An error occurred while deleting allocations.')
        : I18n.t('An error occurred while converting allocations.')

    return (
      <Flex.Item as="div" padding="x-small medium">
        <Alert variant="error" data-testid="legacy-allocations-error-alert">
          {conversionJobError || defaultError}
        </Alert>
      </Flex.Item>
    )
  }

  if (isConversionInProgress) {
    const progressText =
      conversionAction === 'delete'
        ? I18n.t('Allocation deletion in progress')
        : I18n.t('Allocation conversion in progress')
    const spinnerTitle =
      conversionAction === 'delete'
        ? I18n.t('Deleting allocations')
        : I18n.t('Converting allocations')

    return (
      <Flex.Item as="div" padding="x-small medium">
        <Alert variant="info" data-testid="legacy-allocations-converting-alert">
          <Flex direction="column">
            <Text>{progressText}</Text>
            <Spinner
              size="x-small"
              margin="small small 0 0"
              renderTitle={spinnerTitle}
              data-testid="legacy-allocations-converting-spinner"
            />
          </Flex>
        </Alert>
      </Flex.Item>
    )
  }

  return (
    <Flex.Item as="div" padding="x-small medium">
      <Alert variant="warning" data-testid="legacy-allocations-alert">
        {I18n.t(
          'This assignment has peer review allocations that are in the old format. To continue, either delete those allocations or convert them into the new format.',
        )}
        <Flex margin="small 0 0 0" gap="small">
          <Button data-testid="legacy-allocations-delete-button" onClick={launchDeletion}>
            {I18n.t('Delete')}
          </Button>
          <Button
            color="primary"
            data-testid="legacy-allocations-convert-button"
            onClick={launchConversion}
          >
            {I18n.t('Convert')}
          </Button>
        </Flex>
      </Alert>
    </Flex.Item>
  )
}

export default AllocationConverterMessage
