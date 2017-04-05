define([
  'jsx/gradezilla/shared/AssignmentMuterDialogManager',
  'compiled/AssignmentMuter'
], (AssignmentMuterDialogManager, AssignmentMuter) => {
  const assignment = { foo: 'bar' };
  const url = 'http://example.com';

  QUnit.module('AssignmentMuterDialogManager - constructor');

  test('sets the arguments as properties', function () {
    [true, false].forEach((submissionsLoaded) => {
      const manager = new AssignmentMuterDialogManager(assignment, url, submissionsLoaded);
      equal(manager.assignment, assignment);
      equal(manager.url, url);
      equal(manager.submissionsLoaded, submissionsLoaded);
    });
  });

  QUnit.module('AssignmentMuterDialogManager - showDialog');

  test('when assignment is muted calls AssignmentMuter.confirmUnmute', function () {
    const confirmUnmuteSpy = this.spy(AssignmentMuter.prototype, 'confirmUnmute');
    assignment.muted = true;
    const manager = new AssignmentMuterDialogManager(assignment, url, true);
    manager.showDialog();

    equal(confirmUnmuteSpy.callCount, 1);
  });

  test('when assignment is not muted calls AssignmentMuter.showDialog', function () {
    const showDialogSpy = this.spy(AssignmentMuter.prototype, 'showDialog');
    assignment.muted = false;
    const manager = new AssignmentMuterDialogManager(assignment, url, true);
    manager.showDialog();

    equal(showDialogSpy.callCount, 1);
  });

  QUnit.module('AssignmentMuterDialogManager - isDialogEnabled');

  test('return value agrees with submissionsLoaded value', function () {
    [true, false].forEach((submissionsLoaded) => {
      const manager = new AssignmentMuterDialogManager(assignment, url, submissionsLoaded);
      equal(manager.isDialogEnabled(), submissionsLoaded);
    });
  });
});
