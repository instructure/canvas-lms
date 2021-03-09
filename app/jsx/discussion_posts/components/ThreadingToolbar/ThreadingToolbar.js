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

import PropTypes from 'prop-types'
import React from 'react'
import {Flex} from '@instructure/ui-flex'
import {Reply} from './Reply'
import {Like} from './Like'
import {Expansion} from './Expansion'

export function ThreadingToolbar({...props}) {
  return (
    <Flex>
      {React.Children.map(props.children, c => (
        <Flex.Item margin="0 xx-small">{c}</Flex.Item>
      ))}
    </Flex>
  )
}

ThreadingToolbar.propTypes = {
  children: PropTypes.arrayOf(PropTypes.node)
}

ThreadingToolbar.Reply = Reply
ThreadingToolbar.Like = Like
ThreadingToolbar.Expansion = Expansion

export default ThreadingToolbar
