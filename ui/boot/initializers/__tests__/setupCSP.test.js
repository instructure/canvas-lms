/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import setupCSP from '../setupCSP'
import {waitFor} from '@testing-library/react'

const oldEnv = window.ENV

describe('setupCSP', () => {
  afterEach(() => {
    window.ENV = oldEnv
  })

  it('does nothing when there is no CSP policy defined on the rootElement', () => {
    const iframe = document.createElement('iframe')
    iframe.className = 'attachment-html-iframe'
    document.body.appendChild(iframe)
    setupCSP(document)
    expect(iframe.getAttribute('csp')).toBeNull()
  })

  it('adds csp policies to iframes existing on the page when called', () => {
    const cspContentAttribute =
      'default-src https://cdn.example.net; child-src "none"; object-src "none"'
    window.ENV = {csp: cspContentAttribute}
    const iframe = document.createElement('iframe')
    iframe.className = 'attachment-html-iframe'
    document.body.appendChild(iframe)
    setupCSP(document)
    return waitFor(() => expect(iframe.getAttribute('csp')).toBe(cspContentAttribute))
  })

  it('adds the csp policy to iframes that get added to the page after initial load', () => {
    const cspContentAttribute =
      'default-src https://cdn.example.net; child-src "none"; object-src "none"'
    window.ENV = {csp: cspContentAttribute}
    setupCSP(document)
    const iframe = document.createElement('iframe')
    iframe.className = 'attachment-html-iframe'
    document.body.appendChild(iframe)
    return waitFor(() => expect(iframe.getAttribute('csp')).toBe(cspContentAttribute))
  })

  it("doesn't add the csp policy to untagged iframes", () => {
    const cspContentAttribute =
      'default-src https://cdn.example.net; child-src "none"; object-src "none"'
    window.ENV = {csp: cspContentAttribute}
    const iframe = document.createElement('iframe')
    document.body.appendChild(iframe)
    setupCSP(document)
    return waitFor(() => expect(iframe.getAttribute('csp')).toBe(null))
  })
})
