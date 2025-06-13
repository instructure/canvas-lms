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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {SearchableContexts} from '../../../../model/SearchableContext'
import {ContextPath} from '../ContextPath'
import {Spacing} from '@instructure/emotion'
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
          <Flex alignItems="center" as="div" gap="xx-small">
            {hasPath ? (
              <Flex.Item shouldShrink>
                <ContextPath path={display_path} />
              </Flex.Item>
            ) : undefined}
            {hasPath && (course_code || sis_id) ? <View>·</View> : undefined}
            {course_code ? (
              <Flex.Item as="div" shouldGrow>
                <View>
                  {I18n.t('Course ID: %{course_code}', {
                    course_code: course_code,
                  })}
                </View>
              </Flex.Item>
            ) : undefined}
            {sis_id && course_code ? <View>|</View> : undefined}
            {sis_id ? (
              <Flex.Item as="div" shouldGrow>
                <View>{I18n.t('SIS ID: %{sis_id}', {sis_id: sis_id})}</View>
              </Flex.Item>
            ) : undefined}
          </Flex>
        </Text>
      </Flex.Item>
    </Flex>
  )
})
