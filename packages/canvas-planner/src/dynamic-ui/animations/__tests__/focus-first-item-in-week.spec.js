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

import {initialize} from '../../../utilities/alertUtils'
import {FocusFirstItemOnWeekLoad, FocusFirstItemOnWeekJump} from '../focus-first-item-in-week'
import {createAnimation, mockComponent} from './test-utils'

const srAlertFunc = jest.fn()
initialize({srAlertCallback: srAlertFunc})

beforeEach(() => {
  srAlertFunc.mockReset()
})

describe('FocusFirstItemOnWeekLoad', () => {
  it('does nothing if on initial load', () => {
    const {animation} = createAnimation(FocusFirstItemOnWeekLoad)
    animation.focusFirstItem = jest.fn()
    animation.acceptAction({type: 'WEEK_LOADED', payload: {initialWeeklyLoad: true}})
    animation.uiDidUpdate()
    expect(animation.focusFirstItem).not.toHaveBeenCalled()
  })

  it('does something if not initial load', () => {
    const {animation} = createAnimation(FocusFirstItemOnWeekLoad)
    animation.focusFirstItem = jest.fn()
    animation.acceptAction({
      type: 'WEEK_LOADED',
      payload: {weekDays: ['day1']}
    })
    animation.uiDidUpdate()
    expect(animation.focusFirstItem).toHaveBeenCalledWith(['day1'], true)
  })

  it('focuses on the first item on the first day', () => {
    const days = [
      ['3000-03-29T12:00:00Z', [{uniqueId: 'assignmen-17'}, {uniqueId: 'does-not-matter'}]]
    ]
    const component = mockComponent('first', '3000-03-29T12:00:00Z')
    const {animation, animator, registry} = createAnimation(FocusFirstItemOnWeekLoad)
    registry.getComponent.mockReturnValue({component})
    animator.scrollToTop = fn => fn()
    animation.acceptAction({
      type: 'WEEK_LOADED',
      payload: {weekDays: days, initialWeeklyLoad: false}
    })
    animation.uiDidUpdate()
    expect(animator.focusElement).toHaveBeenCalledWith(component.getFocusable())
    expect(srAlertFunc).toHaveBeenCalledWith('Course X Assignment due Saturday')
  })
})

describe('FocusFirstItemOnWeekJump', () => {
  it('forwards JUMP_TO_WEEK payload to helper function', () => {
    const {animation} = createAnimation(FocusFirstItemOnWeekJump)
    animation.focusFirstItem = jest.fn()
    animation.acceptAction({
      type: 'JUMP_TO_WEEK',
      payload: {weekDays: ['day1']}
    })
    animation.uiDidUpdate()
    expect(animation.focusFirstItem).toHaveBeenCalledWith(['day1'])
  })

  it('focuses on the first item on the first day', () => {
    const days = [
      ['3000-03-29T12:00:00Z', [{uniqueId: 'assignmen-17'}, {uniqueId: 'does-not-matter'}]]
    ]
    const component = mockComponent('first', '3000-03-29T12:00:00Z')
    const {animation, animator, registry} = createAnimation(FocusFirstItemOnWeekJump)
    registry.getComponent.mockReturnValue({component})
    animator.scrollToTop = fn => fn()
    animation.acceptAction({
      type: 'JUMP_TO_WEEK',
      payload: {weekDays: days}
    })
    animation.uiDidUpdate()
    expect(animator.focusElement).toHaveBeenCalledWith(component.getFocusable())
    expect(srAlertFunc).toHaveBeenCalledWith('Course X Assignment due Saturday')
  })
})
