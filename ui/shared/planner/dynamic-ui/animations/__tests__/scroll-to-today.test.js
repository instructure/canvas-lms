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

import MockDate from 'mockdate'
import moment from 'moment-timezone'
import {initialize} from '../../../utilities/alertUtils'
import {ScrollToToday, JumpScrollToToday} from '../scroll-to-today'
import {createAnimation, mockRegistryEntry} from './test-utils'

const TZ = 'Asia/Tokyo'
const today = moment.tz('2018-04-15T12:00:00', TZ)
const successalert = jest.fn()
const srAlert = jest.fn()
const pastMessage = 'Nothing planned today. Selecting most recent item.'
const futureMessage = 'Nothing planned today. Selecting next item.'
const nothingTodayMessage = 'There is nothing planned for today.'

beforeAll(() => {
  MockDate.set(today, TZ)
  initialize({
    visualSuccessCallback: successalert,
    visualErrorCallback: jest.fn(),
    srAlertCallback: srAlert,
  })
})
afterAll(() => {
  MockDate.reset()
})
beforeEach(() => {
  successalert.mockReset()
  jest.clearAllMocks()
})

describe('scrollToToday', () => {
  describe('items are in the planner', () => {
    it('scrolls when today is in the DOM', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalled()
      expect(animator.scrollToTop).not.toHaveBeenCalled()
      expect(store.dispatch).not.toHaveBeenCalled()
    })

    it('scrolls to the top when it cannot find today', () => {
      const {animation, animator, store, registry} = createAnimation(ScrollToToday)
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.scrollTo).not.toHaveBeenCalled()
      expect(animator.scrollToTop).toHaveBeenCalled()
    })

    it('focuses on the first item due today', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable')
    })

    it('focuses on next item if none today', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [
        mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ).add(1, 'day')), // in the future
      ]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(successalert).toHaveBeenCalledWith(futureMessage)
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable')
    })

    it('focuses on previous item if none today or after', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [
        mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ).add(-1, 'day')), // in the past
      ]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(successalert).toHaveBeenCalledWith(pastMessage)
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable')
    })

    it('focuses on future item even if past item is closer', () => {
      const some_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return some_elem
      }
      const mockRegistryEntries = [
        mockRegistryEntry('past-item', 'p1', moment.tz(today, TZ).add(-1, 'day')), // in the past
        mockRegistryEntry('some-item', 'f1', moment.tz(today, TZ).add(10, 'day')), // way in the future
      ]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(some_elem)
      mockRegistryEntries[1].component.getScrollable.mockReturnValue(some_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(successalert).toHaveBeenCalledWith(futureMessage)
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('f1-focusable')
    })

    it('ignores items w/o a date', () => {
      successalert.mockReset()
      const some_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return some_elem
      }
      const mockRegistryEntries = [
        mockRegistryEntry('past-item', 'p1', moment.tz(today, TZ).add(-1, 'day')), // in the past
        mockRegistryEntry('some-item', 'f1', undefined),
      ]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(some_elem)
      mockRegistryEntries[1].component.getScrollable.mockReturnValue(some_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(successalert).toHaveBeenCalledWith(pastMessage)
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('p1-focusable')
    })
  })

  describe('items require loading', () => {
    it('scrolls to top and dispatches loadPastUntilToday', () => {
      const {animation, animator, store} = createAnimation(ScrollToToday)
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.scrollToTop).toHaveBeenCalled()
      expect(store.dispatch).toHaveBeenCalled()
    })
  })

  describe('there are no items', () => {
    it('leaves focus on the Today button', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      registry.getAllItemsSorted.mockReturnValue([])
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.focusElement).not.toHaveBeenCalled()
    })
  })

  describe('when there is no component', () => {
    it('leaves focus on the Today button', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      registry.getAllItemsSorted.mockReturnValue([{}])
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.focusElement).not.toHaveBeenCalled()
    })
  })

  describe('when there is no component.focusable', () => {
    it('leaves focus on the Today button', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      mockRegistryEntries[0].component.getFocusable = jest.fn(() => undefined)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.focusElement).not.toHaveBeenCalled()
    })
  })

  describe('in weekly planner mode', () => {
    describe('when there are no items today', () => {
      it('leaves focus where it is', () => {
        const today_elem = {}
        const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
        manager.getDocument().querySelector = () => today_elem
        manager.getDocument().getElementById = id => {
          return id === 'MissingAssignments' ? 'missing items' : 'weekly header'
        }
        registry.getAllItemsSorted.mockReturnValue([])
        store.getState.mockReturnValue({
          timeZone: TZ,
        })
        animation.acceptAction({type: 'SCROLL_TO_TODAY', payload: {isWeekly: true}})
        animation.uiDidUpdate()
        expect(srAlert).toHaveBeenCalledWith(nothingTodayMessage)
        expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
        expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
        expect(animator.focusElement).not.toHaveBeenCalledWith('missing items')
        expect(animator.focusElement).not.toHaveBeenCalledWith('weekly header')
      })
    })

    describe('when there are items today, but the action specifies focusing on missing items instead', () => {
      it('focuses on missing items', () => {
        const today_elem = {}
        const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
        manager.getDocument().querySelector = function () {
          return today_elem
        }
        manager.getDocument().getElementById = function () {
          return 'missing items'
        }
        const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
        mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
        registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
        store.getState.mockReturnValue({
          timeZone: TZ,
        })
        animation.acceptAction({
          type: 'SCROLL_TO_TODAY',
          payload: {focusTarget: 'missing-items', isWeekly: true},
        })
        animation.uiDidUpdate()
        expect(srAlert).not.toHaveBeenCalledWith(nothingTodayMessage)
        expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
        expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
        expect(animator.focusElement).toHaveBeenCalledWith('missing items')
      })
    })
  })

  describe('when there are items today, and the action specifies focusing on today', () => {
    it('focuses on the first item due today', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(ScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({
        type: 'SCROLL_TO_TODAY',
        payload: {focusTarget: 'today', isWeekly: true},
      })

      animation.uiDidUpdate()
      expect(animator.forceScrollTo).toHaveBeenCalledTimes(1)
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalledTimes(1)
      expect(animator.focusElement).toHaveBeenCalledWith('i1-focusable')
    })
  })

  describe('JumpScrollToToday', () => {
    // This is the same logic as scrollToToday, but responding to a different action
    // let's just test the basics
    it('scrolls when today is in the DOM', () => {
      const today_elem = {}
      const {animation, animator, store, registry, manager} = createAnimation(JumpScrollToToday)
      manager.getDocument().querySelector = function () {
        return today_elem
      }
      const mockRegistryEntries = [mockRegistryEntry('some-item', 'i1', moment.tz(today, TZ))]
      mockRegistryEntries[0].component.getScrollable.mockReturnValue(today_elem)
      registry.getAllItemsSorted.mockReturnValue(mockRegistryEntries)
      store.getState.mockReturnValue({
        timeZone: TZ,
      })
      animation.acceptAction({type: 'JUMP_TO_THIS_WEEK', payload: {}})

      animation.uiDidUpdate()
      expect(animator.forceScrollTo.mock.calls[0][0]).toEqual(today_elem)
      expect(animator.scrollTo).toHaveBeenCalled()
      expect(animator.scrollToTop).not.toHaveBeenCalled()
      expect(store.dispatch).not.toHaveBeenCalled()
    })
  })
})
