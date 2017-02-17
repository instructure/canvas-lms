define([
  'react-dnd',
  'jsx/shared/helpers/compose',
  './Types',
  './DashboardCard'
], ({ DropTarget, DragSource }, compose, ItemTypes, DashboardCard) => {
  const cardSource = {
    beginDrag(props) {
      return {
        assetString: props.assetString,
        originalIndex: props.currentIndex
      };
    },
    isDragging(props, monitor) {
      return monitor.getItem().assetString === props.assetString;
    },
    endDrag(props, monitor) {
      const { assetString: draggedAssetString } = monitor.getItem();
      if (!monitor.didDrop()) {
        props.moveCard(draggedAssetString, props.position);
      }
      // TODO: Call something to actually move things to the right positions on the server
    }
  };

  const cardTarget = {
    canDrop() {
      return false;
    },
    hover(props, monitor) {
      const { assetString: draggedAssetString } = monitor.getItem();
      const { assetString: overAssetString } = props;
      if (draggedAssetString !== overAssetString) {
        const { currentIndex: overIndex } = props;
        props.moveCard(draggedAssetString, overIndex);
      }
    }
  };

  /* eslint-disable new-cap */
  return compose(
    DropTarget(ItemTypes.CARD, cardTarget, connect => ({
      connectDropTarget: connect.dropTarget()
    })),
    DragSource(ItemTypes.CARD, cardSource, (connect, monitor) => ({
      connectDragSource: connect.dragSource(),
      isDragging: monitor.isDragging()
    }))
  )(DashboardCard);
  /* eslint-enable new-cap */
});
