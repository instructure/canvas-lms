/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render, waitFor} from '@testing-library/react'
import {ExpandableErrorAlert} from '../ExpandableErrorAlert'
import React from 'react'
import userEvent from '@testing-library/user-event'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('ExpandableErrorAlert', () => {
  it('displays child content', () => {
    const {getByText} = render(<ExpandableErrorAlert>I&apos;m a child 👶</ExpandableErrorAlert>)

    expect(getByText("I'm a child 👶")).toBeInTheDocument()
  })

  it('toggles error details when error details button is clicked', async () => {
    const error = 'Something broke.'
    const {queryByText, getByText, getByRole} = render(<ExpandableErrorAlert error={error} />)

    expect(queryByText(error)).not.toBeInTheDocument()

    await userEvent.click(getByRole('button', {name: 'Error details'}))
    expect(getByText(error)).toBeInTheDocument()

    await userEvent.click(getByRole('button', {name: 'Error details'}))
    expect(queryByText(error)).not.toBeInTheDocument()
  })

  it('does not display an error details button if there is no error', () => {
    const {getByText, queryByText, rerender} = render(
      <ExpandableErrorAlert>Error</ExpandableErrorAlert>
    )
    expect(getByText('Error')).toBeInTheDocument()
    expect(queryByText('Error details')).not.toBeInTheDocument()

    rerender(<ExpandableErrorAlert error="">Error</ExpandableErrorAlert>)
    expect(getByText('Error')).toBeInTheDocument()
    expect(queryByText('Error details')).not.toBeInTheDocument()
  })

  it('renders a live region alert when text is provided', () => {
    const {getByText} = render(
      <>
        <div id="flash_screenreader_holder" role="alert" />
        <ExpandableErrorAlert liveRegionText="My error summary">My error</ExpandableErrorAlert>
      </>
    )

    expect(getByText('My error')).toBeInTheDocument()
    expect(getByText('My error summary')).toBeInTheDocument()
  })

  it('dismisses the live region alert when the primary alert is dismissed', async () => {
    const {getByText, getByRole} = render(
      <>
        <div id="flash_screenreader_holder" role="alert" />
        <ExpandableErrorAlert liveRegionText="My error summary" closeable={true}>
          My error
        </ExpandableErrorAlert>
      </>
    )

    const [error, summary] = [getByText('My error'), getByText('My error summary')]
    expect(error).toBeInTheDocument()
    expect(summary).toBeInTheDocument()

    await userEvent.click(getByRole('button', {name: 'Close'}))
    waitFor(() => {
      expect(error).not.toBeInTheDocument()
      expect(summary).not.toBeInTheDocument()
    })
  })

  it('displays a functioning close button when closeable is true', async () => {
    const {getByText, getByRole, queryByText, queryByRole, rerender} = render(
      <ExpandableErrorAlert>My error</ExpandableErrorAlert>
    )

    expect(getByText('My error')).toBeInTheDocument()
    expect(queryByRole('button', {name: 'Close'})).not.toBeInTheDocument()

    rerender(<ExpandableErrorAlert closeable={true}>My error</ExpandableErrorAlert>)

    expect(getByText('My error')).toBeInTheDocument()
    const closeButton = getByRole('button', {name: 'Close'})
    expect(closeButton).toBeInTheDocument()
    await userEvent.click(closeButton)

    waitFor(() => {
      expect(queryByText('My error')).not.toBeInTheDocument()
    })
  })
})
