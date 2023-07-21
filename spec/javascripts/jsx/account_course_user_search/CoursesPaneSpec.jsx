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
import {shallow} from 'enzyme'
import CoursesPane from 'ui/features/account_course_user_search/react/components/CoursesPane'
import CoursesStore from 'ui/features/account_course_user_search/react/store/CoursesStore'
import TermsStore from 'ui/features/account_course_user_search/react/store/TermsStore'
import AccountsTreeStore from 'ui/features/account_course_user_search/react/store/AccountsTreeStore'

const stores = [CoursesStore, TermsStore, AccountsTreeStore]

let wrapper
QUnit.module('Account Course User Search CoursesPane View', {
  setup() {
    stores.forEach(store => store.reset({accountId: '1'}))
    wrapper = shallow(
      <CoursesPane
        accountId="1"
        roles={[{id: '1'}]}
        queryParams={{}}
        onUpdateQueryParams={function () {}}
      />
    )
  },
  teardown() {
    stores.forEach(store => store.reset({}))
  },
})

test('onUpdateFilters calls debouncedApplyFilters after updating state', () => {
  const instance = wrapper.instance()
  const spy = sinon.spy(instance, 'debouncedApplyFilters')
  instance.onUpdateFilters()
  ok(spy.called)
})

test('have an h1 on the page', () => {
  equal(wrapper.find('h1').length, 1, 'There is one H1 on the page')
})
