/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import PropTypes, {shape, instanceOf} from 'prop-types'
import {ApolloProvider, createClient} from '@canvas/apollo'
import LibraryManager from './LibraryManager'

const client = createClient()

export default function CommentLibrary({setComment, courseId, textAreaRef, userId}) {
  return (
    <ApolloProvider client={client}>
      <LibraryManager
        setComment={setComment}
        courseId={courseId}
        textAreaRef={textAreaRef}
        userId={userId}
      />
    </ApolloProvider>
  )
}

CommentLibrary.propTypes = {
  setComment: PropTypes.func.isRequired,
  courseId: PropTypes.string.isRequired,
  textAreaRef: shape({
    current: instanceOf(Element)
  }).isRequired,
  userId: PropTypes.string.isRequired
}
