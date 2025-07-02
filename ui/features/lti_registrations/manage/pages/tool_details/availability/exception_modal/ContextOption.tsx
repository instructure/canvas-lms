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

import * as React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Spacing} from '@instructure/emotion'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {SearchableContexts} from '../../../../model/SearchableContext'
const I18n = createI18nScope('lti_registrations')

type ContextOptionProps = {
  context: SearchableContexts['accounts' | 'courses'][number]
  margin?: Spacing
}

export const ContextOption = React.memo(({context, margin}: ContextOptionProps) => {
  const {name, display_path, sis_id} = context
  const course_code = 'course_code' in context ? context.course_code : undefined
  const hasPath = display_path.length > 0
  return (
    <Flex alignItems="start" direction="column" margin={margin}>
      <Text>{name}</Text>
      <Flex.Item shouldShrink>
        <Text size="small">
          <Flex alignItems="center" gap="xx-small">
            {hasPath ? <EllipsifiedItem>{display_path.join(' / ')}</EllipsifiedItem> : undefined}
            {hasPath && (course_code || sis_id) ? <View>·</View> : undefined}
            {course_code ? (
              <EllipsifiedItem>
                <View>
                  {I18n.t('Course ID: %{course_code}', {
                    course_code: course_code,
                  })}
                </View>
              </EllipsifiedItem>
            ) : undefined}
            {sis_id && course_code ? <View>|</View> : undefined}
            {sis_id ? (
              <EllipsifiedItem>
                <View>{I18n.t('SIS ID: %{sis_id}', {sis_id: sis_id})}</View>
              </EllipsifiedItem>
            ) : undefined}
          </Flex>
        </Text>
      </Flex.Item>
    </Flex>
  )
})

const EllipsifiedItem = ({
  children,
  style,
}: {children: React.ReactNode; style?: React.CSSProperties}) => (
  <div
    style={{
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      whiteSpace: 'nowrap',
      ...style,
    }}
  >
    {children}
  </div>
)
