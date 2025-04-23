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
import {useUpdateEntry} from '../../hooks/useUpdateEntry'
import useInsightStore from '../../hooks/useInsightStore'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('discussion_insights')

type DisagreeFeedbackProps = {
  entryId: number
}

const DisagreeFeedback: React.FC<DisagreeFeedbackProps> = ({entryId}) => {
  const feedbackNotes = useInsightStore(state => state.feedbackNotes)
  const setFeedbackNotes = useInsightStore(state => state.setFeedbackNotes)
  const {loading, updateEntry} = useUpdateEntry()

  const inputRef = useRef<HTMLInputElement | null>(null)
  useEffect(() => {
    if (inputRef.current) {
      inputRef.current.focus()
    }
  }, [entryId])

  const handleSubmit = async () => {
    if (!feedbackNotes) {
      return
    }

    try {
      await updateEntry({
        entryId,
        entryFeedback: {
          action: 'dislike',
          notes: feedbackNotes,
        },
      })
      showFlashAlert({
        type: 'success',
        message: I18n.t('Thanks for your input, your explanation has been recorded!'),
      })
    } catch (_error) {
      showFlashAlert({
        type: 'error',
        message: I18n.t('We couldn’t save your explanation. Please try again.'),
      })
    }
  }

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
            value={feedbackNotes}
            onChange={e => setFeedbackNotes(e.target.value)}
            inputRef={inputElement => {
              inputRef.current = inputElement
            }}
          />
        </Flex.Item>
        <FlexItem width={'fit-content'} align="end">
          <Button id="send-insights-feedback" onClick={handleSubmit} disabled={loading}>
            {I18n.t('Send Feedback')}
          </Button>
        </FlexItem>
      </Flex>
    </Flex>
  )
}

export default DisagreeFeedback
