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

import '@canvas/files/mockFilesENV'
import Folder from '@canvas/files/backbone/models/Folder'
import RestrictedDialogForm from '@canvas/files/react/components/RestrictedDialogForm'
import {mergeTimeAndDate} from '@instructure/moment-utils'
import {fireEvent, render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'

describe('RestrictedDialogForm', () => {
  const defaultProps = {
    models: [],
    closeDialog: () => {},
    usageRightsRequiredForContext: false,
  }

  const renderComponent = (props = {}) => {
    return render(<RestrictedDialogForm {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    // Mock jQuery plugins
    const $ = require('jquery')
    $.fn.disableWhileLoading = jest.fn()
    $.fn.errorBox = jest.fn()
    $.when = jest.fn(() => ({
      done: callback => {
        callback()
        return {fail: jest.fn()}
      },
    }))
    $.fn.data = jest.fn()
    $.fn.val = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('with multiple selected items', () => {
    it('enables button when an option is selected', () => {
      const props = {
        models: [
          new Folder({
            id: 1000,
            hidden: false,
          }),
          new Folder({
            id: 999,
            hidden: true,
          }),
        ],
      }

      renderComponent(props)

      const updateButton = screen.getByText('Update')
      expect(updateButton).toBeDisabled()

      const publishInput = screen.getByLabelText('Publish')
      fireEvent.click(publishInput)
      fireEvent.change(publishInput, {target: {checked: true}})

      expect(updateButton).toBeEnabled()
    })
  })

  describe('form submission', () => {
    it('calls save with only hidden if calendarOption is false', () => {
      const folder = new Folder({
        id: 999,
        hidden: true,
        lock_at: undefined,
        unlock_at: undefined,
      })
      const saveSpy = jest.spyOn(folder, 'save')
      const props = {
        models: [folder],
      }

      renderComponent(props)

      const onlyAvailableWithLink = screen.getByLabelText('Only available with link')
      const form = screen.getByTestId('restricted-access-form')

      fireEvent.click(onlyAvailableWithLink)
      fireEvent.change(onlyAvailableWithLink, {target: {checked: true}})

      fireEvent.submit(form)

      expect(saveSpy).toHaveBeenCalledWith(
        {},
        {attrs: {hidden: true, lock_at: '', unlock_at: '', locked: false}},
      )
    })

    it('calls save with calendar dates when date range is selected', () => {
      const folder = new Folder({
        id: 999,
        hidden: true,
        lock_at: undefined,
        unlock_at: undefined,
      })
      const saveSpy = jest.spyOn(folder, 'save')
      const props = {
        models: [folder],
      }

      renderComponent(props)

      const scheduleOption = screen.getByLabelText('Schedule availability')
      fireEvent.click(scheduleOption)
      fireEvent.change(scheduleOption, {target: {checked: true}})

      // Set dates and times
      const startDate = new Date(2016, 5, 1)
      const endDate = new Date(2016, 5, 4)
      const unlockAtDate = screen.getByLabelText('Available From Date')
      const unlockAtTime = screen.getByLabelText('Available From Time')
      const lockAtDate = screen.getByLabelText('Available Until Date')
      const lockAtTime = screen.getByLabelText('Available Until Time')

      const $ = require('jquery')
      $.fn.data = jest.fn(function (key) {
        if (key === 'unfudged-date') {
          if (this[0] === unlockAtDate) return startDate
          if (this[0] === lockAtDate) return endDate
        }
        return undefined
      })
      $.fn.val = jest.fn(function () {
        if (this[0] === unlockAtTime) return '5 AM'
        if (this[0] === lockAtTime) return '5 PM'
        return ''
      })

      fireEvent.submit(screen.getByTestId('restricted-access-form'))

      expect(saveSpy).toHaveBeenCalledWith(
        {},
        {
          attrs: {
            hidden: false,
            lock_at: mergeTimeAndDate('5 PM', endDate),
            unlock_at: mergeTimeAndDate('5 AM', startDate),
            locked: false,
          },
        },
      )
    })

    it('accepts blank unlock_at date', () => {
      const folder = new Folder({
        id: 999,
        hidden: true,
        lock_at: undefined,
        unlock_at: undefined,
      })
      const saveSpy = jest.spyOn(folder, 'save')
      const props = {
        models: [folder],
      }

      renderComponent(props)

      const scheduleOption = screen.getByLabelText('Schedule availability')
      fireEvent.click(scheduleOption)
      fireEvent.change(scheduleOption, {target: {checked: true}})

      // Set only lock date/time
      const endDate = new Date(2016, 5, 4)
      const lockAtDate = screen.getByLabelText('Available Until Date')
      const lockAtTime = screen.getByLabelText('Available Until Time')

      const $ = require('jquery')
      $.fn.data = jest.fn(function (key) {
        if (key === 'unfudged-date') {
          if (this[0] === lockAtDate) return endDate
        }
        return undefined
      })
      $.fn.val = jest.fn(function () {
        if (this[0] === lockAtTime) return '5 PM'
        return ''
      })

      fireEvent.submit(screen.getByTestId('restricted-access-form'))

      expect(saveSpy).toHaveBeenCalledWith(
        {},
        {
          attrs: {
            hidden: false,
            lock_at: mergeTimeAndDate('5 PM', endDate),
            unlock_at: '',
            locked: false,
          },
        },
      )
    })

    it('accepts blank lock_at date', () => {
      const folder = new Folder({
        id: 999,
        hidden: true,
        lock_at: undefined,
        unlock_at: undefined,
      })
      const saveSpy = jest.spyOn(folder, 'save')
      const props = {
        models: [folder],
      }

      renderComponent(props)

      const scheduleOption = screen.getByLabelText('Schedule availability')
      fireEvent.click(scheduleOption)
      fireEvent.change(scheduleOption, {target: {checked: true}})

      // Set only unlock date/time
      const startDate = new Date(2016, 5, 4)
      const unlockAtDate = screen.getByLabelText('Available From Date')
      const unlockAtTime = screen.getByLabelText('Available From Time')

      const $ = require('jquery')
      $.fn.data = jest.fn(function (key) {
        if (key === 'unfudged-date') {
          if (this[0] === unlockAtDate) return startDate
        }
        return undefined
      })
      $.fn.val = jest.fn(function () {
        if (this[0] === unlockAtTime) return '5 AM'
        return ''
      })

      fireEvent.submit(screen.getByTestId('restricted-access-form'))

      expect(saveSpy).toHaveBeenCalledWith(
        {},
        {
          attrs: {
            hidden: false,
            lock_at: '',
            unlock_at: mergeTimeAndDate('5 AM', startDate),
            locked: false,
          },
        },
      )
    })

    it('rejects unlock_at date after lock_at date', () => {
      const folder = new Folder({
        id: 999,
        hidden: true,
        lock_at: undefined,
        unlock_at: undefined,
      })
      const saveSpy = jest.spyOn(folder, 'save')
      const props = {
        models: [folder],
      }

      renderComponent(props)

      const scheduleOption = screen.getByLabelText('Schedule availability')
      fireEvent.click(scheduleOption)
      fireEvent.change(scheduleOption, {target: {checked: true}})

      const startDate = new Date(2016, 5, 4)
      const endDate = new Date(2016, 5, 1) // Earlier than startDate
      const unlockAtDate = screen.getByLabelText('Available From Date')
      const unlockAtTime = screen.getByLabelText('Available From Time')
      const lockAtDate = screen.getByLabelText('Available Until Date')
      const lockAtTime = screen.getByLabelText('Available Until Time')

      const $ = require('jquery')
      $.fn.data = jest.fn(function (key) {
        if (key === 'unfudged-date') {
          if (this[0] === unlockAtDate) return startDate
          if (this[0] === lockAtDate) return endDate
        }
        return undefined
      })
      $.fn.val = jest.fn(function () {
        if (this[0] === unlockAtTime) return '5 PM'
        if (this[0] === lockAtTime) return '5 AM'
        return ''
      })

      fireEvent.submit(screen.getByTestId('restricted-access-form'))

      expect(saveSpy).not.toHaveBeenCalled()
    })
  })
})
