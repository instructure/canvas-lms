/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {arrayOf} from 'prop-types'
import CommentRow from './CommentRow'
import I18n from 'i18n!assignments_2'
import noComments from '../../SVG/NoComments.svg'
import React from 'react'
import {SubmissionComment} from '../../graphqlData/SubmissionComment'
import SVGWithTextPlaceholder from '../../../shared/SVGWithTextPlaceholder'

function CommentContent(props) {
  return (
    <>
      {!props.comments.length && (
        <SVGWithTextPlaceholder
          text={I18n.t('Send a comment to your instructor about this assignment.')}
          url={noComments}
        />
      )}
      {props.comments
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt))
        .map(comment => (
          <CommentRow key={comment._id} comment={comment} />
        ))}
    </>
  )
}

CommentContent.propTypes = {
  comments: arrayOf(SubmissionComment.shape).isRequired
}

export default React.memo(CommentContent)
