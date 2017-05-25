/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import Events from 'jsx/gradezilla/default_gradebook/slick-grid/grid-support/Events';
import GridHelper from 'jsx/gradezilla/default_gradebook/slick-grid/grid-support/GridHelper';
import Navigation from 'jsx/gradezilla/default_gradebook/slick-grid/grid-support/Navigation';
import State from 'jsx/gradezilla/default_gradebook/slick-grid/grid-support/State';

export default class GridSupport {
  constructor (grid) {
    this.grid = grid;

    this.events = new Events();
    this.state = new State(grid, this);
    this.navigation = new Navigation(grid, this);
    this.helper = new GridHelper(grid);
  }

  initialize () {
    this.state.initialize();
    this.navigation.initialize();
  }
}
