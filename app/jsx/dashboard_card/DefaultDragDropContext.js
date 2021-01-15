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

import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import {DragDropContext} from 'react-dnd'

// Exporting as a separate module prevents the HTML5 backend from being
// reinitialized multiple times if the consuming component is re-rendered.
// This allows the Dashboard card components to be reused in more places,
// and consumers can still pass in a custom context using a different backend
// if they want. See https://github.com/react-dnd/react-dnd/issues/186.
export default DragDropContext(ReactDnDHTML5Backend)
