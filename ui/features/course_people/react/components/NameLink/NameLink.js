/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {string, oneOfType, arrayOf, node, func} from 'prop-types'
import {Link} from '@instructure/ui-link'

const NameLink = ({_id, htmlUrl, children, onClick}) => {
  const isCurrentUser = _id === ENV.current_user.id
  return (
    <Link
      isWithinText={false}
      as="a"
      href={isCurrentUser ? htmlUrl : null}
      onClick={isCurrentUser ? null : () => onClick()}
    >
      {children}
    </Link>
  )
}

NameLink.propTypes = {
  _id: string.isRequired,
  htmlUrl: string.isRequired,
  children: oneOfType([arrayOf(node), node]),
  onClick: func
}

NameLink.defaultProps = {
  children: null,
  onClick: () => {}
}

export default NameLink
