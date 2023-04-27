// @ts-nocheck
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

import Columns from './Columns'
import Events from './Events'
import GridHelper from './GridHelper'
import Navigation from './Navigation'
import State from './State'
import Style from './Style'
import slickgrid from 'slickgrid'
import type ColumnHeaderRenderer from '../headers/ColumnHeaderRenderer'

export type GridSupportOptions = {
  activeBorderColor?: string
  columnHeaderRenderer?: ColumnHeaderRenderer
  rows: any[]
}

export default class GridSupport {
  grid: slickgrid.Grid

  options: GridSupportOptions

  events: Events

  helper: GridHelper

  columns: Columns

  state: State

  navigation: Navigation

  style: Style

  constructor(
    grid: slickgrid.Grid,
    options: GridSupportOptions = {rows: [], activeBorderColor: ''}
  ) {
    this.grid = grid
    this.options = options

    this.events = new Events()
    this.helper = new GridHelper(grid)

    this.columns = new Columns(grid, this)
    this.state = new State(grid, this)
    this.navigation = new Navigation(grid, this)
    this.style = new Style(grid, this)
  }

  initialize() {
    this.columns.initialize()
    this.state.initialize()
    this.navigation.initialize()
    this.style.initialize()
  }

  destroy() {
    this.style.destroy()
  }
}
