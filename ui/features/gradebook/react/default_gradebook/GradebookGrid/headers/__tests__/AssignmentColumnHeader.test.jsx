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

import React from 'react'
import { render, cleanup, waitFor, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import sinon from 'sinon';

import AsyncComponents from '../../../AsyncComponents'
import AssignmentColumnHeader from '../AssignmentColumnHeader'
import MessageStudentsWhoDialog from '../../../../shared/MessageStudentsWhoDialog'
import {getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid AssignmentColumnHeader', () => {
  let container
  let component
  let gradebookElements
  let props
  let students
  let menuContent;

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))

    students = [
      {
        id: '1001',
        isInactive: false,
        isTestStudent: false,
        name: 'Adam Jones',
        sortableName: 'Jones, Adam',
        submission: {
          excused: false,
          postedAt: null,
          score: 7,
          submittedAt: null,
          workflowState: 'graded',
        },
      },
      {
        id: '1002',
        isInactive: false,
        isTestStudent: false,
        name: 'Betty Ford',
        sortableName: 'Ford, Betty',
        submission: {
          excused: false,
          postedAt: null,
          score: 8,
          submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)'),
          workflowState: 'graded',
        },
      },
      {
        id: '1003',
        isInactive: false,
        isTestStudent: false,
        name: 'Charlie Xi',
        sortableName: 'Xi, Charlie',
        submission: {
          excused: false,
          postedAt: null,
          score: null,
          submittedAt: null,
          workflowState: 'unsubmitted',
        },
      },
    ]

    gradebookElements = []
    props = {
      addGradebookElement(el) {
        gradebookElements.push(el)
      },
      allStudents: [...students],
      assignment: {
        anonymizeStudents: false,
        courseId: '1201',
        htmlUrl: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        name: 'Math 1.1',
        omitFromFinalGrade: false,
        pointsPossible: 10,
        postManually: false,
        published: true,
        submissionTypes: ['online_text_entry'],
      },
      assignmentDetailsAction: {
        disabled: false,
        onSelect() {},
      },
      curveGradesAction: {
        isDisabled: false,
        onSelect() {},
      },
      downloadSubmissionsAction: {
        hidden: false,
        onSelect() {},
      },
      enterGradesAsSetting: {
        hidden: false,
        onSelect() {},
        selected: 'points',
        showGradingSchemeOption: true,
      },
      getCurrentlyShownStudents: () => students.slice(0, 2),
      hideGradesAction: {
        hasGradesOrPostableComments: true,
        hasGradesOrCommentsToHide: true,
        onSelect() {},
      },
      postGradesAction: {
        enabledForUser: false,
        hasGradesOrPostableComments: true,
        hasGradesOrCommentsToPost: true,
        onSelect() {},
      },
      onMenuDismiss() {},
      removeGradebookElement(el) {
        gradebookElements.splice(gradebookElements.indexOf(el), 1)
      },
      reuploadSubmissionsAction: {
        hidden: false,
        onSelect() {},
      },
      setDefaultGradeAction: {
        disabled: false,
        onSelect() {},
      },
      showGradePostingPolicyAction: {
        onSelect() {},
      },
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending() {},
        onSortByGradeDescending() {},
        onSortByLate() {},
        onSortByMissing() {},
        settingKey: 'grade',
      },
      submissionsLoaded: true,
      userId: '123',
    }
  })

  afterEach(() => {
    cleanup()
    container.remove()
  })

  function mountComponent() {
    component = render(<AssignmentColumnHeader {...props} />, { container })
  }

  function getAssignmentLink() {
    return [...container.querySelectorAll('a')].find(link => link.textContent === 'Math 1.1')
  }

  function getOptionsMenuTrigger() {
    return [...container.querySelectorAll('button')].find(
      button => button.textContent === 'Math 1.1 Options'
    ) || null;
  }

  function getOptionsMenuContent() {
    const button = getOptionsMenuTrigger()
    return document.querySelector(`[aria-labelledby="${button.id}"]`)
  }

  function openOptionsMenu() {
    const trigger = getOptionsMenuTrigger();
    if (trigger) {
      fireEvent.click(trigger);
      menuContent = getOptionsMenuContent();
    }
  }

  function mountAndOpenOptionsMenu() {
    mountComponent();
    openOptionsMenu();
  }

  function closeOptionsMenu() {
    const trigger = getOptionsMenuTrigger();
    fireEvent.click(trigger);
  }

  describe('assignment name', () => {
    beforeEach(mountComponent)

    test('is present as a link', () => {
      expect(getAssignmentLink()).toBeInTheDocument()
    })

    test('links to the assignment url', () => {
      expect(getAssignmentLink()).toHaveAttribute('href', 'http://localhost/assignments/2301')
    })
  })

  describe('header indicators', () => {
    function getColumnHeaderIcon(name = null) {
      const iconSpecifier = name != null ? `svg[name="${name}"]` : 'svg'
      return container.querySelector(`.Gradebook__ColumnHeaderIndicators ${iconSpecifier}`)
    }

    beforeEach(() => {
      props.postGradesAction.enabledForUser = true
    })

    describe('when the assignment is auto-posted', () => {
      test('displays no icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.score != null) {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        expect(getColumnHeaderIcon()).not.toBeInTheDocument()
      })

      test('displays an "off" icon when submissions are graded but unposted', () => {
        mountComponent()
        expect(getColumnHeaderIcon('IconOff')).toBeInTheDocument()
      })
    })

    describe('when the assignment is manually-posted', () => {
      beforeEach(() => {
        props.assignment.postManually = true
      })

      test('does not display an "off" icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.workflowState === 'graded') {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        expect(getColumnHeaderIcon('IconOff')).not.toBeInTheDocument()
      })
    })

    test('displays no icon when submissions have not been loaded', () => {
      props.submissionsLoaded = false
      mountComponent()
      expect(getColumnHeaderIcon()).not.toBeInTheDocument()
    })
  })

  describe('secondary details', () => {
    function getSecondaryDetailText() {
      return container.querySelector('.Gradebook__ColumnHeaderDetail--secondary').textContent
    }

    test('displays points possible', () => {
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Out of 10')
    })

    test('displays points possible when zero', () => {
      props.assignment.pointsPossible = 0
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Out of 0')
    })

    test('displays an anonymous status when students are anonymized', () => {
      props.assignment.anonymizeStudents = true
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Anonymous')
    })

    describe('when the assignment is not published', () => {
      beforeEach(() => {
        props.assignment.published = false
      })

      test('displays an unpublished status', () => {
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Unpublished')
      })

      test('displays an unpublished status when students are anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Unpublished')
      })
    })

    describe('when the assignment is manually posted', () => {
      beforeEach(() => {
        props.assignment.postManually = true
      })

      test('displays post policy "Manual" text', () => {
        mountComponent()
        expect(getSecondaryDetailText()).toContain('Manual')
      })

      test('prioritizes "Anonymous" text when the assignment is anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Anonymous')
      })
    })

    test('does not display "Manual" text when the assignment is auto-posted', () => {
      mountComponent()
      expect(getSecondaryDetailText()).not.toContain('Manual')
    })
  })

  describe('"Options" menu trigger', () => {
    test('is present for a published assignment', () => {
      mountComponent();
      expect(getOptionsMenuTrigger()).toBeInTheDocument();
    });

    test('is not present for an unpublished assignment', () => {
      props.assignment.published = false;
      mountComponent();
      expect(getOptionsMenuTrigger()).not.toBeInTheDocument();
    });

    test('is labeled with the assignment name', () => {
      mountComponent();
      const trigger = getOptionsMenuTrigger();
      expect(trigger.textContent).toContain('Math 1.1 Options');
    });

    test('opens the options menu when clicked', () => {
      mountComponent();
      fireEvent.click(getOptionsMenuTrigger());
      expect(getOptionsMenuContent()).toBeInTheDocument();
    });

    test('closes the options menu when clicked', () => {
      mountAndOpenOptionsMenu();
      fireEvent.click(getOptionsMenuTrigger());
      expect(getOptionsMenuContent()).not.toBeInTheDocument();
    });
  });

  describe('"Options" menu', () => {
    describe('when opened', () => {
      beforeEach(() => {
        mountAndOpenOptionsMenu();
      });

      test('is added as a Gradebook element', () => {
        expect(gradebookElements.indexOf(menuContent)).not.toBe(-1);
      });

      test('adds the "menuShown" class to the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction');
        expect(actionContainer.classList).toContain('menuShown');
      });
    });

    describe('when closed', () => {
      beforeEach(() => {
        props.onMenuDismiss = jest.fn();
        mountAndOpenOptionsMenu();
        closeOptionsMenu();
      });

      test('is removed as a Gradebook element', () => {
        expect(gradebookElements.indexOf(menuContent)).toBe(-1);
      });

      test('calls the onMenuDismiss callback', () => {
        expect(props.onMenuDismiss).toHaveBeenCalledTimes(1);
      });

      test('removes the "menuShown" class from the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction');
        expect(actionContainer.classList).not.toContain('menuShown');
      });
    });
  })

  describe('"Options" > "Sort by" setting', () => {
    function getSortByOption(label) {
      return getMenuItem(menuContent, 'Sort by', label);
    }

    test('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu();
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by');
      expect(gradebookElements.indexOf(sortByMenuContent)).not.toBe(-1);
    });

    test('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu();
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by');
      closeOptionsMenu();
      expect(gradebookElements.indexOf(sortByMenuContent)).toBe(-1);
    });

    describe('"Grade - Low to High" option', () => {
      test('is selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'ascending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('true');
      });

      test('is not selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'descending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false');
      });

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-disabled')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeAscending = jest.fn();
        });

        test('calls the .sortBySetting.onSortByGradeAscending callback', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Grade - Low to High').click();
          expect(props.sortBySetting.onSortByGradeAscending).toHaveBeenCalledTimes(1);
        });

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Grade - Low to High').focus();
          getSortByOption('Grade - Low to High').click();
          expect(document.activeElement).toBe(getOptionsMenuTrigger());
        });
      });
    });

    describe('"Grade - High to Low" option', () => {
      test('is selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'descending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('true');
      });

      test('is not selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'ascending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false');
      });

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-disabled')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeDescending = jest.fn();
        });

        test('calls the .sortBySetting.onSortByGradeDescending callback', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Grade - High to Low').click();
          expect(props.sortBySetting.onSortByGradeDescending).toHaveBeenCalledTimes(1);
        });

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Grade - High to Low').focus();
          getSortByOption('Grade - High to Low').click();
          expect(document.activeElement).toBe(getOptionsMenuTrigger());
        });
      });
    });

    describe('"Missing" option', () => {
      test('is selected when sorting by missing', () => {
        props.sortBySetting.settingKey = 'missing';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('true');
      });

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'ascending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('false');
      });

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Missing').getAttribute('aria-disabled')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByMissing = jest.fn();
        });

        test('calls the .sortBySetting.onSortByMissing callback', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Missing').click();
          expect(props.sortBySetting.onSortByMissing).toHaveBeenCalledTimes(1);
        });

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Missing').focus();
          getSortByOption('Missing').click();
          expect(document.activeElement).toBe(getOptionsMenuTrigger());
        });
      });
    })

    describe('"Late" option', () => {
      test('is selected when sorting by late', () => {
        props.sortBySetting.settingKey = 'late';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('true');
      });

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade';
        props.sortBySetting.direction = 'ascending';
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('false');
      });

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('false');
      });

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true;
        mountAndOpenOptionsMenu();
        expect(getSortByOption('Late').getAttribute('aria-disabled')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByLate = jest.fn();
        });

        test('calls the .sortBySetting.onSortByLate callback', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Late').click();
          expect(props.sortBySetting.onSortByLate).toHaveBeenCalledTimes(1);
        });

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu();
          getSortByOption('Late').focus();
          getSortByOption('Late').click();
          expect(document.activeElement).toBe(getOptionsMenuTrigger());
        });
      });
    })
  })

  describe('"Options" > "SpeedGrader" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu();
    });

    test('is present', () => {
      const menuItem = getMenuItem(menuContent, 'SpeedGrader');
      expect(menuItem).toBeInTheDocument();
    });

    test('links to SpeedGrader for the current assignment', () => {
      const menuItem = getMenuItem(menuContent, 'SpeedGrader');
      expect(menuItem.href).toContain('/courses/1201/gradebook/speed_grader?assignment_id=2301');
    });
  });

  describe('"Options" > "Message Students Who" action', () => {
    let loadMessageStudentsWhoDialogPromise;

    beforeEach(() => {
      loadMessageStudentsWhoDialogPromise = Promise.resolve(MessageStudentsWhoDialog);
      sinon.stub(AsyncComponents, 'loadMessageStudentsWhoDialog').returns(loadMessageStudentsWhoDialogPromise);
      sinon.stub(MessageStudentsWhoDialog, 'show');
      mountAndOpenOptionsMenu();
    });

    afterEach(() => {
      sinon.restore();
    });

    test('is always present', () => {
      expect(menuContent).not.toBeNull();
      const menuItem = getMenuItem(menuContent, 'Message Students Who');
      expect(menuItem).toBeInTheDocument();
    });

    test('is disabled when anonymizing students', async () => {
      props.assignment.anonymizeStudents = true;
      expect(menuContent).not.toBeNull();
      const menuItem = getMenuItem(menuContent, 'Message Students Who');
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true');
      });
    });

    test('is not disabled when submissions are loaded', () => {
      expect(menuContent).not.toBeNull();
      const menuItem = getMenuItem(menuContent, 'Message Students Who');
      expect(menuItem).not.toHaveAttribute('aria-disabled');
    });

    describe('when clicked', () => {
      test('does not restore focus to the "Options" menu trigger', () => {
        expect(menuContent).not.toBeNull();
        const menuItem = getMenuItem(menuContent, 'Message Students Who');
        fireEvent.click(menuItem);
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('includes a callback for restoring focus upon dialog close', async () => {
        expect(menuContent).not.toBeNull();
        const menuItem = getMenuItem(menuContent, 'Message Students Who');
        fireEvent.click(menuItem);
        await loadMessageStudentsWhoDialogPromise;
        const [, onClose] = MessageStudentsWhoDialog.show.lastCall.args;
        onClose();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });

      test('includes non-test students in the "settings" hash', async () => {
        expect(menuContent).not.toBeNull();
        const menuItem = getMenuItem(menuContent, 'Message Students Who');
        fireEvent.click(menuItem);
        await loadMessageStudentsWhoDialogPromise;
        const [settings] = MessageStudentsWhoDialog.show.lastCall.args;
        expect(settings.students.length).toBe(2);
      });

      test('excludes test students from the "settings" hash', async () => {
        students[0].isTestStudent = true;
        expect(menuContent).not.toBeNull();
        const menuItem = getMenuItem(menuContent, 'Message Students Who');
        fireEvent.click(menuItem);
        await loadMessageStudentsWhoDialogPromise;
        const [settings] = MessageStudentsWhoDialog.show.lastCall.args;
        expect(settings.students.map(student => student.name)).toEqual(['Betty Ford']);
      });
    });
  });

  describe('"Options" > "Curve Grades" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu();
    });

    test('is always present', () => {
      const menuItem = getMenuItem(menuContent, 'Curve Grades');
      expect(menuItem).toBeInTheDocument();
    });

    test('is disabled when .curveGradesAction.isDisabled is true', async () => {
      props.curveGradesAction.isDisabled = true;
      const menuItem = getMenuItem(menuContent, 'Curve Grades');
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true');
      });
    });

    test('is not disabled when .curveGradesAction.isDisabled is false', () => {
      const menuItem = getMenuItem(menuContent, 'Curve Grades');
      expect(menuItem).not.toHaveAttribute('aria-disabled');
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.curveGradesAction.onSelect = sinon.stub();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades');
        fireEvent.click(menuItem);
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .curveGradesAction.onSelect callback', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades');
        fireEvent.click(menuItem);
        expect(props.curveGradesAction.onSelect.callCount).toBe(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades');
        fireEvent.click(menuItem);
        const [callback] = props.curveGradesAction.onSelect.lastCall.args;
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('"Options" > "Set Default Grade" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu();
    });

    test('is always present', () => {
      const menuItem = getMenuItem(menuContent, 'Set Default Grade');
      expect(menuItem).toBeInTheDocument();
    });

    test('is disabled when .setDefaultGradeAction.disabled is true', async () => {
      props.setDefaultGradeAction.disabled = true;
      const menuItem = getMenuItem(menuContent, 'Set Default Grade');
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true');
      });
    });

    test('is not disabled when .setDefaultGradeAction.disabled is false', () => {
      const menuItem = getMenuItem(menuContent, 'Set Default Grade');
      expect(menuItem).not.toHaveAttribute('aria-disabled');
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.setDefaultGradeAction.onSelect = sinon.stub();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade');
        fireEvent.click(menuItem);
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .setDefaultGradeAction.onSelect callback', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade');
        fireEvent.click(menuItem);
        expect(props.setDefaultGradeAction.onSelect.callCount).toBe(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade');
        fireEvent.click(menuItem);
        const [callback] = props.setDefaultGradeAction.onSelect.lastCall.args;
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('"Options" > "Post grades" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true;
      props.postGradesAction.hasGradesOrCommentsToPost = true;
      mountAndOpenOptionsMenu();
    });

    describe('when the current user can edit grades', () => {
      test('has the default text when submissions can be posted', () => {
        expect(getMenuItem(menuContent, 'Post grades')).toBeInTheDocument();
      });

      test('is enabled when submissions can be posted', () => {
        expect(getMenuItem(menuContent, 'Post grades')).not.toHaveAttribute('aria-disabled');
      });

      test('has the text "All grades posted" when no submissions can be posted', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades posted')).toBeInTheDocument();
        });
      });

      test('has the text "No grades to post" when no submissions are graded or have comments', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false;
        props.postGradesAction.hasGradesOrPostableComments = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'No grades to post')).toBeInTheDocument();
        });
      });

      test('is disabled when no submissions can be posted', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades posted')).toHaveAttribute('aria-disabled', 'true');
        });
      });
    });

    test('does not appear when posting is not enabled for this user', async () => {
      props.postGradesAction.enabledForUser = false;
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Post grades')).toBeUndefined();
      });
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.postGradesAction.onSelect = sinon.stub();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Post grades').click();
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .postGradesAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Post grades').click();
        expect(props.postGradesAction.onSelect.callCount).toBe(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Post grades').click();
        const [callback] = props.postGradesAction.onSelect.lastCall.args;
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('"Options" > "Hide grades" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true;
      props.hideGradesAction.hasGradesOrCommentsToHide = true;
      mountAndOpenOptionsMenu();
    });

    describe('when post policies is enabled', () => {
      test('has the default text when submissions can be hidden', () => {
        expect(getMenuItem(menuContent, 'Hide grades')).toBeInTheDocument();
      });

      test('is enabled when submissions can be hidden', () => {
        expect(getMenuItem(menuContent, 'Hide grades')).not.toHaveAttribute('aria-disabled');
      });

      test('has the text "All grades hidden" when no submissions can be hidden', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades hidden')).toBeInTheDocument();
        });
      });

      test('has the text "No grades to hide" when no submissions are graded or have comments', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false;
        props.hideGradesAction.hasGradesOrPostableComments = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'No grades to hide')).toBeInTheDocument();
        });
      });

      test('is disabled when no submissions can be hidden', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false;
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades hidden')).toHaveAttribute('aria-disabled', 'true');
        });
      });
    });

    test('is present when the current user can post grades', () => {
      expect(getMenuItem(menuContent, 'Hide grades')).toBeInTheDocument();
    });

    test('is not present when the current user cannot post grades', async () => {
      props.postGradesAction.enabledForUser = false;
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Hide grades')).toBeUndefined();
      });
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.hideGradesAction.onSelect = sinon.stub();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Hide grades').click();
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .hideGradesAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Hide grades').click();
        expect(props.hideGradesAction.onSelect.callCount).toBe(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Hide grades').click();
        const [callback] = props.hideGradesAction.onSelect.lastCall.args;
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('"Options" > "Grade Posting Policy" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true;
      mountAndOpenOptionsMenu();
    });

    test('is present when the current user can post grades', () => {
      expect(getMenuItem(menuContent, 'Grade Posting Policy')).toBeInTheDocument();
    });

    test('is not present when the current user cannot post grades', async () => {
      props.postGradesAction.enabledForUser = false;
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Grade Posting Policy')).toBeUndefined();
      });
    });
  });

  describe('"Options" > "Enter Grades as" setting', () => {
    function getEnterGradesAsOption(label) {
      return getMenuItem(menuContent, 'Enter Grades as', label);
    }

    beforeEach(() => {
      props.enterGradesAsSetting = {
        hidden: false,
        selected: 'points',
        showGradingSchemeOption: false,
        onSelect: jest.fn(),
      };
    });

    test('is present when .enterGradesAsSetting.hidden is false', () => {
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Enter Grades as')).toBeInTheDocument();
    });

    test('is not present when .enterGradesAsSetting.hidden is true', () => {
      props.enterGradesAsSetting.hidden = true;
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Enter Grades as')).toBeUndefined();
    });

    describe('"Points" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Points')).toBeInTheDocument();
      });

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'points';
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Points').getAttribute('aria-checked')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.enterGradesAsSetting.selected = 'percent';
          props.enterGradesAsSetting.onSelect = jest.fn();
        });

        test('calls the onSelect callback', () => {
          mountAndOpenOptionsMenu();
          getEnterGradesAsOption('Points').click();
          expect(props.enterGradesAsSetting.onSelect).toHaveBeenCalledTimes(1);
        });

        test('calls the onSelect callback with "points"', () => {
          mountAndOpenOptionsMenu();
          getEnterGradesAsOption('Points').click();
          const [selected] = props.enterGradesAsSetting.onSelect.mock.calls[0];
          expect(selected).toBe('points');
        });
      });
    });

    describe('"Percentage" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Percentage')).toBeInTheDocument();
      });

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'percent';
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Percentage').getAttribute('aria-checked')).toBe('true');
      });

      describe('when clicked', () => {
        beforeEach(() => {
          props.enterGradesAsSetting.selected = 'points';
          props.enterGradesAsSetting.onSelect = jest.fn();
          mountAndOpenOptionsMenu();
        });

        test('calls the onSelect callback', () => {
          getEnterGradesAsOption('Percentage').click();
          expect(props.enterGradesAsSetting.onSelect).toHaveBeenCalledTimes(1);
        });

        test('calls the onSelect callback with "percent"', () => {
          getEnterGradesAsOption('Percentage').click();
          const [selected] = props.enterGradesAsSetting.onSelect.mock.calls[0];
          expect(selected).toBe('percent');
        });
      });
    });

    describe('"Grading Scheme" option', () => {
      test('is present when "showGradingSchemeOption" is true', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true;
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Grading Scheme')).toBeInTheDocument();
      });

      test('is not present when "showGradingSchemeOption" is false', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = false;
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Grading Scheme')).toBeUndefined();
      });

      test('is optionally selected', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true;
        props.enterGradesAsSetting.selected = 'gradingScheme';
        mountAndOpenOptionsMenu();
        expect(getEnterGradesAsOption('Grading Scheme').getAttribute('aria-checked')).toBe('true');
      });
    });
  });

  describe('"Options" > "Download Submissions" action', () => {
    test('is present when .downloadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Download Submissions')).toBeTruthy();
    });

    test('is not present when .downloadSubmissionsAction.hidden is true', () => {
      props.downloadSubmissionsAction.hidden = true;
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Download Submissions')).toBeUndefined();
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.downloadSubmissionsAction.onSelect = jest.fn();
        mountAndOpenOptionsMenu();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Download Submissions').click();
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .downloadSubmissionsAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Download Submissions').click();
        expect(props.downloadSubmissionsAction.onSelect).toHaveBeenCalledTimes(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Download Submissions').click();
        const [callback] = props.downloadSubmissionsAction.onSelect.mock.calls[0];
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('"Options" > "Re-Upload Submissions" action', () => {
    test('is present when .reuploadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Re-Upload Submissions')).toBeTruthy();
    });

    test('is not present when .reuploadSubmissionsAction.hidden is true', () => {
      props.reuploadSubmissionsAction.hidden = true;
      mountAndOpenOptionsMenu();
      expect(getMenuItem(menuContent, 'Re-Upload Submissions')).toBeUndefined();
    });

    describe('when clicked', () => {
      beforeEach(() => {
        props.reuploadSubmissionsAction.onSelect = jest.fn();
        mountAndOpenOptionsMenu();
      });

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click();
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger());
      });

      test('calls the .reuploadSubmissionsAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click();
        expect(props.reuploadSubmissionsAction.onSelect).toHaveBeenCalledTimes(1);
      });

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click();
        const [callback] = props.reuploadSubmissionsAction.onSelect.mock.calls[0];
        callback();
        expect(document.activeElement).toBe(getOptionsMenuTrigger());
      });
    });
  });

  describe('#handleKeyDown()', () => {
    let preventDefault;

    beforeEach(() => {
      preventDefault = jest.fn();
      mountComponent();
    });

    function triggerKeyDown(element, key, shiftKey = false) {
      fireEvent.keyDown(element, {
        key,
        keyCode: key === 'Tab' ? 9 : 13,
        shiftKey,
        preventDefault,
      });
    }

    describe('when the assignment link has focus', () => {
      beforeEach(() => {
        const assignmentLink = getAssignmentLink();
        assignmentLink.focus();
      });

      test('does not handle Shift+Tab', () => {
        triggerKeyDown(getAssignmentLink(), 'Tab', true);
        expect(preventDefault).not.toHaveBeenCalled();
      });
    });

    describe('when the "Options" menu trigger has focus', () => {
      beforeEach(() => {
        const optionsTrigger = getOptionsMenuTrigger();
        optionsTrigger.focus();
      });

      test('does not handle Tab', () => {
        triggerKeyDown(getOptionsMenuTrigger(), 'Tab', false);
        expect(preventDefault).not.toHaveBeenCalled();
      });

      test('Enter opens the "Options" menu', () => {
        triggerKeyDown(getOptionsMenuTrigger(), 'Enter');
        expect(menuContent).toBeTruthy();
      });
    });

    describe('when the header does not have focus', () => {
      test('does not handle Tab', () => {
        triggerKeyDown(document.body, 'Tab', false);
        expect(preventDefault).not.toHaveBeenCalled();
      });

      test('does not handle Shift+Tab', () => {
        triggerKeyDown(document.body, 'Tab', true);
        expect(preventDefault).not.toHaveBeenCalled();
      });

      test('does not handle Enter', () => {
        triggerKeyDown(document.body, 'Enter');
        expect(preventDefault).not.toHaveBeenCalled();
      });
    });
  });

  describe('focus', () => {
    let instance;

    beforeEach(() => {
      mountComponent();
      instance = component;
    });

    afterEach(() => {
      document.body.removeChild(container);
    });

    function focusElement(element) {
      const event = new Event('focus', { bubbles: true, cancelable: true });
      element.dispatchEvent(event);
    }

    function blurElement(element) {
      const event = new Event('blur', { bubbles: true, cancelable: true });
      element.dispatchEvent(event);
    }

    test('adds the "focused" class to the header when the assignment link receives focus', () => {
      focusElement(getAssignmentLink());
      expect(container.firstChild.classList.contains('focused')).toBe(true);
    });

    test('adds the "focused" class to the header when the "Options" menu trigger receives focus', () => {
      focusElement(getOptionsMenuTrigger());
      expect(container.firstChild.classList.contains('focused')).toBe(true);
    });

    test('removes the "focused" class from the header when focus leaves', () => {
      focusElement(getOptionsMenuTrigger());
      blurElement(getOptionsMenuTrigger());
      expect(container.firstChild.classList.contains('focused')).toBe(false);
    });
  });
})
