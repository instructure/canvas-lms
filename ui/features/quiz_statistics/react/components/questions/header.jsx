/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ScreenReaderContent from '@canvas/quiz-legacy-client-apps/react/components/screen_reader_content'

const I18n = useI18nScope('quiz_statistics')

const QuestionHeader = ({position = 1, responseCount = 0, participantCount = 0, questionText}) => (
  <header>
    <ScreenReaderContent tagName="h3">
      {I18n.t('question_header', 'Question %{position}', {position})}
    </ScreenReaderContent>

    {/*
      we'd like SR to read the question description after its position
    */}
    <ScreenReaderContent dangerouslySetInnerHTML={{__html: questionText}} />

    <span className="question-attempts">
      {I18n.t('attempts', 'Attempts: %{count} out of %{total}', {
        count: responseCount,
        total: participantCount,
      })}
    </span>
  </header>
)

export default QuestionHeader
