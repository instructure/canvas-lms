/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {MaintainScrollPositionWhenScrollingIntoThePast} from '../index'
import {createAnimation} from './test-utils'

it('records and forwards the memo for the fixed element', () => {
  const {animation, app, animator} = createAnimation(MaintainScrollPositionWhenScrollingIntoThePast)
  app.fixedElementForItemScrolling
    .mockReturnValueOnce('scroll-past-fixed-element-first')
    .mockReturnValueOnce('scroll-past-fixed-element-second')
  animator.elementPositionMemo.mockReturnValueOnce('position-memo')
  animation.invokeUiWillUpdate()
  animation.invokeUiDidUpdate()
  expect(animator.elementPositionMemo).toHaveBeenCalledWith('scroll-past-fixed-element-first')
  expect(animator.maintainViewportPositionFromMemo).toHaveBeenCalledWith(
    'scroll-past-fixed-element-second',
    'position-memo'
  )
})
