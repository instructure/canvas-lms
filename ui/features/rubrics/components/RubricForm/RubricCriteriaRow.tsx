/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Pill} from '@instructure/ui-pill'
import {IconButton} from '@instructure/ui-buttons'
import {
  IconDragHandleLine,
  IconDuplicateLine,
  IconEditLine,
  IconTrashLine,
} from '@instructure/ui-icons'

export const RubricCriteriaRow = () => {
  return (
    <>
      <Flex>
        <Flex.Item align="start">
          <Text weight="bold">1.</Text>
        </Flex.Item>
        <Flex.Item margin="0 small" align="start" shouldGrow={true}>
          <View as="div">
            <Tag
              text={
                <AccessibleContent alt="Remove outcome">
                  <Text>FA.V.CR.1</Text>
                </AccessibleContent>
              }
              size="small"
              dismissible={true}
              onClick={() => {}}
              themeOverride={{
                defaultBackground: 'white',
                defaultBorderColor: 'rgb(3, 116, 181)',
                defaultColor: 'rgb(3, 116, 181)',
              }}
            />
          </View>
          <View as="div" margin="small 0 0 0">
            <Text weight="bold">Effective Use of Space</Text>
          </View>
          <View as="div">
            <Text>
              Great use of space to show depth with use of foreground, middleground, and background.{' '}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item align="start">
          <Pill
            color="info"
            margin="0 large 0 0"
            disabled={true}
            themeOverride={{
              background: 'rgb(3, 116, 181)',
              infoColor: 'white',
            }}
          >
            <Text size="x-small">10 pts</Text>
          </Pill>
          <IconButton withBackground={false} withBorder={false} screenReaderLabel="" size="small">
            <IconDragHandleLine />
          </IconButton>
          <IconButton withBackground={false} withBorder={false} screenReaderLabel="" size="small">
            <IconEditLine />
          </IconButton>
          <IconButton withBackground={false} withBorder={false} screenReaderLabel="" size="small">
            <IconTrashLine />
          </IconButton>
          <IconButton withBackground={false} withBorder={false} screenReaderLabel="" size="small">
            <IconDuplicateLine />
          </IconButton>
        </Flex.Item>
      </Flex>

      <View as="hr" margin="medium 0 small 0" />
    </>
  )
}
