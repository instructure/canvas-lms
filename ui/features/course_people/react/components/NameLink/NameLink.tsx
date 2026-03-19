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
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import '@canvas/context-cards/react/StudentContextCardTrigger'
import {STUDENT_ENROLLMENT} from '../../../util/constants'

interface Enrollment {
  type: string
}

interface NameLinkProps {
  studentId: string
  htmlUrl: string
  name: string
  pronouns?: string | null
  enrollments: Enrollment[]
}

const NameLink: React.FC<NameLinkProps> = ({studentId, htmlUrl, name, pronouns, enrollments}) => {
  const formatPronouns = (pronounString?: string | null) => {
    if (!pronounString) return ''
    return <Text fontStyle="italic" data-testid="user-pronouns">{` (${pronounString})`}</Text>
  }

  return (
    // InstUI components remove className props so we wrap our component with a span
    // to get the StudentContextCardTrigger to trigger when the link is clicked
    <span
      className={
        enrollments.some(enrollment => enrollment.type === STUDENT_ENROLLMENT)
          ? 'student_context_card_trigger'
          : ''
      }
      data-student_id={studentId}
      data-course_id={ENV.course?.id}
    >
      <Link isWithinText={false} href={htmlUrl} margin="0 x-small 0 0">
        <Text wrap="break-word">{name}</Text>
        {formatPronouns(pronouns)}
      </Link>
    </span>
  )
}

export default NameLink
