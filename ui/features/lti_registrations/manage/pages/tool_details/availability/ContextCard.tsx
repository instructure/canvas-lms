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
import React from 'react'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import {Heading} from '@instructure/ui-heading'

import {IconCoursesLine, IconInfoLine, IconSubaccountsLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Link} from '@instructure/ui-link'
import {renderExceptionCounts} from './renderExceptionCounts'
import {CourseId} from '../../../model/CourseId'
import {AccountId} from '../../../model/AccountId'
import {ContextPath} from './ContextPath'
import {Tag} from '@instructure/ui-tag'

const I18n = createI18nScope('lti_registrations')

export type ContextProps = {
  context_name: string
  available?: boolean
  course_id?: CourseId
  account_id?: AccountId
  path_segments?: string[]
  inherit_note: boolean
  depth?: number
  path?: string
  exception_counts?: {
    child_control_count: number
    course_count: number
    subaccount_count: number
  }
}

/**
 * Computes the border color for the context card based on
 * whether the course ID is present and path length.
 * @param courseId
 * @param pathLength
 * @returns
 */
const borderColor = (courseId: CourseId | undefined) => {
  // #C1368F Plum 50 Secondary
  // #007B86 Sea 50 Secondary
  return courseId ? '#C1368F' : '#007B86'
}

/**
 * This card will render the information pertaining
 * to a context.
 *
 * Most parameters are optional, since in some instances
 * we will show all of the context control data (like on
 * the LTI registration details page), and in others we
 * will only show the context name and path (like when the
 * user is selecting a context to create a new control).
 */
export const ContextCard = ({
  context_name,
  available,
  course_id,
  account_id,
  path_segments = [],
  inherit_note,
  depth = 0,
  exception_counts,
}: ContextProps) => {
  const marginLeft = depth * 20 + 'px'

  const contextUrl =
    typeof account_id !== 'undefined' ? `/accounts/${account_id}` : `/courses/${course_id}`

  // Generate a unique ID for this context card based on course_id or account_id
  const contextType = typeof account_id !== 'undefined' ? 'account' : 'course'
  const contextId = contextType === 'account' ? account_id : course_id
  const availabilityId =
    typeof available !== 'undefined' ? `availability-${contextType}-${contextId}` : ''
  const pathId = `path-${contextType}-${contextId}`
  const exceptionCountsId = `exceptions-${contextType}-${contextId}`
  const inheritNoteId = inherit_note ? `inherit-note-${contextType}-${contextId}` : ''

  // ariaDescribedBy is a string of IDs that reference the other elements
  // that should be read when a screenreader focuses on the name of this exception.
  // If there is a way for the referenced element to possibly not exist, make sure
  // that its ID is blank in this array (like if 'available' is undefined or
  // 'inherit_note' is false.
  const ariaDescribedBy = [availabilityId, pathId, exceptionCountsId, inheritNoteId].join(' ')

  return (
    <div style={{marginLeft}}>
      <View
        as="div"
        padding="x-small x-small x-small small"
        borderWidth="0 0 0 large"
        borderColor={borderColor(course_id)}
        focusWithin={true}
      >
        <Flex as="div">
          <Flex.Item margin="0 small 0 0" as="div">
            {typeof account_id !== 'undefined' ? (
              <IconSubaccountsLine size="x-small" />
            ) : (
              <IconCoursesLine size="x-small" />
            )}
          </Flex.Item>
          <Flex.Item as="div" shouldShrink>
            <Flex as="div" margin="0" alignItems="center">
              <Heading level="h4" margin="0 xx-small 0 0" aria-describedby={ariaDescribedBy}>
                <Text weight="bold">
                  <Link href={contextUrl} data-pendo="lti-registrations-availability-context-link">
                    {context_name}
                  </Link>
                </Text>
              </Heading>
              {typeof available !== 'undefined' ? (
                <span id={availabilityId} aria-hidden="true">
                  <Tag text={available ? I18n.t('Available') : I18n.t('Not Available')} />
                </span>
              ) : null}
            </Flex>
            <Flex.Item shouldGrow>
              {path_segments.length > 0 ? (
                <div>
                  <div aria-hidden="true">
                    <ContextPath path={path_segments} />
                  </div>
                  <ScreenReaderContent id={pathId} aria-hidden="true">
                    {I18n.t('Exists under %{path_segments}', {
                      path_segments,
                    })}
                  </ScreenReaderContent>
                </div>
              ) : null}
            </Flex.Item>
            <View as="div" margin="0" id={exceptionCountsId} aria-hidden="true">
              {exception_counts && account_id && renderExceptionCounts(exception_counts)}
            </View>
            {inherit_note && (
              <View as="div" margin="0" id={inheritNoteId} aria-hidden="true">
                <Flex alignItems="center">
                  <Flex.Item margin="0 xx-small 0 0">
                    <IconInfoLine />
                  </Flex.Item>
                  <Flex.Item>
                    {I18n.t("This exception inherits the parent's availability and has no effect.")}
                  </Flex.Item>
                </Flex>
              </View>
            )}
          </Flex.Item>
        </Flex>
      </View>
    </div>
  )
}
