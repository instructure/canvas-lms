/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import 'tinymce/tinymce'
import {render, act, fireEvent} from '@testing-library/react'
import Conference from '../Conference'

// we use RichContentEditor.preloadRemoteModule() to consolidate the import of
// tinymce in the code, but since dynamic loading takes time during tests, we do
// a static import here and mock out the dynamic
jest.mock('jsx/shared/rce/RichContentEditor')

describe('Conference', () => {
  const pluginConference = {
    id: 1,
    title: 'Plugin Conference',
    conference_type: 'PluginConference',
    url: 'invalid://foo'
  }

  const ltiConference = {
    id: 1,
    title: 'LTI Conference',
    conference_type: 'LtiConference',
    url: 'invalid://foo',
    lti_settings: {
      type: 'link',
      url: 'invalid://bar'
    }
  }

  describe('Link conferences', () => {
    it('shows plugin conferences as links', () => {
      const {getByRole} = render(<Conference conference={pluginConference} />)
      const link = getByRole('button')
      expect(link.textContent).toEqual('Plugin Conference')
      expect(link.href).toEqual('invalid://foo/join')
    })

    it('shows lti link conferences as links', () => {
      const {getByRole} = render(<Conference conference={ltiConference} />)
      const link = getByRole('button')
      expect(link.textContent).toEqual('LTI Conference')
      expect(link.href).toEqual('invalid://bar')
    })

    it('shows icons if present in LTI conference', () => {
      const conference = {...ltiConference}
      conference.lti_settings.icon = {url: 'invalid://icon'}
      const {getByRole} = render(<Conference conference={conference} />)
      const link = getByRole('button')
      const icon = link.querySelector('img')
      expect(icon.src).toEqual('invalid://icon')
    })

    it('shows a remove button if handler provided', () => {
      const removeConference = jest.fn()
      const {getByText} = render(
        <Conference conference={pluginConference} removeConference={removeConference} />
      )
      const closeButton = getByText('Remove conference')
      expect(closeButton).not.toBeNull()
    })

    it('calls remove handler if clicked', () => {
      const removeConference = jest.fn()
      const {getByText} = render(
        <Conference conference={pluginConference} removeConference={removeConference} />
      )
      const closeButton = getByText('Remove conference')
      act(() => {
        fireEvent.click(closeButton)
      })
      expect(removeConference).toHaveBeenCalled()
    })

    it('does not show remove button if handler not provided', () => {
      const {queryByText} = render(<Conference conference={pluginConference} />)
      const closeButton = queryByText('Remove conference')
      expect(closeButton).toBeNull()
    })
  })

  describe('HTML conferences', () => {
    const htmlConference = {
      id: 1,
      title: 'HTML Conference',
      conference_type: 'LtiConference',
      url: 'invalid://foo',
      lti_settings: {
        type: 'html',
        html: '<div><a href="/foo">This is some text</a></div>'
      }
    }

    it('shows lti html conferences as html', () => {
      const {getByText} = render(<Conference conference={htmlConference} />)
      const link = getByText('This is some text')
      expect(link.href).toMatch(/foo$/)
    })

    it('sanitizes html text', () => {
      const conference = {...htmlConference}
      conference.lti_settings.html = `
        <script>alert('badness')</script>
        <script src="invalid://evil"></script>
        <img src="invalid://image" />
        <a href="invalid://link">I'm okay</a>`
      render(<Conference conference={htmlConference} />)
      const content = document.body.innerHTML
      expect(content).not.toMatch(/alert/)
      expect(content).not.toMatch(/script/)
      expect(content).not.toMatch(/evil/)
      expect(content).toMatch(/invalid:\/\/image/)
      expect(content).toMatch(/invalid:\/\/link/)
      expect(content).toMatch(/I'm okay/)
    })

    it('shows a remove button if handler provided', () => {
      const removeConference = jest.fn()
      const {getByText} = render(
        <Conference conference={htmlConference} removeConference={removeConference} />
      )
      const closeButton = getByText('Remove conference')
      expect(closeButton).not.toBeNull()
    })

    it('calls remove handler if clicked', () => {
      const removeConference = jest.fn()
      const {getByText} = render(
        <Conference conference={htmlConference} removeConference={removeConference} />
      )
      const closeButton = getByText('Remove conference')
      act(() => {
        fireEvent.click(closeButton)
      })
      expect(removeConference).toHaveBeenCalled()
    })

    it('does not show remove button if handler not provided', () => {
      const {queryByText} = render(<Conference conference={htmlConference} />)
      const closeButton = queryByText('Remove conference')
      expect(closeButton).toBeNull()
    })
  })
})
