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
import _ from 'lodash'
import AnnouncementRow from 'jsx/shared/components/AnnouncementRow'

QUnit.module('AnnouncementRow component')

const makeProps = (props = {}) =>
  _.merge(
    {
      announcement: {
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
          avatar_image_url: null
        },
        read_state: 'unread',
        unread_count: 0,
        discussion_subentry_count: 5,
        locked: false,
        html_url: '',
        user_count: 10
      },
      canManage: false,
      masterCourseData: {}
    },
    props
  )

test('renders the AnnouncementRow component', () => {
  const tree = mount(<AnnouncementRow {...makeProps()} />)
  ok(tree.exists())
})

test('renders a checkbox if canManage: true', () => {
  const tree = mount(<AnnouncementRow {...makeProps({canManage: true})} />)
  const node = tree.find('Checkbox')
  ok(node.exists())
})

test('renders no checkbox if canManage: false', () => {
  const tree = mount(<AnnouncementRow {...makeProps({canManage: false})} />)
  const node = tree.find('Checkbox')
  notOk(node.exists())
})

test('renders UnreadBadge if announcement has replies > 0', () => {
  const announcement = {discussion_subentry_count: 5}
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  const node = tree.find('UnreadBadge')
  ok(node.exists())
})

test('renders UnreadBadge if announcement has replies == 0', () => {
  const announcement = {discussion_subentry_count: 0}
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  const node = tree.find('UnreadBadge')
  notOk(node.exists())
})

test('renders "Delayed until" date label if announcement is delayed', () => {
  const announcement = {delayed_post_at: new Date().toString()}
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  const node = tree.find('.ic-item-row__meta-content-heading')
  ok(node.text().includes('Delayed until'))
})

test('renders "Posted on" date label if announcement is not delayed', () => {
  const announcement = {delayed_post_at: null}
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  const node = tree.find('.ic-item-row__meta-content-heading')
  ok(node.text().includes('Posted on'))
})

test('renders the SectionsTooltip component', () => {
  const announcement = {user_count: 200}
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  equal(tree.find('SectionsTooltip Text').text(), 'All Sections')
})

test('renders the SectionsTooltip component with sections', () => {
  const announcement = {
    sections: [
      {id: 6, course_id: 1, name: 'section 4', user_count: 2},
      {id: 5, course_id: 1, name: 'section 2', user_count: 1}
    ]
  }
  const tree = mount(<AnnouncementRow {...makeProps({announcement})} />)
  equal(tree.find('SectionsTooltip Text').text(), '2 Sectionssection 4section 2')
})

test('does not render master course lock icon if masterCourseData is not provided', assert => {
  const done = assert.async()
  const masterCourseData = null
  const rowRef = row => {
    notOk(row.masterCourseLock)
    done()
  }
  mount(<AnnouncementRow {...makeProps({masterCourseData, rowRef})} />)
})

test('renders master course lock icon if masterCourseData is provided', assert => {
  const done = assert.async()
  const masterCourseData = {isMasterCourse: true, masterCourse: {id: '1'}}
  const rowRef = row => {
    ok(row.masterCourseLock)
    done()
  }
  mount(<AnnouncementRow {...makeProps({masterCourseData, rowRef})} />)
})

test('renders reply button icon if is not locked', () => {
  const tree = mount(<AnnouncementRow {...makeProps({announcement: {locked: false}})} />)
  const node = tree.find('IconReplyLine')
  ok(node.exists())
})

test('does not render reply button icon if is locked', () => {
  const tree = mount(<AnnouncementRow {...makeProps({announcement: {locked: true}})} />)
  const node = tree.find('IconReplyLine')
  notOk(node.exists())
})

test('removes non-text content from announcement message', () => {
  const messageHtml = `
    <p>Hello World!</p>
    <img src="/images/stuff/things.png" />
    <p>foo bar</p>
  `
  const tree = mount(<AnnouncementRow {...makeProps({announcement: {message: messageHtml}})} />)
  const node = tree.find('.ic-announcement-row__content').getDOMNode()
  equal(node.childNodes.length, 1)
  equal(node.childNodes[0].nodeType, 3) // nodeType === 3 is text node type
  ok(node.textContent.includes('Hello World!'))
  ok(node.textContent.includes('foo bar'))
})
