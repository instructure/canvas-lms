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

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {DateTimeInput} from '@instructure/ui-date-time-input'
import {FormMessage} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('assignment_scheduled_release_policy')
const GRADES_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR = I18n.t(
  'Grades release date must be the same or after comments release date',
)
const COMMENTS_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR = I18n.t(
  'Comments release date must be the same or before grades release date',
)

type SeparateScheduledReleaseProps = {
  gradeErrorMessages: FormMessage[]
  commentErrorMessages: FormMessage[]
  postGradesAt?: string | null
  postCommentsAt?: string | null
  handleChange: (changes: Partial<SeparateScheduledReleaseProps>) => void
  handleErrorMessages: (grades: FormMessage[], comments: FormMessage[]) => void
}
export const SeparateScheduledRelease = ({
  gradeErrorMessages,
  commentErrorMessages,
  postGradesAt,
  postCommentsAt,
  handleChange,
  handleErrorMessages,
}: SeparateScheduledReleaseProps) => {
  const filterRelationshipErrors = (messages: FormMessage[]) => {
    const relationshipErrorTexts = [
      GRADES_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR,
      COMMENTS_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR,
    ]
    return messages.filter(msg => !relationshipErrorTexts.includes(msg.text))
  }

  const validateReleaseDates = (
    gradesDateString: string | null,
    commentsDateString: string | null,
    changedField: 'grades' | 'comments',
  ) => {
    const gradeMessages: FormMessage[] = []
    const commentMessages: FormMessage[] = []

    const gradesDate = gradesDateString ? new Date(gradesDateString) : null
    const commentsDate = commentsDateString ? new Date(commentsDateString) : null

    if (changedField === 'grades' && gradesDate && gradesDate < new Date()) {
      gradeMessages.push({text: I18n.t('Date must be in the future'), type: 'error'})
    }

    if (changedField === 'comments' && commentsDate && commentsDate < new Date()) {
      commentMessages.push({text: I18n.t('Date must be in the future'), type: 'error'})
    }

    if (gradesDate && commentsDate && gradesDate < commentsDate) {
      gradeMessages.push({
        text: GRADES_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR,
        type: 'error',
      })
      commentMessages.push({
        text: COMMENTS_RELEASE_DATE_RELATIONSHIP_VALIDATION_ERROR,
        type: 'error',
      })
    }

    // Preserve existing errors from the unchanged field (excluding relationship errors)
    const preservedGradeErrors =
      changedField === 'comments' ? filterRelationshipErrors(gradeErrorMessages) : []
    const preservedCommentErrors =
      changedField === 'grades' ? filterRelationshipErrors(commentErrorMessages) : []

    handleErrorMessages(
      [...preservedGradeErrors, ...gradeMessages],
      [...preservedCommentErrors, ...commentMessages],
    )
  }

  const onChangeGradeReleaseDate = (_e: React.SyntheticEvent, isoDate?: string) => {
    const messages: FormMessage[] = []
    handleChange({postGradesAt: isoDate})

    if (!isoDate) {
      messages.push({text: I18n.t('Please enter a valid date'), type: 'error'})
      handleErrorMessages(messages, filterRelationshipErrors(commentErrorMessages))
      return
    }

    validateReleaseDates(isoDate, postCommentsAt || null, 'grades')
  }

  const onChangeCommentReleaseDate = (_e: React.SyntheticEvent, isoDate?: string) => {
    const messages: FormMessage[] = []
    handleChange({postCommentsAt: isoDate})

    if (!isoDate) {
      messages.push({text: I18n.t('Please enter a valid date'), type: 'error'})
      handleErrorMessages(filterRelationshipErrors(gradeErrorMessages), messages)
      return
    }

    validateReleaseDates(postGradesAt || null, isoDate, 'comments')
  }

  return (
    <View as="div" margin="0 medium 0">
      <View as="div" margin="medium 0" data-testid="separate-scheduled-post-datetime-grade">
        <DateTimeInput
          description={<ScreenReaderContent>{I18n.t('Grades Release Date')}</ScreenReaderContent>}
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel={I18n.t('Grades Release Date')}
          timeRenderLabel={I18n.t('Time')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          onChange={onChangeGradeReleaseDate}
          layout="stacked"
          value={postGradesAt ?? undefined}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          messages={gradeErrorMessages}
          allowNonStepInput={true}
          timeStep={15}
          isRequired
        />
      </View>
      <View as="div" margin="medium 0" data-testid="separate-scheduled-post-datetime-comment">
        <DateTimeInput
          description={<ScreenReaderContent>{I18n.t('Comments Release Date')}</ScreenReaderContent>}
          datePlaceholder={I18n.t('Select Date')}
          dateRenderLabel={I18n.t('Comments Release Date')}
          timeRenderLabel={I18n.t('Time')}
          prevMonthLabel={I18n.t('Previous month')}
          nextMonthLabel={I18n.t('Next month')}
          onChange={onChangeCommentReleaseDate}
          layout="stacked"
          value={postCommentsAt ?? undefined}
          invalidDateTimeMessage={I18n.t('Invalid date!')}
          messages={commentErrorMessages}
          allowNonStepInput={true}
          timeStep={15}
          isRequired
        />
      </View>
    </View>
  )
}
