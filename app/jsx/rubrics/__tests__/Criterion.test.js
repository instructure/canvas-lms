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
    const component = (
      <Criterion
        assessment={assessments.freeForm.data[1]}
        criterion={rubrics.freeForm.criteria[1]}
        freeForm
      />
    )

    const render = shallow(component)
    const expectState = (state) =>
      expect(render.find('LongDescriptionDialog').prop('open')).toEqual(state)

    expectState(false)
    render.find('LongDescription').prop('showLongDescription')()
    expectState(true)
    render.find('LongDescriptionDialog').prop('close')()
    expectState(false)
  })
})
