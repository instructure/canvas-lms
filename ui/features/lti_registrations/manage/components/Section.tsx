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
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import type {Spacing} from '@instructure/emotion'

export const Section = ({
  title,
  children,
  margin = '0 small medium small',
  subtitle,
}: {
  title?: string
  children: React.ReactNode
  margin?: Spacing
  subtitle?: React.ReactNode
}) => {
  return (
    <View
      borderRadius="large"
      borderColor="secondary"
      borderWidth="small"
      margin={margin}
      as="div"
      padding="medium"
    >
      {title ? (
        <Heading level="h3" margin="0 0 small 0">
          {title}
        </Heading>
      ) : null}
      {subtitle}
      {children}
    </View>
  )
}

export const SubSection = ({
  title,
  children,
  margin = 'small 0 0 0',
}: {
  title: string
  children?: React.ReactNode
  margin?: Spacing
}) => {
  return (
    <>
      <Heading level="h4" margin={margin}>
        {title}
      </Heading>
      {children}
    </>
  )
}
