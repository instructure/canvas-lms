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
import {render} from '@testing-library/react'
import * as enzyme from 'enzyme'
import CourseFilter from 'ui/features/blueprint_course_master/react/components/CourseFilter'
import getSampleData from '../getSampleData'

const defaultProps = () => ({
  subAccounts: getSampleData().subAccounts,
  terms: getSampleData().terms,
})
let fixtures

QUnit.module('CourseFilter', hooks => {
  hooks.beforeEach(() => {
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = '<div id="flash_screenreader_holder" role="alert"></div>'
  })

  hooks.afterEach(() => {
    fixtures.innerHTML = ''
  })

  test('renders the CourseFilter component', () => {
    const tree = enzyme.shallow(<CourseFilter {...defaultProps()} />)
    const node = tree.find('.bca-course-filter')
    ok(node.exists())
  })

  test('onChange fires with search filter when text is entered in search box', assert => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = filter => {
      equal(filter.search, 'giraffe')
      done()
    }
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('input[type="search"]')
    input.instance().value = 'giraffe'
    input.simulate('change')
  })

  test('onActivate fires when filters are focused', () => {
    const props = defaultProps()
    props.onActivate = sinon.spy()
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('input[type="search"]')
    input.simulate('focus')
    ok(props.onActivate.calledOnce)
  })

  test('onChange not fired when < 3 chars are entered in search text input', assert => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = sinon.spy()
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('input[type="search"]')
    input.instance().value = 'aa'
    input.simulate('change')
    setTimeout(() => {
      equal(props.onChange.callCount, 0)
      done()
    }, 0)
  })

  test('onChange fired when 3 chars are entered in search text input', assert => {
    const done = assert.async()
    const props = defaultProps()
    props.onChange = sinon.spy()
    const tree = enzyme.mount(<CourseFilter {...props} />)
    const input = tree.find('input[type="search"]')
    input.instance().value = 'aaa'
    input.simulate('change')
    setTimeout(() => {
      ok(props.onChange.calledOnce)
      done()
    }, 0)
  })

  QUnit.module('CourseFilter > Filter behavior', suiteHooks => {
    let container
    let component
    let select

    suiteHooks.afterEach(() => {
      component.unmount()
      container.remove()
    })

    function renderComponent(props) {
      return render(<CourseFilter {...props} />, {container})
    }

    function clickToExpand() {
      select.click()
    }

    function getOptionsList() {
      const optionsListId = select.getAttribute('aria-controls')
      return document.getElementById(optionsListId)
    }

    function getOption(optionLabel) {
      return getOptions().find($option => $option.textContent.trim() === optionLabel)
    }

    function getOptions() {
      return [...getOptionsList().querySelectorAll('[role="option"]')]
    }

    function getOptionLabels() {
      return getOptions().map(option => option.textContent.trim())
    }

    function selectOption(optionLabel) {
      getOption(optionLabel).click()
    }

    test('onChange fires with term filter when term is selected', assert => {
      const done = assert.async()
      const props = defaultProps()
      props.onChange = filter => {
        equal(filter.term, '1')
        done()
      }
      container = document.body.appendChild(document.createElement('div'))
      component = renderComponent(props)
      select = container.querySelectorAll('input[type="text"]')[0]

      clickToExpand()
      selectOption('Term One')
    })

    test('onChange fires with subaccount filter when a subaccount is selected', assert => {
      const done = assert.async()
      const props = defaultProps()
      props.onChange = filter => {
        equal(filter.subAccount, '2')
        done()
      }
      container = document.body.appendChild(document.createElement('div'))
      component = renderComponent(props)
      select = container.querySelectorAll('input[type="text"]')[1]

      clickToExpand()
      selectOption('Account Two')
    })
  })
})
