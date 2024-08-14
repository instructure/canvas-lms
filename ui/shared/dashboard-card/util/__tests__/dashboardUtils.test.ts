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

import {
  sortByPosition,
  mapActivityStreamSummaries,
  mapDashboardResponseToCard,
  handleDashboardCardError,
  processDashboardCards,
} from '../dashboardUtils'
import type {ActivityStreamSummary, Card} from '../../types'
import {CourseDashboardCard as CourseDashboardCardType} from '../../graphql/CourseDashboardCard'
import {ActivityStreamSummary as ActivityStreamSummaryType} from '../../graphql/ActivityStream'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

describe('sortByPosition', () => {
  it('handles first position smaller', () => {
    const a = {position: 1}
    const b = {position: 2}
    expect(sortByPosition(a, b)).toBeLessThan(0)
  })

  it('handles first position larger', () => {
    const a = {position: 2}
    const b = {position: 1}
    expect(sortByPosition(a, b)).toBeGreaterThan(0)
  })

  it('handles positions equal', () => {
    const a = {position: 1}
    const b = {position: 1}
    expect(sortByPosition(a, b)).toBe(0)
  })

  it('handles first undefined', () => {
    const a = {position: undefined}
    const b = {position: 1}
    expect(sortByPosition(a, b)).toBeGreaterThan(0)
  })

  it('handles second undefined', () => {
    const a = {position: 1}
    const b = {position: undefined}
    expect(sortByPosition(a, b)).toBeLessThan(0)
  })

  it('handles both undefined', () => {
    const a = {position: undefined}
    const b = {position: undefined}
    expect(sortByPosition(a, b)).toBe(0)
  })
})

describe('mapActivityStreamSummaries', () => {
  it('maps activity stream summaries', () => {
    const mockedStreamItems = ActivityStreamSummaryType.mock().summary
    const mockResponse = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {
              _id: '123',
              activityStream: {
                summary: mockedStreamItems,
              },
            },
          ],
        },
      },
    }

    const expectedMappedData: ActivityStreamSummary[] = [
      {
        id: '123',
        summary: mockedStreamItems.map((item: any) => ({
          count: item.count,
          notification_category: item.notificationCategory,
          type: item.type,
          unread_count: item.unreadCount,
        })),
      },
    ]

    expect(mapActivityStreamSummaries(mockResponse)).toEqual(expectedMappedData)
  })

  it('returns empty array if no data', () => {
    expect(mapActivityStreamSummaries(null)).toEqual([])
  })

  it('handles if activityStream is null', () => {
    const mockResponse = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {
              _id: '123',
              activityStream: null,
            },
          ],
        },
      },
    }

    const expectedMappedData: ActivityStreamSummary[] = [
      {
        id: '123',
        summary: [],
      },
    ]

    expect(mapActivityStreamSummaries(mockResponse)).toEqual(expectedMappedData)
  })
})

describe('mapDashboardResponseToCard', () => {
  it('maps dashboard response to card', () => {
    const mockedDashCard = CourseDashboardCardType.mock()
    const mockResponse = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {
              _id: '123',
              dashboardCard: mockedDashCard,
            },
          ],
        },
      },
    }

    const expectedMappedData: Card[] = [
      {
        shortName: mockedDashCard.shortName,
        originalName: mockedDashCard.originalName,
        courseCode: mockedDashCard.courseCode,
        id: '123',
        href: mockedDashCard.href,
        links: mockedDashCard.links,
        term: mockedDashCard.term.name !== 'Default Term' ? mockedDashCard.term.name : null,
        assetString: mockedDashCard.assetString,
        color: mockedDashCard.color,
        image: mockedDashCard.image,
        isFavorited: mockedDashCard.isFavorited,
        enrollmentType: mockedDashCard.enrollmentType,
        enrollmentState: mockedDashCard.enrollmentState,
        observee: mockedDashCard.observee,
        position: mockedDashCard.position,
        published: mockedDashCard.published,
        canChangeCoursePublishState: mockedDashCard.canChangeCoursePublishState,
        defaultView: mockedDashCard.defaultView,
        pagesUrl: mockedDashCard.pagesUrl,
        frontPageTitle: mockedDashCard.frontPageTitle,
        isK5Subject: mockedDashCard.isK5Subject,
        isHomeroom: mockedDashCard.isHomeroom,
        canReadAnnouncements: mockedDashCard.canReadAnnouncements,
        canManage: mockedDashCard.canManage,
        longName: mockedDashCard.longName,
      },
    ]

    expect(mapDashboardResponseToCard(mockResponse)).toEqual(expectedMappedData)
  })

  it('returns empty array if no data', () => {
    expect(mapDashboardResponseToCard(null)).toEqual([])
  })

  it('returns empty array if dashboardCard is null', () => {
    const mockResponse = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {
              _id: '123',
              dashboardCard: null,
            },
          ],
        },
      },
    }

    expect(mapDashboardResponseToCard(mockResponse)).toEqual([])
  })
})

describe('processDashboardCards', () => {
  it('maps and sorts dashboard cards', () => {
    const mockedDashCard1 = CourseDashboardCardType.mock()
    const mockedDashCard2 = CourseDashboardCardType.mock()
    const mockedDashCard3 = CourseDashboardCardType.mock()

    // Not in order
    mockedDashCard1.position = 2
    mockedDashCard2.position = 1
    mockedDashCard3.position = 3

    const mockData = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {_id: '1', dashboardCard: mockedDashCard1},
            {_id: '2', dashboardCard: mockedDashCard2},
            {_id: '3', dashboardCard: mockedDashCard3},
          ],
        },
      },
    }

    const result = processDashboardCards(mockData)

    expect(result).toHaveLength(3)
    expect(result[0].id).toBe('2') // position 1 should be first
    expect(result[1].id).toBe('1') // position 2 should be second
    expect(result[2].id).toBe('3') // position 3 should be third
  })

  it('returns empty array if no data', () => {
    const result = processDashboardCards(null)
    expect(result).toEqual([])
  })

  it('handles single card correctly', () => {
    const mockedDashCard = CourseDashboardCardType.mock()
    const mockData = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [{_id: '1', dashboardCard: mockedDashCard}],
        },
      },
    }

    const result = processDashboardCards(mockData)

    expect(result).toHaveLength(1)
    expect(result[0].id).toBe('1')
  })

  it('filters out null dashboard cards', () => {
    const mockedDashCard = CourseDashboardCardType.mock()
    const mockData = {
      legacyNode: {
        favoriteCoursesConnection: {
          nodes: [
            {_id: '1', dashboardCard: mockedDashCard},
            {_id: '2', dashboardCard: null},
            {_id: '3', dashboardCard: mockedDashCard},
          ],
        },
      },
    }

    const result = processDashboardCards(mockData)

    expect(result).toHaveLength(2)
    expect(result.map(card => card.id)).toEqual(['1', '3'])
  })
})

describe('handleDashboardCardError', () => {
  it('shows flash alert', () => {
    const e = new Error('Some error')
    handleDashboardCardError(e)

    expect(showFlashAlert).toHaveBeenCalledWith({
      err: e,
      message: 'Failed loading course cards',
      type: 'error',
    })
  })
})
