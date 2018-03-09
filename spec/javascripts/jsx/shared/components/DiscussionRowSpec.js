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
import { mount } from 'enzyme'
import _ from 'lodash'
import DiscussionRow from 'jsx/shared/components/DiscussionRow'

QUnit.module('DiscussionRow component')

const makeProps = (props = {}) => _.merge({
  discussion: {
    id: '1',
    position: 1,
    published: true,
    title: 'Hello World',
    message: 'Foo bar bar baz boop beep bop Foo',
    posted_at: 'January 10, 2019 at 10:00 AM',
    author: {
      id: '5',
      display_name: 'John Smith',
      html_url: '',
      avatar_image_url: null,
    },
    read_state: 'unread',
    unread_count: 0,
    discussion_subentry_count: 5,
    locked: false,
    html_url: '',
    user_count: 10,
  },
  canPublish: false,
  masterCourseData: {},
}, props)

test('renders the DiscussionRow component', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  ok(tree.exists())
})

test('renders UnreadBadge if discussion has replies > 0', () => {
  const discussion = { discussion_subentry_count: 5 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  ok(node.exists())
})

test('does not render UnreadBadge if discussion has replies == 0', () => {
  const discussion = { discussion_subentry_count: 0 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  notOk(node.exists())
})

test('renders ReadBadge if discussion is unread', () => {
  const discussion = { read_state: "unread" }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('Badge')
  ok(node.exists())
})

test('does not render ReadBadge if discussion is read', () => {
  const discussion = { read_state: "read" }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('Badge')
  notOk(node.exists())
})

test('renders ReadBadge if discussion has replies == 0', () => {
  const discussion = { discussion_subentry_count: 0 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  notOk(node.exists())
})

test('renders the subscription ToggleIcon', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  const node = tree.find('ToggleIcon')
  ok(node.exists())
  strictEqual(node.length, 1)
})

test('renders the publish ToggleIcon', () => {
  const tree = mount(<DiscussionRow {...makeProps({canPublish: true})} />)
  const node = tree.find('ToggleIcon')
  ok(node.exists())
  strictEqual(node.length, 2)
})

test('renders "Delayed until" date label if discussion is delayed', () => {
  const discussion = { delayed_post_at: (new Date).toString() }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.ic-item-row__meta-content-heading')
  ok(node.text().includes('Delayed until'))
})

test('renders "Posted on" date label if discussion is not delayed', () => {
  const discussion = { delayed_post_at: null }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.ic-item-row__meta-content-heading')
  ok(node.text().includes('Posted on'))
})

test('renders the SectionsTooltip component', () => {
  const discussion = { user_count: 200 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  equal(tree.find('SectionsTooltip Text').text(), 'All Sections')
})

test('renders the SectionsTooltip component with sections', () => {
  const discussion = { sections: [
    { "id": 6, "course_id": 1, "name": "section 4", "user_count": 2 },
    { "id": 5, "course_id": 1, "name": "section 2", "user_count": 1 }
  ]}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  equal(tree.find('SectionsTooltip Text').text(), '2 Sectionssection 4section 2')
})

test('does not render master course lock icon if masterCourseData is not provided', (assert) => {
  const done = assert.async()
  const masterCourseData = null
  const rowRef = (row) => {
    notOk(row.masterCourseLock)
    done()
  }
  mount(<DiscussionRow {...makeProps({ masterCourseData, rowRef })} />)
})

test('renders master course lock icon if masterCourseData is provided', (assert) => {
  const done = assert.async()
  const masterCourseData = { isMasterCourse: true, masterCourse: { id: '1' } }
  const rowRef = (row) => {
    ok(row.masterCourseLock)
    done()
  }
  mount(<DiscussionRow {...makeProps({ masterCourseData, rowRef })} />)
})

test('renders drag icon', () => {
  const tree = mount(<DiscussionRow {...makeProps({draggable: true})} />)
  const node = tree.find('IconDragHandleLine')
  ok(node.exists())
})

test('removes non-text content from discussion message', () => {
  const messageHtml = `
    <p>Hello World!</p>
    <img src="/images/stuff/things.png" />
    <p>foo bar</p>
  `
  const tree = mount(<DiscussionRow {...makeProps({ discussion: { message: messageHtml } })} />)
  const node = tree.find('.ic-discussion-row__content').getDOMNode()
  equal(node.childNodes.length, 1)
  equal(node.childNodes[0].nodeType, 3) // nodeType === 3 is text node type
  ok(node.textContent.includes('Hello World!'))
  ok(node.textContent.includes('foo bar'))
})

test('renders manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({ canManage: true })} />)
  const manageMenuNode = tree.find('PopoverMenu')
  ok(manageMenuNode.exists())
  const courseItemRow = tree.find('CourseItemRow')
  ok(courseItemRow.exists())
  ok(courseItemRow.props().manageMenuOptions.length > 0)
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  ok(allKeys.includes('duplicate'))
  ok(allKeys.includes('togglepinned'))
  ok(allKeys.includes('togglelocked'))
})

test('renders move-to in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    canManage: true,
    onMoveDiscussion: ()=>{}
   })} />)
  const manageMenuNode = tree.find('PopoverMenu')
  ok(manageMenuNode.exists())
  const courseItemRow = tree.find('CourseItemRow')
  ok(courseItemRow.exists())
  ok(courseItemRow.props().manageMenuOptions.length > 0)
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  ok(allKeys.includes('move'))
})

test('does not render manage menu if not permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({ canManage: false })} />)
  const node = tree.find('PopoverMenu')
  notOk(node.exists())
})
