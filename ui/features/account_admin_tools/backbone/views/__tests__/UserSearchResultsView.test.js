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
import UserSearchResultsView from '../UserSearchResultsView'
import UserRestore from '../../models/UserRestore'

const errorMessageJSON = {
  status: 'not_found',
  message: 'There was no foo bar in the baz',
}

const userJSON = {
  id: 17,
  name: 'Deleted User',
  sis_user_id: null,
}

describe('UserSearchResultsView', () => {
  let userRestore
  let userSearchResultsView
  let flashContainer

  beforeEach(() => {
    userRestore = new UserRestore({account_id: 6})
    userSearchResultsView = new UserSearchResultsView({model: userRestore})

    // Set up flash container
    flashContainer = document.createElement('div')
    flashContainer.id = 'flash_screenreader_holder'
    document.body.appendChild(flashContainer)

    // Mock screenreader flash message
    $.screenReaderFlashMessage = message => {
      flashContainer.textContent = message
    }

    $('#fixtures').append(userSearchResultsView.render().el)
  })

  afterEach(() => {
    $('#fixtures').empty()
    document.body.removeChild(flashContainer)
  })

  it('sets restored to false when initialized', () => {
    expect(userRestore.get('restored')).toBeFalsy()
  })

  it('calls render when model has a change event triggered', () => {
    const renderSpy = jest.spyOn(userSearchResultsView, 'render')
    userSearchResultsView.applyBindings()
    userRestore.trigger('change')
    expect(renderSpy).toHaveBeenCalledTimes(1)
  })

  it('calls restore on model when restore button is clicked', () => {
    userRestore.set(userJSON)
    const restoreSpy = jest.spyOn(userRestore, 'restore').mockResolvedValue({})
    userSearchResultsView.$restoreUserBtn.click()
    expect(restoreSpy).toHaveBeenCalledTimes(1)
  })

  it('displays not found message when model has no id and a status', () => {
    userRestore.clear({silent: true})
    userRestore.set(errorMessageJSON)
    expect(userSearchResultsView.$el.find('.alert-error').length).toBeGreaterThan(0)
  })

  it('displays restore options when a deleted user is found', () => {
    userRestore.set(userJSON)
    expect(userSearchResultsView.$el.find('#restoreUserBtn')).toHaveLength(1)
  })

  it('shows screenreader text when user not found', () => {
    userRestore.clear({silent: true})
    userRestore.set(errorMessageJSON)
    userSearchResultsView.resultsFound()
    expect(flashContainer.textContent).toBe('User not found')
  })

  it('shows screenreader text on finding deleted user', () => {
    userRestore.set(userJSON)
    userSearchResultsView.resultsFound()
    expect(flashContainer.textContent).toBe('User found')
  })

  it('shows screenreader text on finding non-deleted user', () => {
    userRestore.set({
      ...userJSON,
      login_id: 'du',
    })
    userSearchResultsView.resultsFound()
    expect(flashContainer.textContent).toBe('User found (not deleted)')
  })

  it('shows options to view a user if a user was restored', () => {
    userRestore.set(userJSON, {silent: true})
    userRestore.set('restored', true, {silent: true})
    userRestore.set('login_id', 'du')
    expect(userSearchResultsView.$el.find('.alert-success')).toHaveLength(1)
    expect(userSearchResultsView.$el.find('#viewUser')).toHaveLength(1)
  })

  it('shows options to view a user', () => {
    userRestore.set(userJSON, {silent: true})
    userRestore.set('login_id', 'du')
    expect(userSearchResultsView.$el.find('#viewUser')).toHaveLength(1)
  })
})
