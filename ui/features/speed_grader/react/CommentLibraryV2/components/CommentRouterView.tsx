/* eslint-disable react/prop-types */
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

import {useState} from 'react'
import CommentReadView from './CommentReadView'
import CommentEditView from './CommentEditView'

export type CommentRouterViewProps = {
  comment: string
  index: number
  id: string
  onClick: () => void
}
const CommentRouterView: React.FC<CommentRouterViewProps> = ({comment, id, ...props}) => {
  const [isEditing, setIsEditing] = useState(false)

  if (isEditing) {
    return <CommentEditView id={id} initialValue={comment} onClose={() => setIsEditing(false)} />
  }
  return <CommentReadView id={id} comment={comment} setIsEditing={setIsEditing} {...props} />
}

export default CommentRouterView
