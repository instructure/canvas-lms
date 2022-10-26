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
import * as enzyme from 'enzyme'
import BlueprintLockOptions from 'ui/features/course_settings/react/components/BlueprintLockOptions'

QUnit.module('BlueprintLockOptions component')

const defaultProps = () => ({
  isMasterCourse: false,
  disabledMessage: '',
  useRestrictionsbyType: false,
  generalRestrictions: {
    content: false,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
  restrictionsByType: {
    assignment: {content: false, points: false, due_dates: false, availability_dates: false},
    discussion_topic: {content: false, points: false, due_dates: false, availability_dates: false},
    wiki_page: {content: false, points: false, due_dates: false, availability_dates: false},
    quiz: {content: false, points: false, due_dates: false, availability_dates: false},
    attachment: {content: false, points: false, due_dates: false, availability_dates: false},
  },
  lockableAttributes: ['content', 'points', 'due_dates', 'availability_dates'],
})

test('renders the BlueprintLockOptions component', () => {
  const tree = enzyme.shallow(<BlueprintLockOptions {...defaultProps()} />)
  const node = tree.find('Checkbox')
  const radioButton = tree.find('.bcs_sub-menu-item RadioInput')
  ok(node.exists())
  notOk(radioButton.exists())
})

test('renders the general menu when locktype is false and checkbox is checked', () => {
  const props = defaultProps()
  props.isMasterCourse = true
  const tree = enzyme.shallow(<BlueprintLockOptions {...props} />)
  const node = tree.find('.bcs_radio_input-group LockCheckList')
  ok(node.exists())
})

test('renders the granular menu when locktype is true and checkbox is checked', () => {
  const props = defaultProps()
  props.isMasterCourse = true
  props.useRestrictionsbyType = true
  const tree = enzyme.shallow(<BlueprintLockOptions {...props} />)
  const node = tree.find('.bcs_radio_input-group ExpandableLockOptions')
  ok(node.exists())
})

test('renders disabled when message is present', () => {
  const props = defaultProps()
  props.disabledMessage = 'This is a message'
  const tree = enzyme.shallow(<BlueprintLockOptions {...props} />)
  const checkbox = tree.find('Checkbox[disabled=true]')
  equal(checkbox.length, 1)
})
