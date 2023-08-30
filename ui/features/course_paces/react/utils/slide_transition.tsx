/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Transition} from '@instructure/ui-motion'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'

interface ComponentProps {
  readonly children: any
  readonly direction: 'horizontal' | 'vertical'
  readonly expanded: boolean
  readonly size: string | number
}

const SlideTransition = ({children, direction, expanded, size}: ComponentProps) => {
  const horizontalProps =
    direction === 'horizontal'
      ? {
          as: 'span' as ViewProps['as'],
          width: expanded ? size : '0',
        }
      : {}
  const verticalProps =
    direction === 'vertical'
      ? {
          as: 'div' as ViewProps['as'],
          maxHeight: expanded ? size : '0',
        }
      : {}

  return (
    <View
      className="course-paces-collapse"
      data-testid="course-paces-collapse"
      {...horizontalProps}
      {...verticalProps}
    >
      <Transition
        in={expanded}
        type="fade"
        unmountOnExit={true}
        themeOverride={{duration: '500ms'}}
      >
        {children}
      </Transition>
    </View>
  )
}

export default SlideTransition
