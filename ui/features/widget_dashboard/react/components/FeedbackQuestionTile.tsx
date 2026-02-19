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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('widget_dashboard')

const FEEDBACK_QUESTIONS = [
  {
    question: I18n.t('What do you think of the new dashboard?'),
    linkText: I18n.t('Let us know!'),
  },
  {
    question: I18n.t('Have an idea for a new widget?'),
    linkText: I18n.t('Let us know!'),
  },
  {
    question: I18n.t('What would make this dashboard better?'),
    linkText: I18n.t('Please share your feedback!'),
  },
]

const FEEDBACK_FORM_URL =
  'https://docs.google.com/forms/d/e/1FAIpQLSfy8bDc50ay-KfdBZmt-SwP7yKOHIjNaVobHMOwFHDzfB7OXw/viewform?usp=header'

const FeedbackQuestionTile: React.FC = () => {
  const selectedQuestion = useMemo(() => {
    const sessionKey = 'feedback_question_index'
    const storedIndex = sessionStorage.getItem(sessionKey)

    let currentIndex: number
    if (storedIndex === null) {
      currentIndex = 0
    } else {
      currentIndex = (Number(storedIndex) + 1) % FEEDBACK_QUESTIONS.length
    }

    sessionStorage.setItem(sessionKey, String(currentIndex))
    return FEEDBACK_QUESTIONS[currentIndex]
  }, [])

  return (
    <View
      as="div"
      padding="small medium"
      background="primary"
      borderRadius="medium"
      shadow="resting"
      data-testid="feedback-question-tile"
    >
      <Flex direction="column" alignItems="center" gap="x-small">
        <Flex.Item>
          <Text as="div" weight="normal" size="medium">
            {selectedQuestion.question}
          </Text>
        </Flex.Item>
        <Flex.Item overflowY="visible">
          <Link
            href={FEEDBACK_FORM_URL}
            isWithinText={false}
            target="_blank"
            renderIcon={null}
            data-testid="feedback-question-link"
          >
            {selectedQuestion.linkText}
          </Link>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default FeedbackQuestionTile
