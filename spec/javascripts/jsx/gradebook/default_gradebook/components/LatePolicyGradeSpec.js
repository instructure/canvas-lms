/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import LatePolicyGrade from 'ui/features/gradebook/react/default_gradebook/components/LatePolicyGrade'

QUnit.module('LatePolicyGrade', suiteHooks => {
  let wrapper

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent(props = {}) {
    const defaultProps = {
      assignment: {
        pointsPossible: 100,
      },
      submission: {
        score: 70,
        grade: '70%',
        pointsDeducted: 3,
      },
      enterGradesAs: 'percent',
      gradingScheme: [
        ['A', 90],
        ['B', 80],
        ['C', 70],
      ],
    }
    wrapper = mount(<LatePolicyGrade {...defaultProps} {...props} />)
  }

  test('includes the late penalty as a negative value', () => {
    mountComponent()
    strictEqual(wrapper.find('#late-penalty-value').text(), '-3')
  })

  test('includes the final grade', () => {
    mountComponent()
    strictEqual(wrapper.find('#final-grade-value').text(), '70%')
  })

  test('rounds the final grade when a decimal value', () => {
    mountComponent({submission: {score: 7.345, grade: '7.345', pointsDeducted: 3}})
    strictEqual(wrapper.find('#final-grade-value').text(), '7.35%')
  })

  test('formats the final grade as points when enterGradesAs is set to points', () => {
    mountComponent({submission: {score: 70.25}, enterGradesAs: 'points'})
    strictEqual(wrapper.find('#final-grade-value').text(), '70.25')
  })

  test('formats the final grade as percentage when enterGradesAs is set to percent', () => {
    mountComponent({submission: {score: 70.25}, enterGradesAs: 'percent'})
    strictEqual(wrapper.find('#final-grade-value').text(), '70.25%')
  })

  test('formats the final grade as a letter grade when enterGradesAs is set to gradingScheme', () => {
    mountComponent({submission: {score: 70.25}, enterGradesAs: 'gradingScheme'})
    strictEqual(wrapper.find('#final-grade-value').text(), 'C')
  })

  test('formats the final grade as "Complete" when enterGradesAs is set to passFail and score > 0', () => {
    mountComponent({submission: {score: 70.25}, enterGradesAs: 'passFail'})
    strictEqual(wrapper.find('#final-grade-value').text(), 'Complete')
  })

  test('formats the final grade as "Incomplete" when enterGradesAs is set to passFail and score == 0', () => {
    mountComponent({submission: {score: 0}, enterGradesAs: 'passFail'})
    strictEqual(wrapper.find('#final-grade-value').text(), 'Incomplete')
  })
})
