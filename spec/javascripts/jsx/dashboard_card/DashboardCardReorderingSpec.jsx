define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'react-dnd',
  'react-dnd-test-backend',
  'jsx/dashboard_card/DraggableDashboardCard',
  'jsx/dashboard_card/getDroppableDashboardCardBox',
  'jsx/dashboard_card/DashboardCardBox',
  'jsx/dashboard_card/DashboardCard',
  'jsx/dashboard_card/DashboardCardMovementMenu',
  'helpers/fakeENV'
], (React, ReactDOM, TestUtils, { DragDropContext }, ReactDndTestBackend, DraggableDashboardCard, getDroppableDashboardCardBox, DashboardCardBox, DashboardCard, DashboardCardMovementMenu, fakeENV) => {
  let cards;
  let fakeServer;

  QUnit.module('DashboardCard Reordering', {
    setup () {
      fakeENV.setup({
        DASHBOARD_REORDERING_ENABLED: true
      });

      cards = [{
        id: 1,
        assetString: 'course_1',
        position: 0,
        originalName: 'Intro to Dashcards 1',
        shortName: 'Dash 101'
      }, {
        id: 2,
        assetString: 'course_2',
        position: 1,
        originalName: 'Intermediate Dashcarding',
        shortName: 'Dash 201'
      }, {
        id: 3,
        assetString: 'course_3',
        originalName: 'Advanced Dashcards',
        shortName: 'Dash 301'
      }];

      fakeServer = sinon.fakeServer.create();
    },
    teardown () {
      fakeENV.teardown();
      cards = null;
      fakeServer.restore();
    }
  });

  test('it renders', () => {
    const Box = getDroppableDashboardCardBox()
    const root = TestUtils.renderIntoDocument(
      <Box reorderingEnabled courseCards={cards} />
    );
    ok(root);
  });

  test('cards have opacity of 0 while moving', () => {
    const Card = DraggableDashboardCard.DecoratedComponent.DecoratedComponent;
    const card = TestUtils.renderIntoDocument(
      <Card
        {...cards[0]}
        connectDragSource={el => el}
        connectDropTarget={el => el}
        isDragging
        reorderingEnabled
      />
    );
    const div = TestUtils.findRenderedDOMComponentWithClass(card, 'ic-DashboardCard')
    equal(div.style.opacity, 0);
  });

  test('moving a card adjusts the position property', () => {
    const Box = getDroppableDashboardCardBox(ReactDndTestBackend);
    const root = TestUtils.renderIntoDocument(
      <Box
        reorderingEnabled
        courseCards={cards}
        connectDropTarget={el => el}
      />
    );

    const backend = root.getManager().getBackend();
    const renderedCardComponents = TestUtils.scryRenderedComponentsWithType(root, DraggableDashboardCard);
    const sourceHandlerId = renderedCardComponents[0].getDecoratedComponentInstance().getHandlerId();
    const targetHandlerId = renderedCardComponents[1].getHandlerId();

    backend.simulateBeginDrag([sourceHandlerId]);
    backend.simulateHover([targetHandlerId]);
    backend.simulateDrop();

    const renderedAfterDragNDrop = TestUtils.scryRenderedDOMComponentsWithClass(root, 'ic-DashboardCard');
    equal(renderedAfterDragNDrop[0].getAttribute('aria-label'), 'Intermediate Dashcarding');
    equal(renderedAfterDragNDrop[1].getAttribute('aria-label'), 'Intro to Dashcards 1');
  });

  test('DashboardCard renders a DashboardCardMovementMenu when reordering is enabled', () => {
    const props = cards[0];
    const card = TestUtils.renderIntoDocument(
      <DashboardCard
        connectDragSource={el => el}
        connectDropTarget={el => el}
        reorderingEnabled
        {...props}
      />
    );

    const menuComponent = TestUtils.findRenderedComponentWithType(card, DashboardCardMovementMenu);
    ok(menuComponent);
  });
});
