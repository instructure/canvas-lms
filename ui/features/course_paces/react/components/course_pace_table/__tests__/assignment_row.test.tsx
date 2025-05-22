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
import {waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {renderRow} from '@canvas/util/react/testing/TableHelper'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import {
  BLACKOUT_DATES,
  PACE_ITEM_1,
  PACE_ITEM_3,
  PACE_ITEM_4,
  PRIMARY_PACE,
  STUDENT_PACE,
  STUDENT_PACE_UNRELEASED_ITEMS,
} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {AssignmentRow, type ComponentProps} from '../assignment_row'

const setPaceItemDuration = jest.fn()
const setPaceItemDurationTimeToCompleteCalendarDays = jest.fn()

jest.mock('@canvas/conditional-release-cyoe-helper', () => ({
  getItemData: jest.fn(),
}))

const defaultProps: ComponentProps = {
  coursePace: PRIMARY_PACE,
  dueDate: '2020-01-01T02:00:00-05:00',
  excludeWeekends: false,
  coursePaceItem: PRIMARY_PACE.modules[0].items[0],
  coursePaceItemPosition: 0,
  isSyncing: false,
  blackoutDates: BLACKOUT_DATES,
  showProjections: true,
  setPaceItemDuration,
  datesVisible: true,
  hover: false,
  isStacked: false,
  isStudentPace: false,
  coursePaceItemChanges: [],
  blueprintLocked: false,
  selectedDaysToSkip: [],
  context_type: 'Course',
  setPaceItemDurationTimeToCompleteCalendarDays,
}

const NO_SUBMISSION_TEXT = 'No Submission'
const LATE_SUBMISSION_TEXT = 'Late Submission'
const UNRELEASED_ASSIGNMENT_TEXT =
  'Based on Mastery Path results this assignment may not be assigned to this student.'

beforeAll(() => {
  ENV.CONTEXT_TIMEZONE = 'America/New_York' // to match defaultProps.dueDate
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('AssignmentRow', () => {
  it('renders the assignment title and icon of the module item', () => {
    const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    expect(getByText(defaultProps.coursePaceItem.assignment_title)).toBeInTheDocument()
  })

  it('renders the assignment title as a link to the assignment', () => {
    const {getByRole} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))

    getByRole('link', {name: defaultProps.coursePaceItem.assignment_title})
  })

  it('renders an input that updates the duration for that module item', async () => {
    // Disable the time selection feature to ensure setPaceItemDuration is called
    window.ENV.FEATURES = {
      ...window.ENV.FEATURES,
      course_pace_time_selection: false,
    }

    // Reset the mock before the test
    setPaceItemDuration.mockReset()
    setPaceItemDuration.mockImplementation(() => {})

    const {getByRole} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    const daysInput = getByRole('textbox', {
      name: 'Duration for assignment Basic encryption/decryption',
    }) as HTMLInputElement
    expect(daysInput).toBeInTheDocument()
    expect(daysInput.value).toBe('2')

    await userEvent.type(daysInput, '{selectall}{backspace}4')
    await userEvent.tab()

    expect(setPaceItemDuration).toHaveBeenCalled()
    expect(setPaceItemDuration).toHaveBeenCalledWith('60', 4)
  })

  it('renders the projected due date if projections are being shown', () => {
    const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    expect(getByText('Wed, Jan 1, 2020')).toBeInTheDocument()
  })

  it('does not show the projected due date if projections are being hidden', async () => {
    const {queryByText} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} datesVisible={false} showProjections={false} />),
    )
    await waitFor(() => expect(queryByText('Wed, Jan 1, 2020')).not.toBeInTheDocument())
  })

  it('renders an icon showing whether or not the module item is published', () => {
    const publishedIcon = renderConnected(renderRow(<AssignmentRow {...defaultProps} />)).getByText(
      'Published',
    )
    expect(publishedIcon).toBeInTheDocument()

    const unpublishedProps = {
      ...defaultProps,
      coursePaceItem: {...defaultProps.coursePaceItem, published: false},
    }
    const unpublishedIcon = renderConnected(
      renderRow(<AssignmentRow {...unpublishedProps} />),
    ).getByText('Unpublished')
    expect(unpublishedIcon).toBeInTheDocument()
  })

  it('disables duration inputs while publishing', () => {
    const {getByRole} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} isSyncing={true} />),
    )
    const daysInput = getByRole('textbox', {
      name: 'Duration for assignment Basic encryption/decryption',
    })
    expect(daysInput).toBeDisabled()
  })

  it('renders provided possible points, and pluralizes them correctly', () => {
    const {getByText, rerender} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))

    expect(getByText('100 pts')).toBeInTheDocument()

    rerender(renderRow(<AssignmentRow {...defaultProps} coursePaceItem={PACE_ITEM_3} />))
    expect(getByText('1 pt')).toBeInTheDocument()
  })

  it('renders successfully when possible points are omitted', () => {
    const {getByText, rerender} = renderConnected(
      renderRow(
        <AssignmentRow
          {...defaultProps}
          coursePaceItem={{...PACE_ITEM_1, points_possible: undefined}}
        />,
      ),
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()

    rerender(
      renderRow(
        <AssignmentRow
          {...defaultProps}
          coursePaceItem={{...PACE_ITEM_1, points_possible: null}}
        />,
      ),
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()
  })

  describe('with course paces for students', () => {
    beforeEach(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_pace_pacing_status_labels = true
      window.ENV.FEATURES.course_pace_time_selection = true

      // Reset and mock the function before each test
      setPaceItemDurationTimeToCompleteCalendarDays.mockReset()
      setPaceItemDurationTimeToCompleteCalendarDays.mockImplementation(() => {})
    })

    it('renders an input for student paces that updates the duration for that module item', async () => {
      const {getByRole} = renderConnected(
        renderRow(<AssignmentRow {...defaultProps} isStudentPace={true} />),
      )
      const daysInput = getByRole('textbox', {
        name: 'Duration for assignment Basic encryption/decryption',
      }) as HTMLInputElement
      expect(daysInput).toBeInTheDocument()
      expect(daysInput.value).toBe('2')

      await userEvent.type(daysInput, '{selectall}{backspace}4')
      await userEvent.tab()

      expect(setPaceItemDurationTimeToCompleteCalendarDays).toHaveBeenCalled()
      expect(setPaceItemDurationTimeToCompleteCalendarDays).toHaveBeenCalledWith(
        '60',
        4,
        BLACKOUT_DATES,
      )
    })
  })

  it("renders an indicator next to duration picker when there's unsaved changes", () => {
    const unsavedChangeText = 'Unsaved change'
    const {queryByText, getByText, rerender} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} />),
    )
    const daysInput = getByText(
      'Duration for assignment Basic encryption/decryption',
    ) as HTMLInputElement
    expect(daysInput).toBeInTheDocument()
    expect(queryByText(unsavedChangeText)).not.toBeInTheDocument()

    const coursePaceItemChanges = [
      {id: PACE_ITEM_1.id, oldValue: PACE_ITEM_1, newValue: {...PACE_ITEM_1, duration: 3}},
    ]
    rerender(
      renderRow(<AssignmentRow {...defaultProps} coursePaceItemChanges={coursePaceItemChanges} />),
    )
    expect(getByText(unsavedChangeText)).toBeInTheDocument()
  })

  it('renders rows where the items are off pace', () => {
    const rowProps = {
      ...defaultProps,
      dueDate: '2025-01-01',
      coursePace: STUDENT_PACE,
      context_type: 'Enrollment',
      coursePaceItem: {
        ...PACE_ITEM_3,
        submission_status: 'missing',
      },
    }

    // Enable the feature flag for status labels
    window.ENV.FEATURES = {
      ...window.ENV.FEATURES,
      course_pace_pacing_status_labels: true,
    }

    const {getByText, rerender} = renderConnected(renderRow(<AssignmentRow {...rowProps} />))

    // Look for the text with the warning icon
    expect(getByText(NO_SUBMISSION_TEXT)).toBeInTheDocument()

    // Simulate an item that was submitted after it's due date
    rerender(
      renderRow(
        <AssignmentRow
          {...rowProps}
          coursePaceItem={{...PACE_ITEM_3, submission_status: 'late'}}
        />,
      ),
    )
    expect(getByText(LATE_SUBMISSION_TEXT)).toBeInTheDocument()
  })

  it('renders rows where the items are on pace', () => {
    const rowProps = {
      ...defaultProps,
      dueDate: '2025-01-01',
      coursePace: STUDENT_PACE,
      context_type: 'Enrollment',
    }

    // Simulate an item that was submitted on time
    const {queryByText, rerender} = renderConnected(
      renderRow(<AssignmentRow {...rowProps} coursePaceItem={PACE_ITEM_1} />),
    )
    expect(queryByText(NO_SUBMISSION_TEXT)).toBeNull()
    expect(queryByText(LATE_SUBMISSION_TEXT)).toBeNull()

    // Simulate an item that is not submittable
    rerender(renderRow(<AssignmentRow {...rowProps} coursePaceItem={PACE_ITEM_1} />))
    expect(queryByText(NO_SUBMISSION_TEXT)).toBeNull()
    expect(queryByText(LATE_SUBMISSION_TEXT)).toBeNull()

    // Simulate an item that is not due yet
    rowProps.dueDate = '2999-01-01'
    rerender(renderRow(<AssignmentRow {...rowProps} coursePaceItem={PACE_ITEM_1} />))
    expect(queryByText(NO_SUBMISSION_TEXT)).toBeNull()
    expect(queryByText(LATE_SUBMISSION_TEXT)).toBeNull()

    // Simulate an item that is unreleased
    rerender(
      renderRow(
        <AssignmentRow {...rowProps} coursePaceItem={{...PACE_ITEM_1, unreleased: true}} />,
      ),
    )
    expect(queryByText(NO_SUBMISSION_TEXT)).toBeNull()
    expect(queryByText(LATE_SUBMISSION_TEXT)).toBeNull()
  })

  it('renders unreleasd indicator when the item is unreleased', () => {
    window.ENV.FEATURES.course_pace_pacing_with_mastery_paths = true

    const rowProps = {
      ...defaultProps,
      dueDate: '2025-01-01',
      coursePace: STUDENT_PACE_UNRELEASED_ITEMS,
      context_type: 'Enrollment',
    }

    const {getByText} = renderConnected(
      renderRow(<AssignmentRow {...rowProps} coursePaceItem={PACE_ITEM_4} />),
    )

    expect(getByText(UNRELEASED_ASSIGNMENT_TEXT)).toBeInTheDocument()
  })

  it('returns null when isTrigger and releasedLabel are both false', () => {
    ;(CyoeHelper.getItemData as jest.Mock).mockReturnValue({isTrigger: false, releasedLabel: ''})

    const {queryByTestId} = renderConnected(
      renderRow(<AssignmentRow {...{...defaultProps, context_type: 'Section'}} />),
    )

    expect(
      queryByTestId(`mastery-paths-data-${defaultProps.coursePaceItem.module_item_id}`),
    ).toBeNull()
  })

  it('renders Mastery Paths link when isTrigger is true and moduleItemId is provided', () => {
    ;(CyoeHelper.getItemData as jest.Mock).mockReturnValue({isTrigger: true, releasedLabel: ''})
    window.ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
    const {getByText} = renderConnected(
      renderRow(<AssignmentRow {...{...defaultProps, context_type: 'Section'}} />),
    )
    const link = getByText('Mastery Paths')
    expect(link).toBeInTheDocument()
    expect(link).toHaveAttribute(
      'href',
      `${ENV.CONTEXT_URL_ROOT}/modules/items/${defaultProps.coursePaceItem.module_item_id}/edit_mastery_paths`,
    )
  })

  it('renders both Mastery Paths link and Pill when isTrigger is true and releasedLabel is provided', () => {
    ;(CyoeHelper.getItemData as jest.Mock).mockReturnValue({
      isTrigger: true,
      releasedLabel: '100 pts - 70 pts',
    })
    window.ENV.FEATURES.course_pace_pacing_with_mastery_paths = true
    const {getByText} = renderConnected(
      renderRow(<AssignmentRow {...{...defaultProps, context_type: 'Section'}} />),
    )

    expect(getByText('Mastery Paths')).toBeInTheDocument()
    expect(getByText('100 pts - 70 pts')).toBeInTheDocument()
  })

  describe('localized', () => {
    const locale = ENV.LOCALE
    beforeAll(() => {
      ENV.LOCALE = 'en-GB'
    })
    afterAll(() => {
      ENV.LOCALE = locale
    })
    it('localizes the projected dates', () => {
      const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
      expect(getByText('Wed, 1 Jan 2020')).toBeInTheDocument()
    })
  })

  describe('with course_pace_time_selection enabled', () => {
    beforeEach(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_pace_time_selection = true

      // Reset and mock the function before each test
      setPaceItemDurationTimeToCompleteCalendarDays.mockReset()
      setPaceItemDurationTimeToCompleteCalendarDays.mockImplementation(() => {})
    })

    it('renders an input that updates the duration for that module item', async () => {
      const {getByRole} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
      const daysInput = getByRole('textbox', {
        name: 'Duration for assignment Basic encryption/decryption',
      }) as HTMLInputElement
      expect(daysInput).toBeInTheDocument()
      expect(daysInput.value).toBe('2')

      await userEvent.type(daysInput, '{selectall}{backspace}4')
      await userEvent.tab()

      expect(setPaceItemDurationTimeToCompleteCalendarDays).toHaveBeenCalled()
      expect(setPaceItemDurationTimeToCompleteCalendarDays).toHaveBeenCalledWith(
        '60',
        4,
        BLACKOUT_DATES,
      )
    })
  })
})
