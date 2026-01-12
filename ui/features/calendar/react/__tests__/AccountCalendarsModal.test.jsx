/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {cleanup, render, fireEvent, waitFor, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {
  accountCalendarsAPIPage1Response,
  accountCalendarsAPIPage2Response,
  allAccountCalendarsResponse,
  emptyResponse,
  accountCalendarsAPISearchResponse,
} from './mocks'
import AccountCalendarsModal, {
  SEARCH_ENDPOINT,
  SAVE_PREFERENCES_ENDPOINT,
} from '../AccountCalendarsModal'
import {alertForMatchingAccounts} from '@canvas/calendar/AccountCalendarsUtils'

// Mock debounce to execute immediately for test stability
vi.mock('es-toolkit/compat', async importOriginal => {
  const actual = await importOriginal()
  return {
    ...actual,
    debounce: (fn, _wait) => {
      const debouncedFn = (...args) => {
        return fn(...args)
      }
      debouncedFn.cancel = vi.fn()
      return debouncedFn
    },
    isEqual: actual.isEqual,
  }
})

vi.mock('@canvas/calendar/AccountCalendarsUtils', () => {
  return {
    alertForMatchingAccounts: vi.fn(),
  }
})

const page1Results = accountCalendarsAPIPage1Response.account_calendars
const page2Results = accountCalendarsAPIPage2Response.account_calendars
const searchResult = accountCalendarsAPISearchResponse.account_calendars
const totalCalendars = allAccountCalendarsResponse.total_results

// MSW server setup
const server = setupServer(
  http.get(SEARCH_ENDPOINT, ({request}) => {
    const url = new URL(request.url)
    const perPage = url.searchParams.get('per_page')
    const page = url.searchParams.get('page')
    const searchTerm = url.searchParams.get('search_term')

    if (searchTerm === 'Test') {
      return HttpResponse.json(accountCalendarsAPISearchResponse)
    }

    if (searchTerm === 'Test2') {
      return HttpResponse.json(emptyResponse)
    }

    if (perPage === '5') {
      return HttpResponse.json(allAccountCalendarsResponse)
    }

    if (page === '2') {
      return HttpResponse.json(accountCalendarsAPIPage2Response)
    }

    // Default: return page 1 with Link header for pagination
    return HttpResponse.json(accountCalendarsAPIPage1Response, {
      headers: {
        Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
      },
    })
  }),

  http.post(SAVE_PREFERENCES_ENDPOINT, ({request}) => {
    return HttpResponse.json({status: 'ok'})
  }),
)

const getProps = (overrides = {}) => ({
  getSelectedOtherCalendars: () => [page1Results[0]],
  onSave: vi.fn(),
  calendarsPerRequest: 2,
  featureSeen: true,
  ...overrides,
})

describe('Other Calendars modal ', () => {
  beforeAll(() => {
    server.listen({onUnhandledRequest: 'bypass'})
  })

  beforeEach(() => {
    // Ensure flash alert holder exists and is empty
    let flashHolder = document.getElementById('flashalert_message_holder')
    if (!flashHolder) {
      flashHolder = document.createElement('div')
      flashHolder.id = 'flashalert_message_holder'
      document.body.appendChild(flashHolder)
    }
    flashHolder.innerHTML = ''

    let srHolder = document.getElementById('flash_screenreader_holder')
    if (!srHolder) {
      srHolder = document.createElement('div')
      srHolder.id = 'flash_screenreader_holder'
      srHolder.setAttribute('role', 'alert')
      document.body.appendChild(srHolder)
    }
    srHolder.innerHTML = ''
  })

  afterEach(() => {
    cleanup()
    server.resetHandlers()
    vi.clearAllMocks()

    // Clean up flash messages
    const flashHolder = document.getElementById('flashalert_message_holder')
    if (flashHolder) {
      flashHolder.innerHTML = ''
    }
    const srHolder = document.getElementById('flash_screenreader_holder')
    if (srHolder) {
      srHolder.innerHTML = ''
    }
  })

  afterAll(() => {
    server.close()
  })

  it('renders "calendarsPerRequest" number of account calendars when open', async () => {
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps()} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByText(page1Results[0].name)).toBeInTheDocument()
    })
    expect(screen.getByText(page1Results[1].name)).toBeInTheDocument()
    expect(screen.queryByText(page2Results[0].name)).not.toBeInTheDocument()
  })

  it('shows the calendars already enabled', async () => {
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps()} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByTestId(`account-${page1Results[0].id}-checkbox`)).toBeChecked()
    })
    expect(screen.getByTestId(`account-${page1Results[1].id}-checkbox`)).not.toBeChecked()
  })

  it('saves the new enabled calendars state', async () => {
    const onSave = vi.fn()
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps({onSave})} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByTestId(`account-${page1Results[1].id}-checkbox`)).toBeInTheDocument()
    })

    const calendarToEnable = screen.getByTestId(`account-${page1Results[1].id}-checkbox`)
    const saveButton = screen.getByTestId('save-calendars-button')

    await user.click(calendarToEnable)
    await user.click(saveButton)

    await waitFor(() => {
      expect(onSave).toHaveBeenCalled()
    })
  })

  it('renders the "Show more" option when there are more calendars to fetch', async () => {
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps()} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByText('Show more')).toBeInTheDocument()
    })

    await user.click(screen.getByText('Show more'))

    // After clicking show more, page 2 results should appear
    await waitFor(() => {
      expect(screen.getByText(page2Results[0].name)).toBeInTheDocument()
    })
  })

  it('does not render the "Show more" option when all the calendars have been fetched', async () => {
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps({calendarsPerRequest: 5})} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByTestId(`account-${page1Results[1].id}-checkbox`)).toBeInTheDocument()
    })
    expect(screen.queryByText('Show more')).not.toBeInTheDocument()
  })

  it('mark feature as seen when the modal is opened for the first time', async () => {
    let markAsSeenCalled = false
    server.use(
      http.post(SAVE_PREFERENCES_ENDPOINT, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('mark_feature_as_seen') === 'true') {
          markAsSeenCalled = true
        }
        return HttpResponse.json({status: 'ok'})
      }),
    )

    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps({featureSeen: null})} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(markAsSeenCalled).toBe(true)
    })
  })

  it('does not try to mark the feature as seen if it is already seen', async () => {
    let markAsSeenCalled = false
    server.use(
      http.post(SAVE_PREFERENCES_ENDPOINT, ({request}) => {
        const url = new URL(request.url)
        if (url.searchParams.get('mark_feature_as_seen') === 'true') {
          markAsSeenCalled = true
        }
        return HttpResponse.json({status: 'ok'})
      }),
    )

    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps({featureSeen: true})} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    // Wait for modal to open and initial fetch
    await waitFor(() => {
      expect(screen.getByTestId(`account-${page1Results[0].id}-checkbox`)).toBeInTheDocument()
    })

    expect(markAsSeenCalled).toBe(false)
  })

  it('disables the save button if the user has not made any change', async () => {
    const user = userEvent.setup()
    render(<AccountCalendarsModal {...getProps()} />)

    const addCalendarButton = screen.getByTestId('add-other-calendars-button')
    await user.click(addCalendarButton)

    await waitFor(() => {
      expect(screen.getByTestId('save-calendars-button')).toBeDisabled()
    })

    const calendarToEnable = screen.getByTestId(`account-${page1Results[1].id}-checkbox`)
    await user.click(calendarToEnable)

    expect(screen.getByTestId('save-calendars-button')).not.toBeDisabled()
  })

  describe('auto subscribe', () => {
    it('shows auto-subscribed calendars as disabled', async () => {
      const searchResponse = structuredClone(accountCalendarsAPIPage1Response)
      searchResponse.account_calendars[1].auto_subscribe = true

      server.use(
        http.get(SEARCH_ENDPOINT, () => {
          return HttpResponse.json(searchResponse, {
            headers: {
              Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
            },
          })
        }),
      )

      const user = userEvent.setup()
      render(
        <AccountCalendarsModal
          {...getProps({
            getSelectedOtherCalendars: () => searchResponse.account_calendars,
          })}
        />,
      )

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByTestId(`account-${page1Results[0].id}-checkbox`)).toBeChecked()
      })
      expect(screen.getByTestId(`account-${page1Results[1].id}-checkbox`)).toBeChecked()
      expect(screen.getByTestId(`account-${page1Results[1].id}-checkbox`)).toBeDisabled()
    })

    it('includes a tooltip for auto-subscribed calendars', async () => {
      const searchResponse = structuredClone(accountCalendarsAPIPage1Response)
      searchResponse.account_calendars[1].auto_subscribe = true

      server.use(
        http.get(SEARCH_ENDPOINT, () => {
          return HttpResponse.json(searchResponse, {
            headers: {
              Link: '</api/v1/account_calendars?&per_page=2&page=2>; rel="next"',
            },
          })
        }),
      )

      const user = userEvent.setup()
      render(
        <AccountCalendarsModal
          {...getProps({
            getSelectedOtherCalendars: () => searchResponse.account_calendars,
          })}
        />,
      )

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByText('Select Calendars')).toBeInTheDocument()
      })

      const helpButton = screen.getByText('help').closest('button')
      expect(helpButton).toBeInTheDocument()
      await user.click(helpButton)

      expect(screen.getByText('Calendars added by the admin cannot be removed')).toBeInTheDocument()
    })
  })

  describe('Search bar ', () => {
    it('shows the total number of available calendars to search through', async () => {
      const user = userEvent.setup()
      render(<AccountCalendarsModal {...getProps()} />)

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(
          screen.getByPlaceholderText(`Search ${totalCalendars} calendars`),
        ).toBeInTheDocument()
      })
    })

    it('fetches calendars that match with the input value', async () => {
      const user = userEvent.setup()
      render(<AccountCalendarsModal {...getProps()} />)

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByTestId('search-input')).toBeInTheDocument()
      })

      const searchBar = screen.getByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test'}})

      // Should show search results
      await waitFor(() => {
        expect(screen.getByTestId(`account-${searchResult[0].id}-checkbox`)).toBeInTheDocument()
      })
    })

    it('does not trigger search requests if the user has not typed at least 2 characters', async () => {
      const user = userEvent.setup()
      render(<AccountCalendarsModal {...getProps()} />)

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByTestId('search-input')).toBeInTheDocument()
      })

      const searchBar = screen.getByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'T'}})

      // Original page 1 results should still be shown
      await waitFor(() => {
        expect(screen.getByText(page1Results[0].name)).toBeInTheDocument()
      })
    })

    it('shows an empty state if no calendar was found', async () => {
      const user = userEvent.setup()
      render(<AccountCalendarsModal {...getProps()} />)

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByTestId('search-input')).toBeInTheDocument()
      })

      const searchBar = screen.getByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test2'}})

      await waitFor(() => {
        expect(screen.getByTestId('account-calendars-empty-state')).toBeInTheDocument()
      })
      // Use regex to handle the curly apostrophe in "can't"
      expect(screen.getByText(/Hmm, we can.t find any matching calendars/)).toBeInTheDocument()
    })

    it('announces search results for screen readers', async () => {
      const user = userEvent.setup()
      render(<AccountCalendarsModal {...getProps()} />)

      const addCalendarButton = screen.getByTestId('add-other-calendars-button')
      await user.click(addCalendarButton)

      await waitFor(() => {
        expect(screen.getByTestId('search-input')).toBeInTheDocument()
      })

      const searchBar = screen.getByTestId('search-input')
      fireEvent.change(searchBar, {target: {value: 'Test'}})

      await waitFor(() => {
        expect(screen.getByTestId(`account-${searchResult[0].id}-checkbox`)).toBeInTheDocument()
      })

      expect(alertForMatchingAccounts).toHaveBeenCalledWith(1, false)
    })
  })
})
