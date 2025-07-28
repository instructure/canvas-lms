/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {type ComponentProps, type ReactNode} from 'react'
import {Text} from '@instructure/ui-text'
import {IconWarningSolid} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import './FieldGroup.css'

type Message = {
  type: 'newError' | 'hint'
  text: string
}

export interface FieldGroupProps {
  title: string
  isRequired?: boolean
  children?: ReactNode
  messages?: Array<Message>
}

const FieldGroup = ({title, isRequired, children, messages}: FieldGroupProps) => {
  return (
    <section className="field-group">
      <Text as="h2" weight="bold" size="x-large">
        {title}
        <Text color="danger" size="x-large">
          {isRequired ? '*' : ''}
        </Text>
      </Text>
      <View as="div" margin="0 0 medium 0">
        {messages?.map(message => {
          const commonProps: ComponentProps<typeof Text> = {
            children: message.text,
            size: 'small',
          }
          const messageComponent = {
            newError: (
              <Flex gap="xx-small" key={message.text}>
                <IconWarningSolid color="error" data-testid="error-icon" />
                <Text {...commonProps} color="danger" />
              </Flex>
            ),
            hint: <Text {...commonProps} key={message.text} color="secondary" />,
          }[message.type]

          return messageComponent
        })}
      </View>
      <div>{children}</div>
    </section>
  )
}

export default FieldGroup
