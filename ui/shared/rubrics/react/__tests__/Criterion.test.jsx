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
import {shallow} from 'enzyme'
import Criterion from '../Criterion'
import {Table} from '@instructure/ui-table'
import {rubrics, assessments} from './fixtures'

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

      const testRenderedComponents = props => {
        const component = mods => shallow(<Criterion {...{...props, ...mods}} />)

        it('renders the root component as expected', () => {
          const wrapper = component()

          // Should render a Table.Row as the root element
          expect(wrapper.find(Table.Row)).toHaveLength(1)

          // Should render appropriate content based on freeForm
          if (props.freeForm) {
            // For freeForm rubrics, should render Comments component instead of Ratings
            expect(wrapper.find('Comments')).toHaveLength(1)
          } else {
            // For non-freeForm rubrics, should render Ratings component
            expect(wrapper.find('Ratings')).toHaveLength(1)
          }

          // Should have the criterion description
          const criterion = props.criterion
          if (criterion.description) {
            expect(wrapper.text()).toContain(criterion.description)
          }
        })

        subComponents.forEach(name => {
          it(`renders the ${name} sub-component(s) as expected`, () => {
            const wrapper = component()
            const subComponents = wrapper.find(name)

            if (name === 'OutcomeIcon') {
              // OutcomeIcon should only appear for outcome criteria
              if (criteriaType === 'outcome') {
                expect(subComponents.length).toBeGreaterThan(0)
                // Should contain screen reader text about learning outcomes
                if (subComponents.length > 0) {
                  expect(subComponents.dive().text()).toContain('Learning Outcome')
                }
              }
            } else if (name === 'Threshold') {
              // Threshold appears when mastery_points is set
              if (props.criterion.mastery_points != null) {
                expect(subComponents.length).toBeGreaterThan(0)
              }
            } else if (name === 'LongDescription') {
              // LongDescription appears when there's a long_description
              if (props.criterion.long_description) {
                expect(subComponents.length).toBeGreaterThan(0)
              }
            } else if (name === 'LongDescriptionDialog') {
              // Dialog should always be present when LongDescription exists
              if (props.criterion.long_description) {
                expect(subComponents.length).toBeGreaterThan(0)
                expect(subComponents.prop('open')).toBe(false) // Should start closed
              }
            }
          })
        })
      }

      describe(`with a ${criteriaType} criterion`, () => {
        describe('by default', () => {
          testRenderedComponents(basicProps)
        })

        describe('when assessing', () => {
          testRenderedComponents({...basicProps, onAssessmentChange: () => {}})

          it('should render Points component when assessing', () => {
            const wrapper = shallow(
              <Criterion {...{...basicProps, onAssessmentChange: () => {}}} />,
            )

            if (!basicProps.criterion.ignore_for_scoring) {
              expect(wrapper.find('Points')).toHaveLength(1)
            }
          })
        })

        describe('without an assessment', () => {
          testRenderedComponents({...basicProps, assessment: undefined})

          it('should handle missing assessment gracefully', () => {
            const wrapper = shallow(<Criterion {...{...basicProps, assessment: undefined}} />)

            // Should still render the basic structure
            expect(wrapper.find(Table.Row)).toHaveLength(1)

            // Should render appropriate content based on freeForm
            if (basicProps.freeForm) {
              expect(wrapper.find('Comments')).toHaveLength(1)
            } else {
              expect(wrapper.find('Ratings')).toHaveLength(1)
            }
          })
        })
      })
    })
  })
})

describe('Criterion', () => {
  it('can open and close the long description dialog', () => {
    const criterion = {
      ...rubrics.freeForm.criteria[1],
      long_description: '<p> a wild paragraph appears </p>',
    }

    const component = (
      <Criterion assessment={assessments.freeForm.data[1]} criterion={criterion} freeForm={true} />
    )

    const render = shallow(component)
    const expectState = state =>
      expect(render.find('LongDescriptionDialog').prop('open')).toEqual(state)

    expectState(false)
    render.find('LongDescription').prop('showLongDescription')()
    expectState(true)

    const dialog = render.find('LongDescriptionDialog')
    const dialogContent = dialog.dive().find('div')
    expect(dialogContent).toHaveLength(1)
    expect(dialogContent.html()).toContain('a wild paragraph appears')

    dialog.prop('close')()
    expectState(false)
  })

  it('does not have a threshold when mastery_points is null / there is no outcome', () => {
    const nullified = {...rubrics.points.criteria[1], mastery_points: null}
    const el = shallow(<Criterion criterion={nullified} freeForm={false} />)

    expect(el.find('Threshold')).toHaveLength(0)
  })

  it('does not have a points column when hasPointsColumn is false', () => {
    const el = shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        hasPointsColumn={false}
      />,
    )

    expect(el.find(Table.Cell)).toHaveLength(1)
  })

  it('only shows comments when they exist or editComments is true', () => {
    const withAssessment = changes =>
      shallow(
        <Criterion
          assessment={{...assessments.points.data[1], ...changes}}
          onAssessmentChange={jest.fn()}
          criterion={rubrics.points.criteria[1]}
          freeForm={false}
        />,
      )
        .find('Ratings')
        .prop('footer')

    expect(withAssessment({comments: 'blah', editComments: false})).toBeDefined()
    expect(withAssessment({comments: '', editComments: true})).toBeDefined()
    expect(withAssessment({comments: '', editComments: false})).toBeNull()
  })

  it('allows extra credit for outcomes when enabled', () => {
    const el = shallow(
      <Criterion
        allowExtraCredit={true}
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        onAssessmentChange={() => {}}
      />,
    )

    expect(el.find('Points').prop('allowExtraCredit')).toEqual(true)
  })

  describe('the Points for a criterion', () => {
    const points = props =>
      shallow(
        <Criterion assessment={assessments.points.data[1]} freeForm={false} {...props} />,
      ).find('Points')

    const criterion = rubrics.points.criteria[1]
    it('are visible by default', () => {
      expect(points({criterion})).toHaveLength(1)
    })

    it('can be changed', () => {
      const onAssessmentChange = jest.fn()
      const el = points({criterion, onAssessmentChange})
      const onPointChange = el.find('Points').prop('onPointChange')

      onPointChange({points: '10', description: 'good', id: '1'})
      onPointChange({points: '10.245', description: 'better', id: '2'})
      onPointChange({points: 'blergh', description: 'invalid', id: '3'})
      expect(onAssessmentChange.mock.calls).toEqual([
        [{description: 'good', id: '1', points: {text: '10', valid: true, value: 10}}],
        [{description: 'better', id: '2', points: {text: '10.245', valid: true, value: 10.245}}],
        [
          {
            description: 'invalid',
            id: '3',
            points: {text: 'blergh', valid: false, value: undefined},
          },
        ],
      ])
    })

    it('can be selected and deselected', () => {
      const onAssessmentChange = jest.fn()
      const el = points({criterion, onAssessmentChange})
      const onPointChange = el.find('Points').prop('onPointChange')

      onPointChange({points: '10', description: 'good', id: '1'}, false)
      onPointChange({points: '10', description: 'good', id: '1'}, true)

      expect(onAssessmentChange.mock.calls).toEqual([
        [{description: 'good', id: '1', points: {text: '10', valid: true, value: 10}}],
        [{points: {text: '', valid: true}}],
      ])
    })

    it('are hidden when hidePoints is true', () => {
      expect(points({criterion, hidePoints: true})).toHaveLength(0)
    })

    describe('when ignore_for_scoring is set', () => {
      const ignoredPoints = props =>
        points({
          criterion: {
            ...rubrics.points.criteria[1],
            ignore_for_scoring: true,
          },
          ...props,
        })

      it('are not shown by default', () => expect(ignoredPoints()).toHaveLength(0))

      it('are not shown in summary mode', () =>
        expect(ignoredPoints({isSummary: true})).toHaveLength(0))

      it('are not shown when assessing', () => {
        expect(ignoredPoints({onAssessmentChange: () => {}})).toHaveLength(0)
      })
    })
  })

  it('renders points and rating-points when restrictive quantitative data is false and hasPointsColumn is true', () => {
    const component = shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        hidePoints={false}
        freeForm={false}
        hasPointsColumn={true}
      />,
    )

    expect(component.find('[data-testid="criterion-points"]').exists()).toBe(true)
    expect(component.find('[data-testid="points"]').exists()).toBe(true)
  })

  it('renders points and rating-points when restrictive quantitative data is false and hasPointsColumn if false', () => {
    const component = shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={true}
        hasPointsColumn={true}
      />,
    )

    expect(component.find('[data-testid="points"]').exists()).toBe(true)
  })

  describe('with restrict_quantitative_data', () => {
    let originalENV

    beforeEach(() => {
      originalENV = {...window.ENV}
      window.ENV.restrict_quantitative_data = true
    })

    afterEach(() => {
      window.ENV = originalENV
    })

    it('does not renders points and rating-points when restrictive quantitative data is true and hasPointsColumn is false', () => {
      const component = shallow(
        <Criterion
          assessment={assessments.points.data[1]}
          criterion={rubrics.points.criteria[1]}
          freeForm={false}
          hasPointsColumn={false}
        />,
      )

      expect(component.find('[data-testid="points"]').exists()).toBe(false)
    })
  })
})
