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
import React, {useEffect, useRef} from 'react'
import {Button} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'

const I18n = createI18nScope('discussion_insights')

const DisagreeFeedback = () => {
  const inputRef = useRef<HTMLInputElement | null>(null)
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.focus()
    }
  }, [])

  return (
    <Flex gap="mediumSmall" direction="column">
      <FlexItem>
        <Text size="medium">
          {I18n.t('Can you please explain why you disagree with the evaluation?')}
        </Text>
      </FlexItem>
      <Flex direction="row" gap="small">
        <Flex.Item shouldGrow shouldShrink>
          <TextInput
            renderLabel={I18n.t('Explanation')}
            id="disagree-feedback"
            placeholder={I18n.t('Start typing...')}
            inputRef={inputElement => {
              inputRef.current = inputElement
            }}
          />
        </Flex.Item>
        <FlexItem width={'fit-content'} align="end">
          <Button type="submit">{I18n.t('Send Feedback')}</Button>
        </FlexItem>
      </Flex>
    </Flex>
  )
}

export default DisagreeFeedback
