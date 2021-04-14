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

import {DiscussionEntry} from '../../../graphql/DiscussionEntry'
import {DiscussionThread} from '../../DiscussionThread/DiscussionThread'
import PropTypes from 'prop-types'
import React from 'react'

export const DiscussionThreadContainer = props => {
  return (
    <div
      style={{
        maxWidth: '55.625rem',
        marginTop: '1.5rem'
      }}
    >
      {props.threads?.map(r => {
        return <DiscussionThread key={`discussion-thread-${r.id}`} {...r} />
      })}
    </div>
  )
}

DiscussionThreadContainer.propTypes = {
  threads: PropTypes.arrayOf(DiscussionEntry.shape).isRequired
}

export default DiscussionThreadContainer
