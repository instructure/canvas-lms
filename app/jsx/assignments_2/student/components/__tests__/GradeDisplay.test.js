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
import ReactDOM from 'react-dom'
import $ from 'jquery'

import GradeDisplay from '../GradeDisplay'

describe('GradeDisplay', () => {
  beforeAll(() => {
    const found = document.getElementById('fixtures')
    if (!found) {
      const fixtures = document.createElement('div')
      fixtures.setAttribute('id', 'fixtures')
      document.body.appendChild(fixtures)
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
  })

  it('renders points correctly when no receivedGrade are set', () => {
    ReactDOM.render(
      <GradeDisplay gradingType="points" pointsPossible={32} />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('–/32 Points')
  })

  it('renders points correctly when receivedGrade is set', () => {
    ReactDOM.render(
      <GradeDisplay gradingType="points" receivedGrade={4} pointsPossible={5} />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('4/5 Points')
  })

  it('renders correctly when receivedGrade is 0', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade={0} pointsPossible={5} />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('0/5 Points')
  })

  it('defaults to using points if gradingType is not explictly set', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade={4} pointsPossible={5} />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('4/5 Points')
  })

  it('renders correctly when displayType is percent', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade="15%" pointsPossible={5} gradingType="percent" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('15%')
  })

  it('renders percent correctly when no grade is set', () => {
    ReactDOM.render(
      <GradeDisplay pointsPossible={5} gradingType="percent" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('–')
  })

  it('renders grading scheme correcty with grade', () => {
    ReactDOM.render(
      <GradeDisplay
        receivedGrade="Absolutely Amazing"
        pointsPossible={5}
        gradingType="gpa_scale"
      />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('Absolutely Amazing')
  })

  it('renders grading scheme correcty with no grade', () => {
    ReactDOM.render(
      <GradeDisplay pointsPossible={5} gradingType="gpa_scale" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('–')
  })

  it('renders pass fail correcty with grade', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade="complete" pointsPossible={5} gradingType="pass_fail" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('complete')
  })

  it('renders pass fail correcty with incomplete grade', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade="incomplete" pointsPossible={100} gradingType="pass_fail" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('incomplete')
  })

  it('renders pass fail correcty with no grade', () => {
    ReactDOM.render(
      <GradeDisplay pointsPossible={5} gradingType="pass_fail" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('ungraded')
  })

  it('renders letter grade correctly with grade', () => {
    ReactDOM.render(
      <GradeDisplay receivedGrade="A" pointsPossible={5} gradingType="letter_grade" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('A')
  })

  it('renders letter grade correctly with no grade', () => {
    ReactDOM.render(
      <GradeDisplay pointsPossible={5} gradingType="letter_grade" />,
      document.getElementById('fixtures')
    )
    const textElement = $('[data-test-id="grade-display"]')
    expect(textElement.text()).toEqual('–')
  })
})
