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
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('accessibility_checker')

interface Props {
  nextButtonName: string
  onSkip: () => void
  onSaveAndNext: () => void
  onBack?: () => void
  onBackToStart?: () => void
  isBackDisabled?: boolean
  isSkipDisabled?: boolean
  isSaveAndNextDisabled?: boolean
  isBackToStartDisabled?: boolean
  showBackToStart?: boolean
}

const BackButton: React.FC<{onClick?: () => void; isDisabled?: boolean}> = ({
  onClick,
  isDisabled,
}) => (
  <Button
    data-testid="back-button"
    onClick={onClick}
    disabled={isDisabled}
    aria-label={I18n.t('Back to previous issue')}
  >
    {I18n.t('Back')}
  </Button>
)

const SkipButton: React.FC<{onClick?: () => void; isDisabled?: boolean}> = ({
  onClick,
  isDisabled,
}) => (
  <Button
    data-testid="skip-button"
    onClick={onClick}
    disabled={isDisabled}
    aria-label={I18n.t('Skip issue')}
  >
    {I18n.t('Skip')}
  </Button>
)

const BackToStartButton: React.FC<{onClick?: () => void; isDisabled?: boolean}> = ({
  onClick,
  isDisabled,
}) => (
  <Button
    data-testid="back-to-start-button"
    onClick={onClick}
    disabled={isDisabled}
    aria-label={I18n.t('Back to start')}
  >
    {I18n.t('Back to start')}
  </Button>
)

const Footer: React.FC<Props> = ({
  nextButtonName,
  onSkip,
  onSaveAndNext,
  onBack,
  onBackToStart,
  isBackDisabled,
  isSkipDisabled,
  isSaveAndNextDisabled,
  isBackToStartDisabled,
  showBackToStart,
}: Props) => {
  return (
    <View as="footer" background="secondary">
      <Flex justifyItems="space-between" alignItems="center" padding="small">
        <Flex.Item>
          <Flex gap="small">
            {showBackToStart ? (
              <>
                <BackToStartButton onClick={onBackToStart} isDisabled={isBackToStartDisabled} />
                <BackButton onClick={onBack} isDisabled={isBackDisabled} />
              </>
            ) : (
              <>
                <BackButton onClick={onBack} isDisabled={isBackDisabled} />
                <SkipButton onClick={onSkip} isDisabled={isSkipDisabled} />
              </>
            )}
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <Button
            data-testid="save-and-next-button"
            onClick={onSaveAndNext}
            aria-label={I18n.t('Save and Next issue')}
            color="primary"
            disabled={isSaveAndNextDisabled}
          >
            {nextButtonName}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default Footer
