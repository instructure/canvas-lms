// Copyright (C) 2015 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
import $ from 'jquery'
import React from 'react'
import {render} from '@testing-library/react'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'
import Navigation from '../OldSideNav'

const unreadComponent = jest.fn(() => <></>)

describe('GlobalNavigation', () => {
  beforeEach(() => {
    unreadComponent.mockClear()
    window.ENV.current_user_id = 10
    window.ENV.current_user_disabled_inbox = false
    window.ENV.CAN_VIEW_CONTENT_SHARES = true
    window.ENV.SETTINGS = {release_notes_badge_disabled: false}
    window.ENV.FEATURES = {embedded_release_notes: true}
  })

  it('renders', () => {
    expect(() => render(<Navigation unreadComponent={unreadComponent} />)).not.toThrow()
  })

  describe('unread badges', () => {
    it('renders the shares unread, inbox unread, and release notes unread component', () => {
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(3)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).toEqual(
        expect.arrayContaining([
          '/api/v1/users/self/content_shares/unread_count',
          '/api/v1/conversations/unread_count',
          '/api/v1/release_notes/unread_count',
        ])
      )
    })

    it('does not render the shares unread component when the user does not have permission', () => {
      ENV.CAN_VIEW_CONTENT_SHARES = false
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(
        expect.arrayContaining(['/api/v1/users/self/content_shares/unread_count'])
      )
    })

    it('does not render the shares unread component when the user is not logged in', () => {
      ENV.current_user_id = null
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(
        expect.arrayContaining(['/api/v1/users/self/content_shares/unread_count'])
      )
    })

    it('does not render the inbox unread component when user has opted out of notifications', () => {
      ENV.current_user_disabled_inbox = true
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(expect.arrayContaining(['/api/v1/conversations/unread_count']))
    })

    it('does not render the release notes unread component when user has opted out of notifications', () => {
      ENV.SETTINGS.release_notes_badge_disabled = true
      render(<Navigation unreadComponent={unreadComponent} />)
      expect(unreadComponent).toHaveBeenCalledTimes(2)
      const urls = unreadComponent.mock.calls.map(parms => parms[0].dataUrl)
      expect(urls).not.toEqual(expect.arrayContaining(['/api/v1/release_notes/unread_count']))
    })
  })

  describe('Subjects/Course list', () => {
    const originalGetJSON = $.getJSON
    beforeEach(() => {
      $.getJSON = jest.fn()
    })
    afterEach(() => {
      $.getJSON = originalGetJSON
      document.cookie = ''
    })

    describe('for a student', () => {
      beforeAll(() => {
        window.ENV.current_user_roles = ['user', 'student']
      })
      it("requests the user's courses", () => {
        const navRef = React.createRef()
        render(<Navigation ref={navRef} unreadComponent={unreadComponent} />)
        navRef.current.ensureLoaded('courses')
        expect($.getJSON).toHaveBeenCalledWith(
          '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname',
          expect.anything()
        )
      })

      it("doesn't request the user's courses twice", () => {
        const navRef = React.createRef()
        render(<Navigation ref={navRef} unreadComponent={unreadComponent} />)
        navRef.current.ensureLoaded('courses')
        navRef.current.ensureLoaded('courses')
        expect($.getJSON).toHaveBeenCalledTimes(1)
      })
    })

    describe('for an observer', () => {
      beforeAll(() => {
        window.ENV.current_user_roles = ['user', 'observer']
        document.cookie = `${OBSERVER_COOKIE_PREFIX}${ENV.current_user_id}=17`
      })

      it("requests the user's observee's courses", () => {
        const navRef = React.createRef()
        render(<Navigation ref={navRef} unreadComponent={unreadComponent} />)
        navRef.current.ensureLoaded('courses')
        expect($.getJSON).toHaveBeenCalledWith(
          '/api/v1/users/self/favorites/courses?include[]=term&exclude[]=enrollments&sort=nickname&observed_user_id=17',
          expect.anything()
        )
      })

      it("doesn't request the same observee's courses twice", () => {
        const navRef = React.createRef()
        render(<Navigation ref={navRef} unreadComponent={unreadComponent} />)
        navRef.current.ensureLoaded('courses')
        navRef.current.ensureLoaded('courses')
        expect($.getJSON).toHaveBeenCalledTimes(1)
      })

      it('makes a new request is the observee changes', () => {
        const navRef = React.createRef()
        render(<Navigation ref={navRef} unreadComponent={unreadComponent} />)
        navRef.current.ensureLoaded('courses')
        document.cookie = `${OBSERVER_COOKIE_PREFIX}${ENV.current_user_id}=27`
        navRef.current.ensureLoaded('courses')
        expect($.getJSON).toHaveBeenCalledTimes(2)
      })
    })
  })
})
