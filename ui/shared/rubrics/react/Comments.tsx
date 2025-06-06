/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import type {ReactNode} from 'react'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('edit_rubricComments')

const ellipsis = () => I18n.t('…')

const truncate = (comment: string) =>
  comment.length > 100 ? comment.slice(0, 99) + ellipsis() : comment

const slug = (str: string) => str.replace(/\W/g, '')

interface Assessment {
  criterion_id: string
  comments?: string
  comments_html?: string
  points: {
    text?: string
    value?: number
    valid?: boolean
  }
  focusPoints?: number
  saveCommentsForLater?: boolean
}

interface FreeFormCommentsProps {
  allowSaving: boolean
  savedComments: string[]
  comments?: string
  large: boolean
  saveLater?: boolean
  setComments: (comments: string) => void
  setSaveLater: (saveLater: boolean) => void
}

const FreeFormComments = ({
  allowSaving,
  savedComments,
  comments = '',
  large,
  saveLater = false,
  setComments,
  setSaveLater,
}: FreeFormCommentsProps) => {
  const first = (
    <SimpleSelect.Option key="first" id="first" value="first">
      {I18n.t('[ Select ]')}
    </SimpleSelect.Option>
  )

  const options = savedComments.map((comment, ix) => (
    <SimpleSelect.Option
      key={slug(comment).slice(-8)}
      id={`${slug(comment).slice(-6)}_${ix}`}
      value={ix.toString()}
      label={comment}
    >
      {truncate(comment)}
    </SimpleSelect.Option>
  ))
  const selector = [
    <SimpleSelect
      renderLabel={I18n.t('Saved Comments')}
      assistiveText={I18n.t('Select from saved comments')}
      onChange={(_unused: any, el: any) => {
        setComments(savedComments[el.value])
      }}
      key="simple-select"
    >
      {[first, ...options]}
    </SimpleSelect>,
    <br key="br" />,
  ]

  const saveBox = () => {
    if (allowSaving && large) {
      return (
        <Checkbox
          checked={saveLater}
          label={I18n.t('Save this comment for reuse')}
          size="small"
          onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
            setSaveLater(event.target.checked)
          }
        />
      )
    }
  }

  const label = I18n.t('Comments')
  const toScreenReader = (el: string) => <ScreenReaderContent>{el}</ScreenReaderContent>

  const commentClass = `rubric-comment edit-freeform-comments-${large ? 'large' : 'small'}`
  return (
    <div className={commentClass}>
      {options.length > 0 ? selector : null}
      <TextArea
        data-selenium="criterion_comments_text"
        label={large ? label : toScreenReader(label)}
        placeholder={large ? undefined : label}
        maxHeight="50rem"
        onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => setComments(e.target.value)}
        resize="vertical"
        size="small"
        value={comments}
      />
      {large ? <br /> : null}
      {saveBox()}
    </div>
  )
}

const commentElement = (assessment: Assessment) => {
  if (assessment.comments_html || assessment.comments) {
    return (
      <div>
        <Text size="small" weight="bold">
          {I18n.t('Comments')}
        </Text>
        {assessment.comments_html ? (
          <div dangerouslySetInnerHTML={{__html: assessment.comments_html}} />
        ) : (
          <div>{assessment.comments}</div>
        )}
      </div>
    )
  } else {
    return null
  }
}

interface CommentTextProps {
  assessment?: Assessment | null
  placeholder?: string
  weight: 'normal' | 'light' | 'bold'
}

export const CommentText = ({assessment = null, placeholder = '', weight}: CommentTextProps) => (
  <span className="react-rubric-break-words">
    <Text size="x-small" weight={weight}>
      {assessment !== null ? commentElement(assessment) : placeholder}
    </Text>
  </span>
)

interface CommentsProps {
  allowSaving?: boolean
  editing: boolean
  assessment?: Assessment | null
  footer?: ReactNode
  large?: boolean
  savedComments: string[]
  setComments: (comments: string) => void
  setSaveLater: (saveLater: boolean) => void
}

const Comments = ({
  allowSaving = true,
  editing,
  assessment,
  footer = null,
  large = true,
  savedComments,
  setComments,
  setSaveLater,
}: CommentsProps) => {
  if (!editing || assessment === null) {
    return (
      <div className="rubric-freeform">
        <CommentText
          assessment={assessment}
          placeholder={I18n.t(
            'This area will be used by the assessor to leave comments related to this criterion.',
          )}
          weight="normal"
        />
        {footer}
      </div>
    )
  } else {
    return (
      <FreeFormComments
        comments={assessment?.comments}
        saveLater={assessment?.saveCommentsForLater}
        allowSaving={allowSaving}
        savedComments={savedComments}
        large={large}
        setComments={setComments}
        setSaveLater={setSaveLater}
      />
    )
  }
}

export default Comments
