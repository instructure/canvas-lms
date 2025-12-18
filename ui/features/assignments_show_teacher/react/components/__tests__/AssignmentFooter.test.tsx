/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

/*
 * copyright (c) 2025 - present instructure, inc.
 *
 * this file is part of canvas.
 *
 * canvas is free software: you can redistribute it and/or modify it under
 * the terms of the gnu affero general public license as published by the free
 * software foundation, version 3 of the license.
 *
 * canvas is distributed in the hope that it will be useful, but without any
 * warranty; without even the implied warranty of merchantability or fitness for
 * a particular purpose. see the gnu affero general public license for more
 * details.
 *
 * you should have received a copy of the gnu affero general public license along
 * with this program. if not, see <http://www.gnu.org/licenses/>.
 */

import {MockedProvider} from '@apollo/client/testing'
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AssignmentFooter from '../AssignmentFooter'
import {MODULE_SEQUENCE_QUERY} from '@canvas/assignments/graphql/common/Queries'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'

const mockModuleSequence = (overrides = {}) => {
  return {
    request: {
      query: MODULE_SEQUENCE_QUERY,
      variables: {moduleItemId: '2'},
    },
    result: {
      data: {
        moduleItem: {
          loaded: true,
          error: null,
          next: {
            id: '3',
            position: 1,
            title: 'Assignment 3',
            url: '/assignments/3',
          },
          previous: {
            id: '1',
            position: 3,
            title: 'Assignment 1',
            url: '/assignments/1',
          },
        },
      },
    },
    ...overrides,
  }
}

const mockModuleSequenceError = () => {
  return {
    request: {
      query: MODULE_SEQUENCE_QUERY,
      variables: {moduleItemId: '2'},
    },
    error: new Error('Simulated Error'),
  }
}

const renderWithAlertManager = (component: React.ReactNode, mockedContext: any) => {
  return render(
    <AlertManagerContext.Provider value={mockedContext}>{component}</AlertManagerContext.Provider>,
  )
}

describe('AssignmentFooter', () => {
  it('renders previous and next buttons when sequence is loaded', async () => {
    render(
      <MockedProvider mocks={[mockModuleSequence()]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('Previous')).toBeInTheDocument()
      expect(screen.getByText('Next')).toBeInTheDocument()
    })
  })

  it('renders nothing when sequence is not loaded', async () => {
    render(
      <MockedProvider mocks={[mockModuleSequence({result: {data: {moduleItem: {loaded: false}}}})]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.queryByText('Previous')).not.toBeInTheDocument()
      expect(screen.queryByText('Next')).not.toBeInTheDocument()
    })
  })

  it('calls setOnFailure and does not render nav buttons when there is an error loading the sequence', async () => {
    const mockedContext = {
      setOnFailure: vi.fn(),
    }
    renderWithAlertManager(
      <MockedProvider mocks={[mockModuleSequenceError()]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
      mockedContext,
    )

    await waitFor(() => {
      expect(mockedContext.setOnFailure).toHaveBeenCalledTimes(1)
      expect(screen.queryByText('Previous')).not.toBeInTheDocument()
      expect(screen.queryByText('Next')).not.toBeInTheDocument()
    })
  })

  it('renders only "Previous" button when last assignment in modules', async () => {
    const mockedResultOverride = {
      result: {
        data: {
          moduleItem: {
            next: null,
            previous: {
              id: '1',
              position: 1,
              title: 'Assignment 1',
              url: '/assignments/1',
            },
          },
        },
      },
    }

    render(
      <MockedProvider mocks={[mockModuleSequence(mockedResultOverride)]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('Previous')).toBeInTheDocument()
      expect(screen.queryByText('Next')).not.toBeInTheDocument()
    })
  })

  it('renders only "Next" button when first assignment in modules', async () => {
    const mockedResultOverride = {
      result: {
        data: {
          moduleItem: {
            previous: null,
            next: {
              id: '3',
              position: 1,
              title: 'Assignment 3',
              url: '/assignments/3',
            },
          },
        },
      },
    }

    render(
      <MockedProvider mocks={[mockModuleSequence(mockedResultOverride)]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.queryByText('Previous')).not.toBeInTheDocument()
      expect(screen.getByText('Next')).toBeInTheDocument()
    })
  })

  it('shows tooltip with previous assignment title on hover', async () => {
    const user = userEvent.setup()
    render(
      <MockedProvider mocks={[mockModuleSequence()]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('Previous')).toBeInTheDocument()
    })

    await user.hover(screen.getByTestId('previous-assignment-button'))
    await waitFor(() => {
      expect(screen.getByText('Assignment 1')).toBeInTheDocument()
    })
  })

  it('shows tooltip with next assignment title on hover', async () => {
    const user = userEvent.setup()
    render(
      <MockedProvider mocks={[mockModuleSequence()]}>
        <AssignmentFooter moduleItemId={'2'} />
      </MockedProvider>,
    )

    await waitFor(() => {
      expect(screen.getByText('Next')).toBeInTheDocument()
    })

    await user.hover(screen.getByTestId('next-assignment-button'))
    await waitFor(() => {
      expect(screen.getByText('Assignment 3')).toBeInTheDocument()
    })
  })
})
