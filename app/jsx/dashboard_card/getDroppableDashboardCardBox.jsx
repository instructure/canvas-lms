define([
  'react-dnd',
  'react-dnd-html5-backend',
  'jsx/shared/helpers/compose',
  './Types',
  './DashboardCardBox'
], ({ DragDropContext, DropTarget }, ReactDnDHTML5Backend, compose, ItemTypes, DashboardCardBox) => {
  const cardTarget = {
    drop () {}
  };

  const getDroppableDashboardCardBox = (backend = ReactDnDHTML5Backend) => (
    /* eslint-disable new-cap */
    compose(
      DragDropContext(backend),
      DropTarget(ItemTypes.CARD, cardTarget, connect => ({
        connectDropTarget: connect.dropTarget()
      }))
    )(DashboardCardBox)
    /* eslint-enable new-cap */
  );

  return getDroppableDashboardCardBox;
});
