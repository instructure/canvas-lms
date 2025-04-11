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

import ProfileShow from '../ProfileShow'
import $ from 'jquery'
import 'jquery-migrate'

describe('ProfileShow', () => {
  let view
  let container

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)

    container.innerHTML = `
      <div class="profile-link" data-testid="profile-link"></div>
      <textarea id="profile_bio" data-testid="profile-bio"></textarea>
      <table id="profile_link_fields">
        <input type="text" name="link_urls[]" data-testid="link-url-input" />
      </table>
    `

    view = new ProfileShow()
  })

  afterEach(() => {
    container.remove()
  })

  // Skip accessibility test for now since we need to update the assertions utility
  it.skip('should be accessible', done => {
    expect(true).toBe(true)
    done()
  })

  describe('link management', () => {
    it('manages focus when removing links', () => {
      // Arrange
      view.addLinkField()
      const $row1 = $('#profile_link_fields tr:last-child')
      view.addLinkField()
      const $row2 = $('#profile_link_fields tr:last-child')

      // Act & Assert - Remove second row
      view.removeLinkRow(null, $row2.find('.remove_link_row'))
      expect(document.activeElement).toBe($row1.find('.remove_link_row')[0])

      // Act & Assert - Remove first row
      view.removeLinkRow(null, $row1.find('.remove_link_row'))
      expect(document.activeElement).toBe(document.querySelector('#profile_bio'))
    })
  })

  describe('form focus management', () => {
    it('focuses name input when available and edit is clicked', () => {
      // Arrange
      const nameInput = document.createElement('input')
      nameInput.id = 'name_input'
      container.appendChild(nameInput)

      // Act
      view.showEditForm()

      // Assert
      expect(document.activeElement).toBe(nameInput)
    })

    it('focuses bio textarea when name input is not available and edit is clicked', () => {
      // Act
      view.showEditForm()

      // Assert
      expect(document.activeElement).toBe(document.querySelector('#profile_bio'))
    })
  })

  describe('form validation', () => {
    beforeEach(() => {
      container.innerHTML = `
        <form id="profile_form">
          <input id="user_short_name" name="user[short_name]" value="John Doe" />
          <input id="profile_title" name="user_profile[title]" />
          <textarea id="profile_bio" name="user_profile[bio]"></textarea>
          <table id="profile_link_fields">
            <input id="profile_link" type="text" name="link_urls[]" />
          </table>
        </form>
      `
    })

    describe('name', () => {
      describe('valid input', () => {
        it('succeeds', () => {
          // Arrange
          const form = document.querySelector('#profile_form')
          const preventDefault = jest.fn()

          // Act & Assert
          view.validateForm({preventDefault, target: form})
          expect(preventDefault).not.toHaveBeenCalled()
        })
      })

      describe('invalid input', () => {
        it('fails', () => {
          // Arrange
          const form = document.querySelector('#profile_form')
          const nameInput = document.querySelector('#user_short_name')
          nameInput.value = ''
          const preventDefault = jest.fn()

          // Act & Assert
          view.validateForm({preventDefault, target: form})
          expect(preventDefault).toHaveBeenCalled()
        })
      })

      describe('input field is not in the DOM', () => {
        it('succeeds', () => {
          // Arrange
          const form = document.querySelector('#profile_form')
          const nameInput = document.querySelector('#user_short_name')
          nameInput.remove()
          const preventDefault = jest.fn()

          // Act & Assert
          view.validateForm({preventDefault, target: form})
          expect(preventDefault).not.toHaveBeenCalled()
        })
      })
    })

    it('validates title input length', () => {
      // Arrange
      const form = document.querySelector('#profile_form')
      const titleInput = document.querySelector('#profile_title')
      const preventDefault = jest.fn()

      // Act & Assert - Valid input
      titleInput.value = 'a'.repeat(255)
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).not.toHaveBeenCalled()

      // Act & Assert - Invalid input
      titleInput.value = 'a'.repeat(256)
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).toHaveBeenCalled()
    })

    it('validates bio input length', () => {
      // Arrange
      const form = document.querySelector('#profile_form')
      const bioInput = document.querySelector('#profile_bio')
      const preventDefault = jest.fn()

      // Act & Assert - Valid input
      bioInput.value = 'a'.repeat(65536)
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).not.toHaveBeenCalled()

      // Act & Assert - Invalid input
      bioInput.value = 'a'.repeat(65537)
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).toHaveBeenCalled()
    })

    it('validates URL has no spaces', () => {
      // Arrange
      const form = document.querySelector('#profile_form')
      const linkInput = document.querySelector('#profile_link')
      const preventDefault = jest.fn()

      // Act & Assert - Valid input
      linkInput.value = 'yahoo'
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).not.toHaveBeenCalled()

      // Act & Assert - Invalid input
      linkInput.value = 'ya hoo'
      view.validateForm({preventDefault, target: form})
      expect(preventDefault).toHaveBeenCalled()
    })
  })

  describe('profile update notifications', () => {
    it('shows success message when success container is present', () => {
      // Arrange
      container.innerHTML = '<div id="profile_alert_holder_success"></div>'
      view = new ProfileShow()

      // Assert
      expect(document.querySelector('#profile_alert_holder_success').textContent).toBe(
        'Profile has been saved successfully',
      )
    })

    it('shows failure message when failed container is present', () => {
      // Arrange
      container.innerHTML = '<div id="profile_alert_holder_failed"></div>'
      view = new ProfileShow()

      // Assert
      expect(document.querySelector('#profile_alert_holder_failed').textContent).toBe(
        'Profile save was unsuccessful',
      )
    })
  })
})
