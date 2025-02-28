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

import React, {type FC} from 'react'
import {Avatar} from '@instructure/ui-avatar'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import StatusPill from './StatusPill'
import {PENDING_ENROLLMENT, INACTIVE_ENROLLMENT} from '../../../util/constants'
import type {Enrollment, EnrollmentState} from '../../../types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('course_people')

export type UserLinkProps = {
  uid: string
  avatarUrl: string
  name: string
  htmlUrl: string
  pronouns: string | null
  enrollments: Enrollment[]
}

const UserLink: FC<UserLinkProps> = ({
  uid,
  avatarUrl,
  name,
  htmlUrl,
  pronouns,
  enrollments
}) => {
  const renderPronouns = () => {
    if (!pronouns) return null
    return (
      <Text fontStyle="italic" data-testid={`pronouns-user-${uid}`}>
        {'\u00A0'}({pronouns})
      </Text>
    )
  }

  // Prioritize pending over inactive state
  let enrollmentState: EnrollmentState = undefined
  if (enrollments.some(e => e.state === PENDING_ENROLLMENT)) {
    enrollmentState = PENDING_ENROLLMENT
  } else if (enrollments.some(e => e.state === INACTIVE_ENROLLMENT)) {
    enrollmentState = INACTIVE_ENROLLMENT
  }

  return (
    <Flex as="div">
      <Flex.Item>
        <Link href={htmlUrl} isWithinText={false}>
          <Avatar
            size="x-small"
            name={name}
            src={avatarUrl}
            alt={I18n.t('Avatar for %{name}', {name})}
            margin="0 x-small xxx-small 0"
            data-testid={`avatar-user-${uid}`}
          />
        </Link>
      </Flex.Item>
      <Flex.Item shouldShrink>
        <Link href={htmlUrl} isWithinText={false} data-testid={`link-user-${uid}`}>
          <Text data-testid={`name-user-${uid}`}>{name}</Text>
          {renderPronouns()}
        </Link>
        {enrollmentState && '\u00A0'}
        <StatusPill state={enrollmentState} />
      </Flex.Item>
    </Flex>
  )
}

export default UserLink
