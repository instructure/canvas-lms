/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {SimpleSelect} from '@instructure/ui-simple-select'
import type {UpdateAssessmentData} from '../types/rubric'

const I18n = createI18nScope('rubrics-assessment-tray')

type CommentLibraryProps = {
  rubricSavedComments: string[]
  criterionId: string
  setCommentText: (text: string) => void
  updateAssessmentData: (data: Partial<UpdateAssessmentData>) => void
}

export const CommentLibrary = ({
  rubricSavedComments,
  criterionId,
  setCommentText,
  updateAssessmentData,
}: CommentLibraryProps) => {
  const COMMENT_LIBRARY_FIRST_STRING = '[ Select ]'
  const COMMENT_LIBRARY_SELECT_ID = 'select-comment-initialized'

  const first = (
    <SimpleSelect.Option key="first" id={COMMENT_LIBRARY_SELECT_ID} value="">
      {COMMENT_LIBRARY_FIRST_STRING}
    </SimpleSelect.Option>
  )

  const slug = (str: string) => str.replace(/\W/g, '')

  const ellipsis = () => I18n.t('…')

  const truncate = (comment: string) =>
    comment.length > 100 ? comment.slice(0, 99) + ellipsis() : comment

  const options = rubricSavedComments.map((comment, index) => (
    <SimpleSelect.Option
      key={slug(comment).slice(-8)}
      id={`${slug(comment).slice(-6)}_${index}`}
      value={index.toString()}
      label={truncate(comment)}
      data-testid={`comment-library-option-${criterionId}-${index}`}
    >
      {truncate(comment)}
    </SimpleSelect.Option>
  ))

  return (
    <SimpleSelect
      renderLabel={false}
      assistiveText={I18n.t('Select from saved comments')}
      onChange={(_unused, el) => {
        if (el.id === COMMENT_LIBRARY_SELECT_ID) {
          return
        }
        const selectedIndex = Number.parseInt(el.value?.toString() ?? '', 10)
        const fullComment = rubricSavedComments[selectedIndex]
        setCommentText(fullComment)
        updateAssessmentData({comments: fullComment})
      }}
      key={criterionId}
      data-testid={`comment-library-${criterionId}`}
    >
      {[first, ...options]}
    </SimpleSelect>
  )
}
