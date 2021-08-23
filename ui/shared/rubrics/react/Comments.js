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
import PropTypes from 'prop-types'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Checkbox} from '@instructure/ui-checkbox'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import I18n from 'i18n!edit_rubricComments'

import {assessmentShape} from './types'

const ellipsis = () => I18n.t('…')

const truncate = comment => (comment.length > 100 ? comment.slice(0, 99) + ellipsis() : comment)

const slug = str => str.replace(/\W/g, '')

const FreeFormComments = props => {
  const {allowSaving, savedComments, comments, large, saveLater, setComments, setSaveLater} = props
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
      onChange={(_unused, el) => {
        setComments(savedComments[el.value])
      }}
    >
      {[first, ...options]}
    </SimpleSelect>,
    <br key="br" />
  ]

  const saveBox = () => {
    if (allowSaving && large) {
      return (
        <Checkbox
          checked={saveLater}
          label={I18n.t('Save this comment for reuse')}
          size="small"
          onChange={event => setSaveLater(event.target.checked)}
        />
      )
    }
  }

  const label = I18n.t('Comments')
  const toScreenReader = el => <ScreenReaderContent>{el}</ScreenReaderContent>

  const commentClass = `edit-freeform-comments-${large ? 'large' : 'small'}`
  return (
    <div className={commentClass}>
      {options.length > 0 ? selector : null}
      <TextArea
        data-selenium="criterion_comments_text"
        label={large ? label : toScreenReader(label)}
        placeholder={large ? undefined : label}
        maxHeight="50rem"
        onChange={e => setComments(e.target.value)}
        resize="vertical"
        size="small"
        value={comments}
      />
      {large ? <br /> : null}
      {saveBox()}
    </div>
  )
}
FreeFormComments.propTypes = {
  allowSaving: PropTypes.bool.isRequired,
  savedComments: PropTypes.arrayOf(PropTypes.string).isRequired,
  comments: PropTypes.string,
  large: PropTypes.bool.isRequired,
  saveLater: PropTypes.bool,
  setComments: PropTypes.func.isRequired,
  setSaveLater: PropTypes.func.isRequired
}
FreeFormComments.defaultProps = {
  comments: '',
  saveLater: false
}

const commentElement = assessment => {
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

export const CommentText = ({assessment, placeholder, weight}) => (
  <span className="react-rubric-break-words">
    <Text size="x-small" weight={weight}>
      {assessment !== null ? commentElement(assessment) : placeholder}
    </Text>
  </span>
)
CommentText.propTypes = {
  assessment: PropTypes.shape(assessmentShape),
  placeholder: PropTypes.string,
  weight: PropTypes.string.isRequired
}
CommentText.defaultProps = {
  assessment: null,
  placeholder: ''
}

const Comments = props => {
  const {editing, assessment, footer, ...commentProps} = props
  if (!editing || assessment === null) {
    return (
      <div className="rubric-freeform">
        <CommentText
          assessment={assessment}
          placeholder={I18n.t(
            'This area will be used by the assessor to leave comments related to this criterion.'
          )}
          weight="normal"
        />
        {footer}
      </div>
    )
  } else {
    return (
      <FreeFormComments
        comments={assessment.comments}
        saveLater={assessment.saveCommentsForLater}
        {...commentProps}
      />
    )
  }
}
Comments.propTypes = {
  allowSaving: PropTypes.bool,
  editing: PropTypes.bool.isRequired,
  assessment: PropTypes.shape(assessmentShape),
  footer: PropTypes.node,
  large: PropTypes.bool,
  savedComments: PropTypes.arrayOf(PropTypes.string).isRequired,
  setComments: PropTypes.func.isRequired,
  setSaveLater: PropTypes.func.isRequired
}
Comments.defaultProps = {
  allowSaving: true,
  footer: null,
  large: true
}

export default Comments
