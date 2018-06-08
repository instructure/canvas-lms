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
          expect(component().debug()).toMatchSnapshot()
        })

        subComponents.forEach((name) => {
          it(`renders the ${name} sub-component(s) as expected`, () => {
            component().find(name)
              .forEach((el) => expect(el.shallow().debug()).toMatchSnapshot())
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

  it('only shows instructor comments in sidebar when relevant', () => {
    // in particular, we only show the comment sidebar when:
    // - there are comments
    // - the rubric is not free-form
    // - we are not assessing the rubric
    // - the rubric is not in summary mode
    const comments = (changes) => shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        {...changes}
      />
    ).find('CommentText')

    expect(comments()).toHaveLength(1)
    const noComments = { ...assessments.points.data[1], comments: undefined }
    expect(comments({ assessment: noComments })).toHaveLength(0)
    expect(comments({ freeForm: true })).toHaveLength(0)
    expect(comments({ onAssessmentChange: () => {} })).toHaveLength(0)
    expect(comments({ isSummary: true })).toHaveLength(0)
  })

  it('does not have a points column in summary mode', () => {
    const el = shallow(
      <Criterion
        assessment={assessments.points.data[1]}
        criterion={rubrics.points.criteria[1]}
        freeForm={false}
        isSummary
      />
    )

    expect(el.find('td')).toHaveLength(1)
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
})
