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
import { mount, ReactWrapper } from 'enzyme';
import SubmissionCommentCreateForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentCreateForm';
import SubmissionTray from 'jsx/gradezilla/default_gradebook/components/SubmissionTray';

QUnit.module('SubmissionTray', function (hooks) {
  let clock;
  let content;
  let wrapper;

  hooks.beforeEach(function () {
    const applicationElement = document.createElement('div');
    applicationElement.id = 'application';
    document.getElementById('fixtures').appendChild(applicationElement);
    clock = sinon.useFakeTimers();
  });

  hooks.afterEach(function () {
    wrapper.unmount();
    document.getElementById('fixtures').innerHTML = '';
    clock.restore();
  });

  function mountComponent (props) {
    const defaultProps = {
      contentRef (ref) {
        content = ref;
      },
      colors: {
        late: '#FEF7E5',
        missing: '#F99',
        excused: '#E5F3FC'
      },
      editedCommentId: null,
      editSubmissionComment () {},
      locale: 'en',
      onRequestClose () {},
      onClose () {},
      showContentComingSoon: false,
      submissionUpdating: false,
      isOpen: true,
      courseId: '1',
      currentUserId: '2',
      speedGraderEnabled: true,
      student: {
        id: '27',
        name: 'Jane Doe',
        gradesUrl: 'http://gradeUrl/'
      },
      submission: {
        grade: '100%',
        excused: false,
        late: false,
        missing: false,
        pointsDeducted: 3,
        secondsLate: 0,
        assignmentId: '30'
      },
      updateSubmission () {},
      updateSubmissionComment () {},
      assignment: {
        name: 'Book Report',
        htmlUrl: 'http://htmlUrl/',
        muted: false,
        published: true
      },
      isFirstAssignment: true,
      isLastAssignment: true,
      selectNextAssignment () {},
      selectPreviousAssignment () {},
      isFirstStudent: true,
      isLastStudent: true,
      selectNextStudent () {},
      selectPreviousStudent () {},
      submissionCommentsLoaded: true,
      createSubmissionComment () {},
      deleteSubmissionComment () {},
      processing: false,
      setProcessing () {},
      submissionComments: [],
      isInOtherGradingPeriod: false,
      isInClosedGradingPeriod: false,
      isInNoGradingPeriod: false
    };
    wrapper = mount(<SubmissionTray {...defaultProps} {...props} />);
    clock.tick(50); // wait for Tray to transition open
  }

  function avatarDiv () {
    return document.querySelector('#SubmissionTray__Avatar');
  }

  function studentNameDiv () {
    return document.querySelector('#student-carousel a');
  }

  function wrapContent () {
    return new ReactWrapper(content, wrapper.node);
  }

  function radioInputGroupDiv () {
    return document.querySelector('#SubmissionTray__RadioInputGroup');
  }

  test('shows "Content Coming Soon" content if showContentComingSoon is true', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true });
    server.respondWith('GET', /^\/images\/.*\.svg$/, [
      200, { 'Content-Type': 'img/svg+xml' }, '{}'
    ]);
    mountComponent({ showContentComingSoon: true });
    ok(document.querySelector('.ComingSoonContent__Container'));
    server.restore();
  });

  test('shows SpeedGrader link if enabled', function () {
    const speedGraderUrl = '/courses/1/gradebook/speed_grader?assignment_id=30#%7B%22student_id%22%3A27%7D';
    mountComponent();
    const speedGraderLink = document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]').getAttribute('href');
    strictEqual(speedGraderLink, speedGraderUrl);
  });

  test('does not show SpeedGrader link if disabled', function () {
    mountComponent({speedGraderEnabled: false});
    const speedGraderLink = document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]');
    notOk(speedGraderLink);
  });

  test('shows avatar if showContentComingSoon is false and avatar is not null', function () {
    const avatarUrl = 'http://bob_is_not_a_domain/me.jpg?filter=make_me_pretty';
    const gradesUrl = 'http://gradesUrl/';
    mountComponent({ student: { id: '27', name: 'Bob', avatarUrl, gradesUrl } });
    const avatarBackground = avatarDiv().firstChild.style.getPropertyValue('background-image');
    strictEqual(avatarBackground, `url("${avatarUrl}")`);
  });

  test('shows no avatar if showContentComingSoon is false and avatar is null', function () {
    mountComponent({ student: { id: '27', name: 'Joe', gradesUrl: 'http://gradesUrl/' } });
    notOk(avatarDiv());
  });

  test('shows the state of the submission', function () {
    mountComponent();

    strictEqual(wrapContent().find('SubmissionStatus').length, 1);
  });

  test('passes along assignment prop to SubmissionStatus', function () {
    mountComponent();
    const submissionStatusProps = wrapContent().find('SubmissionStatus').at(0).props();

    deepEqual(submissionStatusProps.assignment, wrapper.props().assignment);
  });

  test('passes along submission prop to SubmissionStatus', function () {
    mountComponent();
    const submissionStatusProps = wrapContent().find('SubmissionStatus').at(0).props();

    deepEqual(submissionStatusProps.submission, wrapper.props().submission);
  });

  test('passes along isInOtherGradingPeriod prop to SubmissionStatus', function () {
    mountComponent();
    const isInOtherGradingPeriod = wrapContent().find('SubmissionStatus').at(0).prop('isInOtherGradingPeriod');

    deepEqual(isInOtherGradingPeriod, wrapper.prop('isInOtherGradingPeriod'));
  });

  test('passes along isInClosedGradingPeriod prop to SubmissionStatus', function () {
    mountComponent();
    const isInClosedGradingPeriod = wrapContent().find('SubmissionStatus').at(0).prop('isInClosedGradingPeriod');

    deepEqual(isInClosedGradingPeriod, wrapper.prop('isInClosedGradingPeriod'));
  });

  test('passes along isInNoGradingPeriod prop to SubmissionStatus', function () {
    mountComponent();
    const isInNoGradingPeriod = wrapContent().find('SubmissionStatus').at(0).prop('isInNoGradingPeriod');

    deepEqual(isInNoGradingPeriod, wrapper.prop('isInNoGradingPeriod'));
  });

  test('shows name if showContentComingSoon is false', function () {
    mountComponent({ student: { id: '27', name: 'Sara', gradesUrl: 'http://gradeUrl/' } });
    strictEqual(studentNameDiv().innerHTML, 'Sara');
  });

  test('shows the late policy grade when points have been deducted', function () {
    mountComponent();
    strictEqual(wrapContent().find('LatePolicyGrade').length, 1);
  });

  test('uses the submission to show the late policy grade', function () {
    mountComponent();
    const latePolicyGrade = wrapContent().find('LatePolicyGrade').at(0);
    equal(latePolicyGrade.prop('submission').grade, '100%');
    strictEqual(latePolicyGrade.prop('submission').pointsDeducted, 3);
  });

  test('does not show the late policy grade when zero points have been deducted', function () {
    mountComponent({ submission: { excused: false, late: true, missing: false, pointsDeducted: 0, secondsLate: 0, assignmentId: '30' } });
    strictEqual(wrapContent().find('LatePolicyGrade').length, 0);
  });

  test('does not show the late policy grade when points deducted is null', function () {
    mountComponent({ submission: { excused: false, late: true, missing: false, pointsDeducted: null, secondsLate: 0, assignmentId: '30' } });
    strictEqual(wrapContent().find('LatePolicyGrade').length, 0);
  });

  test('shows a radio input group if showContentComingSoon is false', function () {
    mountComponent();
    ok(radioInputGroupDiv());
  });

  test('does not show a radio input group if showContentComingSoon is true', function () {
    const server = sinon.fakeServer.create({ respondImmediately: true });
    server.respondWith('GET', /^\/images\/.*\.svg$/, [
      200, { 'Content-Type': 'img/svg+xml' }, '{}'
    ]);
    mountComponent({ showContentComingSoon: true });
    notOk(radioInputGroupDiv());
    server.restore();
  });

  test('shows assignment carousel', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel').length, 1);
  });

  test('shows assignment carousel containing given assignment name', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel').text(), 'Book Report');
  });

  test('shows assignment carousel with no left arrow when isFirstAssignment and isLastAssignment are true', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with no right arrow when isFirstAssignment and isLastAssignment are true', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with left arrow when isFirstAssignment and isLastAssignment are false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with right arrow when isFirstAssignment and isLastAssignment are false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with left arrow when isFirstAssignment is false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: true
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with no right arrow when isFirstAssignment is false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: true
    });
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with right arrow when isLastAssignment is false', function () {
    mountComponent({
      isFirstAssignment: true,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with no left arrow when isLastAssignment is false', function () {
    mountComponent({
      isFirstAssignment: true,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel', function () {
    mountComponent();
    strictEqual(wrapContent().find('#student-carousel').length, 1);
  });

  test('shows student carousel containing given student name', function () {
    mountComponent();
    strictEqual(wrapContent().find('#student-carousel').text(), 'Jane Doe');
  });

  test('shows student carousel with no left arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent();
    strictEqual(wrapContent().find('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel with no right arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent();
    strictEqual(wrapContent().find('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel with left arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false
    });
    strictEqual(wrapContent().find('#student-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows student carousel with right arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false
    });
    strictEqual(wrapContent().find('#student-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows student carousel with left arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true
    });
    strictEqual(wrapContent().find('#student-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows student carousel with no right arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true
    });
    strictEqual(wrapContent().find('#student-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows student carousel with right arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false
    });
    strictEqual(wrapContent().find('#student-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows student carousel with no left arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false
    });
    strictEqual(wrapContent().find('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('does not add padding to the carousel container when an avatar is present', function () {
    const student = {
      id: '27',
      name: 'Jane Doe',
      gradesUrl: 'http://gradeUrl/',
      avatarUrl: 'http://avatarUrl/'
    };

    mountComponent({
      student,
      isFirstStudent: false,
      isLastStudent: false
    });

    strictEqual(wrapContent().find('#SubmissionTray__Content').find('Container').at(0).prop('padding'), '0 0 0 0');
  });

  test('adds padding to the carousel container when no avatar is present', function () {
    const student = {
      id: '27',
      name: 'Jane Doe',
      gradesUrl: 'http://gradeUrl/',
    };

    mountComponent({
      student,
      isFirstStudent: false,
      isLastStudent: false
    });

    strictEqual(wrapContent().find('#SubmissionTray__Content').find('Container').at(0).prop('padding'), 'small 0 0 0');
  });

  test('renders the new comment form if the editedCommentId is null', function () {
    mountComponent();
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 1);
  });

  test('does not render the new comment form if the editedCommentId is not null', function () {
    mountComponent({ editedCommentId: '5' });
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 0);
  });
});
