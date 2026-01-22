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
import TruncateWithTooltip from '@canvas/instui-bindings/react/TruncateWithTooltip'

const I18n = createI18nScope('lti_registrations')

type ContextOptionProps = {
  context: SearchableContexts['accounts' | 'courses'][number]
  includePath?: boolean
  icon?: React.ReactNode
  margin?: Spacing
}

export const ContextOption = React.memo(
  ({context, margin, includePath = true, icon}: ContextOptionProps) => {
    const {name, display_path, sis_id} = context
    const course_code = 'course_code' in context ? context.course_code : undefined
    const hasPath = display_path.length > 0 && includePath

    return (
      <Flex alignItems="center" direction="row" margin={margin}>
        {icon ? <Flex.Item margin="0 x-small 0 0">{icon}</Flex.Item> : undefined}
        <Flex.Item shouldGrow shouldShrink>
          <Flex alignItems="start" direction="column" as="div">
            <Flex.Item shouldShrink shouldGrow>
              <Text wrap="break-word">{name}</Text>
            </Flex.Item>
            <Flex.Item shouldShrink overflowX="hidden" width="100%">
              <Flex gap="none" wrap="wrap">
                {hasPath ? (
                  // @ts-expect-error: Flex.Item has incorrect props, maxWidth exists
                  // and works great here.
                  <Flex.Item shouldShrink maxWidth="33%">
                    <Text size="small">
                      <TruncateWithTooltip position="middle">
                        {display_path.join(' / ')}
                      </TruncateWithTooltip>
                    </Text>
                  </Flex.Item>
                ) : undefined}
                {hasPath && (course_code || sis_id) ? (
                  <Flex.Item padding="0 xx-small">
                    <Text size="small">·</Text>
                  </Flex.Item>
                ) : undefined}
                {course_code ? (
                  // @ts-expect-error: Flex.Item has incorrect props, maxWidth exists
                  // and works great here.
                  <Flex.Item shouldShrink maxWidth="33%">
                    <Text size="small">
                      <TruncateWithTooltip position="middle">
                        {I18n.t('Course Code: %{course_code}', {
                          course_code: course_code,
                        })}
                      </TruncateWithTooltip>
                    </Text>
                  </Flex.Item>
                ) : undefined}
                {sis_id && course_code ? (
                  <Flex.Item padding="0 xx-small">
                    <Text size="small">·</Text>
                  </Flex.Item>
                ) : undefined}
                {sis_id ? (
                  // @ts-expect-error: Flex.Item has incorrect props, maxWidth exists
                  // and works great here.
                  <Flex.Item shouldShrink maxWidth="33%">
                    <Text size="small">
                      <TruncateWithTooltip position="middle">
                        {I18n.t('SIS ID: %{sis_id}', {sis_id: sis_id})}
                      </TruncateWithTooltip>
                    </Text>
                  </Flex.Item>
                ) : undefined}
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    )
  },
)
