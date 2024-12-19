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

import $ from 'jquery'
import 'jquery-migrate'
import Popover from 'jquery-popover'
import Outcome from '@canvas/grade-summary/backbone/models/Outcome'
import OutcomePopoverView from '../OutcomePopoverView'
import template from '@canvas/outcomes/jst/outcomePopover.handlebars'

describe('OutcomePopoverView', () => {
  let popoverView
  let container

  const createEvent = (name, options = {}) => {
    return $.Event(name, {...options, currentTarget: popoverView.el})
  }

  beforeEach(() => {
    $.screenReaderFlashMessageExclusive = jest.fn()
    jest.useFakeTimers()
    container = document.createElement('div')
    container.id = 'application'
    document.body.appendChild(container)

    popoverView = new OutcomePopoverView({
      el: $('<div data-testid="outcome-popover"><i></i></div>'),
      model: new Outcome(),
      template,
    })
  })

  afterEach(() => {
    jest.clearAllTimers()
    jest.useRealTimers()
    container.remove()
  })

  describe('#closePopover', () => {
    it('returns true when no popover exists', () => {
      expect(popoverView.popover).toBeUndefined()
      expect(popoverView.closePopover()).toBe(true)
    })

    it('closes existing popover and returns true', () => {
      popoverView.popover = new Popover(createEvent('mouseleave'), popoverView.render(), {
        verticalSide: 'bottom',
        manualOffset: 14,
      })

      expect(popoverView.popover).toBeInstanceOf(Popover)
      expect(popoverView.closePopover()).toBe(true)
      expect(popoverView.popover).toBeUndefined()
    })
  })

  describe('mouse interactions', () => {
    it('handles mouseenter event', () => {
      const openPopoverSpy = jest.spyOn(popoverView, 'openPopover')
      expect(popoverView.inside).toBeFalsy()

      popoverView.el.find('i').trigger(createEvent('mouseenter'))

      expect(openPopoverSpy).toHaveBeenCalled()
      expect(popoverView.inside).toBe(true)
    })

    it('ignores mouseleave when no popover exists', () => {
      const closePopoverSpy = jest.spyOn(popoverView, 'closePopover')
      expect(popoverView.popover).toBeUndefined()

      popoverView.el.find('i').trigger(createEvent('mouseleave'))
      jest.advanceTimersByTime(popoverView.TIMEOUT_LENGTH)

      expect(closePopoverSpy).not.toHaveBeenCalled()
    })

    it('handles mouseleave when popover exists', () => {
      popoverView.el.find('i').trigger('mouseenter')
      expect(popoverView.popover).toBeDefined()
      expect(popoverView.inside).toBe(true)

      const closePopoverSpy = jest.spyOn(popoverView, 'closePopover')
      popoverView.el.find('i').trigger(createEvent('mouseleave'))
      jest.advanceTimersByTime(popoverView.TIMEOUT_LENGTH)

      expect(closePopoverSpy).toHaveBeenCalled()
    })
  })

  describe('#openPopover', () => {
    it('creates popover and sets up graph view', () => {
      expect(popoverView.popover).toBeUndefined()

      const elementSpy = jest.spyOn(popoverView.outcomeLineGraphView, 'setElement')
      const renderSpy = jest.spyOn(popoverView.outcomeLineGraphView, 'render')

      popoverView.openPopover(createEvent('mouseenter'))

      expect(popoverView.popover).toBeInstanceOf(Popover)
      expect(elementSpy).toHaveBeenCalled()
      expect(renderSpy).toHaveBeenCalled()
    })
  })
})
