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
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import SubmissionCommentUpdateForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentUpdateForm';

QUnit.module('SubmissionCommentUpdateForm', function (hooks) {
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<SubmissionCommentUpdateForm {...props} />);
  }

  function cancelButton () {
    return wrapper.find('button').at(0);
  }

  function submitButton () {
    return wrapper.find('button').at(1);
  }

  hooks.beforeEach(function () {
    props = {
      cancelCommenting () {},
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

  test('"Submit" button is present even if there is no text entered in the comment area', function () {
    props.comment = '';
    wrapper = mountComponent();
    strictEqual(submitButton().length, 1);
  });

  test('"Cancel" button is present even if there is no text entered in the comment area', function () {
    props.comment = '';
    wrapper = mountComponent();
    strictEqual(cancelButton().length, 1);
  });

  test('"Submit" button is present if the content is all spaces', function () {
    props.comment = '    ';
    wrapper = mountComponent();
    strictEqual(submitButton().length, 1);
  });

  test('"Cancel" button is present if the content is all spaces', function () {
    props.comment = '    ';
    wrapper = mountComponent();
    strictEqual(cancelButton().length, 1);
  });

  test('"Submit" button is present if there is text entered in the comment area', function () {
    wrapper = mountComponent();
    strictEqual(submitButton().length, 1);
  });

  test('"Cancel" button is present if there is text entered in the comment area', function () {
    wrapper = mountComponent();
    strictEqual(cancelButton().length, 1);
  });

  test('"Submit" button is disabled if the current comment is the same as the comment prop passed in', function () {
    wrapper = mountComponent();
    strictEqual(submitButton().prop('aria-disabled'), 'true');
  });

  test('"Cancel" button is enabled if the current comment is the same as the comment prop passed in', function () {
    wrapper = mountComponent();
    strictEqual(cancelButton().prop('aria-disabled'), null);
  });

  test('"Submit" button is disabled if the current comment after trimming is the same as the comment prop passed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '    A comment    ' } });
    strictEqual(submitButton().prop('aria-disabled'), 'true');
  });

  test('"Cancel" button is enabled if the current comment after trimming is the same as the comment prop passed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '    A comment    ' } });
    strictEqual(cancelButton().prop('aria-disabled'), null);
  });

  test('"Submit" button is disabled if the all the content in the comment is removed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '' } });
    strictEqual(submitButton().prop('aria-disabled'), 'true');
  });

  test('"Cancel" button is enabled if the all the content in the comment is removed', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '' } });
    strictEqual(cancelButton().prop('aria-disabled'), null);
  });

  test('"Submit" button is disabled if the all the content in the comment is removed except for spaces', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '     ' } });
    strictEqual(submitButton().prop('aria-disabled'), 'true');
  });

  test('"Cancel" button is enabled if the all the content in the comment is removed except for spaces', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: '     ' } });
    strictEqual(cancelButton().prop('aria-disabled'), null);
  });

  test('"Submit" button is disabled while processing', function () {
    props.processing = true;
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(submitButton().prop('aria-disabled'), 'true');
  });

  test('"Cancel" button is disabled while processing', function () {
    props.processing = true;
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(cancelButton().prop('aria-disabled'), 'true');
  });

  test('"Submit" button is enabled if the comment is changed and is not empty', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(submitButton().prop('aria-disabled'), null);
  });

  test('"Cancel" button is enabled if the comment is changed and is not empty', function () {
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    strictEqual(cancelButton().prop('aria-disabled'), null);
  });

  test('"Submit" button has the text "Submit"', function () {
    wrapper = mountComponent();
    strictEqual(submitButton().text(), 'Submit');
  });

  test('"Cancel" button has the text "Cancel"', function () {
    wrapper = mountComponent();
    strictEqual(cancelButton().text(), 'Cancel');
  });

  test('"Submit" button label reads "Update Comment"', function () {
    wrapper = mountComponent();
    strictEqual(submitButton().prop('label'), 'Update Comment');
  });

  test('"Cancel" button label reads "Cancel Updating Comment"', function () {
    wrapper = mountComponent();
    strictEqual(cancelButton().prop('label'), 'Cancel Updating Comment');
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
    submitButton().simulate('click', event);
    strictEqual(event.preventDefault.callCount, 1);
  });

  test('clicking the "Submit" button calls setProcessing', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    submitButton().simulate('click');
    strictEqual(props.setProcessing.callCount, 1);
  });

  test('clicking the "Submit" button calls setProcessing with true', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    props.setProcessing = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    submitButton().simulate('click');
    strictEqual(props.setProcessing.firstCall.args[0], true);
  });

  test('updateSubmissionComment is called when the comment is valid and the button is clicked', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    submitButton().simulate('click');
    strictEqual(props.updateSubmissionComment.callCount, 1);
  });

  test('passes the comment id when calling updateSubmissionComment', function () {
    props.updateSubmissionComment = sinon.stub().resolves();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    submitButton().simulate('click');
    strictEqual(props.updateSubmissionComment.firstCall.args[1], '23');
  });

  test('clicking the "Cancel" button triggers cancelCommenting', function () {
    props.cancelCommenting = sinon.stub();
    wrapper = mountComponent();
    wrapper.find('textarea').simulate('change', { target: { value: 'A changed comment' } });
    cancelButton().simulate('click');
    strictEqual(props.cancelCommenting.callCount, 1);
  });
});
