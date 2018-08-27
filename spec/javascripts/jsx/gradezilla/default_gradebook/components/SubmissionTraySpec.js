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
import { mount, ReactWrapper, shallow } from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme';
import SubmissionCommentCreateForm from 'jsx/gradezilla/default_gradebook/components/SubmissionCommentCreateForm';
import SubmissionTray from 'jsx/gradezilla/default_gradebook/components/SubmissionTray';

/* eslint qunit/no-identical-names: 0 */

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
    enterGradesAs: 'points',
    gradingDisabled: false,
    gradingScheme: [['A', 0.90], ['B+', 0.85], ['B', 0.80], ['B-', 0.75]],
    locale: 'en',
    onAnonymousSpeedGraderClick () {},
    onGradeSubmission () {},
    onRequestClose () {},
    onClose () {},
    submissionUpdating: false,
    isOpen: true,
    courseId: '1',
    currentUserId: '2',
    speedGraderEnabled: true,
    student: {
      id: '27',
      name: 'Jane Doe',
      gradesUrl: 'http://gradeUrl/',
      isConcluded: false
    },
    submission: {
      assignmentId: '30',
      excused: false,
      grade: '100%',
      id: '2501',
      late: false,
      missing: false,
      pointsDeducted: 3,
      secondsLate: 0
    },
    updateSubmission () {},
    updateSubmissionComment () {},
    assignment: {
      anonymizeStudents: false,
      name: 'Book Report',
      gradingType: 'points',
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
    isInNoGradingPeriod: false,
    isNotCountedForScore: false
  };

  function mountComponent (props) {
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

  QUnit.module('Student Carousel', function () {
    test('is disabled when the tray is "processing"', function () {
      mountComponent({ processing: true });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), true);
    });

    test('is not disabled when the tray is not "processing"', function () {
      mountComponent({ processing: false });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), false);
    });

    test('is disabled when the submission comments have not loaded', function () {
      mountComponent({ submissionCommentsLoaded: false });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), true);
    });

    test('is not disabled when the submission comments have loaded', function () {
      mountComponent({ submissionCommentsLoaded: true });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), false);
    });

    test('is disabled when the submission is updating', function () {
      mountComponent({ submissionUpdating: true });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), true);
    });

    test('is not disabled when the submission is not updating', function () {
      mountComponent({ submissionUpdating: false });
      strictEqual(wrapContent().find('Carousel').at(0).prop('disabled'), false);
    });
  });

  QUnit.module('Assignment Carousel', function () {
    test('is disabled when the tray is "processing"', function () {
      mountComponent({ processing: true });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), true);
    });

    test('is not disabled when the tray is not "processing"', function () {
      mountComponent({ processing: false });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), false);
    });

    test('is disabled when the submission comments have not loaded', function () {
      mountComponent({ submissionCommentsLoaded: false });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), true);
    });

    test('is not disabled when the submission comments have loaded', function () {
      mountComponent({ submissionCommentsLoaded: true });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), false);
    });

    test('is disabled when the submission is updating', function () {
      mountComponent({ submissionUpdating: true });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), true);
    });

    test('is not disabled when the submission is not updating', function () {
      mountComponent({ submissionUpdating: false });
      strictEqual(wrapContent().find('Carousel').at(1).prop('disabled'), false);
    });
  });

  test('shows SpeedGrader link if enabled', function () {
    const speedGraderUrl = encodeURI('/courses/1/gradebook/speed_grader?assignment_id=30#{"student_id":"27"}');
    mountComponent();
    const speedGraderLink = document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]').getAttribute('href');
    strictEqual(speedGraderLink, speedGraderUrl);
  });

  test('invokes "onAnonymousSpeedGraderClick" when the SpeedGrader link is clicked if the assignment is anonymous', function () {
    const props = {
      assignment: {
        anonymizeStudents: true,
        name: 'Book Report',
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        published: true
      },
      onAnonymousSpeedGraderClick: sinon.stub()
    }
    mountComponent(props)
    document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]').click()
    strictEqual(props.onAnonymousSpeedGraderClick.callCount, 1)
  })

  test('omits student_id from SpeedGrader link if enabled and assignment has anonymized students', function() {
    mountComponent({assignment: {anonymizeStudents: true}});
    const speedGraderLink = document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]').getAttribute('href');
    notOk(speedGraderLink.match(/student_id/))
  });

  test('does not show SpeedGrader link if disabled', function () {
    mountComponent({speedGraderEnabled: false});
    const speedGraderLink = document.querySelector('.SubmissionTray__Container a[href*="speed_grader"]');
    notOk(speedGraderLink);
  });

  test('shows avatar if avatar is not null', function () {
    const avatarUrl = 'http://bob_is_not_a_domain/me.jpg?filter=make_me_pretty';
    const gradesUrl = 'http://gradesUrl/';
    const props = { student: { id: '27', name: 'Bob', avatarUrl, gradesUrl, isConcluded: false } }

    wrapper = shallow(<SubmissionTray {...defaultProps} {...props} />);
    strictEqual(wrapper.find('Avatar').prop('src'), avatarUrl)
  });

  test('shows no avatar if avatar is null', function () {
    mountComponent({ student: { id: '27', name: 'Joe', gradesUrl: 'http://gradesUrl/', isConcluded: false } });
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

  test('shows name', function () {
    mountComponent({ student: { id: '27', name: 'Sara', gradesUrl: 'http://gradeUrl/', isConcluded: false } });
    strictEqual(studentNameDiv().innerText, 'Sara');
  });

  QUnit.module('LatePolicyGrade', function () {
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
      mountComponent({
        submission: {
          excused: false, id: '2501', late: true, missing: false, pointsDeducted: 0, secondsLate: 0, assignmentId: '30'
        }
      });
      strictEqual(wrapContent().find('LatePolicyGrade').length, 0);
    });

    test('does not show the late policy grade when points deducted is null', function () {
      mountComponent({
        submission: {
          excused: false, id: '2501', late: true, missing: false, pointsDeducted: null, secondsLate: 0, assignmentId: '30'
        }
      });
      strictEqual(wrapContent().find('LatePolicyGrade').length, 0);
    });

    test('receives the "enterGradesAs" given to the Tray', function () {
      mountComponent({ enterGradesAs: 'percent' });
      strictEqual(wrapContent().find('LatePolicyGrade').prop('enterGradesAs'), 'percent');
    });

    test('receives the "gradingScheme" given to the Tray', function () {
      const gradingScheme = [['A', 0.90], ['B+', 0.85], ['B', 0.80], ['B-', 0.75], ['C+', 0.70]];
      mountComponent({ gradingScheme });
      deepEqual(wrapContent().find('LatePolicyGrade').prop('gradingScheme'), gradingScheme);
    });
  });

  test('shows a radio input group', function () {
    mountComponent();
    ok(radioInputGroupDiv());
  });

  test('enables the late policy radio input group when gradingDisabled is false', function () {
    mountComponent({ gradingDisabled: false });
    strictEqual(wrapContent().find('SubmissionTrayRadioInputGroup').props().disabled, false);
  });

  test('disables the late policy radio input group when gradingDisabled is true', function () {
    mountComponent({ gradingDisabled: true });
    strictEqual(wrapContent().find('SubmissionTrayRadioInputGroup').props().disabled, true);
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
      avatarUrl: 'http://avatarUrl/',
      isConcluded: false
    };

    mountComponent({
      student,
      isFirstStudent: false,
      isLastStudent: false
    });

    strictEqual(wrapContent().find('#SubmissionTray__Content').find('View').at(0).prop('padding'), '0 0 0 0');
  });

  test('adds padding to the carousel container when no avatar is present', function () {
    const student = {
      id: '27',
      name: 'Jane Doe',
      gradesUrl: 'http://gradeUrl/',
      isConcluded: false
    };

    mountComponent({
      student,
      isFirstStudent: false,
      isLastStudent: false
    });

    strictEqual(wrapContent().find('#SubmissionTray__Content').find('View').at(0).prop('padding'), 'small 0 0 0');
  });

  QUnit.module('Grade Input', function () {
    test('receives the "assignment" given to the Tray', function () {
      const assignment = {
        anonymizeStudents: false,
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        moderatedGrading: false,
        muted: false,
        name: 'Book Report',
        published: true
      };
      mountComponent({ assignment });
      equal(wrapContent().find('GradeInput').prop('assignment'), assignment);
    });

    test('is disabled when grading is disabled', function () {
      mountComponent({ gradingDisabled: true });
      strictEqual(wrapContent().find('GradeInput').prop('disabled'), true);
    });

    test('is not disabled when grading is not disabled', function () {
      mountComponent({ gradingDisabled: false });
      strictEqual(wrapContent().find('GradeInput').prop('disabled'), false);
    });

    test('receives the "onGradeSubmission" callback given to the Tray', function () {
      function onGradeSubmission () {}
      mountComponent({ onGradeSubmission });
      equal(wrapContent().find('GradeInput').prop('onSubmissionUpdate'), onGradeSubmission);
    });

    test('receives the "submission" given to the Tray', function () {
      const submission = {
        assignmentId: '2301',
        enteredGrade: '100%',
        excused: false,
        grade: '70%',
        id: '2501',
        late: false,
        missing: false,
        pointsDeducted: 3,
        secondsLate: 0
      };
      mountComponent({ submission });
      equal(wrapContent().find('GradeInput').prop('submission'), submission);
    });

    test('receives the "submissionUpdating" given to the Tray', function () {
      mountComponent({ submissionUpdating: true });
      strictEqual(wrapContent().find('GradeInput').prop('submissionUpdating'), true);
    });

    test('receives the "enterGradesAs" given to the Tray', function () {
      mountComponent({ enterGradesAs: 'percent' });
      strictEqual(wrapContent().find('GradeInput').prop('enterGradesAs'), 'percent');
    });

    test('receives the "gradingScheme" given to the Tray', function () {
      const gradingScheme = [['A', 0.90], ['B+', 0.85], ['B', 0.80], ['B-', 0.75], ['C+', 0.70]];
      mountComponent({ gradingScheme });
      deepEqual(wrapContent().find('GradeInput').prop('gradingScheme'), gradingScheme);
    });

    test('passes along isNotCountedForScore prop to SubmissionStatus', function () {
      mountComponent()
      const isNotCountedForScore = wrapContent().find('SubmissionStatus').at(0).prop('isNotCountedForScore')
      deepEqual(isNotCountedForScore, wrapper.prop('isNotCountedForScore'))
    });

    test('receives the "pendingGradeInfo" given to the Tray', function() {
      const pendingGradeInfo = {
        excused: false,
        grade: '10',
        valid: true
      };
      mountComponent({ pendingGradeInfo });
      equal(wrapContent().find('GradeInput').prop('pendingGradeInfo'), pendingGradeInfo);
    });
  });

  test('renders the new comment form if the editedCommentId is null', function () {
    mountComponent();
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 1);
  });

  test('renders new comment form if assignment is not muted', function () {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: true,
      muted: false,
      name: 'foo',
      published: false
    };
    mountComponent({assignment});
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 1);
  });

  test('renders new comment form if assignment is muted and not anonymous or moderated', function () {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: false,
      muted: true,
      name: 'foo',
      published: false
    };
    mountComponent({assignment});
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 1);
  });

  test('does not render new comment form if assignment has anonymized students', function () {
    const assignment = {
      anonymizeStudents: true,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: false,
      muted: true,
      name: 'foo',
      published: false
    };
    mountComponent({assignment});
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 0);
  });

  test('does not render new comment form if assignment is muted and moderated', function () {
    const assignment = {
      anonymizeStudents: false,
      gradingType: 'points',
      htmlUrl: 'foo',
      moderatedGrading: true,
      muted: true,
      name: 'foo',
      published: false
    };
    mountComponent({assignment});
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 0);
  });

  test('does not render the new comment form if the editedCommentId is not null', function () {
    mountComponent({ editedCommentId: '5' });
    const form = wrapContent().find(SubmissionCommentCreateForm);
    strictEqual(form.length, 0);
  });

  test('cancelCommenting calls editSubmissionComment', function () {
    const editSubmissionComment = sinon.stub();
    mountComponent({ editedCommentId: '5', editSubmissionComment });
    wrapper.instance().cancelCommenting();
    strictEqual(editSubmissionComment.callCount, 1);
  });

  test('cancelCommenting sets the edited submission comment id to null', function () {
    const editSubmissionComment = sinon.stub();
    mountComponent({ editedCommentId: '5', editSubmissionComment });
    wrapper.instance().cancelCommenting();
    const editedCommentId = editSubmissionComment.firstCall.args[0];
    strictEqual(editedCommentId, null);
  });
});
