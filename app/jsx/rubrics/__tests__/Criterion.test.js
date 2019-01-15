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
import _ from 'lodash'
import React from 'react'
import sinon from 'sinon'
import { shallow } from 'enzyme'
import Criterion from '../Criterion'
import { rubrics, assessments } from './fixtures'

const criteriaTypes = ['custom', 'outcome']

const subComponents = ['Threshold', 'OutcomeIcon', 'LongDescription', 'LongDescriptionDialog']

_.toPairs(rubrics).forEach(([key, rubric]) => {
  const assessment = assessments[key]

  describe(rubric.title, () => {
    criteriaTypes.forEach((criteriaType, ix) => {
      const basicProps = {
        assessment: assessment.data[ix],
        criterion: rubric.criteria[ix],
        freeForm: key === 'freeForm',
      }

      const testRenderedSnapshots = (props) => {
        const component = (mods) => shallow(<Criterion {...{ ...props, ...mods }} />)

        it('renders the root component as expected', () => {
          expect(component()).toMatchSnapshot()
        })

        subComponents.forEach((name) => {
          it(`renders the ${name} sub-component(s) as expected`, () => {
            component().find(name)
              .forEach((el) => expect(el.shallow()).toMatchSnapshot())
          })
        })
      }

      describe(`with a ${criteriaType} criterion`, () => {
        describe('by default', () => {
          testRenderedSnapshots(basicProps)
        })

        describe('when assessing', () => {
          testRenderedSnapshots({ ...basicProps, onAssessmentChange: () => {}})
        })

        describe('without an assessment', () => {
          testRenderedSnapshots({ ...basicProps, assessment: undefined})
        })
      })
    })
  })
})

describe('Criterion', () => {
  it('can open and close the long description dialog', () => {
    const criterion = {
      ...rubrics.freeForm.criteria[1],
      long_description: '<p> a wild paragraph appears </p>'
    }

    const component = (
      <Criterion
        assessment={assessments.freeForm.data[1]}
        criterion={criterion}
        freeForm
      />
    )

    const render = shallow(component)
    const expectState = (state) =>
      expect(render.find('LongDescriptionDialog').prop('open')).toEqual(state)

    expectState(false)
    render.find('LongDescription').prop('showLongDescription')()
    expectState(true)
    const dialog = render.find('LongDescriptionDialog')
    expect(dialog.shallow().find('div').html()).toMatchSnapshot()
    dialog.prop('close')()
    expectState(false)
  })

  it('does not have a threshold when mastery_points is null / there is no outcome', () => {
    const nullified = { ...rubrics.points.criteria[1], mastery_points: null }
    const el = shallow(
      <Criterion
        criterion={nullified}
        freeForm={false}
      />
    )

    expect(el.find('Threshold')).toHaveLength(0)
  })

  it('does not have a points column when hasPointsColumn is false', () => {
    const el = shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        hasPointsColumn={false}
      />
    )

    expect(el.find('td')).toHaveLength(1)
  })

  it('only shows comments when they exist or editComments is true', () => {
    const withAssessment= (changes) => shallow(
      <Criterion
        assessment={{ ...assessments.points.data[1], ...changes }}
        onAssessmentChange={sinon.spy()}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
      />
    ).find('Ratings').prop('footer')

    expect(withAssessment({ comments: 'blah', editComments: false })).toBeDefined()
    expect(withAssessment({ comments: '', editComments: true })).toBeDefined()
    expect(withAssessment({ comments: '', editComments: false })).toBeNull()
  })

  it('allows extra credit for outcomes when enabled', () => {
    const el = shallow(
      <Criterion
        allowExtraCredit
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        onAssessmentChange={() => {}}
      />
    )

    expect(el.find('Points').prop('allowExtraCredit')).toEqual(true)
  })

  describe('the Points for a criterion', () => {
    const points = (props) => shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        freeForm={false}
        {...props}
      />
    ).find('Points')

    const criterion = rubrics.points.criteria[1]
    it('are visible by default', () => {
      expect(points({ criterion })).toHaveLength(1)
    })

    it('can be changed', () => {
      const onAssessmentChange = sinon.spy()
      const el = points({ criterion, onAssessmentChange })
      const onPointChange = el.find('Points').prop('onPointChange')

      onPointChange({points: '10', description: 'good', id: '1'})
      onPointChange({points: '10.245', description: 'better', id: '2'})
      onPointChange({points: 'blergh', description: 'invalid', id: '3'})
      expect(onAssessmentChange.args).toEqual([
        [{description: 'good', id: '1', points: { text: '10', valid: true, value: 10 } }],
        [{description: 'better', id: '2', points: { text: '10.245', valid: true, value: 10.245 } } ],
        [{description: 'invalid', id: '3', points: { text: 'blergh', valid: false, value: undefined } }]
      ])
    })

    it('are hidden when hidePoints is true', () => {
      expect(points({ criterion, hidePoints: true })).toHaveLength(0)
    })

    describe('when ignore_for_scoring is set', () => {
      const ignoredPoints = (props) => points({
        criterion: {
          ...rubrics.points.criteria[1],
          ignore_for_scoring: true
        },
        ...props
      })

      it('are not shown by default', () =>
        expect(ignoredPoints()).toHaveLength(0)
      )

      it('are not shown in summary mode', () =>
        expect(ignoredPoints({ isSummary: true })).toHaveLength(0)
      )

      it('are not shown when assessing', () => {
        expect(ignoredPoints({ onAssessmentChange: () => {} })).toHaveLength(0)
      })
    })
  })
})
