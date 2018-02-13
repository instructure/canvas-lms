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
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCell';

QUnit.module('AssignmentRowCell', (suiteHooks) => {
  let $container;
  let props;
  let wrapper;

  function mountComponent () {
    return mount(<AssignmentRowCell {...props} />, { attachTo: $container });
  }

  function simulateKeyDown (keyCode, shiftKey = false) {
    const event = new Event('keydown');
    event.which = keyCode
    event.shiftKey = shiftKey;
    return wrapper.node.handleKeyDown(event);
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div');
    document.body.appendChild($container);

    props = {
      assignment: {
        gradingType: 'points',
        id: '2301',
        pointsPossible: 10
      },
      editorOptions: {
        column: {
          assignmentId: '2301',
          field: 'assignment_2301',
          object: {
            grading_type: 'points',
            id: '2301',
            points_possible: 10
          }
        },
        grid: {},
        item: { // student row object
          id: '1101',
          assignment_2301: { // submission
            user_id: '1101'
          }
        }
      },
      enterGradesAs: 'points',
      gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]],
      isSubmissionTrayOpen: false,
      onGradeSubmission() {},
      onToggleSubmissionTrayOpen() {},
      submission: {
        assignmentId: '2301',
        enteredGrade: '6.8',
        enteredScore: 7.8,
        excused: false,
        id: '2501',
        userId: '1101'
      },
      submissionIsUpdating: false
    };
  });

  suiteHooks.afterEach(() => {
    wrapper.unmount();
    $container.remove();
  });

  QUnit.module('#render', () => {
    test('assigns a reference to its child SubmissionCell container', () => {
      wrapper = mountComponent()
      ok(
        wrapper.contains(wrapper.node.contentContainer),
        'component node contains the referenced container node'
      )
    })

    QUnit.module('when the "enter grades as setting" is "points"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'points'
      })

      test('renders a GradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').node.isFocused(), true)
      })

      test('disables the GradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').prop('disabled'), true)
      })

      test('renders end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__EndText').length, 1)
      })

      test('renders points possible in the end text', () => {
        wrapper = mountComponent()
        equal(wrapper.find('.Grid__AssignmentRowCell__EndText').text(), '/10')
      })

      test('renders nothing in the end text when the assignment has no points possible', () => {
        props.assignment.pointsPossible = 0
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__EndText').text(), '')
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })
    })

    QUnit.module('when the "enter grades as setting" is "percent"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'percent'
      })

      test('renders a GradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').node.isFocused(), true)
      })

      test('disables the GradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').prop('disabled'), true)
      })

      test('renders end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__EndText').length, 1)
      })

      test('renders nothing in the end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__EndText').text(), '')
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })
    })

    QUnit.module('when the "enter grades as setting" is "gradingScheme"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'gradingScheme'
      })

      test('renders a GradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').node.isFocused(), true)
      })

      test('disables the GradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('GradeInput').prop('disabled'), true)
      })

      test('does not render end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__EndText').length, 0)
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })
    })

    QUnit.module('when the "enter grades as setting" is "passFail"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('renders an "pass_fail" SubmissionCell', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.node.submissionCell.constructor, SubmissionCell.pass_fail)
      })

      test('renders the SubmissionCell within the AssignmentRowCell', () => {
        wrapper = mountComponent()
        ok(
          wrapper.node.contentContainer.querySelector('.gradebook-cell'),
          'container includes a gradebook cell'
        )
      })

      test('includes editor options when rendering the SubmissionCell', () => {
        wrapper = mountComponent();
        deepEqual(wrapper.node.submissionCell.opts.item, props.editorOptions.item)
      });
    });
  });

  QUnit.module('#handleKeyDown', () => {
    QUnit.module('with a GradeInput', hooks => {
      hooks.beforeEach(() => {
        props.assignment.gradingType = 'points'
      })

      test('skips SlickGrid default behavior when tabbing from grade input', () => {
        wrapper = mountComponent()
        wrapper.node.gradeInput.focus()
        const continueHandling = simulateKeyDown(9, false) // tab to tray button trigger
        strictEqual(continueHandling, false)
      })

      test('skips SlickGrid default behavior when shift-tabbing from tray button', () => {
        wrapper = mountComponent()
        wrapper.node.trayButton.focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to grade input
        strictEqual(continueHandling, false)
      })

      test('does not skip SlickGrid default behavior when tabbing from tray button', () => {
        wrapper = mountComponent()
        wrapper.node.trayButton.focus()
        const continueHandling = simulateKeyDown(9, false) // tab out of grid
        equal(typeof continueHandling, 'undefined')
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from grade input', () => {
        wrapper = mountComponent()
        wrapper.node.gradeInput.focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab out of grid
        equal(typeof continueHandling, 'undefined')
      })

      test('skips SlickGrid default behavior when pressing enter on tray button', () => {
        wrapper = mountComponent()
        wrapper.node.trayButton.focus()
        const continueHandling = simulateKeyDown(13) // enter on tray button (open tray)
        strictEqual(continueHandling, false)
      })

      test('does not skip SlickGrid default behavior when pressing enter on grade input', () => {
        wrapper = mountComponent()
        wrapper.node.gradeInput.focus()
        const continueHandling = simulateKeyDown(13) // enter on grade input (commit editor)
        equal(typeof continueHandling, 'undefined')
      })

      QUnit.module('when the grade is invalid', contextHooks => {
        contextHooks.beforeEach(() => {
          props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        })

        test('Tab on the invalid grade indicator skips SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.node.invalidGradeIndicator.focus()
          const continueHandling = simulateKeyDown(9, false) // tab to tray button trigger
          strictEqual(continueHandling, false)
        })

        test('Shift+Tab on the grade input skips SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.node.gradeInput.focus()
          const continueHandling = simulateKeyDown(9, true) // shift+tab back to indicator
          strictEqual(continueHandling, false)
        })

        test('Shift+Tab on the invalid grade indicator does not skip SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.node.invalidGradeIndicator.focus()
          const continueHandling = simulateKeyDown(9, true) // shift+tab out of grid
          equal(typeof continueHandling, 'undefined')
        })
      })
    })

    QUnit.module('with a SubmissionCell', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('skips SlickGrid default behavior when tabbing from grade input', () => {
        wrapper = mountComponent();
        wrapper.node.submissionCell.focus();
        const continueHandling = simulateKeyDown(9, false); // tab to tray button trigger
        strictEqual(continueHandling, false);
      });

      test('skips SlickGrid default behavior when shift-tabbing from tray button', () => {
        wrapper = mountComponent();
        wrapper.node.trayButton.focus();
        const continueHandling = simulateKeyDown(9, true); // shift+tab back to grade input
        strictEqual(continueHandling, false);
      });

      test('does not skip SlickGrid default behavior when tabbing from tray button', () => {
        wrapper = mountComponent();
        wrapper.node.trayButton.focus();
        const continueHandling = simulateKeyDown(9, false); // tab into next cell
        equal(typeof continueHandling, 'undefined');
      });

      test('does not skip SlickGrid default behavior when shift-tabbing from grade input', () => {
        wrapper = mountComponent();
        wrapper.node.submissionCell.focus();
        const continueHandling = simulateKeyDown(9, true); // shift+tab out of grid
        equal(typeof continueHandling, 'undefined');
      });

      test('skips SlickGrid default behavior when entering into tray button', () => {
        wrapper = mountComponent();
        wrapper.node.trayButton.focus();
        const continueHandling = simulateKeyDown(13); // enter into tray button
        strictEqual(continueHandling, false);
      });

      test('does not skip SlickGrid default behavior when pressing enter on grade input', () => {
        wrapper = mountComponent();
        wrapper.node.submissionCell.focus();
        const continueHandling = simulateKeyDown(13); // enter on grade input (commit editor)
        equal(typeof continueHandling, 'undefined');
      });
    });
  });

  QUnit.module('#focus', () => {
    test('sets focus on the text input for a GradeInput', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      wrapper.node.focus()
      strictEqual(wrapper.find('GradeInput').node.isFocused(), true)
    })

    test('sets focus on the button for a Complete/Incomplete SubmissionCell', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      wrapper.node.focus()
      strictEqual(document.activeElement, wrapper.node.submissionCell.$input[0])
    })
  })

  QUnit.module('#isValueChanged', () => {
    test('delegates to the "hasGradeChanged" method for a GradeInput', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      sinon.stub(wrapper.find('GradeInput').node, 'hasGradeChanged').returns(true)
      strictEqual(wrapper.node.isValueChanged(), true)
    })

    test('delegates to the "isValueChanged" method for a Complete/Incomplete SubmissionCell', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      sinon.stub(wrapper.node.submissionCell, 'isValueChanged').returns(true)
      strictEqual(wrapper.node.isValueChanged(), true)
    })
  })

  QUnit.module('#serializeValue', () => {
    test('returns null', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      strictEqual(wrapper.node.serializeValue(), null)
    })

    test('delegates to the "serializeValue" method for a Complete/Incomplete SubmissionCell', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      sinon.stub(wrapper.node.submissionCell, 'serializeValue').returns('9.7')
      strictEqual(wrapper.node.serializeValue(), '9.7')
    })
  })

  QUnit.module('#loadValue', () => {
    test('ignores the absence of a SubmissionCell', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      wrapper.node.loadValue()
      ok(true, 'SubmissionCell is not assumed')
    })

    test('delegates to the "loadValue" method for a Complete/Incomplete SubmissionCell', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      sinon.spy(wrapper.node.submissionCell, 'loadValue')
      wrapper.node.loadValue()
      strictEqual(wrapper.node.submissionCell.loadValue.callCount, 1)
    })
  })

  QUnit.module('#componentDidUpdate()', () => {
    test('sets focus on the grade input when the submission finishes updating', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      wrapper.setProps({submissionIsUpdating: false})
      strictEqual(document.activeElement, wrapper.find('input').get(0))
    })

    test('does not set focus on the grade input when the submission has not finished updating', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      wrapper.setProps({submissionIsUpdating: true})
      notStrictEqual(document.activeElement, wrapper.find('input').get(0))
    })

    test('does not set focus on the grade input when the tray button has focus', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      const button = wrapper.find('button').get(0)
      button.focus()
      wrapper.setProps({submissionIsUpdating: false})
      strictEqual(document.activeElement, button)
    })

    test('does not change focus when the "enter grades as" setting is "passFail"', () => {
      props.enterGradesAs = 'passFail'
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      const previousFocusElement = document.activeElement
      wrapper.setProps({submissionIsUpdating: false})
      strictEqual(document.activeElement, previousFocusElement)
    })
  })

  QUnit.module('#componentWillUnmount', () => {
    test('destroys the SubmissionCell when present', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent();
      sinon.spy(wrapper.node.submissionCell, 'destroy');
      wrapper.unmount();
      strictEqual(wrapper.node.submissionCell.destroy.callCount, 1);
    });
  });

  QUnit.module('"Toggle Tray" Button', () => {
    const buttonSelector = '.Grid__AssignmentRowCell__Options button'

    test('is rendered when the assignment grading type is "points"', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      strictEqual(wrapper.find(buttonSelector).length, 1)
    })

    test('is rendered when the "enter grades as" setting is "passFail"', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      strictEqual(wrapper.find(buttonSelector).length, 1)
    })

    test('calls onToggleSubmissionTrayOpen when clicked', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub();
      wrapper = mountComponent();
      wrapper.find(buttonSelector).simulate('click')
      strictEqual(props.onToggleSubmissionTrayOpen.callCount, 1);
    });

    test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub();
      wrapper = mountComponent();
      wrapper.find(buttonSelector).simulate('click')
      deepEqual(props.onToggleSubmissionTrayOpen.getCall(0).args, ['1101', '2301']);
    });
  });
});
