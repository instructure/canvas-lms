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
      locale: 'en',
      onRequestClose () {},
      onClose () {},
      showContentComingSoon: false,
      submissionUpdating: false,
      isOpen: true,
      courseId: '1',
      speedGraderEnabled: true,
      student: {
        id: '27',
        name: 'Jane Doe'
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
      assignment: {
        name: 'Book Report',
        htmlUrl: 'http://example.com/theassignment'
      },
      isFirstAssignment: true,
      isLastAssignment: true,
      selectNextAssignment: () => {},
      selectPreviousAssignment: () => {}
    };
    wrapper = mount(<SubmissionTray {...defaultProps} {...props} />);
    clock.tick(50); // wait for Tray to transition open
  }

  function avatarDiv () {
    return document.querySelector('#SubmissionTray__Avatar');
  }

  function studentNameDiv () {
    return document.querySelector('#SubmissionTray__StudentName');
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
    mountComponent({ student: { id: '27', name: 'Bob', avatarUrl } });
    const avatarBackground = avatarDiv().firstChild.style.getPropertyValue('background-image');
    strictEqual(avatarBackground, `url("${avatarUrl}")`);
  });

  test('shows no avatar if showContentComingSoon is false and avatar is null', function () {
    mountComponent({ student: { id: '27', name: 'Joe' } });
    notOk(avatarDiv());
  });

  test('shows name if showContentComingSoon is false', function () {
    mountComponent({ student: { id: '27', name: 'Sara' } });
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
    mountComponent({ showContentComingSoon: true });
    notOk(radioInputGroupDiv());
  });

  test('shows assignment carousel', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel').length, 1);
  });

  test('shows assignment carousel containing given assignment name', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel').text(), 'Book Report');
  });

  test('shows assignment carousel with no arrows when isFirstAssignment and isLastAssignment are true', function () {
    mountComponent();
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 0);
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with both arrows when isFirstAssignment and isLastAssignment are false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 1);
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with left arrow when isFirstAssignment is false', function () {
    mountComponent({
      isFirstAssignment: false,
      isLastAssignment: true
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 1);
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with right arrow when isLastAssignment is false', function () {
    mountComponent({
      isFirstAssignment: true,
      isLastAssignment: false
    });
    strictEqual(wrapContent().find('#assignment-carousel .left-arrow-button-container button').length, 0);
    strictEqual(wrapContent().find('#assignment-carousel .right-arrow-button-container button').length, 1);
  });
});
