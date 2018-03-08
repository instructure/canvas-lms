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
import CoursesPane from 'jsx/account_course_user_search/components/CoursesPane'
import CoursesStore from 'jsx/account_course_user_search/store/CoursesStore'

QUnit.module('Account Course User Search CoursesPane View', {
  setup() {
    CoursesStore.reset({accountId: '1'})
  },
  teardown() {
    CoursesStore.reset({})
  }
})

test('onUpdateFilters calls debouncedApplyFilters after updating state', () => {
  const wrapper = shallow(
    <CoursesPane
      accountId="1"
      roles={[{id: '1'}]}
      queryParams={{}}
      onUpdateQueryParams={function() {}}
    />
  )
  const instance = wrapper.instance()
  const spy = sinon.spy(instance, 'debouncedApplyFilters')
  instance.onUpdateFilters()
  ok(spy.called)
})
