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
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent';
import SubmissionCommentUpdateForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentUpdateForm';

QUnit.module('SubmissionCommentUpdateForm', function (hooks) {
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<SubmissionCommentUpdateForm {...props} />);
  }

  hooks.beforeEach(function () {
    props = {
      comment: 'A comment',
      id: '23',
      updateSubmissionComment () {},
      processing: false,
      setProcessing () {}
    };
  });

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  test('initializes with the original comment in the textarea', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('textarea').node.innerText, 'A comment');
  });

  test('Button is present even if there is no text entered in the comment area', function () {
    props.comment = '';
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').length, 1);
  });

  test('Button is present if the content is all spaces', function () {
    props.comment = '    ';
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').length, 1);
  });

  test('Button is present if there is text entered in the comment area', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').length, 1);
  });

  test('Button is disabled if the current comment is the same as the comment prop passed in', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').props().disabled, true);
  });

  test('Button is disabled if the current comment after trimming is the same as the comment prop passed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '    A comment    ' } });
    strictEqual(wrapper.find('Button').props().disabled, true);
  });

  test('Button is disabled if the all the content in the comment is removed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '' } });
    strictEqual(wrapper.find('Button').props().disabled, true);
  });

  test('Button is disabled if the all the content in the comment is removed except for spaces', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '     ' } });
    strictEqual(wrapper.find('Button').props().disabled, true);
  });

  test('Button is disabled while processing', function () {
    props.processing = true;
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(wrapper.find('Button').prop('disabled'), true);
  });

  test('Button is enabled if the comment is changed and is not empty', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(wrapper.find('Button').props().disabled, false);
  });

  test('Button has the text "Submit"', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').text(), 'Submit');
  });

  test('Button label reads "Update Comment"', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').prop('label'), 'Update Comment');
  });

  test('TextArea has a placeholder message', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('TextArea').prop('placeholder'), 'Leave a comment');
  });

  test('TextArea has a label', function () {
    wrapper = mountComponent();
    ok(wrapper.find('label').contains(<ScreenReaderContent>Leave a comment</ScreenReaderContent>));
  });

  test('focuses on the textarea when mounted', function () {
    wrapper = mountComponent();
    const textareaFocus = sinon.stub(wrapper.instance().textarea, 'focus');
    wrapper.instance().componentDidMount();
    strictEqual(textareaFocus.callCount, 1);
  });

  test('the default action is prevented when the button is clicked', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    const event = {
      preventDefault: sinon.stub(),
    };
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(event.preventDefault.callCount, 1);
  });

  test('clicking the Button calls setProcessing', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(props.setProcessing.callCount, 1);
  });

  test('clicking the Button calls setProcessing with true', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(props.setProcessing.firstCall.args[0], true);
  });

  test('updateSubmissionComment is called when the comment is valid and the button is clicked', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    wrapper.find('button').simulate('click');
    strictEqual(props.updateSubmissionComment.callCount, 1);
  });

  test('passes the comment id when calling updateSubmissionComment', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    wrapper.find('button').simulate('click');
    strictEqual(props.updateSubmissionComment.firstCall.args[1], '23');
  });
});
