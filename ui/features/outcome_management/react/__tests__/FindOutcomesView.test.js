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
import FindOutcomesView from '../FindOutcomesView'
import {createCache} from '@canvas/apollo'
import {MockedProvider} from '@apollo/react-testing'
import {render as realRender, fireEvent} from '@testing-library/react'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {findOutcomesMocks} from '@canvas/outcomes/mocks/Management'
import {
  IMPORT_NOT_STARTED,
  IMPORT_FAILED,
  IMPORT_PENDING,
  IMPORT_COMPLETED,
} from '@canvas/outcomes/react/hooks/useOutcomesImport'

jest.useFakeTimers()

describe('FindOutcomesView', () => {
  let onChangeHandlerMock
  let onClearHandlerMock
  let importOutcomeHandlerMock
  let onLoadMoreHandlerMock
  let onAddAllHandlerMock
  let cache
  const defaultProps = (props = {}) => ({
    collection: {
      id: '1',
      name: 'State Standards',
      isRootGroup: false,
    },
    outcomesGroup: {
      title: 'State Standards',
      _id: '1',
      contextId: '1',
      contextType: 'Account',
      outcomesCount: 3,
      notImportedOutcomesCount: 1,
      outcomes: {
        edges: [
          {
            _id: 10,
            node: {
              _id: '11',
              title: 'Outcome 1',
              description: 'Outcome 1 description',
              isImported: false,
            },
          },
        ],
        pageInfo: {
          endCursor: 'abc',
          hasNextPage: true,
        },
      },
    },
    loading: false,
    searchString: '',
    onChangeHandler: onChangeHandlerMock,
    onClearHandler: onClearHandlerMock,
    disableAddAllButton: false,
    importGroupStatus: IMPORT_NOT_STARTED,
    importOutcomesStatus: {},
    importOutcomeHandler: importOutcomeHandlerMock,
    shouldFocusAddAllBtn: false,
    onAddAllHandler: onAddAllHandlerMock,
    loadMore: onLoadMoreHandlerMock,
    ...props,
  })

  beforeEach(() => {
    cache = createCache()
    onChangeHandlerMock = jest.fn()
    onClearHandlerMock = jest.fn()
    importOutcomeHandlerMock = jest.fn()
    onLoadMoreHandlerMock = jest.fn()
    onAddAllHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '1', mocks = findOutcomesMocks()} = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders component with the correct group name and search bar placeholder', () => {
    const {getByText, getByPlaceholderText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('State Standards')).toBeInTheDocument()
    expect(getByPlaceholderText('Search within State Standards')).toBeInTheDocument()
  })

  it('renders component with default group name and search bar placeholder if name is missing in props', () => {
    const {getByText, getByPlaceholderText} = render(
      <FindOutcomesView
        {...defaultProps({
          collection: {
            ...defaultProps().collection,
            name: null,
          },
        })}
      />
    )
    expect(getByText('Outcome Group')).toBeInTheDocument()
    expect(getByPlaceholderText('Search within Outcome Group')).toBeInTheDocument()
  })

  it('renders component with correct number of outcomes', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('3 Outcomes')).toBeInTheDocument()
  })

  it('sets default outcomes to 0 if missing in collection', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            outcomesCount: 0,
          },
        })}
      />
    )
    expect(getByText('0 Outcomes')).toBeInTheDocument()
  })

  it('calls onChangeHandler when users types in searchbar', () => {
    const {getByDisplayValue} = render(
      <FindOutcomesView {...defaultProps({searchString: '123'})} />
    )
    const input = getByDisplayValue('123')
    fireEvent.change(input, {target: {value: 'test'}})
    expect(onChangeHandlerMock).toHaveBeenCalled()
  })

  it('render a message when search does not return any result', () => {
    const {queryByText} = render(
      <FindOutcomesView
        {...defaultProps({
          searchString: 'abc',
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            outcomes: {
              edges: [],
            },
          },
        })}
      />
    )
    expect(queryByText('The search returned no results.')).toBeInTheDocument()
  })

  it('does not render a message when does not have search when group does not have outcome', () => {
    const {queryByText} = render(
      <FindOutcomesView
        {...defaultProps({
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            outcomes: {
              edges: [],
            },
          },
        })}
      />
    )
    expect(queryByText('The search returned no results.')).not.toBeInTheDocument()
  })

  it('calls onClearHandler on click on clear search button', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps({searchString: '123'})} />)
    const btn = getByText('Clear search field')
    fireEvent.click(btn)
    expect(onClearHandlerMock).toHaveBeenCalled()
  })

  it('calls onAddAllHandler on click on "Add All Outcomes" button', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    const btn = getByText('Add All Outcomes')
    fireEvent.click(btn)
    expect(onAddAllHandlerMock).toHaveBeenCalled()
  })

  it('enables "Add All Outcomes" button if group import failed', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importGroupStatus: IMPORT_FAILED,
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('enables "Add All Outcomes" button if group import not started', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importGroupStatus: IMPORT_NOT_STARTED,
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('disables "Add All Outcomes" button if group import is pending', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importGroupStatus: IMPORT_PENDING,
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
  })

  it('enables "Add All Outcomes" button if there are multiple outcomes that are not imported and one gets imported', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importOutcomesStatus: {11: IMPORT_COMPLETED},
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            notImportedOutcomesCount: 2,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('disables "Add All Outcomes" button if the remaining outcome is getting imported', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importOutcomesStatus: {11: IMPORT_PENDING},
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            notImportedOutcomesCount: 1,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
  })

  it('disables "Add All Outcomes" button if the remaining outcome is imported', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importOutcomesStatus: {11: IMPORT_COMPLETED},
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            notImportedOutcomesCount: 1,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
  })

  it('enables "Add All Outcomes" button if the remaining outcome imports and fails', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importOutcomesStatus: {11: IMPORT_FAILED},
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            notImportedOutcomesCount: 1,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('enables "Add All Outcomes" button if no outcomes from the current group were importedr', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          importOutcomesStatus: {0: IMPORT_COMPLETED},
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            notImportedOutcomesCount: 1,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('displays outcome as not added when outcome has not been imported', () => {
    const {getAllByText} = render(<FindOutcomesView {...defaultProps()} />)
    const addButton = getAllByText('Add')[0].closest('button')
    expect(addButton).not.toBeDisabled()
  })

  it('disables "Add All Outcomes" button if number of outcomes eq 0', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          outcomesGroup: {
            ...defaultProps().outcomesGroup,
            outcomesCount: 0,
          },
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
  })

  it('enables "Add All Outcomes" button if there are outcomes in selected group that are not imported into context', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('Add All Outcomes').closest('button')).toBeEnabled()
  })

  it('disables "Add All Outcomes" button if all outcomes from selected group are imported into context', () => {
    const {getByText} = render(
      <FindOutcomesView
        {...defaultProps({
          outcomesGroup: {...defaultProps().outcomesGroup, notImportedOutcomesCount: 0},
        })}
      />
    )
    expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
  })

  it('hides the "Add All Outcomes" button if the collection is a root group', () => {
    const {queryByText} = render(
      <FindOutcomesView
        {...defaultProps({
          collection: {
            ...defaultProps().collection,
            isRootGroup: true,
          },
        })}
      />
    )
    expect(queryByText('Add All Outcomes')).not.toBeInTheDocument()
  })

  it('hides "Add All Outcomes" button if search string is present', () => {
    const {queryByText} = render(<FindOutcomesView {...defaultProps({searchString: 'test'})} />)
    expect(queryByText('Add All Outcomes')).not.toBeInTheDocument()
  })

  it('shows large loader if data is loading and outcomes are missing/undefined', () => {
    const {getByTestId} = render(
      <FindOutcomesView
        {...defaultProps({
          loading: true,
          outcomesGroup: {...defaultProps().outcomesGroup, outcomes: null},
        })}
      />
    )
    expect(getByTestId('loading')).toBeInTheDocument()
  })

  it('shows "Load More" button if there are more outcomes and data is loaded', () => {
    const {getByText} = render(<FindOutcomesView {...defaultProps()} />)
    expect(getByText('Load More')).toBeInTheDocument()
  })

  it('shows small loader if there are more outcomes and data is loading', () => {
    const {getByTestId} = render(<FindOutcomesView {...defaultProps({loading: true})} />)
    expect(getByTestId('load-more-loading')).toBeInTheDocument()
  })

  it('disables the search bar when the "Add All Outcomes" button is pressed', () => {
    const {getByPlaceholderText} = render(
      <FindOutcomesView
        {...defaultProps({
          importGroupStatus: IMPORT_PENDING,
        })}
      />
    )
    expect(getByPlaceholderText('Search within State Standards').closest('input')).toBeDisabled()
  })

  it('enables the search bar after an "Add All Outcomes" import is completed', () => {
    const {getByPlaceholderText} = render(
      <FindOutcomesView
        {...defaultProps({
          importGroupStatus: IMPORT_COMPLETED,
        })}
      />
    )
    expect(getByPlaceholderText('Search within State Standards').closest('input')).toBeEnabled()
  })

  describe('mobile view', () => {
    const mobileRender = children =>
      render(
        <OutcomesContext.Provider value={{env: {isMobileView: true}}}>
          {children}
        </OutcomesContext.Provider>
      )

    it('does not render the group name', () => {
      const {queryByText} = mobileRender(<FindOutcomesView {...defaultProps()} />)
      expect(queryByText('State Standards')).not.toBeInTheDocument()
    })
  })
})
