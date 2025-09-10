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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AssessmentStatusPill} from './AssessmentStatusPill'

const I18n = createI18nScope('rubrics-assessment-tray')

type AssessmentFooterProps = {
  isPreviewMode: boolean
  isRubricComplete: boolean
  isStandAloneContainer: boolean
  onDismiss: () => void
  onSubmit?: () => void
}
export const AssessmentFooter = ({
  isPreviewMode,
  isRubricComplete,
  isStandAloneContainer,
  onDismiss,
  onSubmit,
}: AssessmentFooterProps) => {
  return (
    <View as="div" data-testid="rubric-assessment-footer" overflowX="hidden" overflowY="hidden">
      <Flex justifyItems="end" margin="small 0" wrap="wrap" gap="small">
        {onSubmit && !isPreviewMode && (
          <Flex.Item>
            <AssessmentStatusPill isRubricComplete={isRubricComplete} />
          </Flex.Item>
        )}
        {isStandAloneContainer && (
          <Flex.Item>
            <Button
              color="secondary"
              onClick={() => onDismiss()}
              data-testid="cancel-rubric-assessment-button"
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
        )}
        {onSubmit && !isPreviewMode && (
          <Flex.Item>
            <Button
              color="primary"
              onClick={() => onSubmit()}
              data-testid="save-rubric-assessment-button"
            >
              {I18n.t('Submit Assessment')}
            </Button>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
