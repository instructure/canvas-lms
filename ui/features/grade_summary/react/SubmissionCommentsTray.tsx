/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tray} from '@instructure/ui-tray'
import SubmissionAttempts from './SubmissionAttempts'
import useStore, {updateState} from './stores'

const I18n = useI18nScope('grade_summary')

type SubmissionCommentsTrayProps = {
  onDismiss?: () => void
}

function SubmissionCommentsTray({onDismiss}: SubmissionCommentsTrayProps) {
  const handleDismiss = () => {
    updateState({submissionTrayOpen: false})
    onDismiss?.()
  }

  const submissionComments = useStore(state => state.submissionCommentsTray)
  const open = useStore(state => state.submissionTrayOpen)
  const attempts = submissionComments?.attempts ?? {}

  return (
    <Tray
      data-testid="submission-tray"
      label={I18n.t('Submission Comments Tray')}
      open={open}
      shouldContainFocus={true}
      placement="end"
      onDismiss={handleDismiss}
      data-id="submissions-comments-tray"
    >
      <View as="div" padding="small" data-testid="submission-tray-details">
        <Flex as="div" alignItems="center" justifyItems="space-between">
          <Flex.Item shouldShrink={true}>
            <Heading as="h2" level="h3">
              <Text>{I18n.t('Feedback')}</Text>
            </Heading>
          </Flex.Item>

          <Flex.Item>
            <CloseButton
              onClick={handleDismiss}
              screenReaderLabel={I18n.t('Close')}
              margin="0 x-small 0 0"
              data-testid="submission-tray-dismiss"
            />
          </Flex.Item>
        </Flex>
      </View>
      <SubmissionAttempts attempts={attempts} />
    </Tray>
  )
}

export default SubmissionCommentsTray
