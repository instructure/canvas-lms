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

import React, {useCallback, useMemo, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  AssistProvider,
  AssistContent,
  AssistFlashCardsInteraction,
} from '@instructure/platform-study-assist'
import type {
  AssistRequest,
  AssistResponse,
  AssistChatFlashCard,
} from '@instructure/platform-study-assist'
import {IconAiSolid, IconInfoLine} from '@instructure/ui-icons'
import CanvasAiInformation from '@canvas/instui-bindings/react/AiInformation'

const I18n = createI18nScope('study_assist')

const GRADIENT = 'linear-gradient(135deg, #7b5ea7 0%, #5b7fa6 60%, #4a919e 100%)'

type Props = {
  open: boolean
  onDismiss: () => void
  fetchAssistResponse: (request: AssistRequest) => Promise<AssistResponse>
}

export default function StudyAssistTray({open, onDismiss, fetchAssistResponse}: Props) {
  const closeButtonRef = useRef<Element | null>(null)
  const allowedPrompts = useMemo(() => window.ENV.STUDY_ASSIST_TOOLS ?? [], [])

  const renderFlashCards = useCallback(
    (
      cards: AssistChatFlashCard[],
      isFetching: boolean,
      isError: boolean,
      getFlashCards: () => void,
    ) => (
      <div style={{padding: '2rem'}}>
        <AssistFlashCardsInteraction
          cardData={cards}
          isFetching={isFetching}
          isError={isError}
          getFlashCards={getFlashCards}
          cardHeight="60vh"
        />
      </div>
    ),
    [],
  )

  return (
    <Tray
      label={I18n.t('Study tools')}
      placement="end"
      size="regular"
      open={open}
      onDismiss={onDismiss}
      defaultFocusElement={() => closeButtonRef.current}
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
            <Flex gap="small">
              <Flex.Item>
                <CanvasAiInformation
                  title={I18n.t('Nutrition Facts')}
                  privacyNoticeText={I18n.t('AI Privacy Notice')}
                  featureName={I18n.t('Study Tools')}
                  modelName={I18n.t('Claude 3 Haiku')}
                  isTrainedWithUserData={false}
                  dataSharedWithModel={I18n.t('Page')}
                  dataSharedWithModelDescription={I18n.t(
                    'Page content is sent to the model to generate study materials.',
                  )}
                  dataRetention={I18n.t('Data is not stored or reused by the model.')}
                  dataLogging={I18n.t('Does Not Log Data')}
                  regionsSupported={I18n.t('US')}
                  isPIIExposed={false}
                  isPIIExposedDescription={I18n.t(
                    'PII in page content may be included, but no PII is intentionally sent to the model.',
                  )}
                  isFeatureBehindSetting={true}
                  isHumanInTheLoop={true}
                  expectedRisks={I18n.t('Generated study content may be inaccurate or incomplete.')}
                  intendedOutcomes={I18n.t(
                    'Students are able to efficiently study course material through AI-generated summaries, quizzes, and flashcards.',
                  )}
                  permissionsLevel={2}
                  triggerButton={
                    <IconButton
                      size="small"
                      color="primary-inverse"
                      withBackground={false}
                      withBorder={false}
                      screenReaderLabel={I18n.t('AI information')}
                      data-testid="study-assist-ai-info-button"
                    >
                      <IconInfoLine />
                    </IconButton>
                  }
                />
              </Flex.Item>
              <Flex.Item>
                <CloseButton
                  elementRef={el => {
                    closeButtonRef.current = el
                  }}
                  onClick={onDismiss}
                  size="small"
                  color="primary-inverse"
                  screenReaderLabel={I18n.t('Close')}
                  data-testid="study-assist-close-button"
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
        {allowedPrompts.length > 0 ? (
          <AssistProvider
            fetchAssistResponse={fetchAssistResponse}
            courseId={window.ENV.COURSE_ID}
            pageId={window.ENV.WIKI_PAGE_ID}
            fileId={window.ENV.FILE_ID}
            featureSlug="canvas-lms:study-assist"
          >
            <div style={{padding: '0 1rem'}}>
              <AssistContent
                chatEnabled={false}
                showLargePrompts={true}
                onAnalyticsEvent={() => null}
                allowedPrompts={allowedPrompts}
                renderFlashCards={renderFlashCards}
              />
            </div>
          </AssistProvider>
        ) : (
          <View as="div" padding="large" textAlign="center">
            <Text color="primary-inverse" data-testid="study-assist-no-tools">
              {I18n.t('No study tools are currently available.')}
            </Text>
          </View>
        )}
      </div>
    </Tray>
  )
}
