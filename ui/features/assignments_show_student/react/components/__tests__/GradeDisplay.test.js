/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import GradeDisplay from '../GradeDisplay'

describe('GradeDisplay', () => {
  it('renders points correctly when no receivedGrade are set', () => {
    const {getByTestId, getByText} = render(
      <GradeDisplay gradingType="points" pointsPossible={32} />
    )

    expect(getByTestId('grade-display')).toContainElement(getByText('–/32 Points'))
  })

  it('renders points correctly when receivedGrade is set', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay gradingType="points" receivedGrade={4} pointsPossible={5} />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('4/5 Points')[1])
  })

  it('renders correctly when receivedGrade is 0', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade={0} pointsPossible={5} />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('0/5 Points')[1])
  })

  it('defaults to using points if gradingType is not explictly set', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade={4} pointsPossible={5} />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('4/5 Points')[1])
  })

  it('renders correctly when displayType is percent', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade="15%" pointsPossible={5} gradingType="percent" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('15%')[1])
  })

  it('renders percent correctly when no grade is set', () => {
    const {getByTestId, getByText} = render(
      <GradeDisplay pointsPossible={5} gradingType="percent" />
    )

    expect(getByTestId('grade-display')).toContainElement(getByText('–'))
  })

  it('renders grading scheme correcty with grade', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade="Absolutely Amazing" pointsPossible={5} gradingType="gpa_scale" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('Absolutely Amazing')[1])
  })

  it('renders grading scheme correcty with no grade', () => {
    const {getByTestId, getByText} = render(
      <GradeDisplay pointsPossible={5} gradingType="gpa_scale" />
    )

    expect(getByTestId('grade-display')).toContainElement(getByText('–'))
  })

  it('renders pass fail correcty with grade', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade="complete" pointsPossible={5} gradingType="pass_fail" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('complete')[1])
  })

  it('renders pass fail correcty with incomplete grade', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade="incomplete" pointsPossible={100} gradingType="pass_fail" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('incomplete')[1])
  })

  it('renders pass fail correcty with no grade', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay pointsPossible={5} gradingType="pass_fail" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('ungraded')[1])
  })

  it('renders letter grade correctly with grade', () => {
    const {getByTestId, getAllByText} = render(
      <GradeDisplay receivedGrade="A" pointsPossible={5} gradingType="letter_grade" />
    )

    expect(getByTestId('grade-display')).toContainElement(getAllByText('A')[1])
  })

  it('renders letter grade correctly with no grade', () => {
    const {getByTestId, getByText} = render(
      <GradeDisplay pointsPossible={5} gradingType="letter_grade" />
    )

    expect(getByTestId('grade-display')).toContainElement(getByText('–'))
  })
})
