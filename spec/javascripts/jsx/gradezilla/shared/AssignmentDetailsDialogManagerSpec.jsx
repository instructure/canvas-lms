define([
  'compiled/AssignmentDetailsDialog',
  'jsx/gradezilla/shared/AssignmentDetailsDialogManager',
], (AssignmentDetailsDialog, AssignmentDetailsDialogManager) => {
  function createAssignmentProp () {
    return {
      id: '1',
      htmlUrl: 'http://assignment_htmlUrl',
      invalid: false,
      muted: false,
      name: 'Assignment #1',
      omitFromFinalGrade: false,
      pointsPossible: 13,
      submissionTypes: ['online_text_entry'],
      courseId: '42'
    }
  }

  function createStudentsProp () {
    return [
      {
        id: '11',
        name: 'Clark Kent',
        isInactive: false,
        submission: {
          score: 7,
          submittedAt: null
        }
      },
      {
        id: '13',
        name: 'Barry Allen',
        isInactive: false,
        submission: {
          score: 8,
          submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
        }
      },
      {
        id: '15',
        name: 'Bruce Wayne',
        isInactive: false,
        submission: {
          score: undefined,
          submittedAt: undefined
        }
      }
    ];
  }

  QUnit.module('AssignmentDetailsDialogManager#isDialogEnabled');

  test('returns true when submissions are loaded', function () {
    const manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), true);

    ok(manager.isDialogEnabled());
  });

  test('returns false when submissions are not loaded', function () {
    const manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), false);

    notOk(manager.isDialogEnabled());
  });

  QUnit.module('AssignmentDetailsDialogManager#showDialog', {
    setup () {
      this.manager = new AssignmentDetailsDialogManager(createAssignmentProp(), createStudentsProp(), true);
    }
  });

  test('calls show() on the AssignmentDetailsDialog', function () {
    const stubbedShow = this.stub(AssignmentDetailsDialog.prototype, 'show');
    this.manager.showDialog();

    ok(stubbedShow.called);
  });
});
