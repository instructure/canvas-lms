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
import {usePendoTracking} from '@canvas/pendo/react/hooks/usePendoTracking'
import {useTranslation} from '@canvas/i18next'
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
  useAssistContext,
} from '@instructure/platform-study-assist'
import type {
  AssistRequest,
  AssistResponse,
  AssistChatFlashCard,
} from '@instructure/platform-study-assist'
import {IconAiSolid, IconArrowStartLine, IconInfoLine} from '@instructure/ui-icons'
import CanvasAiInformation from '@canvas/ai-information'

const GRADIENT = 'linear-gradient(135deg, #7b5ea7 0%, #5b7fa6 60%, #4a919e 100%)'

type Props = {
  open: boolean
  onDismiss: () => void
  fetchAssistResponse: (request: AssistRequest) => Promise<AssistResponse>
}

type TrayHeaderProps = {
  onDismiss: () => void
  closeButtonRef: React.MutableRefObject<Element | null>
}

function TrayHeader({onDismiss, closeButtonRef}: TrayHeaderProps) {
  const {t} = useTranslation('study_assist')
  const {showBackButton, resetChat} = useAssistContext()

  return (
    <Flex as="div" padding="small" alignItems="center">
      <Flex.Item shouldGrow={true}>
        <Flex gap="x-small" alignItems="center">
          {showBackButton && (
            <Flex.Item margin="0 x-small 0 0">
              <IconButton
                size="small"
                color="primary-inverse"
                withBackground={false}
                withBorder={true}
                screenReaderLabel={t('Back')}
                onClick={resetChat}
                data-testid="study-assist-back-button"
              >
                <IconArrowStartLine />
              </IconButton>
            </Flex.Item>
          )}
          <Flex.Item>
            <IconAiSolid />
          </Flex.Item>
          <Flex.Item>
            <Heading themeOverride={{primaryColor: 'white'}}>{t('Study tools')}</Heading>
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item>
        <Flex gap="small">
          <Flex.Item>
            <CanvasAiInformation
              title={t('Nutrition Facts')}
              privacyNoticeText={t('AI Privacy Notice')}
              featureName={t('Study Tools')}
              modelName={t('Claude 3 Haiku')}
              isTrainedWithUserData={false}
              dataSharedWithModel={t('Page')}
              dataSharedWithModelDescription={t(
                'Page content is sent to the model to generate study materials.',
              )}
              dataRetention={t('Data is not stored or reused by the model.')}
              dataLogging={t('Does Not Log Data')}
              regionsSupported={t('US')}
              isPIIExposed={false}
              isPIIExposedDescription={t(
                'PII in page content may be included, but no PII is intentionally sent to the model.',
              )}
              isFeatureBehindSetting={true}
              isHumanInTheLoop={true}
              expectedRisks={t('Generated study content may be inaccurate or incomplete.')}
              intendedOutcomes={t(
                'Students are able to efficiently study course material through AI-generated summaries, quizzes, and flashcards.',
              )}
              permissionsLevel={2}
              triggerButton={
                <IconButton
                  size="small"
                  color="primary-inverse"
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={t('AI information')}
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
              screenReaderLabel={t('Close')}
              data-testid="study-assist-close-button"
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

export default function StudyAssistTray({open, onDismiss, fetchAssistResponse}: Props) {
  const {t} = useTranslation('study_assist')
  const closeButtonRef = useRef<Element | null>(null)
  const allowedPrompts = useMemo(() => window.ENV.STUDY_ASSIST_TOOLS ?? [], [])
  const {trackEvent} = usePendoTracking()

  const handleAnalyticsEvent = useCallback(
    (event: string) => {
      trackEvent({
        eventName: `study_assist_${event}`,
        props: {type: 'track'},
      })
    },
    [trackEvent],
  )

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
          onAnalyticsEvent={handleAnalyticsEvent}
        />
      </div>
    ),
    [handleAnalyticsEvent],
  )

  return (
    <Tray
      label={t('Study tools')}
      placement="end"
      size="regular"
      open={open}
      onDismiss={onDismiss}
      defaultFocusElement={() => closeButtonRef.current}
    >
      <div
        style={{
          background: GRADIENT,
          color: 'white',
          minHeight: '100vh',
          padding: '1rem',
          boxSizing: 'border-box',
        }}
      >
        <AssistProvider
          fetchAssistResponse={fetchAssistResponse}
          courseId={window.ENV.COURSE_ID}
          pageId={window.ENV.WIKI_PAGE_ID}
          fileId={window.ENV.FILE_ID}
          featureSlug="canvas-lms:study-assist"
        >
          <TrayHeader onDismiss={onDismiss} closeButtonRef={closeButtonRef} />
          {allowedPrompts.length > 0 ? (
            <div style={{padding: '0 1rem'}}>
              <AssistContent
                chatEnabled={false}
                showLargePrompts={true}
                onAnalyticsEvent={handleAnalyticsEvent}
                allowedPrompts={allowedPrompts}
                renderFlashCards={renderFlashCards}
              />
            </div>
          ) : (
            <View as="div" padding="large" textAlign="center">
              <Text color="primary-inverse" data-testid="study-assist-no-tools">
                {t('No study tools are currently available.')}
              </Text>
            </View>
          )}
        </AssistProvider>
      </div>
    </Tray>
  )
}
