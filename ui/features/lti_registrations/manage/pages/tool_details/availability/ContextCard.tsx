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
import {Text} from '@instructure/ui-text'
import {renderExceptionCounts} from './renderExceptionCounts'
import {CourseId} from '../../../model/CourseId'
import {AccountId} from '../../../model/AccountId'
import {ContextPath} from './ContextPath'

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
const borderColor = (courseId: CourseId | undefined, pathLength: number) => {
  if (typeof courseId !== 'undefined') {
    return '#B45310' // #B45310 Copper 50 Secondary
  } else if (pathLength > 0) {
    return '#C1368F' // #C1368F Plum 50 Secondary
  } else {
    return '#007B86' // #007B86 Sea 50 Secondary
  }
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
  const pathLength = path_segments?.length || 0
  const marginLeft = depth * 20 + 'px'

  return (
    <div style={{marginLeft}}>
      <View
        as="div"
        padding="x-small x-small x-small small"
        borderWidth="0 0 0 large"
        borderColor={borderColor(course_id, pathLength)}
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
              <Heading level="h4" margin="0 small 0 0">
                <Text weight="bold">{context_name}</Text>
              </Heading>
              {typeof available !== 'undefined' ? (
                <Pill color="primary" margin="0 0 0 small">
                  {available ? I18n.t('Available') : I18n.t('Unavailable')}
                </Pill>
              ) : null}
            </Flex>
            <Flex.Item shouldGrow>
              <ContextPath path={path_segments} />
            </Flex.Item>
            <View as="div" margin="0">
              {exception_counts && renderExceptionCounts(exception_counts)}
            </View>
            {inherit_note && (
              <View as="div" margin="0">
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
