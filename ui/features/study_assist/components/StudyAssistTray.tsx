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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {AssistProvider, AssistContent} from '@instructure/platform-study-assist'
import type {AssistRequest, AssistResponse} from '@instructure/platform-study-assist'
import {IconAiSolid} from '@instructure/ui-icons'

const I18n = createI18nScope('study_assist')

const GRADIENT = 'linear-gradient(135deg, #7b5ea7 0%, #5b7fa6 60%, #4a919e 100%)'

type Props = {
  open: boolean
  onDismiss: () => void
  fetchAssistResponse: (request: AssistRequest) => Promise<AssistResponse>
}

export default function StudyAssistTray({open, onDismiss, fetchAssistResponse}: Props) {
  return (
    <Tray
      label={I18n.t('Study tools')}
      placement="end"
      size="regular"
      open={open}
      onDismiss={onDismiss}
    >
      <div style={{background: GRADIENT, color: 'white', minHeight: '100vh'}}>
        <Flex as="div" padding="small" alignItems="center">
          <Flex.Item shouldGrow={true}>
            <Flex gap="x-small" alignItems="center">
              <Flex.Item>
                <IconAiSolid />
              </Flex.Item>
              <Flex.Item>
                <Heading themeOverride={{primaryColor: 'white'}}>{I18n.t('Study tools')}</Heading>
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              onClick={onDismiss}
              size="small"
              color="primary-inverse"
              screenReaderLabel={I18n.t('Close')}
              data-testid="study-assist-close-button"
            />
          </Flex.Item>
        </Flex>
        <AssistProvider
          fetchAssistResponse={fetchAssistResponse}
          courseId={window.ENV.COURSE_ID}
          moduleItemId={window.ENV.WIKI_PAGE_ID}
        >
          <div style={{padding: '0 1rem'}}>
            <AssistContent
              chatEnabled={false}
              showLargePrompts={true}
              onAnalyticsEvent={() => null}
              allowedPrompts={['Summarize', 'Quiz me', 'Flashcards']}
            />
          </div>
        </AssistProvider>
      </div>
    </Tray>
  )
}
