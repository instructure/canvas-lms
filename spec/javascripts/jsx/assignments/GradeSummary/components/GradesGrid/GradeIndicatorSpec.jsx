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
import {mount} from 'enzyme'

import GradeIndicator from 'ui/features/assignment_grade_summary/react/components/GradesGrid/GradeIndicator'

QUnit.module('GradeSummary GradeIndicator', suiteHooks => {
  let $container
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    props = {
      gradeInfo: {
        grade: 'A',
        graderId: '1101',
        id: '4601',
        score: 10,
        selected: false,
        studentId: '1111',
      },
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  function mountComponent() {
    wrapper = mount(<GradeIndicator {...props} />, {attachTo: $container})
  }

  test('displays the score', () => {
    mountComponent()
    strictEqual(wrapper.text(), '10')
  })

  test('displays a zero score', () => {
    props.gradeInfo.score = 0
    mountComponent()
    strictEqual(wrapper.text(), '0')
  })

  test('displays "–" (en dash) when there is no grade', () => {
    delete props.gradeInfo
    mountComponent()
    strictEqual(wrapper.text(), '–')
  })

  test('changes the background color when the grade is selected', () => {
    mountComponent()
    const style = window.getComputedStyle(wrapper.getDOMNode())
    const backgroundColorBefore = style.backgroundColor
    wrapper.setProps({gradeInfo: {...props.gradeInfo, selected: true}})
    notEqual(style.backgroundColor, backgroundColorBefore)
  })

  test('changes the text color when the grade is selected', () => {
    mountComponent()
    const style = window.getComputedStyle(wrapper.childAt(0).getDOMNode())
    const colorBefore = style.color
    wrapper.setProps({gradeInfo: {...props.gradeInfo, selected: true}})
    notEqual(style.color, colorBefore)
  })

  test('adds screenreader text when the grade is selected', () => {
    mountComponent()
    wrapper.setProps({gradeInfo: {...props.gradeInfo, selected: true}})
    const text = wrapper.children().map(child => child.text())
    deepEqual(text, ['10Selected Grade'])
  })
})
