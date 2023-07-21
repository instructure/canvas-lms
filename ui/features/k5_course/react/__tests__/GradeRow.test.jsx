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
import {render} from '@testing-library/react'
import {GradeRow} from '../GradeRow'

const dtf = new Intl.DateTimeFormat('en', {
  // MMM D, YYYY h:mma
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: ENV.TIMEZONE,
})

const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

describe('GradeRow', () => {
  const getProps = (overrides = {}) => ({
    id: '3',
    assignmentName: 'Essay #2',
    url: 'http://localhost:3000/courses/30/assignments/3',
    dueDate: '2020-04-18T05:59:59Z',
    assignmentGroupName: 'Essays',
    assignmentGroupId: '5',
    pointsPossible: 5,
    gradingType: 'points',
    score: 5,
    grade: '5',
    submissionDate: '2020-03-18T05:59:59Z',
    unread: false,
    late: false,
    excused: false,
    missing: false,
    hasComments: false,
    currentUserId: '1',
    restrictQuantitativeData: false,
    dateFormatter,
    ...overrides,
  })

  it('renders assignment title as a link', () => {
    const {getByText} = render(
      <table>
        <tbody>{GradeRow({...getProps()})}</tbody>
      </table>
    )
    const title = getByText('Essay #2')
    expect(title).toBeInTheDocument()
    expect(title.href).toBe('http://localhost:3000/courses/30/assignments/3')
  })

  describe('unread badge', () => {
    it('is rendered when unread is true', () => {
      const {getByText} = render(
        <table>
          <tbody>{GradeRow({...getProps({unread: true})})}</tbody>
        </table>
      )
      expect(getByText('New grade for Essay #2')).toBeInTheDocument()
    })

    it('is not present when unread is false', () => {
      const {getByText, queryByText} = render(
        <table>
          <tbody>{GradeRow({...getProps()})}</tbody>
        </table>
      )
      expect(getByText('Essay #2')).toBeInTheDocument()
      expect(queryByText('New grade for Essay #2')).not.toBeInTheDocument()
    })
  })

  describe('score column', () => {
    it('shows 5 out of 5 for points gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>{GradeRow({...getProps()})}</tbody>
        </table>
      )
      expect(getByText('5 pts')).toBeInTheDocument()
      expect(getByText('Out of 5 pts')).toBeInTheDocument()
    })

    it('does not show points when restrictQuantitativeData is true', () => {
      const {queryByText} = render(
        <table>
          <tbody>{GradeRow({...getProps({restrictQuantitativeData: true})})}</tbody>
        </table>
      )
      expect(queryByText('Out of 5 pts')).not.toBeInTheDocument()
    })

    it('shows — pts for ungraded assignment with points gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                grade: null,
                score: null,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('— pts')).toBeInTheDocument()
      expect(getByText('Out of 5 pts')).toBeInTheDocument()
    })

    it('shows -- with some alt text for not_graded gradingType', () => {
      const {queryByText, getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'not_graded',
                grade: null,
                score: null,
                pointsPossible: null,
              }),
            })}
          </tbody>
        </table>
      )
      ;['—', 'Out of', 'pts'].forEach(t => {
        expect(queryByText(t, {exact: false})).not.toBeInTheDocument()
      })
      expect(getByText('--')).toBeInTheDocument()
      expect(getByText('Ungraded assignment')).toBeInTheDocument()
    })

    it('shows grade GPA for gpa_scale gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'gpa_scale',
                grade: 'A',
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('A GPA')).toBeInTheDocument()
    })

    it('shows grade for letter_grade gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'letter_grade',
                grade: 'A',
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('A')).toBeInTheDocument()
    })

    it('shows score percent for percent gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'percent',
                grade: '75%',
                score: 7.5,
                pointsPossible: 10,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('75%')).toBeInTheDocument()
    })

    it('shows check icon for passing grade in pass_fail gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'pass_fail',
                grade: 'complete',
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Complete')).toBeInTheDocument()
    })

    it('shows x icon for failing grade in pass_fail gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'pass_fail',
                grade: 'incomplete',
                score: 0,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Incomplete')).toBeInTheDocument()
    })

    it('shows dash for ungraded assignment in pass_fail gradingType', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                gradingType: 'pass_fail',
                grade: null,
                score: null,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Not graded')).toBeInTheDocument()
      expect(getByText('—')).toBeInTheDocument()
    })

    it('shows excused if excused is true', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                excused: true,
                grade: null,
                score: null,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Excused')).toBeInTheDocument()
    })

    it('shows a feedback link if hasComments is true', () => {
      const {getByRole} = render(
        <table>
          <tbody>{GradeRow({...getProps({hasComments: true})})}</tbody>
        </table>
      )
      const link = getByRole('link', {name: 'View feedback'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost:3000/courses/30/assignments/3/submissions/1')
    })

    it('does not render the feedback link if no comments exist', () => {
      const {queryByText} = render(
        <table>
          <tbody>{GradeRow({...getProps()})}</tbody>
        </table>
      )
      expect(queryByText('View feedback')).not.toBeInTheDocument()
    })
  })

  describe('assignment status', () => {
    it('shows missing if missing is true', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                missing: true,
                grade: null,
                points: null,
                submissionDate: null,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Missing')).toBeInTheDocument()
    })

    it('shows submitted with date if submitted on-time', () => {
      const {getByText} = render(
        <table>
          <tbody>{GradeRow({...getProps()})}</tbody>
        </table>
      )
      expect(getByText(`Submitted ${dateFormatter('2020-03-18T05:59:59Z')}`)).toBeInTheDocument()
    })

    it('shows late if marked as late but not submitted', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                late: true,
                submissionDate: null,
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText('Late')).toBeInTheDocument()
    })

    it('shows late with submission date if submitted late', () => {
      const {getByText} = render(
        <table>
          <tbody>
            {GradeRow({
              ...getProps({
                late: true,
                submissionDate: '2020-05-18T05:59:59Z',
              }),
            })}
          </tbody>
        </table>
      )
      expect(getByText(`Late ${dateFormatter('2020-05-18T05:59:59Z')}`)).toBeInTheDocument()
    })
  })
})
