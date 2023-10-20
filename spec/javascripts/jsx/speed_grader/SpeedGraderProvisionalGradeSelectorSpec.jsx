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

import fakeENV from 'helpers/fakeENV'
import React from 'react'
import {mount} from 'enzyme'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import SpeedGraderProvisionalGradeSelector from 'ui/features/speed_grader/react/SpeedGraderProvisionalGradeSelector'

QUnit.module('SpeedGraderProvisionalGradeSelector', hooks => {
  let $container
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {
      detailsInitiallyVisible: true,
      finalGraderId: '2',
      gradingType: 'points',
      onGradeSelected: () => {},
      pointsPossible: 123,
      provisionalGraderDisplayNames: {
        1: 'Gradius',
        2: 'Graderson',
        3: 'Custom',
      },
      provisionalGrades: [
        {
          grade: '11',
          score: 11,
          provisional_grade_id: '1',
          readonly: true,
          scorer_id: '1',
        },
        {
          grade: '22',
          score: 22,
          provisional_grade_id: '2',
          readonly: true,
          scorer_id: '2',
          selected: true,
        },
        {
          grade: '33',
          score: 33,
          provisional_grade_id: '3',
          readonly: false,
          scorer_id: '3',
        },
      ],
    }

    fakeENV.setup({
      instructor_selectable_states: {
        1: false,
        2: true,
        3: true,
      },
    })

    document.documentElement.setAttribute('dir', 'ltr')
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  hooks.afterEach(() => {
    $container.remove()
  })

  function getRadioInput({value = null, label = null} = {}) {
    let matchingNodes = wrapper.find('RadioInput')
    if (value) {
      matchingNodes = matchingNodes.filterWhere(input => input.prop('value') === value)
    }

    if (label) {
      matchingNodes = matchingNodes.filterWhere(input => input.prop('label') === label)
    }

    return matchingNodes.first()
  }

  function mountComponent(additionalProps = {}, customState = {}) {
    const allProps = {...props, ...additionalProps}
    wrapper = mount(<SpeedGraderProvisionalGradeSelector {...allProps} />, {appendTo: $container})

    wrapper.setState({detailsVisible: true, ...customState})
  }

  test('has "Show Details" text if detailsVisible is false', () => {
    mountComponent({}, {detailsVisible: false})
    strictEqual(wrapper.find('Link').first().text(), 'Show Details')
  })

  test('hides the main container if detailsVisible is true', () => {
    mountComponent({}, {detailsVisible: false})
    strictEqual(wrapper.find('#grading_details').exists(), false)
  })

  test('has "Hide Details" text if detailsVisible is true', () => {
    mountComponent()
    strictEqual(wrapper.find('Link').first().text(), 'Hide Details')
  })

  test('shows the main container if detailsVisible is true', () => {
    mountComponent()
    strictEqual(wrapper.find('#grading_details').exists(), true)
  })

  test('includes a radio button for each provisional grade', () => {
    mountComponent()
    strictEqual(wrapper.find('input[type="radio"]').length, 3)
  })

  test('positions the "Custom" radio button first', () => {
    mountComponent()
    strictEqual(wrapper.find('input').first().prop('value'), '2')
  })

  test('prepends a "Custom" radio button if no non-readonly grade is passed', () => {
    const provisionalGrades = [
      {
        grade: '11',
        provisional_grade_id: '1',
        scorer_id: '1',
        readonly: true,
      },
    ]
    mountComponent({provisionalGrades})
    strictEqual(wrapper.find('input').first().prop('value'), 'custom')
  })

  test('selects the first grade whose "selected" field is true', () => {
    mountComponent()
    strictEqual(wrapper.find('input[value="2"]').is('[checked]'), true)
  })

  test('selects the "Custom" button if no grade is selected', () => {
    const provisionalGrades = [
      {
        grade: '11',
        provisional_grade_id: '1',
        scorer_id: '1',
        readonly: true,
      },
    ]
    mountComponent({provisionalGrades})
    strictEqual(wrapper.find('input[value="custom"]').is('[checked]'), true)
  })

  test('includes the grader name in the button label', () => {
    mountComponent()
    strictEqual(getRadioInput({value: '1'}).text().includes('Gradius'), true)
  })

  test('uses a label of "Custom" for the non-readonly button', () => {
    mountComponent()
    strictEqual(getRadioInput({value: '3'}).text().includes('Custom'), true)
  })

  test('includes the score for a provisional grade in the button label', () => {
    mountComponent()
    strictEqual(getRadioInput({value: '1'}).text().includes('11'), true)
  })

  test('includes the points possible for points-based assignments in the button label', () => {
    mountComponent({gradingType: 'points', pointsPossible: 123})
    strictEqual(getRadioInput({value: '1'}).text().includes('out of 123'), true)
  })

  test('omits the points possible for non-points-based assignments in the button label', () => {
    mountComponent({gradingType: 'percent', pointsPossible: 123})
    strictEqual(getRadioInput({value: '1'}).text().includes('out of 123'), false)
  })

  test('enables option when the instructor_state is active', () => {
    mountComponent()
    strictEqual(getRadioInput({value: '2'}).prop('disabled'), false)
  })

  test('disables option when the instructor_state is deleted', () => {
    mountComponent()
    strictEqual(getRadioInput({value: '1'}).prop('disabled'), true)
  })

  test('sorts provisional grades by anonymous grader ID if present', () => {
    const provisionalGrades = [
      {
        grade: '33',
        provisional_grade_id: '1',
        readonly: true,
        anonymous_grader_id: 'ccccc',
      },
      {
        grade: '22',
        provisional_grade_id: '2',
        readonly: true,
        anonymous_grader_id: 'aaaaa',
      },
      {
        grade: '11',
        provisional_grade_id: '3',
        readonly: true,
        anonymous_grader_id: 'bbbbb',
      },
    ]

    mountComponent({provisionalGrades})
    const inputs = Array.from(wrapper.getDOMNode().querySelectorAll('input'))
    deepEqual(
      inputs.map(input => input.value),
      ['custom', '2', '3', '1']
    )
  })

  test('sorts provisional grades by scorer ID if anonymous grader ID is not present', () => {
    const provisionalGrades = [
      {
        grade: '33',
        provisional_grade_id: '1',
        readonly: true,
        scorer_id: '300',
      },
      {
        grade: '22',
        provisional_grade_id: '2',
        readonly: true,
        scorer_id: '200',
        selected: true,
      },
      {
        grade: '11',
        provisional_grade_id: '3',
        readonly: true,
        scorer_id: '100',
      },
    ]

    mountComponent({provisionalGrades})
    const inputs = Array.from(wrapper.getDOMNode().querySelectorAll('input'))
    deepEqual(
      inputs.map(input => input.value),
      ['custom', '3', '2', '1']
    )
  })

  test('calls formatSubmissionGrade to render a provisional grade', () => {
    const provisionalGrades = [
      {
        grade: '123456.78',
        score: 123456.78,
        provisional_grade_id: '1',
        readonly: true,
        scorer_id: '300',
      },
    ]

    const formatSpy = sinon.spy(GradeFormatHelper, 'formatSubmissionGrade')
    mountComponent({provisionalGrades})

    const [gradeToFormat] = formatSpy.firstCall.args
    deepEqual(gradeToFormat, provisionalGrades[0])

    formatSpy.restore()
  })

  test('calls formatSubmissionGrade with the passed-in grading type', () => {
    const provisionalGrades = [
      {
        grade: '123456.78',
        score: 123456.78,
        provisional_grade_id: '1',
        readonly: true,
        scorer_id: '300',
      },
    ]

    const formatSpy = sinon.spy(GradeFormatHelper, 'formatSubmissionGrade')
    mountComponent({provisionalGrades})

    const [, options] = formatSpy.firstCall.args
    strictEqual(options.formatType, 'points')

    formatSpy.restore()
  })
})
