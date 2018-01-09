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

import { DragDropContext, DropTarget } from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import compose from '../shared/helpers/compose'
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
