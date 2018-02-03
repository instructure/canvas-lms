/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import { DropTarget, DragSource } from 'react-dnd'
import compose from '../shared/helpers/compose'
import ItemTypes from './Types'
import DashboardCard from './DashboardCard'
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
export default compose(
    DropTarget(ItemTypes.CARD, cardTarget, connect => ({
      connectDropTarget: connect.dropTarget()
    })),
    DragSource(ItemTypes.CARD, cardSource, (connect, monitor) => ({
      connectDragSource: connect.dragSource(),
      isDragging: monitor.isDragging()
    }))
  )(DashboardCard);
  /* eslint-enable new-cap */
