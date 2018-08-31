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
import { mount, shallow } from 'enzyme';
import SubmissionTray from 'jsx/gradezilla/default_gradebook/components/SubmissionTray';

/* eslint qunit/no-identical-names: 0 */

QUnit.module('SubmissionTray', function (hooks) {
  let defaultProps;
  let clock;
  let content;
  let wrapper;

  hooks.beforeEach(function () {
    const applicationElement = document.createElement('div');
    applicationElement.id = 'application';
    document.getElementById('fixtures').appendChild(applicationElement);
    clock = sinon.useFakeTimers();

    defaultProps = {
      contentRef (ref) {
        content = ref; },
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
        enteredGrade: '10',
        enteredScore: 10,
        excused: false,
        grade: '7',
        id: '2501',
        late: false,
        missing: false,
        pointsDeducted: 3,
        secondsLate: 0,
        score: 7
      },
      updateSubmission () {},
      updateSubmissionComment () {},
      assignment: {
        anonymizeStudents: false,
        name: 'Book Report',
        gradingType: 'points',
        htmlUrl: 'http://htmlUrl/',
        muted: false,
        pointsPossible: 10,
        published: true
      },
      isFirstAssignment: false,
      isLastAssignment: false,
      selectNextAssignment () {},
      selectPreviousAssignment () {},
      isFirstStudent: false,
      isLastStudent: false,
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
  });

  hooks.afterEach(function () {
    wrapper.unmount();
    document.getElementById('fixtures').innerHTML = '';
    clock.restore();
  });

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

  function carouselButton(label) {
    const $buttons = [...content.querySelectorAll('button')]
    return $buttons.find($button => $button.textContent.trim() === label)
  }

  function radioInputGroupDiv () {
    return document.querySelector('#SubmissionTray__RadioInputGroup');
  }

  QUnit.module('Student Carousel', function () {
    function assertStudentButtonsDisabled(disabled) {
      ['Previous student', 'Next student'].forEach(label => {
        const $button = carouselButton(label)
        const message = `'${label}' button is ${disabled ? '' : 'not '} disabled`
        strictEqual($button.getAttribute('aria-disabled'), disabled ? 'true' : null, message)
      })
    }

    test('is disabled when the tray is "processing"', function () {
      mountComponent({ processing: true });
      assertStudentButtonsDisabled(true)
    });

    test('is not disabled when the tray is not "processing"', function () {
      mountComponent({ processing: false });
      assertStudentButtonsDisabled(false)
    });

    test('is disabled when the submission comments have not loaded', function () {
      mountComponent({ submissionCommentsLoaded: false });
      assertStudentButtonsDisabled(true)
    });

    test('is not disabled when the submission comments have loaded', function () {
      mountComponent({ submissionCommentsLoaded: true });
      assertStudentButtonsDisabled(false)
    });

    test('is disabled when the submission is updating', function () {
      mountComponent({ submissionUpdating: true });
      assertStudentButtonsDisabled(true)
    });

    test('is not disabled when the submission is not updating', function () {
      mountComponent({ submissionUpdating: false });
      assertStudentButtonsDisabled(false)
    });
  });

  QUnit.module('Assignment Carousel', function () {
    function assertAssignmentButtonsDisabled(disabled) {
      ['Previous assignment', 'Next assignment'].forEach(label => {
        const $button = carouselButton(label)
        const message = `'${label}' button is ${disabled ? '' : 'not '} disabled`
        strictEqual($button.getAttribute('aria-disabled'), disabled ? 'true' : null, message)
      })
    }

    test('is disabled when the tray is "processing"', function () {
      mountComponent({ processing: true });
      assertAssignmentButtonsDisabled(true);
    });

    test('is not disabled when the tray is not "processing"', function () {
      mountComponent({ processing: false });
      assertAssignmentButtonsDisabled(false);
    });

    test('is disabled when the submission comments have not loaded', function () {
      mountComponent({ submissionCommentsLoaded: false });
      assertAssignmentButtonsDisabled(true);
    });

    test('is not disabled when the submission comments have loaded', function () {
      mountComponent({ submissionCommentsLoaded: true });
      assertAssignmentButtonsDisabled(false);
    });

    test('is disabled when the submission is updating', function () {
      mountComponent({ submissionUpdating: true });
      assertAssignmentButtonsDisabled(true);
    });

    test('is not disabled when the submission is not updating', function () {
      mountComponent({ submissionUpdating: false });
      assertAssignmentButtonsDisabled(false);
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
    defaultProps.isNotCountedForScore = true
    mountComponent();
    ok(content.textContent.includes('Not calculated in final grade'))
  });

  test('passes along isInOtherGradingPeriod prop to SubmissionStatus', function () {
    defaultProps.isInOtherGradingPeriod = true
    mountComponent();
    ok(content.textContent.includes('This submission is in another grading period'))
  });

  test('passes along isInClosedGradingPeriod prop to SubmissionStatus', function () {
    defaultProps.isInClosedGradingPeriod = true
    mountComponent();
    ok(content.textContent.includes('This submission is in a closed grading period'))
  });

  test('passes along isInNoGradingPeriod prop to SubmissionStatus', function () {
    defaultProps.isInNoGradingPeriod = true
    mountComponent();
    ok(content.textContent.includes('This submission is not in any grading period'))
  });

  test('shows student name', function () {
    mountComponent({ student: { id: '27', name: 'Sara', gradesUrl: 'http://gradeUrl/', isConcluded: false } });
    strictEqual(studentNameDiv().innerText, 'Sara');
  });

  QUnit.module('LatePolicyGrade', function () {
    test('shows the late policy grade when points have been deducted', function () {
      mountComponent();
      ok(content.querySelector('#late-penalty-value'))
    });

    test('uses the submission to show the late policy grade', function () {
      mountComponent();
      const $el = content.querySelector('#late-penalty-value')
      strictEqual($el.textContent, '-3')
    });

    test('does not show the late policy grade when zero points have been deducted', function () {
      mountComponent({
        submission: {
          excused: false, id: '2501', late: true, missing: false, pointsDeducted: 0, secondsLate: 0, assignmentId: '30'
        }
      });
      notOk(content.querySelector('#late-penalty-value'))
    });

    test('does not show the late policy grade when points deducted is null', function () {
      mountComponent({
        submission: {
          excused: false, id: '2501', late: true, missing: false, pointsDeducted: null, secondsLate: 0, assignmentId: '30'
        }
      });
      notOk(content.querySelector('#late-penalty-value'))
    });

    test('receives the "enterGradesAs" given to the Tray', function () {
      mountComponent({ enterGradesAs: 'percent' });
      const $el = content.querySelector('#final-grade-value')
      strictEqual($el.textContent, '70%')
    });

    test('receives the "gradingScheme" given to the Tray', function () {
      const gradingScheme = [['A', 0.90], ['B+', 0.85], ['B', 0.80], ['B-', 0.75], ['C+', 0.70]];
      mountComponent({ enterGradesAs: 'gradingScheme', gradingScheme });
      const $el = content.querySelector('#final-grade-value')
      strictEqual($el.textContent, 'C+')
    });
  });

  test('shows a radio input group', function () {
    mountComponent();
    ok(radioInputGroupDiv());
  });

  test('enables the late policy radio input group when gradingDisabled is false', function () {
    mountComponent({ gradingDisabled: false });
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]');
    $inputs.forEach($input => {
      strictEqual($input.getAttribute('aria-disabled'), null);
    })
  });

  test('disables the late policy radio input group when gradingDisabled is true', function () {
    mountComponent({ gradingDisabled: true });
    const $inputs = content.querySelectorAll('[name="SubmissionTrayRadioInput"]');
    $inputs.forEach($input => {
      strictEqual($input.getAttribute('aria-disabled'), 'true');
    })
  });

  test('shows assignment carousel', function () {
    mountComponent();
    ok(content.querySelector('#assignment-carousel'));
  });

  test('shows assignment carousel containing given assignment name', function () {
    mountComponent();
    const $el = content.querySelector('#assignment-carousel');
    ok($el.textContent.includes('Book Report'))
  });

  test('shows assignment carousel with no left arrow when isFirstAssignment and isLastAssignment are true', function () {
    defaultProps = {...defaultProps, isFirstAssignment: true, isLastAssignment: true}
    mountComponent();
    strictEqual(content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with no right arrow when isFirstAssignment and isLastAssignment are true', function () {
    mountComponent({isFirstAssignment: true, isLastAssignment: true});
    strictEqual(content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with left arrow when isFirstAssignment and isLastAssignment are false', function () {
    mountComponent({isFirstAssignment: false, isLastAssignment: false});
    strictEqual(content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with right arrow when isFirstAssignment and isLastAssignment are false', function () {
    mountComponent({isFirstAssignment: false, isLastAssignment: false});
    strictEqual(content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with left arrow when isFirstAssignment is false', function () {
    mountComponent({isFirstAssignment: false, isLastAssignment: true});
    strictEqual(content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with no right arrow when isFirstAssignment is false', function () {
    mountComponent({isFirstAssignment: false, isLastAssignment: true});
    strictEqual(content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows assignment carousel with right arrow when isLastAssignment is false', function () {
    mountComponent({isFirstAssignment: true, isLastAssignment: false});
    strictEqual(content.querySelectorAll('#assignment-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows assignment carousel with no left arrow when isLastAssignment is false', function () {
    mountComponent({isFirstAssignment: true, isLastAssignment: false});
    strictEqual(content.querySelectorAll('#assignment-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel', function () {
    mountComponent();
    ok(content.querySelector('#student-carousel'));
  });

  test('shows student carousel containing given student name', function () {
    mountComponent();
    const $el = content.querySelector('#student-carousel');
    ok($el.textContent.includes('Jane Doe'))
  });

  test('shows student carousel with no left arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true
    });
    strictEqual(content.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel with no right arrow when isFirstStudent and isLastStudent are true', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: true
    });
    strictEqual(content.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 0);
  });

  test('shows student carousel with left arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false
    });
    strictEqual(content.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows student carousel with right arrow when isFirstStudent and isLastStudent are false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: false
    });
    strictEqual(content.querySelectorAll('#student-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows student carousel with left arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true
    });
    strictEqual(content.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 1);
  });

  test('shows student carousel with no right arrow when isFirstStudent is false', function () {
    mountComponent({
      isFirstStudent: false,
      isLastStudent: true
    });
    strictEqual(content.querySelectorAll('#student-carousel .right-arrow-button-container button').length, 0);
  });

  test('shows student carousel with right arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false
    });
    strictEqual(content.querySelectorAll('#student-carousel .right-arrow-button-container button').length, 1);
  });

  test('shows student carousel with no left arrow when isLastStudent is false', function () {
    mountComponent({
      isFirstStudent: true,
      isLastStudent: false
    });
    strictEqual(content.querySelectorAll('#student-carousel .left-arrow-button-container button').length, 0);
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
        pointsPossible: 10,
        published: true
      };
      mountComponent({ assignment });
      const $label = content.querySelector('label[for="grade-detail-tray--grade-input"]')
      equal($label.textContent, 'Grade out of 10')
    });

    test('is disabled when grading is disabled', function () {
      mountComponent({ gradingDisabled: true });
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      strictEqual($input.getAttribute('aria-disabled'), 'true');
    });

    test('is not disabled when grading is not disabled', function () {
      mountComponent({ gradingDisabled: false });
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      strictEqual($input.getAttribute('aria-disabled'), null);
    });

    test('receives the "onGradeSubmission" callback given to the Tray', function () {
      const onGradeSubmission = sinon.stub()
      mountComponent({ onGradeSubmission });
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      $input.value = 'EX'
      $input.dispatchEvent(new Event('input', {bubbles: true}))
      $input.blur()
      const event = new Event('blur', {bubbles: true, cancelable: true})
      $input.dispatchEvent(event)
      strictEqual(onGradeSubmission.callCount, 1);
    });

    test('receives the "submission" given to the Tray', function () {
      mountComponent();
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      strictEqual($input.value, '10');
    });

    test('receives the "submissionUpdating" given to the Tray', function () {
      mountComponent({ submissionUpdating: true });
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      strictEqual($input.getAttribute('aria-disabled'), 'true');
    });

    test('receives the "enterGradesAs" given to the Tray', function () {
      mountComponent({ enterGradesAs: 'percent' });
      const $label = content.querySelector('label[for="grade-detail-tray--grade-input"]')
      equal($label.textContent, 'Grade out of 100%')
    });

    test('receives the "gradingScheme" given to the Tray', function () {
      const gradingScheme = [['A', 0.90], ['B+', 0.85], ['B', 0.80], ['B-', 0.75], ['C+', 0.70]];
      mountComponent({ enterGradesAs: 'gradingScheme', gradingScheme });
      const $label = content.querySelector('label[for="grade-detail-tray--grade-input"]')
      equal($label.textContent, 'Letter Grade')
    });

    test('receives the "pendingGradeInfo" given to the Tray', function() {
      const pendingGradeInfo = {
        excused: false,
        grade: '15',
        valid: true
      };
      mountComponent({ pendingGradeInfo });
      const $input = content.querySelector('#grade-detail-tray--grade-input')
      strictEqual($input.value, '15');
    });
  });

  test('renders the new comment form if the editedCommentId is null', function () {
    mountComponent();
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
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
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
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
    ok(content.querySelector('textarea[placeholder="Leave a comment"]'))
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
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
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
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
  });

  test('does not render the new comment form if the editedCommentId is not null', function () {
    mountComponent({ editedCommentId: '5' });
    notOk(content.querySelector('textarea[placeholder="Leave a comment"]'))
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
