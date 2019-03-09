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
import CommentTextArea from './CommentTextArea'
import CommentContent from './CommentContent'
import {StudentAssignmentShape} from '../../assignmentData'

function Comments(props) {
  const comments = props.assignment.submissionsConnection.nodes[0].commentsConnection.nodes
  return (
    <div data-test-id="comments-container">
      <CommentTextArea />
      <CommentContent comments={comments} />
    </div>
  )
}

Comments.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(Comments)
