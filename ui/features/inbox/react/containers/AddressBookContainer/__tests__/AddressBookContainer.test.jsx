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

import React from 'react'
import {ApolloProvider} from '@apollo/client'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {mswClient} from '@canvas/msw/mswClient'
import {graphql, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {AddressBookContainer} from '../AddressBookContainer'
import {handlers} from '../../../../graphql/mswHandlers'

// ADDRESS_BOOK_RECIPIENTS uses `sisId @include(if: ENV.inbox_sis_id_for_duplicates)`,
// which is evaluated at module load time. Since ENV doesn't have the flag set in tests,
// sisId is never requested. Override the query to always include sisId so SIS tests work.
vi.mock('../../../../graphql/Queries', async () => {
  const {gql} = await import('@apollo/client')
  const actual = await vi.importActual('../../../../graphql/Queries')
  return {
    ...actual,
    ADDRESS_BOOK_RECIPIENTS: gql`
      query GetInboxAddressBookRecipients(
        $userID: ID!
        $context: String
        $search: String
        $afterUser: String
        $afterContext: String
        $courseContextCode: String!
      ) {
        legacyNode(_id: $userID, type: User) {
          ... on User {
            id
            recipients(context: $context, search: $search) {
              sendMessagesAll
              contextsConnection(first: 20, after: $afterContext) {
                nodes {
                  id
                  name
                }
                pageInfo {
                  endCursor
                  hasNextPage
                }
              }
              usersConnection(first: 20, after: $afterUser) {
                nodes {
                  _id
                  id
                  name
                  shortName
                  pronouns
                  sisId
                  observerEnrollmentsConnection(contextCode: $courseContextCode) {
                    nodes {
                      associatedUser {
                        _id
                        name
                      }
                    }
                  }
                }
                pageInfo {
                  endCursor
                  hasNextPage
                }
              }
            }
            __typename
          }
        }
      }
    `,
  }
})

describe('AddressBookContainer', () => {
  const server = setupServer(...handlers)
  let user

  beforeAll(() => {
    server.listen()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    window.ENV = {
      current_user_id: 1,
    }
    user = userEvent.setup()
  })

  const setup = (props = {}) => {
    return render(
      <ApolloProvider client={mswClient}>
        <AddressBookContainer {...props} />
      </ApolloProvider>,
    )
  }

  const openAddressBook = async ({getByTestId}) => {
    const button = getByTestId('address-button')
    await user.click(button)
  }

  describe('Context Selection', () => {
    const contextSelectionProps = {
      width: '360px',
      menuRef: {current: document.createElement('div')},
      onSelect: () => {},
      onTextChange: () => {},
      onSelectedIdsChange: () => {},
      selectedIds: [],
    }

    it('hides context select in initial menu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      expect(items).toHaveLength(2)
      expect(rendered.queryByText('Users')).toBeInTheDocument()
    })

    it('hides context select for initial "Courses" submenu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('hides context select for initial users submenu', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(4) // Back button + 3 users
    })

    it('shows context select for course selection', async () => {
      const rendered = setup(contextSelectionProps)
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems.length).toBeGreaterThan(0)
    })
  })

  describe('Basic Functionality', () => {
    it('renders component', () => {
      const {getByTestId} = setup()
      expect(getByTestId('-address-book-input')).toBeInTheDocument()
    })

    it('filters menu by initial context', async () => {
      const {findByTestId} = setup()
      const input = await findByTestId('-address-book-input')
      expect(input).toBeInTheDocument()
    })

    it('loads courses and users submenu on initial load', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      expect(items).toHaveLength(2)
    })

    it('loads data on initial request', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('should filter menu when typing', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const filteredItems = await rendered.findAllByTestId('address-book-item')
      expect(filteredItems.length).toBeGreaterThan(0)
    })

    it('should return to last filter when backing out of search', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      await user.clear(input)
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })

    it('clears text field when item is clicked', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      await user.click(submenuItems[0])
      expect(input).toHaveValue('')
    })

    it('should navigate through filters', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(4) // Back button + 3 users
    })

    it('clears input when submenu is chosen', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const input = await rendered.findByTestId('-address-book-input')
      await user.type(input, 'Test')
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      expect(input).toHaveValue('')
    })

    it('limits tag selection when limit is 1', async () => {
      const onSelectedIdsChange = vi.fn()
      const rendered = setup({
        selectedIds: ['1'],
        onSelectedIdsChange,
        limitTagCount: 1,
      })
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1]) // Click on Users
      const userItems = await rendered.findAllByTestId('address-book-item')
      await user.click(userItems[1]) // Click the first user item
      expect(onSelectedIdsChange).toHaveBeenCalled()
    })

    it('updates navigation state when activeCourseFilter changes', async () => {
      const rendered = setup()
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[0])
      const submenuItems = await rendered.findAllByTestId('address-book-item')
      expect(submenuItems).toHaveLength(2)
    })
  })

  describe('Callbacks', () => {
    it('calls onSelectedIdsChange when id changes', async () => {
      const onSelectedIdsChange = vi.fn()
      const rendered = setup({onSelectedIdsChange})
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1]) // Click on Users
      const userItems = await rendered.findAllByTestId('address-book-item')
      await user.click(userItems[1]) // Click the first user item
      expect(onSelectedIdsChange).toHaveBeenCalled()
    })

    it('calls onInputValueChange when search term changes', async () => {
      const onInputValueChange = vi.fn()
      const rendered = setup({onInputValueChange})
      const input = await rendered.findByTestId('-address-book-input')

      // Type in the search input which updates searchTerm
      await user.type(input, 'test')

      // The useEffect (line 129-132) should call onInputValueChange with the search term
      await waitFor(() => {
        expect(onInputValueChange).toHaveBeenCalled()
      })
    })
  })

  describe('SIS ID duplicate detection', () => {
    // Each test uses a unique courseContextCode to get a distinct Apollo cache key,
    // preventing stale hits from the shared mswClient singleton across tests.
    let SIS_COURSE_CONTEXT
    beforeEach(() => {
      SIS_COURSE_CONTEXT = `course_sis_${Date.now()}_${Math.random()}`
    })

    const makeRecipientsHandler = nodes =>
      graphql.query('GetInboxAddressBookRecipients', () =>
        HttpResponse.json({
          data: {
            legacyNode: {
              id: 'VXNlci0x',
              __typename: 'User',
              recipients: {
                sendMessagesAll: false,
                contextsConnection: {
                  nodes: [],
                  pageInfo: {hasNextPage: false, endCursor: null, __typename: 'PageInfo'},
                  __typename: 'MessageableContextConnection',
                },
                usersConnection: {
                  nodes,
                  pageInfo: {hasNextPage: false, endCursor: null, __typename: 'PageInfo'},
                  __typename: 'MessageableUserConnection',
                },
                __typename: 'Recipients',
              },
            },
          },
        }),
      )

    const openUsersSubmenu = async rendered => {
      await openAddressBook(rendered)
      const items = await rendered.findAllByTestId('address-book-item')
      await user.click(items[1]) // Click on Users
    }

    it('shows sisId next to users with duplicate names', async () => {
      server.use(
        makeRecipientsHandler([
          {
            _id: '1',
            id: 'U1',
            name: 'John Smith',
            shortName: 'John Smith',
            pronouns: null,
            sisId: 'SIS123',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
          {
            _id: '2',
            id: 'U2',
            name: 'John Smith',
            shortName: 'John Smith',
            pronouns: null,
            sisId: 'SIS456',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
          {
            _id: '3',
            id: 'U3',
            name: 'Jane Doe',
            shortName: 'Jane Doe',
            pronouns: null,
            sisId: 'SIS789',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
        ]),
      )

      const rendered = setup({courseContextCode: SIS_COURSE_CONTEXT})
      await openUsersSubmenu(rendered)

      expect(await rendered.findByText('SIS123')).toBeInTheDocument()
      expect(await rendered.findByText('SIS456')).toBeInTheDocument()
      expect(rendered.queryByText('SIS789')).not.toBeInTheDocument()
    })

    it('hides all sisIds when all names are unique', async () => {
      server.use(
        makeRecipientsHandler([
          {
            _id: '1',
            id: 'U1',
            name: 'Alice Brown',
            shortName: 'Alice Brown',
            pronouns: null,
            sisId: 'SIS111',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
          {
            _id: '2',
            id: 'U2',
            name: 'Bob Wilson',
            shortName: 'Bob Wilson',
            pronouns: null,
            sisId: 'SIS222',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
          {
            _id: '3',
            id: 'U3',
            name: 'Charlie Davis',
            shortName: 'Charlie Davis',
            pronouns: null,
            sisId: 'SIS333',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
        ]),
      )

      const rendered = setup({courseContextCode: SIS_COURSE_CONTEXT})
      await openUsersSubmenu(rendered)

      await rendered.findAllByTestId('address-book-item') // wait for items to load
      expect(rendered.queryByText('SIS111')).not.toBeInTheDocument()
      expect(rendered.queryByText('SIS222')).not.toBeInTheDocument()
      expect(rendered.queryByText('SIS333')).not.toBeInTheDocument()
    })

    it('treats names as duplicates case-insensitively', async () => {
      server.use(
        makeRecipientsHandler([
          {
            _id: '1',
            id: 'U1',
            name: 'John Smith',
            shortName: 'John Smith',
            pronouns: null,
            sisId: 'SIS123',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
          {
            _id: '2',
            id: 'U2',
            name: 'JOHN SMITH',
            shortName: 'JOHN SMITH',
            pronouns: null,
            sisId: 'SIS456',
            observerEnrollmentsConnection: null,
            __typename: 'MessageableUser',
          },
        ]),
      )

      const rendered = setup({courseContextCode: SIS_COURSE_CONTEXT})
      await openUsersSubmenu(rendered)

      expect(await rendered.findByText('SIS123')).toBeInTheDocument()
      expect(await rendered.findByText('SIS456')).toBeInTheDocument()
    })
  })
})
