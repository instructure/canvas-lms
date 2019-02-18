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

import React from 'react'
import NoComments from './NoComments'
import {arrayOf} from 'prop-types'
import CommentRow from './CommentRow'
import {CommentShape} from '../../assignmentData'

function CommentContent(props) {
  return (
    <div className="comments-content-container">
      {!props.comments.length && <NoComments />}
      {props.comments.map(comment => (
        <CommentRow key={comment._id} comment={comment} />
      ))}
    </div>
  )
}

CommentContent.propTypes = {
  comments: arrayOf(CommentShape).isRequired
}

export default React.memo(CommentContent)
