define([
  'react',
  'compiled/views/rubrics/EditRubricPage',
], (React, EditRubricPage) => {
  QUnit.module('RubricEdit');

  test('does not immediately create the dialog', () => {
    const clickSpy = sinon.spy(EditRubricPage.prototype, 'attachInitialEvent')
    const dialogSpy = sinon.spy(EditRubricPage.prototype, 'createDialog')

    new EditRubricPage();

    ok(clickSpy.called, 'sets up the initial click event')
    ok(dialogSpy.notCalled, 'does not immediately create the dialog')
    clickSpy.restore()
    dialogSpy.restore()
  });
});
