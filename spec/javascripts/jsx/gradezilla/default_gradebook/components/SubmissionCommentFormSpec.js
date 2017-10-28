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
import I18n from 'i18n!gradebook';
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import SubmissionCommentForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentForm';

QUnit.module('SubmissionCommentForm', function (hooks) {
  let wrapper;
  let setProcessing = () => {};
  let createSubmissionComment;
  let processing;

  function mountComponent (props) {
    return mount(
      <SubmissionCommentForm
        createSubmissionComment={createSubmissionComment}
        updateSubmissionComments={() => {}}
        setProcessing={setProcessing}
        processing={processing}
        {...props}
      />
    );
  }

  hooks.beforeEach(function () {
    createSubmissionComment = sinon.stub().resolves();
    processing = false;
  });

  hooks.afterEach(function () {
    wrapper.unmount();
    createSubmissionComment = null;
    processing = null;
  });

  test('Button is not disabled', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').props().disabled, false);
  });

  test('Button has the text "Post"', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').text(), 'Post');
  });

  test('TextArea is empty', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('TextArea').prop('value'), '');
  });

  test('TextArea has a placeholder message', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('TextArea').prop('placeholder'), 'Leave a comment');
  });

  test('TextArea has a label', function () {
    wrapper = mountComponent();
    ok(wrapper.find('label').contains(<ScreenReaderContent>Leave a comment</ScreenReaderContent>));
  });

  test('TextArea does not have an error message', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('TextArea').prop('messages').length, 0);
  });

  test('TextArea does not display an error when a message is present', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'a message' } });
    strictEqual(wrapper.find('TextArea').prop('messages').length, 0);
  });

  test('TextArea displays an error when blank message is present', function () {
    setProcessing = value => {
      processing = value
    };
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: ' ' } });
    wrapper.find('button').simulate('click');
    const messages = wrapper.find('TextArea').prop('messages').filter(message =>
      message.text === I18n.t('No message present')
    );
    strictEqual(messages.length, 1)
  });

  test('handlePostComment prevents default', function () {
    wrapper = mountComponent();
    const event = {
      preventDefault: sinon.stub(),
    };
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(event.preventDefault.callCount, 1);
  });

  test('handlePostComment disables Button', function () {
    setProcessing = value => {
      processing = value
      wrapper = mountComponent();
    };
    wrapper = mountComponent();

    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click');
    strictEqual(wrapper.find('Button').prop('disabled'), true);
  });

  test('handlePostComment calls createSubmissionComment when comment is valid', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click');
    strictEqual(createSubmissionComment.callCount, 1);
  });

  test('handlePostComment displays a warning when comment is invalid', function () {
    setProcessing = value => {
      processing = value
    };
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: ' ' } });
    wrapper.find('button').simulate('click');
    const messages = wrapper.find('TextArea').prop('messages').filter(message =>
      message.text === I18n.t('No message present')
    );
    strictEqual(messages.length, 1);
  });

  test('handlePostComment reenables the button when comment is invalid', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: ' ' } });
    wrapper.find('button').simulate('click');
    strictEqual(wrapper.find('Button').prop('disabled'), false);
  });

  test('handlePostComment clears the comment field', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'a message' } });
    wrapper.find('button').simulate('click');
    strictEqual(wrapper.find('textarea').prop('value'), '');
  });
});
