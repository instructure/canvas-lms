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
import SubmissionCommentCreateForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentCreateForm';

QUnit.module('SubmissionCommentCreateForm', function (hooks) {
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<SubmissionCommentCreateForm {...props} />);
  }

  hooks.beforeEach(function () {
    props = {
      createSubmissionComment () {},
      processing: false,
      setProcessing () {}
    };
  });

  hooks.afterEach(function () {
    wrapper.unmount();
  });

  test('Button is not present if there is no text entered in the comment area', function () {
    wrapper = mountComponent();
    strictEqual(wrapper.find('Button').length, 0);
  });

  test('Button is not present if the content is all spaces', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '   ' } });
    strictEqual(wrapper.find('Button').length, 0);
  });

  test('Button is present if there is text entered in the comment area', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    strictEqual(wrapper.find('Button').length, 1);
  });

  test('Button is not disabled', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    strictEqual(wrapper.find('Button').props().disabled, false);
  });

  test('Button has the text "Submit"', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    strictEqual(wrapper.find('Button').text(), 'Submit');
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

  test('the default action is prevented when the button is clicked', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    const event = {
      preventDefault: sinon.stub(),
    };
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(event.preventDefault.callCount, 1);
  });

  test('focuses on the textarea after a successful comment post', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    const focusTextArea = sinon.stub(wrapper.instance().textarea, 'focus');
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(focusTextArea.callCount, 1);
  });

  test('Button is disabled while processing', function () {
    props.processing = true;
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    strictEqual(wrapper.find('Button').prop('disabled'), true);
  });

  test('Button label reads "Submit Comment"', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    strictEqual(wrapper.find('Button').prop('label'), 'Submit Comment');
  });

  test('clicking the Button calls setProcessing', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(props.setProcessing.callCount, 1);
  });

  test('clicking the Button calls setProcessing with true', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click', event);
    strictEqual(props.setProcessing.firstCall.args[0], true);
  });

  test('createSubmissionComment is called when the comment is valid and the button is clicked', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'some message' } });
    wrapper.find('button').simulate('click');
    strictEqual(props.createSubmissionComment.callCount, 1);
  });

  test('clicking the button clears the comment field', function () {
    props.createSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'a message' } });
    wrapper.find('button').simulate('click');
    strictEqual(wrapper.find('textarea').prop('value'), '');
  });
});
