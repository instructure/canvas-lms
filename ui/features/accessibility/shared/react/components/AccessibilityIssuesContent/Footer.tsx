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
  isBackDisabled?: boolean
  isSkipDisabled?: boolean
  isSaveAndNextDisabled?: boolean
}

const Footer: React.FC<Props> = ({
  nextButtonName,
  onSkip,
  onSaveAndNext,
  onBack,
  isBackDisabled,
  isSkipDisabled,
  isSaveAndNextDisabled,
}: Props) => {
  return (
    <View as="footer" background="secondary">
      <Flex justifyItems="space-between" alignItems="center" padding="small">
        <Flex.Item>
          <Flex gap="small">
            <Button data-testid="back-button" onClick={onBack} disabled={isBackDisabled}>
              {I18n.t('Back')}
            </Button>
            <Button data-testid="skip-button" onClick={onSkip} disabled={isSkipDisabled}>
              {I18n.t('Skip')}
            </Button>
          </Flex>
        </Flex.Item>

        <Flex.Item>
          <Button
            data-testid="save-and-next-button"
            onClick={onSaveAndNext}
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
