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
import { mount } from 'enzyme'
import merge from 'lodash/merge'
import CourseItemRow from 'jsx/shared/components/CourseItemRow'
import AnnouncementModel from 'compiled/models/Announcement'
import IconAssignmentLine from 'instructure-icons/lib/Line/IconAssignmentLine'

QUnit.module('CourseItemRow component')

const makeProps = (props = {}) => merge({
  title: <p>Hello World</p>,
  body: <p>Hello World</p>,
  actionsContent: null,
  metaContent: null,
  author: {
    id: '5',
    display_name: 'John Smith',
    html_url: '',
    avatar_image_url: null,
  },
  className: '',
  id: '5',
  itemUrl: '',
  selectable: false,
  defaultSelected: false,
  isRead: false,
  showAvatar: true,
  onSelectedChanged: () => {},
}, props)

test('renders the CourseItemRow component', () => {
  const tree = mount(<CourseItemRow {...makeProps()} />)
  ok(tree.exists())
})

test('renders children inside content column', () => {
  // lodash merge is broken, have to do it this way for whatever reason
  const props = makeProps({})
  props.title = <span className="find-me" />
  props.body = <span className="find-me2" />
  props.sectionToolTip = <span className="find-me3" />
  props.replyButton = <span className="find-me4" />

  const tree = mount(<CourseItemRow { ...props } />)
  ok(tree.find('.ic-item-row__content-col .find-me').exists())
  ok(tree.find('.ic-item-row__content-col .find-me2').exists())
  ok(tree.find('.ic-item-row__content-col .find-me3').exists())
  ok(tree.find('.ic-item-row__content-col .find-me4').exists())
})

test('renders clickable children inside content link', () => {
  // lodash merge is broken, have to do it this way for whatever reason
  const itemUrl = "/foo"
  const props = makeProps(makeProps({ itemUrl }))
  props.title = <span className="find-me" />
  props.body = <span className="find-me2" />
  props.sectionToolTip = <span className="find-me3" />
  props.replyButton = <span className="find-me4" />

  const tree = mount(<CourseItemRow { ...props } />)
  ok(tree.find('.ic-item-row__content-col .ic-item-row__content-link .find-me').exists())
  ok(tree.find('.ic-item-row__content-col .ic-item-row__content-link .find-me2').exists())
  ok(!tree.find('.ic-item-row__content-col .ic-item-row__content-link .find-me3').exists())
  ok(tree.find('.ic-item-row__content-col .ic-item-row__content-link .find-me4').exists())
})

test('renders actions inside actions wrapper', () => {
  const actionsContent = <span className="find-me" />
  const tree = mount(<CourseItemRow {...makeProps({ actionsContent })} />)
  const node = tree.find('.ic-item-row__meta-actions .find-me')
  ok(node.exists())
})

test('renders metaContent inside meta content wrapper', () => {
  const metaContent = <span className="find-me" />
  const tree = mount(<CourseItemRow {...makeProps({ metaContent })} />)
  const node = tree.find('.ic-item-row__meta-content .find-me')
  ok(node.exists())
})

test('renders a checkbox if selectable: true', () => {
  const tree = mount(<CourseItemRow {...makeProps({ selectable: true })} />)
  const node = tree.find('Checkbox')
  ok(node.exists())
})

test('renders a drag handle if draggable: true', () => {
  const tree = mount(<CourseItemRow {...makeProps({ draggable: true, connectDragSource: (component) => component})} />)
  const node = tree.find('IconDragHandleLine')
  ok(node.exists())
})

test('renders inputted icon', () => {
  const tree = mount(<CourseItemRow {...makeProps({ icon: <IconAssignmentLine /> })} />)
  const node = tree.find('IconAssignmentLine')
  ok(node.exists())
})

test('renders no checkbox if selectable: false', () => {
  const tree = mount(<CourseItemRow {...makeProps({ selectable: false })} />)
  const node = tree.find('Checkbox')
  notOk(node.exists())
})

test('renders an avatar if showAvatar: true', () => {
  const tree = mount(<CourseItemRow {...makeProps({ showAvatar: true })} />)
  const node = tree.find('Avatar')
  ok(node.exists())
})

test('renders no avatar if showAvatar: false', () => {
  const tree = mount(<CourseItemRow {...makeProps({ showAvatar: false })} />)
  const node = tree.find('Avatar')
  notOk(node.exists())
})

test('renders unread indicator if isRead: false', () => {
  const tree = mount(<CourseItemRow {...makeProps({ isRead: false })} />)
  const rowNode = tree.find('Badge')
  ok(rowNode.exists())

  const srNode = tree.find('.ic-item-row__content-col ScreenReaderContent')
  ok(srNode.exists())
  ok(srNode.text().includes('Unread'))
})

test('renders no unread indicator if isRead: true', () => {
  const tree = mount(<CourseItemRow {...makeProps({ isRead: true })} />)
  const rowNode = tree.find('.ic-item-row')
  notOk(rowNode.hasClass('ic-item-row__unread'))

  const srNode = tree.find('.ic-item-row__content-col ScreenReaderContent')
  notOk(srNode.exists())
})

test('passes down className prop to component', () => {
  const tree = mount(<CourseItemRow {...makeProps({ className: 'find-me' })} />)
  const rowNode = tree.find('.ic-item-row')
  ok(rowNode.hasClass('find-me'))
})

test('renders master course lock icon if isMasterCourse', () => {
  const props = makeProps()
  props.masterCourse = {
    courseData: { isMasterCourse: true, masterCourse: { id: '1' } },
    getLockOptions: () => ({
      model: new AnnouncementModel(props.announcement),
      unlockedText: '',
      lockedText: '',
      course_id: '3',
      content_id: '5',
      content_type: 'announcement',
    }),
  }
  const tree = mount(<CourseItemRow {...props} />)
  ok(tree.instance().masterCourseLock)
})

test('renders peer review icon if peer review', () => {
  const props = makeProps()
  props.peerReview = true
  const tree = mount(<CourseItemRow {...props} />)
  const peerReviewComponent = tree.find('.ic-item-row__peer_review')
  ok(peerReviewComponent.exists())
})

test('renders master course lock icon if isChildCourse', () => {
  const props = makeProps()
  props.masterCourse = {
    courseData: { isChildCourse: true, masterCourse: { id: '1' } },
    getLockOptions: () => ({
      model: new AnnouncementModel(props.announcement),
      unlockedText: '',
      lockedText: '',
      course_id: '3',
      content_id: '5',
      content_type: 'announcement',
    }),
  }
  const tree = mount(<CourseItemRow {...props} />)
  ok(tree.instance().masterCourseLock)
})

test('renders no master course lock icon if no master course data provided', () => {
  const props = makeProps()
  props.masterCourse = {
    courseData: {},
    getLockOptions: () => ({}),
  }
  const tree = mount(<CourseItemRow {...props} />)
  notOk(tree.instance().masterCourseLock)
})

test('renders no master course lock icon if isMasterCourse and isChildCourse are false', () => {
  const props = makeProps()
  props.masterCourse = {
    courseData: { isMasterCourse: false, isChildCourse: false },
    getLockOptions: () => ({}),
  }
  const tree = mount(<CourseItemRow {...props} />)
  notOk(tree.instance().masterCourseLock)
})

test('calls onSelectChanged when checkbox is toggled', () => {
  const onSelectedChanged = sinon.spy()
  const tree = mount(<CourseItemRow {...makeProps({ onSelectedChanged, selectable: true })} />)
  const instance = tree.instance()
  instance.onSelectChanged({ target: { checked: true } })
  ok(onSelectedChanged.calledWithMatch({ id: '5', selected: true }))
})

test('renders no manage menu when showManageMenu is false', () => {
  const tree = mount(<CourseItemRow {...makeProps({ showManageMenu: false })} />)
  const menu = tree.find('.ic-item-row__manage-menu')
  notOk(menu.exists())
})

test('renders manage menu when showManageMenu is true and manageMenuOptions is not empty', () => {
  const tree = mount(<CourseItemRow {...makeProps({ showManageMenu: true, manageMenuOptions: ['one', 'two'] })} />)
  const menu = tree.find('.ic-item-row__manage-menu')
  ok(menu.exists())
})

test('does not render a clickable div if the body is empty', () => {
  const tree = mount(<CourseItemRow {...makeProps({ body: null })} />)
  const contentLinks = tree.find('.ic-item-row__content-link')
  strictEqual(contentLinks.length, 1)
})
