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
import {merge} from 'lodash'
import { DiscussionRow } from 'jsx/discussions/components/DiscussionRow'

QUnit.module('DiscussionRow component')

const makeProps = (props = {}) => merge({
  discussion: {
    id: '1',
    position: 1,
    published: true,
    title: 'Hello World',
    message: 'Foo bar bar baz boop beep bop Foo',
    posted_at: 'January 10, 2019 at 10:00 AM',
    can_unpublish: true,
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
    last_reply_at: new Date(2018, 1, 14, 0, 0, 0, 0)
  },
  canPublish: false,
  masterCourseData: {},
}, props)

test('renders the DiscussionRow component', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  ok(tree.exists())
  tree.unmount()
})

test('renders UnreadBadge if discussion has replies > 0', () => {
  const discussion = { discussion_subentry_count: 5 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  ok(node.exists())
  tree.unmount()
})

test('renders Correct Screenreader message for locked discussions', () => {
  const discussion = { locked: false, title: "blerp"}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const instance = tree.instance() // Unintuitive but remember this is the message it will do not what it actually is
  equal(instance.makeLockedSuccessFailMessages().successMessage, "Lock discussion blerp succeeded")
  equal(instance.makeLockedSuccessFailMessages().failMessage, "Lock discussion blerp failed")
  tree.unmount()
})

test('renders Correct Screenreader message for unlocked discussions', () => {
  const discussion = { locked: true, title: "blerp"}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const instance = tree.instance() // Unintuitive but remember this is the message it will do not what it actually is
  equal(instance.makeLockedSuccessFailMessages().successMessage, "Unlock discussion blerp succeeded")
  equal(instance.makeLockedSuccessFailMessages().failMessage, "Unlock discussion blerp failed")
  tree.unmount()
})

test('does not render UnreadBadge if discussion has replies == 0', () => {
  const discussion = { discussion_subentry_count: 0 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  notOk(node.exists())
  tree.unmount()
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
  tree.unmount()
})

test('renders ReadBadge if discussion has replies == 0', () => {
  const discussion = { discussion_subentry_count: 0 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('UnreadBadge')
  notOk(node.exists())
  tree.unmount()
})

test('renders the subscription ToggleIcon', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  const node = tree.find('ToggleIcon')
  ok(node.exists())
  strictEqual(node.length, 1)
  tree.unmount()
})

test('disables publish button when can_unpublish is false', () => {
  const discussion = { can_unpublish: false }
  const tree = mount(<DiscussionRow {...makeProps({canPublish: true, discussion})} />)
  const node = tree.find('ToggleIcon .publish-button')
  strictEqual(node.props().children.props.disabled, true)
})

test('allows to publish even if you cannot unpublish', () => {
  const discussion = { can_unpublish: false, published: false }
  const tree = mount(<DiscussionRow {...makeProps({canPublish: true, discussion})} />)
  const node = tree.find('ToggleIcon .publish-button')
  strictEqual(node.props().children.props.disabled, false)
})

test('renders the publish ToggleIcon', () => {
  const tree = mount(<DiscussionRow {...makeProps({canPublish: true})} />)
  const node = tree.find('ToggleIcon')
  ok(node.exists())
  strictEqual(node.length, 2)
})

test('renders "Delayed until" date label if discussion is delayed', () => {
  const delayedDate = new Date
  delayedDate.setYear(delayedDate.getFullYear() + 1)
  const discussion = { delayed_post_at: delayedDate.toString() }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.discussion-availability')
  ok(node.text().includes('Not available'))
  ok(node.exists())
  tree.unmount()
})

test('renders a last reply at date', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  const node = tree.find('.last-reply-at')
  ok(node.exists())
  ok(node.text().includes('Last post at'))
  ok(node.text().includes('Feb'))
  tree.unmount()
})

test('does not render last reply at date if there is none', () => {
  const discussion = { last_reply_at: "" }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.ic-discussion-row')
  ok(!node.text().includes('Last post at'))
  tree.unmount()
})

test('renders available until if approprate', () => {
  const futureDate = new Date
  futureDate.setYear(futureDate.getFullYear() + 1)
  const discussion = { lock_at: futureDate }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.discussion-availability')
  ok(node.exists())
  ok(node.text().includes('Available until'))
  // We need a relative date to ensure future-ness, so we can't really insist
  // on a given date element appearing this time
  tree.unmount()
})

test('renders locked at if appropriate', () => {
  const pastDate = new Date
  pastDate.setYear(pastDate.getFullYear() - 1)
  const discussion = { lock_at: pastDate }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('.discussion-availability')
  ok(node.exists())
  ok(node.text().includes('Was locked at'))
  // We need a relative date to ensure past-ness, so we can't really insist
  // on a given date element appearing this time
  tree.unmount()
})

test('renders nothing if currently available and no end date', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  let node = tree.find('.discussion-available-until')
  notOk(node.exists())
  node = tree.find('.discussion-delayed-until')
  notOk(node.exists())
  node = tree.find('.discussion-was-locked')
  notOk(node.exists())
  tree.unmount()
})

test('renders due date if graded with a due date', () => {
  const props = makeProps({
    discussion: {
      assignment: {
        due_at: '2018-07-01T05:59:00Z',
      }
    }
  })
  const tree = mount(<DiscussionRow {...props} />)
  let node = tree.find('.due-date')
  ok(node.exists())
  node = tree.find('.todo-date')
  notOk(node.exists())
})

test('renders to do date if ungraded with a to do date', () => {
  const props = makeProps({
    discussion: {
      todo_date: '2018-07-01T05:59:00Z',
    }
  })
  const tree = mount(<DiscussionRow {...props} />)
  let node = tree.find('.todo-date')
  ok(node.exists())
  node = tree.find('due-date')
  notOk(node.exists())
})

test('renders neither a due or to do date if neither are available', () => {
  const tree = mount(<DiscussionRow {...makeProps()} />)
  let node = tree.find('.todo-date')
  notOk(node.exists())
  node = tree.find('due-date')
  notOk(node.exists())
})

test('renders the SectionsTooltip component', () => {
  const discussion = { user_count: 200 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  equal(tree.find('SectionsTooltip Text').text(), 'All Sections')
  tree.unmount()
})

test('renders the SectionsTooltip component with sections', () => {
  const discussion = { sections: [
    { "id": 6, "course_id": 1, "name": "section 4", "user_count": 2 },
    { "id": 5, "course_id": 1, "name": "section 2", "user_count": 1 }
  ]}
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  equal(tree.find('SectionsTooltip Text').text(), '2 Sectionssection 4section 2')
  tree.unmount()
})

test('does not render the SectionsTooltip component on a graded discussion', () => {
  const discussion = { user_count: 200, assignment: true }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
  tree.unmount()
})

test('does not render the SectionsTooltip component on a group discussion', () => {
  const discussion = { user_count: 200, group_category_id: 13 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
})

test('does not render the SectionsTooltip component within a group context', () => {
  const discussion = { user_count: 200 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion, contextType: "group" })} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
  tree.unmount()
})

test('does not render the SectionsTooltip component in a blueprint course', () => {
  const discussion = { user_count: 200 }
  const tree = mount(<DiscussionRow {...makeProps({ discussion, isMasterCourse: true})} />)
  const node = tree.find('SectionsTooltip')
  notOk(node.exists())
  tree.unmount()
})

test('does not render master course lock icon if masterCourseData is not provided', (assert) => {
  const masterCourseData = null
  const rowRef = (row) => {
    notOk(row.masterCourseLock)
    done()
  }
  const tree = mount(<DiscussionRow {...makeProps({ masterCourseData, rowRef })} />)
  notOk(tree.instance().masterCourseLock)
})

test('renders master course lock icon if masterCourseData is provided', (assert) => {
  const masterCourseData = { isMasterCourse: true, masterCourse: { id: '1' } }
  const rowRef = (row) => {
    ok(row.masterCourseLock)
    done()
  }
  const tree = mount(<DiscussionRow {...makeProps({ masterCourseData, rowRef })} />)
  ok(tree.instance().masterCourseLock)
  tree.unmount()
})

test('renders drag icon', () => {
  const tree = mount(<DiscussionRow {...makeProps({draggable: true})} />)
  const node = tree.find('IconDragHandle')
  ok(node.exists())
  tree.unmount()
})

test('does not render manage menu if not permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({ displayManageMenu: false })} />)
  const node = tree.find('DiscussionManageMenu')
  notOk(node.exists())
  tree.unmount()
})

test('does not insert the manage menu list if we have not clicked it yet', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    onMoveDiscussion: ()=>{}
  })} />)
  // We still should show the menu thingy itself
  const menuNode = tree.find('DiscussionManageMenu')
  ok(menuNode.exists())
  // We have to search the whole document because the items in instui
  // popover menu are appended to the end of the document rather than
  // within the popover menu or even the discussion row
  const menuItemNode = document.querySelector('#moveTo-discussion-menu-option')
  equal(menuItemNode, null)
  tree.unmount()
})

test('manage menu items do appear upon click', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    onMoveDiscussion: ()=>{}
  })} />)
  const menuNode = tree.find('DiscussionManageMenu')
  ok(menuNode.exists())
  menuNode.find('button').simulate('click')
  // We have to search the whole document because the items in instui
  // popover menu are appended to the end of the document rather than
  // within the popover menu or even the discussion row
  const menuItemNode = document.querySelector('#moveTo-discussion-menu-option')
  ok(menuItemNode.textContent.includes('Move To'))
  tree.unmount()
})

test('renders available date and delayed date on graded discussions', () => {
  const tree = mount(
    <DiscussionRow
      {...makeProps({
        discussion: {
          assignment: {
            lock_at: '2018-07-01T05:59:00Z',
            unlock_at: '2018-06-21T06:00:00Z'
          },
          id: '1',
          position: 1,
          published: true,
          title: 'Hello World',
          message: 'Foo bar bar baz boop beep bop Foo',
          posted_at: 'January 10, 2019 at 10:00 AM',
          can_unpublish: true,
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
          user_count: 10,
          delayed_post_at: '2018-06-21T06:00:00Z',
          last_reply_at: new Date(2018, 1, 14, 0, 0, 0, 0)
        }
      })}
    />
  )
  let node = tree.find('.discussion-availability')
  ok(node.exists())
  node = tree.find('.ic-discussion-row__content')
  ok(node.exists())
  tree.unmount()
})

test('renders move-to in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    onMoveDiscussion: ()=>{}
   })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'moveTo')
  tree.unmount()
})

test('renders pin item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayPinMenuItem: true
   })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'togglepinned')
  tree.unmount()
})

test('renders duplicate item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayDuplicateMenuItem: true
   })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'duplicate')
  tree.unmount()
})

test('renders delete item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayDeleteMenuItem: true
   })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'delete')
  tree.unmount()
})

test('renders lock item in manage menu if permitted', () => {
  const tree = mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    displayLockMenuItem: true
   })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'togglelocked')
  tree.unmount()
})

test('renders mastery paths menu item if permitted', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    discussion: {
      assignment_id: 2
    },
    displayMasteryPathsMenuItem: true
  })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'masterypaths')
  tree.unmount()
})

test('renders mastery paths link if permitted', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    discussion: {
      assignment_id: 2
    },
    displayMasteryPathsLink: true
  })} />)
  const node = tree.find('.discussion-index-mastery-paths-link')
  ok(node.exists())
  ok(node.text().includes('Mastery Paths'))
  tree.unmount()
})

test('renders ltiTool menu if there are some', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
    discussionTopicMenuTools:[{
      base_url: "test.com",
      canvas_icon_class: "icon-lti",
      icon_url: "iconUrltest.com",
      title: "discussion_topic_menu Text",
    }]
  })} />)
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 1)
  equal(allKeys[0], 'test.com')
  tree.unmount()
})

test('renders multiple ltiTool menu if there are multiple', () => {
  const tree=mount(<DiscussionRow {...makeProps({
    displayManageMenu: true,
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
  const manageMenu = tree.find('DiscussionManageMenu')
  const allKeys = manageMenu.props().menuOptions().map((option) => option.key)
  equal(allKeys.length, 2)
  equal(allKeys[1], 'test2.com')
  tree.unmount()
})
