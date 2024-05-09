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
import sinon from 'sinon'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import SpeedGraderProvisionalGradeSelector from '../SpeedGraderProvisionalGradeSelector'
import {render, waitFor} from '@testing-library/react'

describe('SpeedGraderProvisionalGradeSelector', () => {
  let $container
  let props

  beforeEach(() => {
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

    document.documentElement.setAttribute('dir', 'ltr')
    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  test('has "Show Details" text if detailsVisible is false', () => {
    props.detailsVisible = false
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} />)
    expect(wrapper.getByText('Show Details')).toBeInTheDocument()
  })

  test('hides the main container if detailsVisible is true', () => {
    props.detailsVisible = false
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} />)
    expect(wrapper.queryByText('How Is the Grade Determined?')).toBeNull()
  })

  test('has "Hide Details" text if detailsVisible is true', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    window.ENV = {
      instructor_selectable_states: {
        1: false,
        2: true,
        3: true,
      },
    }
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getByText('Hide Details')).toBeInTheDocument()
    })
  })

  test('shows the main container if detailsVisible is true', () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelector('#grading_details')).toBeInTheDocument()
  })

  test('includes a radio button for each provisional grade', () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelectorAll('input[type="radio"]').length).toBe(3)
  })

  test('positions the "Custom" radio button first', () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelectorAll('input')[0].value).toBe('2')
  })

  test('prepends a "Custom" radio button if no non-readonly grade is passed', () => {
    props.provisionalGrades = [
      {
        grade: '11',
        provisional_grade_id: '1',
        scorer_id: '1',
        readonly: true,
      },
    ]
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelectorAll('input')[0].value).toBe('custom')
  })

  test('selects the first grade whose "selected" field is true', () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelectorAll('input')[0].checked).toBe(true)
  })

  test('selects the "Custom" button if no grade is selected', () => {
    props.provisionalGrades = [
      {
        grade: '11',
        provisional_grade_id: '1',
        scorer_id: '1',
        readonly: true,
      },
    ]
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(wrapper.container.querySelectorAll('input[value="custom"]')[0].checked).toBe(true)
  })

  test('includes the grader name in the button label', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getByText('Gradius').closest('div').querySelector('input').value).toBe('1')
    })
  })

  test('uses a label of "Custom" for the non-readonly button', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getAllByText('Custom')[1].closest('div').querySelector('input').value).toBe(
        '3'
      )
    })
  })

  test('includes the score for a provisional grade in the button label', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getByText('11').closest('div').querySelector('input').value).toBe('1')
    })
  })

  test('includes the points possible for points-based assignments in the button label', async () => {
    props.gradingType = 'points'
    props.pointsPossible = 123
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(
        wrapper.getAllByText('out of 123')[0].closest('div').querySelector('input').value
      ).toBe('1')
    })
  })

  test('omits the points possible for non-points-based assignments in the button label', async () => {
    props.gradingType = 'percent'
    props.pointsPossible = 123
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.queryByText('out of 123')).toBeNull()
    })
  })

  test('enables option when the instructor_state is active', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getAllByText('Custom')[0].closest('div').querySelector('input').disabled).toBe(
        false
      )
    })
  })

  test('disables option when the instructor_state is deleted', async () => {
    const ref = React.createRef()
    const wrapper = render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(wrapper.getByText('Gradius').closest('div').querySelector('input').disabled).toBe(true)
    })
  })

  test('calls formatSubmissionGrade to render a provisional grade', async () => {
    const provisionalGrades = [
      {
        grade: '123456.78',
        score: 123456.78,
        provisional_grade_id: '1',
        readonly: true,
        scorer_id: '300',
      },
    ]
    props.provisionalGrades = provisionalGrades

    const formatSpy = sinon.spy(GradeFormatHelper, 'formatSubmissionGrade')
    const ref = React.createRef()
    render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    await waitFor(() => {
      expect(formatSpy.called).toBe(true)
      const [gradeToFormat] = formatSpy.firstCall.args
      expect(gradeToFormat).toBe(provisionalGrades[0])
    })
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
    props.provisionalGrades = provisionalGrades

    const formatSpy = sinon.spy(GradeFormatHelper, 'formatSubmissionGrade')
    const ref = React.createRef()
    render(<SpeedGraderProvisionalGradeSelector {...props} ref={ref} />)
    ref.current.setState({detailsVisible: true})
    expect(formatSpy.firstCall.args[1].formatType).toBe('points')

    formatSpy.restore()
  })
})
