/* * Copyright (C) 2017 - present Instructure, Inc.
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
import SubmissionCommentListItem from 'ui/features/gradebook/react/default_gradebook/components/SubmissionCommentListItem'
import SubmissionCommentUpdateForm from 'ui/features/gradebook/react/default_gradebook/components/SubmissionCommentUpdateForm'
import {IconTrashLine, IconEditLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'

QUnit.module('SubmissionCommentListItem', {
  defaultProps() {
    return {
      id: '1',
      author: 'An Author',
      authorAvatarUrl: '//authorAvatarUrl/',
      authorUrl: '//authorUrl/',
      cancelCommenting() {},
      createdAt: new Date(),
      editedAt: null,
      currentUserIsAuthor: true,
      comment: 'a comment',
      editing: false,
      editSubmissionComment() {},
      last: false,
      deleteSubmissionComment() {},
      updateSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  },
  mountComponent(props) {
    return mount(<SubmissionCommentListItem {...this.defaultProps()} {...props} />)
  },
  teardown() {
    this.wrapper.unmount()
  },
})

test('it has an Avatar', function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find('Avatar').length, 2)
})

test('the avatar names the author', function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find('Avatar').first().prop('name'), this.defaultProps().author)
})

test('the avatar has alt text', function () {
  this.wrapper = this.mountComponent()
  const expectedAltText = `Avatar for ${this.defaultProps().author}`
  strictEqual(this.wrapper.find('Avatar').first().prop('alt'), expectedAltText)
})

test("the avatar soruce is the author's avatar url", function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find('Avatar').first().prop('src'), this.defaultProps().authorAvatarUrl)
})

test("links the avatar to the author's url", function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find('Link').at(0).prop('href'), this.defaultProps().authorUrl)
})

test("links the author's name to the author's url", function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find('Link').at(0).prop('href'), this.defaultProps().authorUrl)
})

test("include the author's names", function () {
  this.wrapper = this.mountComponent()
  ok(this.wrapper.text().includes(this.defaultProps().author))
})

test('trucates long author names', function () {
  this.wrapper = this.mountComponent()
  ok(this.wrapper.text().includes(this.defaultProps().author))
})

test('include the comment', function () {
  this.wrapper = this.mountComponent()
  ok(this.wrapper.text().includes(this.defaultProps().comment))
})

test('clicking the edit icon calls editSubmissionComment', function () {
  const editSubmissionComment = sinon.stub()
  this.wrapper = this.mountComponent({editSubmissionComment})
  this.wrapper.find(IconEditLine).simulate('click')
  strictEqual(editSubmissionComment.callCount, 1)
})

test('clicking the edit icon calls editSubmissionComment with the comment id', function () {
  const editSubmissionComment = sinon.stub()
  this.wrapper = this.mountComponent({editSubmissionComment})
  this.wrapper.find(IconEditLine).simulate('click')
  strictEqual(editSubmissionComment.firstCall.args[0], this.defaultProps().id)
})

test('renders a SubmissionCommentUpdateForm if editing', function () {
  this.wrapper = this.mountComponent({editing: true})
  strictEqual(this.wrapper.find(SubmissionCommentUpdateForm).length, 1)
})

test('does not render a SubmissionCommentUpdateForm if not editing', function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find(SubmissionCommentUpdateForm).length, 0)
})

test('renders an edit icon if the current user is the author', function () {
  this.wrapper = this.mountComponent()
  strictEqual(this.wrapper.find(IconEditLine).length, 1)
})

test('does not render an edit icon if the current user is not the author', function () {
  this.wrapper = this.mountComponent({currentUserIsAuthor: false})
  strictEqual(this.wrapper.find(IconEditLine).length, 0)
})

test('focuses on the edit icon if the component is updated to no longer be editin', function () {
  this.wrapper = this.mountComponent({editing: true})
  const focusOnEditIcon = sinon.stub(this.wrapper.instance().editButton, 'focus')
  this.wrapper.setProps({editing: false})
  strictEqual(focusOnEditIcon.callCount, 1)
})

test('the comment timestamp includes the year if it does not match the current year', function () {
  this.wrapper = this.mountComponent({createdAt: new Date('Jan 8, 2003')})
  const dateText = this.wrapper.find('Text').at(0).text()
  strictEqual(dateText.includes(', 2003'), true)
})

test('the comment timestamp excludes the year if it matches the current year', function () {
  this.wrapper = this.mountComponent()
  const dateText = this.wrapper.find('Text').at(0).text()
  const year = this.wrapper.instance().props.createdAt.getFullYear()
  strictEqual(dateText.includes(`, ${year}`), false)
})

test('uses the edited_at for the timestamp, if one exists', function () {
  this.wrapper = this.mountComponent({
    createdAt: new Date('Jan 8, 2003'),
    editedAt: new Date('Feb 12, 2003'),
  })

  const dateText = this.wrapper.find('Text').at(0).text()
  strictEqual(dateText.includes('Feb 12'), true)
})

test("starts with the text '(Edited)' if the comment has an edited_at", function () {
  this.wrapper = this.mountComponent({
    createdAt: new Date('Jan 8, 2003'),
    editedAt: new Date('Feb 12, 2003'),
  })

  const dateText = this.wrapper.find('Text').at(0).text()
  strictEqual(/^\(Edited\)/.test(dateText), true)
})

test('uses the created_at for the timestamp if edited_at is null', function () {
  this.wrapper = this.mountComponent({createdAt: new Date('Jan 8, 2003')})

  const dateText = this.wrapper.find('Text').at(0).text()
  strictEqual(dateText.includes('Jan 8'), true)
})

test("does not start with the text '(Edited)' if the comment has a null edited_at", function () {
  this.wrapper = this.mountComponent({createdAt: new Date('Jan 8, 2003')})

  const dateText = this.wrapper.find('Text').at(0).text()
  strictEqual(/^\(Edited\)/.test(dateText), false)
})

QUnit.module('SubmissionCommentListItem#deleteSubmissionComment', {
  defaultProps() {
    return {
      id: '1',
      author: 'An Author',
      authorAvatarUrl: '//authorAvatarUrl/',
      authorUrl: '//authorUrl/',
      cancelCommenting() {},
      createdAt: new Date(),
      comment: 'a comment',
      currentUserIsAuthor: true,
      editing: false,
      editSubmissionComment() {},
      last: false,
      deleteSubmissionComment() {},
      updateSubmissionComment() {},
      processing: false,
      setProcessing() {},
    }
  },
  mountComponent(props) {
    this.wrapper = mount(<SubmissionCommentListItem {...this.defaultProps()} {...props} />)
  },

  teardown() {
    this.wrapper.unmount()
  },
})

test('clicking the trash icon calls deleteSubmissionComment', function () {
  const confirmStub = sandbox.stub(window, 'confirm').returns(true)
  const deleteSubmissionComment = sinon.stub()
  this.mountComponent({deleteSubmissionComment})
  this.wrapper.find(IconButton).at(1).simulate('click')
  strictEqual(deleteSubmissionComment.callCount, 1)
  confirmStub.restore()
})

test('clicking the trash icon calls deleteSubmissionComment with the id', function () {
  const confirmStub = sandbox.stub(window, 'confirm').returns(true)
  const deleteSubmissionComment = sinon.stub()
  const id = '42'
  this.mountComponent({id, deleteSubmissionComment})
  this.wrapper.find(IconButton).at(1).simulate('click')
  strictEqual(deleteSubmissionComment.firstCall.args[0], id)
  confirmStub.restore()
})

test('clicking the trash icon prompts for confirmation', function () {
  const confirmStub = sandbox.stub(window, 'confirm').returns(true)
  this.mountComponent()
  this.wrapper.find(IconTrashLine).simulate('click')
  strictEqual(window.confirm.callCount, 1)
  confirmStub.restore()
})

test('confirm is called with a message', function () {
  const confirmStub = sandbox.stub(window, 'confirm').returns(true)
  this.mountComponent()
  this.wrapper.find(IconTrashLine).simulate('click')
  strictEqual(window.confirm.args[0][0], 'Are you sure you want to delete this comment?')
  confirmStub.restore()
})

test('when confirm is false, deleteSubmissionComment is not called', function () {
  const confirmStub = sandbox.stub(window, 'confirm').returns(false)
  const deleteSubmissionComment = sinon.stub()
  this.mountComponent({deleteSubmissionComment})
  this.wrapper.find(IconTrashLine).simulate('click')
  strictEqual(deleteSubmissionComment.callCount, 0)
  confirmStub.restore()
})
