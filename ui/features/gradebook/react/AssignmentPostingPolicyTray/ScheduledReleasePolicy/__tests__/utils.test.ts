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

import {hasScheduledReleaseChanged, validateRelease, combineDateTime} from '../utils/utils'
import {ScheduledRelease} from '../ScheduledReleasePolicy'

describe('utils', () => {
  describe('hasScheduledReleaseChanged', () => {
    it('returns false when both posts are null', () => {
      expect(hasScheduledReleaseChanged(null, null)).toBe(false)
    })

    it('returns false when both posts are undefined', () => {
      expect(hasScheduledReleaseChanged(null, undefined)).toBe(false)
    })

    it('returns true when updated post is provided but original is null', () => {
      const updatedPost: ScheduledRelease = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
        scheduledPostMode: 'shared',
      }
      expect(hasScheduledReleaseChanged(updatedPost, null)).toBe(true)
    })

    it('returns false when dates are identical', () => {
      const updatedPost: ScheduledRelease = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
        scheduledPostMode: 'shared',
      }
      const originalPost = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
      }
      expect(hasScheduledReleaseChanged(updatedPost, originalPost)).toBe(false)
    })

    it('returns true when grades date changes', () => {
      const updatedPost: ScheduledRelease = {
        postGradesAt: '2025-12-18T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
        scheduledPostMode: 'shared',
      }
      const originalPost = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
      }
      expect(hasScheduledReleaseChanged(updatedPost, originalPost)).toBe(true)
    })

    it('returns true when comments date changes', () => {
      const updatedPost: ScheduledRelease = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-18T14:35:00.000Z',
        scheduledPostMode: 'shared',
      }
      const originalPost = {
        postGradesAt: '2025-12-17T14:35:00.000Z',
        postCommentsAt: '2025-12-17T14:35:00.000Z',
      }
      expect(hasScheduledReleaseChanged(updatedPost, originalPost)).toBe(true)
    })
  })

  describe('validateRelease', () => {
    const futureDate = new Date()
    futureDate.setDate(futureDate.getDate() + 1)
    const futureDateString = futureDate.toISOString()

    const pastDate = new Date()
    pastDate.setDate(pastDate.getDate() - 1)
    const pastDateString = pastDate.toISOString()

    describe('when scheduledPostMode is not set', () => {
      it('returns no errors', () => {
        const release: ScheduledRelease = {
          postGradesAt: null,
          postCommentsAt: null,
          scheduledPostMode: undefined,
        }
        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })
    })

    describe('shared mode', () => {
      it('returns no errors for valid future date when date has changed', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
          scheduledPostMode: 'shared',
        }
        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns error when date is null and scheduled post mode set', () => {
        const release: ScheduledRelease = {
          postGradesAt: null,
          postCommentsAt: null,
          scheduledPostMode: 'shared',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(1)
        expect(errors.grades[0].text).toContain('Please enter a valid grades release date')
      })

      it('returns error when date is in the past and has changed', () => {
        const release: ScheduledRelease = {
          postGradesAt: pastDateString,
          postCommentsAt: pastDateString,
          scheduledPostMode: 'shared',
        }
        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(1)
        expect(errors.grades[0].text).toContain('Date must be in the future')
      })

      it('returns no error when date has not changed from original', () => {
        const release: ScheduledRelease = {
          postGradesAt: pastDateString,
          postCommentsAt: pastDateString,
          scheduledPostMode: 'shared',
        }
        const originalPost = {
          postGradesAt: pastDateString,
          postCommentsAt: pastDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('compares dates by timestamp not string format', () => {
        const utcDate = '2025-12-17T14:35:00.000Z'
        const mtDate = '2025-12-17T07:35:00-07:00'

        const release: ScheduledRelease = {
          postGradesAt: utcDate,
          postCommentsAt: utcDate,
          scheduledPostMode: 'shared',
        }
        const originalPost = {
          postGradesAt: mtDate,
          postCommentsAt: mtDate,
        }

        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })
    })

    describe('separate mode', () => {
      it('returns no errors for valid future dates when dates have changed', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
          scheduledPostMode: 'separate',
        }
        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns error when grades date is removed and scheduled post mode set', () => {
        const release: ScheduledRelease = {
          postGradesAt: null,
          postCommentsAt: futureDateString,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(1)
        expect(errors.grades[0].text).toContain('Please enter a valid grades release date')
      })

      it('returns error when comments date is removed and scheduled post mode set', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: null,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.comments).toHaveLength(1)
        expect(errors.comments[0].text).toContain('Please enter a valid comments release date')
      })

      it('returns errors when both dates are removed and scheduled post mode set', () => {
        const release: ScheduledRelease = {
          postGradesAt: null,
          postCommentsAt: null,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(1)
        expect(errors.comments).toHaveLength(1)
      })

      it('returns error when grades date is in the past and has changed', () => {
        const futureDate2 = new Date()
        futureDate2.setDate(futureDate2.getDate() + 2)
        const futureDate2String = futureDate2.toISOString()

        const pastCommentsDate = new Date()
        pastCommentsDate.setDate(pastCommentsDate.getDate() - 2)
        const pastCommentsDateString = pastCommentsDate.toISOString()

        const release: ScheduledRelease = {
          postGradesAt: pastDateString,
          postCommentsAt: pastCommentsDateString,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDate2String,
          postCommentsAt: pastCommentsDateString,
        }
        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(1)
        expect(errors.grades[0].text).toContain('Date must be in the future')
      })

      it('returns error when comments date is in the past and has changed', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: pastDateString,
          scheduledPostMode: 'separate',
        }
        const errors = validateRelease(release, null)
        expect(errors.comments).toHaveLength(1)
        expect(errors.comments[0].text).toContain('Date must be in the future')
      })

      it('returns no error when only grades date has changed and is valid', () => {
        const futureDate2 = new Date()
        futureDate2.setDate(futureDate2.getDate() + 2)
        const futureDate2String = futureDate2.toISOString()

        const release: ScheduledRelease = {
          postGradesAt: futureDate2String,
          postCommentsAt: futureDateString,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
        }

        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns no error when only comments date has changed and is valid', () => {
        const commentsDate1 = new Date()
        commentsDate1.setDate(commentsDate1.getDate() + 1)
        const commentsDate1String = commentsDate1.toISOString()

        const commentsDate2 = new Date()
        commentsDate2.setDate(commentsDate2.getDate() + 2)
        const commentsDate2String = commentsDate2.toISOString()

        const gradesDate = new Date()
        gradesDate.setDate(gradesDate.getDate() + 3)
        const gradesDateString = gradesDate.toISOString()

        const release: ScheduledRelease = {
          postGradesAt: gradesDateString,
          postCommentsAt: commentsDate2String,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: gradesDateString,
          postCommentsAt: commentsDate1String,
        }

        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns no error for past grades date when it has not changed', () => {
        const commentsDate = new Date()
        commentsDate.setDate(commentsDate.getDate() - 2)
        const commentsDateString = commentsDate.toISOString()

        const release: ScheduledRelease = {
          postGradesAt: pastDateString,
          postCommentsAt: commentsDateString,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: pastDateString,
          postCommentsAt: commentsDateString,
        }

        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns no error for past comments date when it has not changed', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: pastDateString,
          scheduledPostMode: 'separate',
        }
        const originalPost = {
          postGradesAt: futureDateString,
          postCommentsAt: pastDateString,
        }

        const errors = validateRelease(release, originalPost)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })

      it('returns errors when grades date is before comments date', () => {
        const commentsDate = new Date()
        commentsDate.setDate(commentsDate.getDate() + 1)
        const commentsDateString = commentsDate.toISOString()

        const gradesDate = new Date()
        gradesDate.setDate(gradesDate.getDate() + 2)
        const gradesDateString = gradesDate.toISOString()

        const release: ScheduledRelease = {
          postGradesAt: commentsDateString,
          postCommentsAt: gradesDateString,
          scheduledPostMode: 'separate',
        }

        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(1)
        expect(errors.comments).toHaveLength(1)
        expect(errors.grades[0].text).toContain(
          'Grades release date and time must be the same or after comments release date',
        )
        expect(errors.comments[0].text).toContain(
          'Comments release date and time must be the same or before grades release date',
        )
      })

      it('returns no errors when grades and comments dates are the same', () => {
        const release: ScheduledRelease = {
          postGradesAt: futureDateString,
          postCommentsAt: futureDateString,
          scheduledPostMode: 'separate',
        }

        const errors = validateRelease(release, null)
        expect(errors.grades).toHaveLength(0)
        expect(errors.comments).toHaveLength(0)
      })
    })
  })

  describe('combineDateTime', () => {
    it('returns undefined when both date and time are null', () => {
      const result = combineDateTime(null, null)
      expect(result).toBeUndefined()
    })

    it('returns undefined when both date and time are undefined', () => {
      const result = combineDateTime(undefined, undefined)
      expect(result).toBeUndefined()
    })

    it('combines date and time correctly when both are provided', () => {
      const dateString = '2025-12-17T00:00:00.000Z'
      const timeString = '2025-01-01T14:30:00.000Z'

      const result = combineDateTime(dateString, timeString)
      const combined = new Date(result!)

      // combineDateTime uses local timezone components
      const expectedDate = new Date(dateString)
      const expectedTime = new Date(timeString)

      expect(combined.getFullYear()).toBe(expectedDate.getFullYear())
      expect(combined.getMonth()).toBe(expectedDate.getMonth())
      expect(combined.getDate()).toBe(expectedDate.getDate())
      expect(combined.getHours()).toBe(expectedTime.getHours())
      expect(combined.getMinutes()).toBe(expectedTime.getMinutes())
    })

    it('uses midnight as default time when only date is provided', () => {
      const dateString = '2025-12-17T15:45:30.500Z'

      const result = combineDateTime(dateString, null)
      const combined = new Date(result!)

      // combineDateTime uses local timezone components
      const expectedDate = new Date(dateString)

      // Should preserve the date but use midnight time (in local timezone)
      expect(combined.getFullYear()).toBe(expectedDate.getFullYear())
      expect(combined.getMonth()).toBe(expectedDate.getMonth())
      expect(combined.getDate()).toBe(expectedDate.getDate())
      expect(combined.getHours()).toBe(0)
      expect(combined.getMinutes()).toBe(0)
      expect(combined.getSeconds()).toBe(0)
    })

    it("uses today's date when only time is provided", () => {
      const now = new Date()
      const timeString = '2020-01-01T14:30:45.000Z'

      const result = combineDateTime(null, timeString)
      const combined = new Date(result!)
      const expectedTime = new Date(timeString)

      // Should use today's date (in local timezone)
      expect(combined.getFullYear()).toBe(now.getFullYear())
      expect(combined.getMonth()).toBe(now.getMonth())
      expect(combined.getDate()).toBe(now.getDate())
      // Should use time from timeString (in local timezone)
      expect(combined.getHours()).toBe(expectedTime.getHours())
      expect(combined.getMinutes()).toBe(expectedTime.getMinutes())
      expect(combined.getSeconds()).toBe(expectedTime.getSeconds())
    })
  })
})
