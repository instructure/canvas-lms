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
import {string, func} from 'prop-types'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

const NameLink = ({_id, htmlUrl, name, pronouns, onClick}) => {
  const isCurrentUser = _id === ENV.current_user.id
  const formatPronouns = pronounString => {
    if (pronounString === null) return ''
    return <Text fontStyle="italic" data-testid="user-pronouns">{` (${pronounString})`}</Text>
  }

  return (
    <Link
      isWithinText={false}
      as="a"
      href={isCurrentUser ? htmlUrl : null}
      onClick={isCurrentUser ? null : () => onClick()}
      margin="0 x-small 0 0"
    >
      {name}
      {formatPronouns(pronouns)}
    </Link>
  )
}

NameLink.propTypes = {
  _id: string.isRequired,
  htmlUrl: string.isRequired,
  name: string.isRequired,
  pronouns: string,
  onClick: func
}

NameLink.defaultProps = {
  pronouns: null,
  onClick: () => {}
}

export default NameLink
