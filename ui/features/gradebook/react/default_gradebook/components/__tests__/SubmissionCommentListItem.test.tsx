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
import {fireEvent, render, screen} from '@testing-library/react'
import SubmissionCommentListItem from '../SubmissionCommentListItem'
import SubmissionCommentUpdateForm from '../SubmissionCommentUpdateForm'

describe('SubmissionCommentListItem', () => {
  let wrapper: any

  const defaultProps = () => {
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
  }

  const mountComponent = (props?: any) => {
    return render(<SubmissionCommentListItem {...defaultProps()} {...props} />)
  }

  afterEach(() => {
    jest.clearAllMocks()
  })

  test('it has an Avatar with the proper properties', function () {
    wrapper = mountComponent()
    const avatar = wrapper.container.querySelector('[src="//authorAvatarUrl/"]')
    expect(avatar).toBeInTheDocument()
    expect(avatar.getAttribute('name')).toEqual('An Author')
    expect(avatar.getAttribute('alt')).toEqual('Avatar for An Author')
  })

  test("links the avatar to the author's url", function () {
    wrapper = mountComponent()
    const anchorLink = wrapper.container.querySelectorAll('a')[0]
    expect(anchorLink.getAttribute('href')).toEqual('//authorUrl/')
  })

  test("links the author's name to the author's url", function () {
    wrapper = mountComponent()
    const authorLink = wrapper.container.querySelectorAll('a')[1]
    expect(authorLink.getAttribute('href')).toEqual('//authorUrl/')
  })

  test("include the author's names", function () {
    mountComponent()
    expect(screen.getByText('An Author')).toBeInTheDocument()
  })

  test('include the comment', function () {
    mountComponent()
    expect(screen.getByText('a comment')).toBeInTheDocument()
  })

  test('clicking the edit icon calls editSubmissionComment with the comment id', function () {
    const editSubmissionComment = jest.fn()
    wrapper = mountComponent({editSubmissionComment})
    fireEvent.click(wrapper.container.querySelector('svg[name="IconEdit"]'))
    expect(editSubmissionComment).toHaveBeenCalledTimes(1)
    expect(editSubmissionComment).toHaveBeenLastCalledWith('1')
  })

  test('renders a SubmissionCommentUpdateForm if editing', function () {
    const updateForm = (SubmissionCommentUpdateForm.prototype.componentDidMount = jest.fn())
    wrapper = mountComponent({editing: true})
    expect(updateForm).toHaveBeenCalledTimes(1)
  })

  test('does not render a SubmissionCommentUpdateForm if not editing', function () {
    const updateForm = (SubmissionCommentUpdateForm.prototype.componentDidMount = jest.fn())
    wrapper = mountComponent()
    expect(updateForm).toHaveBeenCalledTimes(0)
  })

  test('renders an edit icon if the current user is the author', function () {
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('svg[name="IconEdit"]')).toBeInTheDocument()
  })

  test('does not render an edit icon if the current user is not the author', function () {
    wrapper = mountComponent({currentUserIsAuthor: false})
    expect(wrapper.container.querySelector('svg[name="IconEdit"]')).not.toBeInTheDocument()
  })

  test('focuses on the edit icon if the component is updated to no longer be editin', function () {
    wrapper = mountComponent({editing: true})
    wrapper.rerender(<SubmissionCommentListItem {...defaultProps()} editing={false} />)
    expect(wrapper.container.querySelector('button').matches(':focus')).toBe(true)
  })

  test('the comment timestamp includes the year if it does not match the current year', function () {
    wrapper = mountComponent({createdAt: new Date('Jan 8, 2003')})
    expect(screen.getByText('Jan 8, 2003', {exact: false})).toBeInTheDocument()
    expect(screen.queryByText('Edited', {exact: false})).not.toBeInTheDocument() // no edited_at, no edited text
  })

  test('the comment timestamp excludes the year if it matches the current year', function () {
    const current_year = new Date().getFullYear().toString()
    wrapper = mountComponent({createdAt: new Date(`Jan 8, ${current_year}`)})
    expect(screen.getByText('Jan 8', {exact: false}).textContent).not.toContain(current_year)
  })

  test('uses the edited_at (with "Edited" text) for the timestamp, if one exists', function () {
    wrapper = mountComponent({
      createdAt: new Date('Jan 8, 2003'),
      editedAt: new Date('Feb 12, 2003'),
    })
    expect(screen.getByText('(Edited) Feb 12, 2003', {exact: false})).toBeInTheDocument()
  })

  describe('SubmissionCommentListItem#deleteSubmissionComment', () => {
    const deleteSubmissionDefaultProps = () => {
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
    }
    const deleteSubmissionMountComponent = (props?: any) => {
      wrapper = render(<SubmissionCommentListItem {...deleteSubmissionDefaultProps()} {...props} />)
    }

    test('clicking the trash icon calls deleteSubmissionComment', function () {
      const confirmStub = jest.spyOn(window, 'confirm').mockReturnValue(true)
      const deleteSubmissionComment = jest.fn()
      deleteSubmissionMountComponent({id: '42', deleteSubmissionComment})
      fireEvent.click(wrapper.container.querySelector('svg[name="IconTrash"]'))
      expect(confirmStub).toHaveBeenCalledTimes(1)
      expect(confirmStub).toHaveBeenCalledWith('Are you sure you want to delete this comment?')
      expect(deleteSubmissionComment).toHaveBeenCalledTimes(1)
      expect(deleteSubmissionComment).toHaveBeenCalledWith('42')
    })

    test('when confirm is false, deleteSubmissionComment is not called', function () {
      jest.spyOn(window, 'confirm').mockReturnValue(false)
      const deleteSubmissionComment = jest.fn()
      deleteSubmissionMountComponent({deleteSubmissionComment})
      fireEvent.click(wrapper.container.querySelector('svg[name="IconTrash"]'))
      expect(deleteSubmissionComment).toHaveBeenCalledTimes(0)
    })
  })
})
