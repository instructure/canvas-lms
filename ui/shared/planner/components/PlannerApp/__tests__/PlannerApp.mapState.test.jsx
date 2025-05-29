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
// No React import needed for this test file
import {mapStateToProps} from '../index'

describe('PlannerApp mapStateToProps', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('maps isLoading to true when state.loading.isLoading is true', () => {
    const state = {
      loading: {
        isLoading: true,
        hasSomeItems: false,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({isLoading: true})
  })

  it('maps isLoading to true when hasSomeItems is null', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: null,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({isLoading: true})
  })

  it('maps isLoading to false when hasSomeItems is false', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: false,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({isLoading: false})
  })

  it('maps isCompletelyEmpty correctly when there are no items', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: false,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({isCompletelyEmpty: true})
  })

  it('maps isCompletelyEmpty to false when there are items', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: true,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [['2024-05-29', [{}]]],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({isCompletelyEmpty: false})
  })

  it('maps loadingPast from state', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: false,
        loadingPast: true,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({loadingPast: true})
  })

  it('maps allPastItemsLoaded from state', () => {
    const state = {
      loading: {
        isLoading: false,
        hasSomeItems: false,
        allPastItemsLoaded: true,
        partialPastDays: [],
        partialFutureDays: [],
        partialWeekDays: [],
      },
      days: [],
    }
    const props = mapStateToProps(state)
    expect(props).toMatchObject({allPastItemsLoaded: true})
  })
})
