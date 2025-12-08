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

import {LTI_ASSET_PROCESSORS_QUERY} from '@canvas/lti-asset-processor/shared-with-sg/replicated/queries/getLtiAssetProcessors'
import {useLtiAssetProcessors, useLtiAssetReports} from '../graphqlQueryHooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {render, waitFor} from '@testing-library/react'
import {executeQuery} from '@canvas/graphql'
import {defaultGetLtiAssetProcessorsResult} from '@canvas/lti-asset-processor/shared-with-sg/replicated/__fixtures__/default/ltiAssetProcessors'
import {defaultGetLtiAssetReportsResult} from '@canvas/lti-asset-processor/shared-with-sg/replicated/__fixtures__/default/ltiAssetReports'
import {LTI_ASSET_REPORTS_QUERY} from '@canvas/lti-asset-processor/shared-with-sg/replicated/queries/getLtiAssetReports'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/graphql', () => ({
  executeQuery: jest.fn(() => 'foo'),
}))

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

let queryClient: QueryClient

const renderWithQueryClient = (ui: React.ReactElement) =>
  render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)

let backupENV = window.ENV

beforeEach(() => {
  backupENV = window.ENV
  window.ENV = {...backupENV, FEATURES: {...backupENV.FEATURES, lti_asset_processor: true}}

  queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  jest.clearAllMocks()
})

afterEach(() => {
  window.ENV = backupENV
})

function mockExecuteQuery(returnValue: any) {
  ;(executeQuery as jest.MockedFunction<typeof executeQuery>).mockReturnValue(
    Promise.resolve(returnValue),
  )
}

async function renderAndWaitForData(ui: React.ReactElement) {
  const rendered = renderWithQueryClient(ui)
  await waitFor(() => expect(rendered.getByTestId('test-data')).toBeInTheDocument())
  const elem = rendered.getByTestId('test-data')
  const returnedData = JSON.parse(elem.innerText)
  return returnedData
}

describe('useLtiAssetProcessors', () => {
  function TestUseLtiAssetProcessorsComponent({
    args,
  }: {
    args: Parameters<typeof useLtiAssetProcessors>
  }) {
    const query = useLtiAssetProcessors(...args)
    return !query.data ? null : <div data-testid="test-data">{JSON.stringify(query.data)}</div>
  }

  const params: Parameters<typeof useLtiAssetProcessors> = [{assignmentId: '123'}]

  it('calls executeQuery with the correct parameters', async () => {
    mockExecuteQuery(defaultGetLtiAssetProcessorsResult)

    const returnedData = await renderAndWaitForData(
      <TestUseLtiAssetProcessorsComponent args={params} />,
    )

    expect(returnedData).toEqual(defaultGetLtiAssetProcessorsResult)
    expect(executeQuery).toHaveBeenCalledWith(LTI_ASSET_PROCESSORS_QUERY, ...params)
  })

  it('does not call executeQuery when the feature flag is disabled', async () => {
    window.ENV = {...backupENV, FEATURES: {...backupENV.FEATURES, lti_asset_processor: false}}
    mockExecuteQuery(defaultGetLtiAssetProcessorsResult)

    const rendered = renderWithQueryClient(<TestUseLtiAssetProcessorsComponent args={params} />)

    await waitFor(() => expect(rendered.queryByTestId('test-data')).not.toBeInTheDocument())

    expect(executeQuery).not.toHaveBeenCalled()
  })

  it('shows a flash alert on error', async () => {
    ;(executeQuery as jest.MockedFunction<typeof executeQuery>).mockRejectedValue(
      new Error('Network error'),
    )

    renderWithQueryClient(<TestUseLtiAssetProcessorsComponent args={params} />)

    await waitFor(() =>
      expect(showFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Error loading Document Processors',
          type: 'error',
        }),
      ),
    )
  })
})

describe('useLtiAssetReports', () => {
  function TestUseLtiAssetReportsComponent({args}: {args: Parameters<typeof useLtiAssetReports>}) {
    const query = useLtiAssetReports(...args)
    return !query.data ? null : <div data-testid="test-data">{JSON.stringify(query.data)}</div>
  }

  const params: Parameters<typeof useLtiAssetReports> = [
    {assignmentId: '123', studentUserId: '456', studentAnonymousId: null},
  ]

  it('calls executeQuery with the correct parameters', async () => {
    const responseData = defaultGetLtiAssetReportsResult()
    mockExecuteQuery(responseData)

    const returnedData = await renderAndWaitForData(
      <TestUseLtiAssetReportsComponent args={params} />,
    )

    expect(returnedData).toEqual(responseData)
    expect(executeQuery).toHaveBeenCalledWith(LTI_ASSET_REPORTS_QUERY, ...params)
  })

  it('does not call executeQuery when the feature flag is disabled', async () => {
    window.ENV = {...backupENV, FEATURES: {...backupENV.FEATURES, lti_asset_processor: false}}
    mockExecuteQuery(defaultGetLtiAssetReportsResult())

    const rendered = renderWithQueryClient(<TestUseLtiAssetReportsComponent args={params} />)

    await waitFor(() => expect(rendered.queryByTestId('test-data')).not.toBeInTheDocument())

    expect(executeQuery).not.toHaveBeenCalled()
  })

  it('does not call executeQuery when cancel is true', async () => {
    mockExecuteQuery(defaultGetLtiAssetReportsResult())

    const rendered = renderWithQueryClient(
      <TestUseLtiAssetReportsComponent args={[params[0], {cancel: true}]} />,
    )

    await waitFor(() => expect(rendered.queryByTestId('test-data')).not.toBeInTheDocument())

    expect(executeQuery).not.toHaveBeenCalled()
  })

  it('does not call executeQuery unless both studentUserId and studentAnonymousId are provided', async () => {
    mockExecuteQuery(defaultGetLtiAssetReportsResult())

    const rendered = renderWithQueryClient(
      <TestUseLtiAssetReportsComponent
        args={[{assignmentId: '123', studentUserId: null, studentAnonymousId: null}]}
      />,
    )

    await waitFor(() => expect(rendered.queryByTestId('test-data')).not.toBeInTheDocument())

    expect(executeQuery).not.toHaveBeenCalled()
  })

  it('shows a flash alert on error', async () => {
    ;(executeQuery as jest.MockedFunction<typeof executeQuery>).mockRejectedValue(
      new Error('Network error'),
    )

    renderWithQueryClient(<TestUseLtiAssetReportsComponent args={params} />)

    await waitFor(() =>
      expect(showFlashAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Error loading Document Processor Reports',
          type: 'error',
        }),
      ),
    )
  })
})
