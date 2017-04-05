import { DragDropContext, DropTarget } from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import compose from 'jsx/shared/helpers/compose'
import ItemTypes from './Types'
import DashboardCardBox from './DashboardCardBox'
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

export default getDroppableDashboardCardBox
