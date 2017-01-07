define([
  'react',
  'react-addons-test-utils',
  'jsx/dashboard_card/DashboardCardMovementMenu',
], (React, TestUtils, DashboardCardMovementMenu) => {
  module('DashboardCardMovementMenu');

  test('it calls handleMove properly', () => {
    const handleMoveSpy = sinon.spy();
    const props = {
      assetString: 'course_1',
      cardTitle: 'Strategery 101',
      handleMove: handleMoveSpy,
      menuOptions: {
        canMoveLeft: true,
        canMoveRight: true,
        canMoveToBeginning: true,
        canMoveToEnd: true
      }
    }
    const menu = TestUtils.renderIntoDocument(
      <DashboardCardMovementMenu {...props} />
    );

    // handleMoveCard returns a function that's the actual handler.
    menu.handleMoveCard(2)();

    ok(handleMoveSpy.calledWith('course_1', 2));
  });
});
