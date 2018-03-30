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

test('renders Correct Screenreader message for locked discussions', () => {
  const discussion = { locked: false, title: "blerp"}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const instance = tree.instance() // Unintuitive but remember this is the message it will do not what it actually is
  equal(instance.makeLockedSuccessFailMessages().successMessage, "Lock discussion blerp succeeded")
  equal(instance.makeLockedSuccessFailMessages().failMessage, "Lock discussion blerp failed")
})

test('renders Correct Screenreader message for unlocked discussions', () => {
  const discussion = { locked: true, title: "blerp"}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const instance = tree.instance() // Unintuitive but remember this is the message it will do not what it actually is
  equal(instance.makeLockedSuccessFailMessages().successMessage, "Unlock discussion blerp succeeded")
  equal(instance.makeLockedSuccessFailMessages().failMessage, "Unlock discussion blerp failed")
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

test('does not renders the SectionsTooltip component on a graded discussion', () => {
  const discussion = { user_count: 200, assignment: true }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
})

test('does not renders the SectionsTooltip component on a group discussion', () => {
  const discussion = { user_count: 200, group_category_id: 13 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
})

test('does not renders the SectionsTooltip component within a group context', () => {
  const discussion = { user_count: 200 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion, contextType: "group" })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
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

test('does not render manage menu if not permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({ displayManageMenu: false })} />)
  const node = tree.find('PopoverMenu')
  notOk(node.exists())
})

test('renders move-to in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    onMoveDiscussion: ()=>{}
   })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'moveTo')
})

test('renders pin item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayPinMenuItem: true
   })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'togglepinned')
})

test('renders duplicate item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayDuplicateMenuItem: true
   })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'duplicate')
})

test('renders delete item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayDeleteMenuItem: true
   })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'delete')
})

test('renders lock item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayLockMenuItem: true
   })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'togglelocked')
})

test('renders mastery paths menu item if permitted', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    discussion: {
      assignment_id: 2
    },
    displayMasteryPathsMenuItem: true
  })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'masterypaths')
})

test('renders ltiTool menu if there are some', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    discussionTopicMenuTools:[{
      base_url: "test.com",
      canvas_icon_class: "icon-lti",
      icon_url: "iconUrltest.com",
      title: "discussion_topic_menu Text",
    }]
  })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'test.com')
})

test('renders multiple ltiTool menu if there are multiple', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    discussionTopicMenuTools:[
      {
        base_url: "test.com",
        canvas_icon_class: "icon-lti",
        icon_url: "iconUrltest.com",
        title: "discussion_topic_menu Text",
      },
      {
        base_url: "test2.com",
        canvas_icon_class: "icon-lti",
        icon_url: "iconUrltest2.com",
        title: "discussion_topic_menu otherText",
      }
    ]
  })} />)
  const courseItemRow = tree.find('CourseItemRow')
  const allKeys = courseItemRow.props().manageMenuOptions.map((option) => option.key)
  equal(allKeys.length, 2)
  equal(allKeys[1], 'test2.com')
})
