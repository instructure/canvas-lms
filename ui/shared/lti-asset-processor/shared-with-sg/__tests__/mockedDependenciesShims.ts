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

// This is basically the same in SG2 (replacing vitest with jest) but seemingly
// can't be shared, probably due to special behavior / hoisting of jest.mock /
// vi.mock

type Mock = jest.Mock
import {
  type GetLtiAssetProcessorsResult,
  type GetLtiAssetReportsResult,
  useLtiAssetProcessors,
  useLtiAssetReports,
} from '../dependenciesShims'

jest.mock('../dependenciesShims', () => ({
  gql: jest.fn(),
  useResubmitLtiAssetReports: jest.fn(() => ({
    resubmitLtiAssetReports: jest.fn(),
  })),
  useLtiAssetProcessors: jest.fn(),
  useLtiAssetReports: jest.fn(),
  useFormatDateTime: jest.fn(() => jest.fn((date: Date) => date.toISOString())),
}))

export function mockUseLtiAssetProcessors(data: GetLtiAssetProcessorsResult): void {
  // mock out dependenciesShims useLtiAssetProcessors
  ;(useLtiAssetProcessors as Mock).mockReturnValue({
    data,
    isLoading: false,
    isError: false,
  })
}

export function mockUseLtiAssetReports(data: GetLtiAssetReportsResult | undefined): void {
  if (data === undefined) {
    ;(useLtiAssetReports as Mock).mockReturnValue({
      data,
      isLoading: true,
      isError: false,
    })
  }
  ;(useLtiAssetReports as Mock).mockReturnValue({
    data,
    isLoading: false,
    isError: false,
  })
}
