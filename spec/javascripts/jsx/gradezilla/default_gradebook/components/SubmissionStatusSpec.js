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

import React from 'react';
import { mount } from 'enzyme';
import SubmissionStatus from 'jsx/gradezilla/default_gradebook/components/SubmissionStatus';

QUnit.module('SubmissionStatus - Pills', function (hooks) {
  let props;
  let wrapper;

  hooks.beforeEach(() => {
    props = {
      assignment: {
        muted: false,
        published: true
      },
      submission: {
        excused: false,
        late: false,
        missing: false,
        secondsLate: 0,
        assignmentId: '1'
      },
      isInOtherGradingPeriod: false,
      isInClosedGradingPeriod: false,
      isInNoGradingPeriod: false
    };
  });

  hooks.afterEach(() => {
    wrapper.unmount();
  });

  function mountComponent() {
    return mount(<SubmissionStatus {...props} />);
  }

  test('shows the "Muted" pill when the assignment is muted', function () {
    props.assignment.muted = true
    wrapper = mountComponent();
    const mutedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Muted');

    strictEqual(mutedPills.length, 1);
  });

  test('does not show the "Muted" pill when the assignment is not muted', function () {
    props.assignment.muted = false
    wrapper = mountComponent();
    const mutedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Muted');

    strictEqual(mutedPills.length, 0);
  });

  test('shows the "Unpublished" pill when the assignment is unpublished', function () {
    props.assignment.published = false;
    wrapper = mountComponent();
    const unpublishedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Unpublished');

    strictEqual(unpublishedPills.length, 1);
  });

  test('does not show the "Unpublished" pill when the assignment is published', function () {
    props.assignment.published = true;
    wrapper = mountComponent();
    const unpublishedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Unpublished');

    strictEqual(unpublishedPills.length, 0);
  });

  test('shows the "Dropped" pill when the submission is dropped', function () {
    props.submission.drop = true;
    wrapper = mountComponent();
    const droppedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Dropped');

    strictEqual(droppedPills.length, 1);
  });

  test('does not show the "Dropped" pill when the submission is not dropped', function () {
    props.submission.drop = false;
    wrapper = mountComponent();
    const droppedPills = wrapper.find('Pill').nodes.filter(node => node.props.text === 'Dropped');

    strictEqual(droppedPills.length, 0);
  });
});

QUnit.module('SubmissionStatus - Grading Period Warnings', function (hooks) {
  let props;
  let wrapper;

  hooks.beforeEach(() => {
    props = {
      assignment: {
        muted: false,
        published: true
      },
      submission: {
        excused: false,
        late: false,
        missing: false,
        secondsLate: 0,
        assignmentId: '1'
      },
      isInOtherGradingPeriod: false,
      isInClosedGradingPeriod: false,
      isInNoGradingPeriod: false
    };
  });

  hooks.afterEach(() => {
    wrapper.unmount();
  });

  function mountComponent() {
    return mount(<SubmissionStatus {...props} />);
  }

  test('when isInNoGradingPeriod is true, warns about submission not being in any grading period', function () {
    props.isInNoGradingPeriod = true;
    wrapper = mountComponent();
    const message = 'This submission is not in any grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 1);
  });

  test('when isInNoGradingPeriod is false, does not warn about submission not being in any grading period', function () {
    props.isInNoGradingPeriod = false;
    wrapper = mountComponent();
    const message = 'This submission is not in any grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 0);
  });

  test('when isInClosedGradingPeriod is true, warns about submission not being in a closed grading period', function () {
    props.isInClosedGradingPeriod = true;
    wrapper = mountComponent();
    const message = 'This submission is in a closed grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 1);
  });

  test('when isInClosedGradingPeriod is false, does not warn about submission not being in a closed grading period', function () {
    props.isInClosedGradingPeriod = false;
    wrapper = mountComponent();
    const message = 'This submission is in a closed grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 0);
  });

  test('when isInOtherGradingPeriod is true, warns about submission not being in another grading period', function () {
    props.isInOtherGradingPeriod = true;
    wrapper = mountComponent();
    const message = 'This submission is in another grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 1);
  });

  test('when isInOtherGradingPeriod is false, does not warn about submission not being in another grading period', function () {
    props.isInOtherGradingPeriod = false;
    wrapper = mountComponent();
    const message = 'This submission is in another grading period.';
    const messageIcon = wrapper.find('IconWarningLine').nodes.filter(node => node.props.title === message);

    strictEqual(messageIcon.length, 0);
  });
});
