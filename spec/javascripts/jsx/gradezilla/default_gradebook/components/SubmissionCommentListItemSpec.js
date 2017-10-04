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

import React from 'react';
import { mount } from 'enzyme';
import SubmissionCommentListItem from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentListItem';

QUnit.module('SubmissionCommentListItem', {
  props () {
    return {
      id: '1',
      author: 'An Author',
      authorAvatarUrl: '//authorAvatarUrl/',
      authorUrl: '//authorUrl/',
      createdAt: new Date(),
      comment: 'a comment',
      last: false,
      deleteSubmissionComment () {}
    };
  },
  setup () {
    this.wrapper = mount(<SubmissionCommentListItem { ...this.props()} />);
  },
  teardown () {
    this.wrapper.unmount();
  }
});

test('it has an Avatar', function () {
  strictEqual(this.wrapper.find('Avatar').length, 1);
});

test('the avatar names the author', function () {
  strictEqual(this.wrapper.find('Avatar').prop('name'), this.props().author);
});

test('the avatar has alt text', function () {
  const expectedAltText = `Avatar for ${this.props().author}`;
  strictEqual(this.wrapper.find('Avatar').prop('alt'), expectedAltText);
});

test("the avatar soruce is the author's avatar url", function () {
  strictEqual(this.wrapper.find('Avatar').prop('src'), this.props().authorAvatarUrl);
});

test("links the avatar to the author's url", function () {
  strictEqual(this.wrapper.find('Link').at(0).prop('href'), this.props().authorUrl);
});

test("links the author's name to the author's url", function () {
  strictEqual(this.wrapper.find('Link').at(1).prop('href'), this.props().authorUrl);
});

test("include the author's names", function () {
  ok(this.wrapper.text().includes(this.props().author));
});

test("trucates long author names", function () {
  ok(this.wrapper.text().includes(this.props().author));
});

test("include the comment", function () {
  ok(this.wrapper.text().includes(this.props().comment));
});

test("the comment timestamp includes the year if it does not match the current year", function () {
  this.wrapper.setProps({ createdAt: new Date('Jan 8, 2003') });
  const dateText = this.wrapper.find('Typography').at(1).text();
  strictEqual(/, 2003/.test(dateText), true);
});

test("the comment timestamp excludes the year if it matches the current year", function () {
  const dateText = this.wrapper.find('Typography').at(1).text();
  const year = this.wrapper.instance().props.createdAt.getFullYear();
  const includesYear = new RegExp(`, ${year}`);
  strictEqual(includesYear.test(dateText), false);
});

QUnit.module('SubmissionCommentListItem#deleteSubmissionComment', {
  defaultProps () {
    return {
      id: '1',
      author: 'An Author',
      authorAvatarUrl: '//authorAvatarUrl/',
      authorUrl: '//authorUrl/',
      createdAt: new Date(),
      comment: 'a comment',
      last: false,
      deleteSubmissionComment () {}
    };
  },
  mountComponent(props) {
    this.wrapper = mount(<SubmissionCommentListItem {...this.defaultProps()} {...props} />);
  },

  teardown () {
    this.wrapper.unmount();
  }
});

test('clicking the trash icon calls deleteSubmissionComment', function () {
  const confirmStub = this.stub(window, 'confirm').returns(true);
  const deleteSubmissionComment = this.stub();
  this.mountComponent({ deleteSubmissionComment });
  this.wrapper.find('Button').simulate('click');
  strictEqual(deleteSubmissionComment.callCount, 1);
  confirmStub.restore();
});

test('clicking the trash icon calls deleteSubmissionComment with the id', function () {
  const confirmStub = this.stub(window, 'confirm').returns(true);
  const deleteSubmissionComment = this.stub();
  const id = '42';
  this.mountComponent({ id, deleteSubmissionComment });
  this.wrapper.find('Button').simulate('click');
  strictEqual(deleteSubmissionComment.firstCall.args[0], id);
  confirmStub.restore();
});

test('clicking the trash icon prompts for confirmation', function () {
  const confirmStub = this.stub(window, 'confirm').returns(true);
  this.mountComponent();
  this.wrapper.find('Button').simulate('click');
  strictEqual(window.confirm.callCount, 1);
  confirmStub.restore();
});

test('confirm is called with a message', function () {
  const confirmStub = this.stub(window, 'confirm').returns(true);
  this.mountComponent();
  this.wrapper.find('Button').simulate('click');
  strictEqual(window.confirm.args[0][0], 'Are you sure you want to delete this comment?');
  confirmStub.restore();
});

test('when confirm is false, deleteSubmissionComment is not called', function () {
  const confirmStub = this.stub(window, 'confirm').returns(false);
  const deleteSubmissionComment = this.stub();
  this.mountComponent({ deleteSubmissionComment });
  this.wrapper.find('Button').simulate('click');
  strictEqual(deleteSubmissionComment.callCount, 0);
  confirmStub.restore();
});
