// Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import {cleanup, render, screen, waitFor, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import LoginHelp, {renderLoginHelp} from '../loginHelp'

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(() =>
    Promise.resolve({
      json: [{}],
      link: null,
    }),
  ),
}))

describe('LoginHelp Component and Helpers', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    document.body.innerHTML = ''
  })

  afterEach(() => {
    cleanup()
    document.body.innerHTML = ''
  })

  describe('LoginHelp Component', () => {
    it('renders the link text correctly', () => {
      render(
        <MockedQueryProvider>
          <LoginHelp linkText="Help" />
        </MockedQueryProvider>,
      )
      expect(screen.getByText('Help')).toBeInTheDocument()
    })

    it('shows modal initially with close button', async () => {
      const {getByRole, getByTestId, getByText} = render(
        <MockedQueryProvider>
          <LoginHelp linkText="Help" />
        </MockedQueryProvider>,
      )

      // Modal should be open initially
      expect(getByRole('dialog', {name: 'Login Help for Canvas LMS'})).toBeInTheDocument()
      expect(getByText('Help')).toBeInTheDocument()

      // Verify close button exists
      expect(getByTestId('login-help-close-button')).toBeInTheDocument()
    })

    it('handles close button click', async () => {
      const user = userEvent.setup()
      const {getByTestId} = render(
        <MockedQueryProvider>
          <LoginHelp linkText="Help" />
        </MockedQueryProvider>,
      )

      // Close button should be clickable
      const closeButton = getByTestId('login-help-close-button')
      await expect(user.click(closeButton)).resolves.not.toThrow()
    })

    it('renders help link when the provided element is an anchor element', async () => {
      const anchorElement = document.createElement('a')
      anchorElement.textContent = 'Help'
      document.body.appendChild(anchorElement)
      renderLoginHelp(anchorElement)
      expect(screen.getByText('Help')).toBeInTheDocument()
    })

    it('renders help link when the provided element is a direct child of an anchor element', async () => {
      const anchorElement = document.createElement('a')
      const spanElement = document.createElement('span')
      spanElement.textContent = 'Help'
      anchorElement.appendChild(spanElement)
      document.body.appendChild(anchorElement)
      renderLoginHelp(spanElement)
      expect(screen.getByText('Help')).toBeInTheDocument()
    })
  })

  describe('renderLoginHelp()', () => {
    beforeEach(() => {
      document.body.innerHTML = ''
    })

    afterEach(() => {
      cleanup()
      document.body.innerHTML = ''
    })

    it('renders modal with link text for simple anchor tag', async () => {
      const anchorElement = document.createElement('a')
      anchorElement.href = '#'
      anchorElement.textContent = 'Help'
      document.body.appendChild(anchorElement)
      renderLoginHelp(anchorElement)

      // Modal should be open initially when renderLoginHelp is called
      await waitFor(
        () => {
          expect(screen.getByText('Login Help for Canvas LMS')).toBeInTheDocument()
        },
        {timeout: 2000},
      )

      // Verify the link is still available
      expect(screen.getByText('Help')).toBeInTheDocument()
    })

    it('renders modal with link text for anchor tag with span child, including hidden span', async () => {
      const anchorElement = document.createElement('a')
      const spanElement = document.createElement('span')
      spanElement.textContent = 'Help'
      anchorElement.appendChild(spanElement)
      const extraSpanElement = document.createElement('span')
      extraSpanElement.textContent = 'Links to an external site.'
      extraSpanElement.style.display = 'none'
      anchorElement.appendChild(extraSpanElement)
      document.body.appendChild(anchorElement)
      renderLoginHelp(spanElement)
      expect(screen.getByText('Help')).toBeInTheDocument()
    })

    it('throws an error if the provided element is neither an anchor element nor a direct child of an anchor element', () => {
      const divElement = document.createElement('div')
      document.body.appendChild(divElement)
      expect(() => renderLoginHelp(divElement)).toThrow(
        'Element must be an <a> element or a descendant of an <a> element',
      )
    })
  })
})
