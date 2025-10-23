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

import {renderHook, act} from '@testing-library/react-hooks/dom'
import {
  usePeerReviewSettings,
  MAX_NUM_PEER_REVIEWS,
  type PeerReviewSettings,
} from '../usePeerReviewSettings'

describe('usePeerReviewSettings', () => {
  const defaultProps = (): PeerReviewSettings => ({
    reviewsRequired: 1,
    pointsPerReview: 0,
    totalPoints: 0,
    allowPeerReviewAcrossMultipleSections: true,
    allowPeerReviewWithinGroups: false,
    usePassFailGrading: false,
    anonymousPeerReviews: false,
    submissionRequiredBeforePeerReviews: false,
  })

  it('initializes with default values', () => {
    const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

    expect(result.current.reviewsRequired).toBe('1')
    expect(result.current.pointsPerReview).toBe('0')
    expect(result.current.totalPoints).toBe('0')
    expect(result.current.errorMessageReviewsRequired).toBeUndefined()
    expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)
    expect(result.current.allowPeerReviewWithinGroups).toBe(false)
    expect(result.current.usePassFailGrading).toBe(false)
    expect(result.current.anonymousPeerReviews).toBe(false)
    expect(result.current.submissionRequiredBeforePeerReviews).toBe(false)
  })

  it('sets initial reviewsRequired based on reviewsRequired prop', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), reviewsRequired: 3}),
    )
    expect(result.current.reviewsRequired).toBe('3')
  })

  it('sets initial submissionRequiredBeforePeerReviews to false when submissionRequired is false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), submissionRequiredBeforePeerReviews: false}),
    )
    expect(result.current.submissionRequiredBeforePeerReviews).toBe(false)
  })

  it('sets initial submissionRequiredBeforePeerReviews to true when submissionRequired is true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), submissionRequiredBeforePeerReviews: true}),
    )
    expect(result.current.submissionRequiredBeforePeerReviews).toBe(true)
  })

  it('sets initial pointsPerReview based on pointsPerReview prop', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), pointsPerReview: 15}),
    )
    expect(result.current.pointsPerReview).toBe('15')
  })

  describe('pointsPerReview formatting', () => {
    it('formats initial pointsPerReview with 2 decimals when value has more decimals', () => {
      const {result} = renderHook(() =>
        usePeerReviewSettings({...defaultProps(), pointsPerReview: 1.123}),
      )
      expect(result.current.pointsPerReview).toBe('1.12')
    })

    it('rounds up to 2 decimals when third decimal is >= 5', () => {
      const {result} = renderHook(() =>
        usePeerReviewSettings({...defaultProps(), pointsPerReview: 1.126}),
      )
      expect(result.current.pointsPerReview).toBe('1.13')
    })

    it('formats initial pointsPerReview as integer when value rounds to whole number', () => {
      const {result} = renderHook(() =>
        usePeerReviewSettings({...defaultProps(), pointsPerReview: 7.999}),
      )
      expect(result.current.pointsPerReview).toBe('8')
    })

    it('formats zero as "0" without decimals', () => {
      const {result} = renderHook(() =>
        usePeerReviewSettings({...defaultProps(), pointsPerReview: 0}),
      )
      expect(result.current.pointsPerReview).toBe('0')
    })

    it('formats integer values without decimal places', () => {
      const {result} = renderHook(() =>
        usePeerReviewSettings({...defaultProps(), pointsPerReview: 5}),
      )
      expect(result.current.pointsPerReview).toBe('5')
    })

    it('formats value after validation on blur', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      // Simulate user entering a value with many decimals
      act(() => {
        result.current.handlePointsPerReviewChange(
          {} as React.ChangeEvent<HTMLInputElement>,
          '3.14159',
        )
      })

      expect(result.current.pointsPerReview).toBe('3.14159') // Not formatted yet

      act(() => {
        const mockEvent = {
          target: {
            value: '3.14159',
            validity: {valid: true},
          },
        } as React.FocusEvent<HTMLInputElement>
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.pointsPerReview).toBe('3.14') // Formatted to 2 decimals
      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('formats value that rounds to integer after validation', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange(
          {} as React.ChangeEvent<HTMLInputElement>,
          '7.999',
        )
      })

      act(() => {
        const mockEvent = {
          target: {
            value: '7.999',
            validity: {valid: true},
          },
        } as React.FocusEvent<HTMLInputElement>
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.pointsPerReview).toBe('8') // Formatted as integer, no decimals
      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('formats value when validation fails and shows error', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange(
          {} as React.ChangeEvent<HTMLInputElement>,
          '-5.123',
        )
      })

      act(() => {
        const mockEvent = {
          target: {
            value: '-5.123',
            validity: {valid: true},
          },
        } as React.FocusEvent<HTMLInputElement>
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.pointsPerReview).toBe('-5.12')
      expect(result.current.errorMessagePointsPerReview).toBe(
        'Points per review cannot be negative.',
      )
    })
  })

  it('calculates totalPoints based on initial reviewsRequired and pointsPerReview', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), reviewsRequired: 3, pointsPerReview: 10}),
    )
    expect(result.current.totalPoints).toBe('30')
  })

  it('sets initial allowPeerReviewAcrossMultipleSections to true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewAcrossMultipleSections: true}),
    )
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)
  })

  it('sets initial allowPeerReviewAcrossMultipleSections to false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewAcrossMultipleSections: false}),
    )
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(false)
  })

  it('sets initial allowPeerReviewWithinGroups to true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewWithinGroups: true}),
    )
    expect(result.current.allowPeerReviewWithinGroups).toBe(true)
  })

  it('sets initial allowPeerReviewWithinGroups to false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewWithinGroups: false}),
    )
    expect(result.current.allowPeerReviewWithinGroups).toBe(false)
  })

  it('sets initial usePassFailGrading to true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), usePassFailGrading: true}),
    )
    expect(result.current.usePassFailGrading).toBe(true)
  })

  it('sets initial usePassFailGrading to false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), usePassFailGrading: false}),
    )
    expect(result.current.usePassFailGrading).toBe(false)
  })

  it('sets initial anonymousPeerReviews to true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), anonymousPeerReviews: true}),
    )
    expect(result.current.anonymousPeerReviews).toBe(true)
  })

  it('sets initial anonymousPeerReviews to false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), anonymousPeerReviews: false}),
    )
    expect(result.current.anonymousPeerReviews).toBe(false)
  })

  it('sets multiple initial values at once', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({
        reviewsRequired: 5,
        pointsPerReview: 10,
        totalPoints: 50,
        allowPeerReviewAcrossMultipleSections: true,
        allowPeerReviewWithinGroups: true,
        usePassFailGrading: true,
        anonymousPeerReviews: true,
        submissionRequiredBeforePeerReviews: true,
      }),
    )
    expect(result.current.reviewsRequired).toBe('5')
    expect(result.current.pointsPerReview).toBe('10')
    expect(result.current.totalPoints).toBe('50')
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)
    expect(result.current.allowPeerReviewWithinGroups).toBe(true)
    expect(result.current.usePassFailGrading).toBe(true)
    expect(result.current.anonymousPeerReviews).toBe(true)
    expect(result.current.submissionRequiredBeforePeerReviews).toBe(true)
  })

  it('sets initial allowPeerReviewAcrossMultipleSections to true when acrossSections is true', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewAcrossMultipleSections: true}),
    )
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)
  })

  it('sets initial allowPeerReviewAcrossMultipleSections to false when acrossSections is false', () => {
    const {result} = renderHook(() =>
      usePeerReviewSettings({...defaultProps(), allowPeerReviewAcrossMultipleSections: false}),
    )
    expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(false)
  })

  describe('reviews required validation', () => {
    it('handles valid numeric input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '5')
      })

      expect(result.current.reviewsRequired).toBe('5')
      expect(result.current.errorMessageReviewsRequired).toBeUndefined()
    })

    it('clears error message when value becomes valid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '-1')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBeDefined()

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '3')
      })

      expect(result.current.errorMessageReviewsRequired).toBeUndefined()
    })

    it('requires input when empty and valid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe('Number of peer reviews is required.')
      expect(result.current.reviewsRequired).toBe('')
    })

    it('validates non-integer input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '2.5')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe(
        'Number of peer reviews must be a whole number.',
      )
    })

    it('validates negative input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '-1')
      })

      act(() => {
        result.current.validateReviewsRequired({} as React.FocusEvent<HTMLInputElement>)
      })

      expect(result.current.errorMessageReviewsRequired).toBe(
        'Number of peer reviews cannot be negative.',
      )
    })

    it('validates input exceeding maximum', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '15')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe(
        `Number of peer reviews cannot exceed ${MAX_NUM_PEER_REVIEWS}.`,
      )
    })

    it('validates non-numeric input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, 'abc')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe('Number of peer reviews is required.')
    })

    it('validates zero as invalid input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '0')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe('Number of peer reviews is required.')
    })

    it('validates browser-rejected invalid input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '')
      })

      const mockEvent = {
        target: {
          validity: {valid: false},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validateReviewsRequired(mockEvent)
      })

      expect(result.current.errorMessageReviewsRequired).toBe('Please enter a valid number.')
    })

    it('returns undefined when field is valid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '5')
      })

      let errorMessage
      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        errorMessage = result.current.validateReviewsRequired(mockEvent)
      })

      expect(errorMessage).toBeUndefined()
      expect(result.current.errorMessageReviewsRequired).toBeUndefined()
    })

    it('returns error message when field is invalid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '-1')
      })

      let errorMessage
      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        errorMessage = result.current.validateReviewsRequired(mockEvent)
      })

      expect(errorMessage).toBe('Number of peer reviews cannot be negative.')
      expect(result.current.errorMessageReviewsRequired).toBe(
        'Number of peer reviews cannot be negative.',
      )
    })
  })

  describe('points per review validation', () => {
    it('handles valid numeric input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      expect(result.current.pointsPerReview).toBe('10')
      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('clears error message when value becomes valid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '-5')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.errorMessagePointsPerReview).toBe(
        'Points per review cannot be negative.',
      )

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '5')
      })

      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('validates negative input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '-5')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.errorMessagePointsPerReview).toBe(
        'Points per review cannot be negative.',
      )
    })

    it('does not set error for valid zero value', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '0')
        result.current.validatePointsPerReview({} as React.FocusEvent<HTMLInputElement>)
      })

      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('does not set error for valid decimal value', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '2.5')
        result.current.validatePointsPerReview({} as React.FocusEvent<HTMLInputElement>)
      })

      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('validates browser-rejected invalid input', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '')
      })

      const mockEvent = {
        target: {
          validity: {valid: false},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validatePointsPerReview(mockEvent)
      })

      expect(result.current.errorMessagePointsPerReview).toBe('Please enter a valid number.')
    })

    it('returns undefined when field is valid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      let errorMessage
      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        errorMessage = result.current.validatePointsPerReview(mockEvent)
      })

      expect(errorMessage).toBeUndefined()
      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
    })

    it('returns error message when field is invalid', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '-5')
      })

      let errorMessage
      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        errorMessage = result.current.validatePointsPerReview(mockEvent)
      })

      expect(errorMessage).toBe('Points per review cannot be negative.')
      expect(result.current.errorMessagePointsPerReview).toBe(
        'Points per review cannot be negative.',
      )
    })
  })

  describe('total points calculation', () => {
    it('calculates total points correctly for whole numbers', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '3')
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      expect(result.current.totalPoints).toBe('30')
    })

    it('calculates total points correctly for decimal results', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '3')
        result.current.handlePointsPerReviewChange(
          {} as React.ChangeEvent<HTMLInputElement>,
          '3.33',
        )
      })

      expect(result.current.totalPoints).toBe('9.99')
    })

    it('returns zero when reviews required is zero', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '0')
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      expect(result.current.totalPoints).toBe('0')
    })

    it('returns zero when points per review is zero', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '3')
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '0')
      })

      expect(result.current.totalPoints).toBe('0')
    })

    it('returns zero when there are validation errors', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '-1')
      })

      act(() => {
        result.current.validateReviewsRequired({} as React.FocusEvent<HTMLInputElement>)
      })

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      expect(result.current.errorMessageReviewsRequired).toBeDefined()
      expect(result.current.totalPoints).toBe('0')
    })

    it('returns zero for invalid numeric inputs', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, 'abc')
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '10')
      })

      expect(result.current.totalPoints).toBe('0')
    })
  })

  describe('checkbox handlers', () => {
    it('handles cross sections checkbox change', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleCrossSectionsCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)

      act(() => {
        result.current.handleCrossSectionsCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(false)
    })

    it('handles inter group checkbox change', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleInterGroupCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.allowPeerReviewWithinGroups).toBe(true)

      act(() => {
        result.current.handleInterGroupCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.allowPeerReviewWithinGroups).toBe(false)
    })

    it('handles pass/fail grading checkbox change', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleUsePassFailCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.usePassFailGrading).toBe(true)

      act(() => {
        result.current.handleUsePassFailCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.usePassFailGrading).toBe(false)
    })

    it('handles anonymity checkbox change', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleAnonymityCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.anonymousPeerReviews).toBe(true)

      act(() => {
        result.current.handleAnonymityCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.anonymousPeerReviews).toBe(false)
    })

    it('handles submission required checkbox change', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleSubmissionRequiredCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.submissionRequiredBeforePeerReviews).toBe(true)

      act(() => {
        result.current.handleSubmissionRequiredCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.submissionRequiredBeforePeerReviews).toBe(false)
    })
  })

  describe('resetFields', () => {
    it('resets all field values and error messages to defaults', () => {
      const {result} = renderHook(() => usePeerReviewSettings(defaultProps()))

      act(() => {
        result.current.handleReviewsRequiredChange({} as React.ChangeEvent<HTMLInputElement>, '-1')
      })

      act(() => {
        result.current.validateReviewsRequired({} as React.FocusEvent<HTMLInputElement>)
      })

      act(() => {
        result.current.handlePointsPerReviewChange({} as React.ChangeEvent<HTMLInputElement>, '-5')
      })

      const mockEvent = {
        target: {
          validity: {valid: true},
        },
      } as React.FocusEvent<HTMLInputElement>

      act(() => {
        result.current.validatePointsPerReview(mockEvent)
      })

      act(() => {
        result.current.handleCrossSectionsCheck({
          target: {checked: false},
        } as React.ChangeEvent<HTMLInputElement>)
        result.current.handleInterGroupCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
        result.current.handleUsePassFailCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
        result.current.handleAnonymityCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
        result.current.handleSubmissionRequiredCheck({
          target: {checked: true},
        } as React.ChangeEvent<HTMLInputElement>)
      })

      expect(result.current.reviewsRequired).toBe('-1')
      expect(result.current.pointsPerReview).toBe('-5')
      expect(result.current.errorMessageReviewsRequired).toBeDefined()
      expect(result.current.errorMessagePointsPerReview).toBeDefined()
      expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(false)
      expect(result.current.allowPeerReviewWithinGroups).toBe(true)
      expect(result.current.usePassFailGrading).toBe(true)
      expect(result.current.anonymousPeerReviews).toBe(true)
      expect(result.current.submissionRequiredBeforePeerReviews).toBe(true)

      act(() => {
        result.current.resetFields()
      })

      expect(result.current.reviewsRequired).toBe('1')
      expect(result.current.pointsPerReview).toBe('0')
      expect(result.current.errorMessageReviewsRequired).toBeUndefined()
      expect(result.current.errorMessagePointsPerReview).toBeUndefined()
      expect(result.current.allowPeerReviewAcrossMultipleSections).toBe(true)
      expect(result.current.allowPeerReviewWithinGroups).toBe(false)
      expect(result.current.usePassFailGrading).toBe(false)
      expect(result.current.anonymousPeerReviews).toBe(false)
      expect(result.current.submissionRequiredBeforePeerReviews).toBe(false)
    })
  })
})
