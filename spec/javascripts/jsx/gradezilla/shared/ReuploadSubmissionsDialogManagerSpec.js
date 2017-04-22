define([
  'jsx/gradezilla/shared/ReuploadSubmissionsDialogManager'
], (ReuploadSubmissionsDialogManager) => {
  QUnit.module('ReuploadSubmissionsDialogManager#constructor');

  test('constructs reupload url from given assignment data and url template', () => {
    const manager = new ReuploadSubmissionsDialogManager({
      id: 'the_id'
    }, 'the_{{ assignment_id }}_url');

    strictEqual(manager.reuploadUrl, 'the_the_id_url');
  });

  QUnit.module('ReuploadSubmissionsDialogManager#isDialogEnabled');

  test('returns true when assignment submssions have been downloaded', () => {
    const manager = new ReuploadSubmissionsDialogManager(
      { hasDownloadedSubmissions: true },
      'the_url'
    );

    strictEqual(manager.isDialogEnabled(), true);
  });

  test('returns false when assignment submssions have not been downloaded', () => {
    const manager = new ReuploadSubmissionsDialogManager(
      { hasDownloadedSubmissions: true },
      'the_url'
    );

    strictEqual(manager.isDialogEnabled(), true);
  });

  QUnit.module('ReuploadSubmissionsDialogManager#showDialog');

  test('sets form action to reupload url', function () {
    const manager = new ReuploadSubmissionsDialogManager({
      id: 'the_id'
    }, 'the_{{ assignment_id }}_url');
    const dialog = this.stub();
    const attr = this.stub().returns({ dialog });
    this.stub(manager, 'getReuploadForm').returns({ attr });
    manager.showDialog();

    ok(attr.calledWith('action', 'the_the_id_url'));
  });

  test('opens dialog', function () {
    const manager = new ReuploadSubmissionsDialogManager({
      id: 'the_id'
    }, 'the_{{ assignment_id }}_url');
    const dialog = this.stub();
    const attr = this.stub().returns({ dialog });
    this.stub(manager, 'getReuploadForm').returns({ attr });
    manager.showDialog();

    strictEqual(dialog.callCount, 1);
  });
});
