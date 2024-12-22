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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import React from 'react'
import AnonymousSpeedGraderAlert from '../AnonymousSpeedGraderAlert'

describe('AnonymousSpeedGraderAlert', () => {
  const defaultProps = {
    onClose: jest.fn(),
    speedGraderUrl: 'http://test.url:3000',
  }

  let applicationElement

  beforeEach(() => {
    applicationElement = document.createElement('div')
    applicationElement.id = 'application'
    document.body.appendChild(applicationElement)
  })

  afterEach(() => {
    applicationElement.remove()
    jest.clearAllMocks()
  })

  it('is closed initially', () => {
    const component = render(<AnonymousSpeedGraderAlert {...defaultProps} />)
    expect(component.queryByRole('dialog')).not.toBeInTheDocument()
  })

  describe('when opened', () => {
    let component
    let alertInstance

    beforeEach(() => {
      const ref = React.createRef()
      component = render(<AnonymousSpeedGraderAlert ref={ref} {...defaultProps} />, {
        container: applicationElement,
      })
      alertInstance = ref.current
      alertInstance.open()
    })

    it('has a label of "Anonymous Mode On"', async () => {
      await waitFor(() => {
        expect(screen.getByText(/Anonymous Mode On/)).toBeInTheDocument()
      })
    })

    it('includes a "Cancel" button', async () => {
      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Cancel/})).toBeInTheDocument()
      })
    })

    it('includes an "Open SpeedGrader" link', async () => {
      await waitFor(() => {
        expect(screen.getByRole('link', {name: /Open SpeedGrader/})).toBeInTheDocument()
      })
    })

    it('links to the supplied SpeedGrader URL', async () => {
      await waitFor(() => {
        expect(screen.getByRole('link', {name: /Open SpeedGrader/})).toHaveAttribute(
          'href',
          'http://test.url:3000',
        )
      })
    })

    it('closes when Cancel is clicked', async () => {
      const user = userEvent.setup()
      await waitFor(() => {
        expect(screen.getByRole('button', {name: /Cancel/})).toBeInTheDocument()
      })
      await user.click(screen.getByRole('button', {name: /Cancel/}))
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })
})
