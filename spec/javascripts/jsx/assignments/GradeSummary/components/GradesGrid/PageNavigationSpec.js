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

import PageNavigation from 'ui/features/assignment_grade_summary/react/components/GradesGrid/PageNavigation'

QUnit.module('GradeSummary PageNavigation', suiteHooks => {
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    props = {
      currentPage: 1,
      onPageClick: sinon.spy(),
      pageCount: 10,
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<PageNavigation {...props} />)
  }

  function findButtons(predicateFn) {
    return wrapper.find('button').filterWhere(predicateFn)
  }

  test('adds a button for each page', () => {
    mountComponent()
    strictEqual(findButtons(button => /\d+/.test(button.text())).length, 5)
  })

  test('includes a button for "Next Page" when not on the last page', () => {
    mountComponent()
    strictEqual(findButtons(button => button.text() === 'Next Page').length, 1)
  })

  test('excludes the button for "Next Page" when on the last page', () => {
    props.currentPage = 10
    mountComponent()
    strictEqual(findButtons(button => button.text() === 'Next Page').length, 0)
  })

  test('includes a button for "Previous Page" when not on the first page', () => {
    props.currentPage = 5
    mountComponent()
    strictEqual(findButtons(button => button.text() === 'Previous Page').length, 1)
  })

  test('excludes the button for "Previous Page" when on the first page', () => {
    mountComponent()
    strictEqual(findButtons(button => button.text() === 'Previous Page').length, 0)
  })

  test('calls onPageClick when a page button is clicked', () => {
    mountComponent()
    findButtons(button => button.text() === '3').simulate('click')
    strictEqual(props.onPageClick.callCount, 1)
  })

  test('includes page number when calling onPageClick', () => {
    mountComponent()
    findButtons(button => button.text() === '3').simulate('click')
    const [page] = props.onPageClick.lastCall.args
    strictEqual(page, 3)
  })

  test('calls onPageClick when the "Next Page" button is clicked', () => {
    props.currentPage = 3
    mountComponent()
    findButtons(button => button.text() === 'Next Page').simulate('click')
    strictEqual(props.onPageClick.callCount, 1)
  })

  test('includes the next page number when calling onPageClick for "Next Page"', () => {
    props.currentPage = 3
    mountComponent()
    findButtons(button => button.text() === 'Next Page').simulate('click')
    const [page] = props.onPageClick.lastCall.args
    strictEqual(page, 4)
  })

  test('calls onPageClick when the "Previous Page" button is clicked', () => {
    props.currentPage = 3
    mountComponent()
    findButtons(button => button.text() === 'Previous Page').simulate('click')
    strictEqual(props.onPageClick.callCount, 1)
  })

  test('includes the previous page number when calling onPageClick for "Previous Page"', () => {
    props.currentPage = 3
    mountComponent()
    findButtons(button => button.text() === 'Previous Page').simulate('click')
    const [page] = props.onPageClick.lastCall.args
    strictEqual(page, 2)
  })
})
