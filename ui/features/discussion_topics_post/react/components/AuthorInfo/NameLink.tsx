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
import {UserType, AuthorInfoProps} from './AuthorInfo'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {SearchSpan} from '../SearchSpan/SearchSpan'
import theme from '@instructure/ui-themes'
import {getDisplayName} from '../../utils'
import {htmlEscape} from '@instructure/html-escape'

interface NameLinkProps {
  userType: string
  user?: UserType
  searchTerm?: string
  mobileOnly?: boolean
  authorNameTextSize?: string
  discussionEntryProps?: AuthorInfoProps
}

const NameLink = (props: NameLinkProps) => {
  let classnames = ''
  if (props.user?.courseRoles?.includes('StudentEnrollment'))
    classnames = 'student_context_card_trigger'
  if (props.mobileOnly) classnames += ' author_post'

  return (
    <div
      className={classnames}
      style={
        props.userType === 'author'
          ? {
              marginBottom: props.mobileOnly ? '0' : '0.3rem',
              marginTop: props.mobileOnly ? '0' : theme.spacing.xxSmall,
              marginLeft: theme.spacing.xxSmall,
              display: 'inline-block',
            }
          : {display: 'inline'}
      }
      data-testid={`student_context_card_trigger_container_${props.userType}`}
      data-student_id={props.user?._id}
      data-course_id={ENV.course_id}
    >
      <Link href={props.user?.htmlUrl} isWithinText={false} themeOverride={{fontWeight: 700}}>
        {props.userType === 'author' ? (
          <>
            <SearchSpan
              isSplitView={props.discussionEntryProps?.isSplitView}
              searchTerm={props.searchTerm}
              htmlBody={htmlEscape(getDisplayName(props.discussionEntryProps))}
            />
            {props.user?.pronouns && (
              <Text
                lineHeight="condensed"
                size={props.authorNameTextSize as any}
                fontStyle="italic"
                data-testid="author-pronouns"
              >
                &nbsp;({props.user?.pronouns})
              </Text>
            )}
          </>
        ) : (
          props.user?.displayName
        )}
      </Link>
    </div>
  )
}

export {NameLink}
