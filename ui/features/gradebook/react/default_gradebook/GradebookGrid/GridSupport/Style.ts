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

import {direction} from '@canvas/i18n/rtlHelper'

export default class Style {
  grid: any

  gridSupport: any

  $styles: any

  constructor(grid, gridSupport) {
    this.grid = grid
    this.gridSupport = gridSupport
  }

  initialize() {
    this.$styles = document.createElement('style')
    this.$styles.id = `GridSupport__Styles--${this.grid.getUID()}`
    document.body.appendChild(this.$styles)

    this.gridSupport.events.onActiveLocationChanged.subscribe((_event, location) => {
      this.updateClassesForActiveLocation(location)
    })
  }

  destroy() {
    if (this.$styles) {
      this.$styles.remove()
      this.$styles = null
    }
  }

  updateClassesForActiveLocation(location) {
    if (location.region === 'header') {
      this.buildClassesForHeader(location)
    } else if (location.region === 'body') {
      this.buildClassesForBody(location)
    } else {
      this.$styles.innerHTML = ''
    }
  }

  buildClassesForHeader(location) {
    const {options} = this.gridSupport
    this.$styles.innerHTML = `
      .slick-header .slick-header-column.${location.columnId} {
        border: 1px solid ${options.activeBorderColor};
        padding-${direction('left')}: 0;
      }
      .slick-row .slick-cell.${location.columnId} {
        border-left: 1px solid ${options.activeBorderColor};
        border-right: 1px solid ${options.activeBorderColor};
      }
      .slick-row.last-row .slick-cell.${location.columnId} {
        border-bottom: 1px solid ${options.activeBorderColor};
      }
    `
  }

  buildClassesForBody(location) {
    const {options} = this.gridSupport
    this.$styles.innerHTML = `
      .slick-header .slick-header-column.${location.columnId}:not(.primary-column) {
        border: 1px solid ${options.activeBorderColor};
        padding-${direction('left')}: 0;
      }
      .slick-cell.${location.columnId}:not(.primary-column):not(.active) {
        border-left: 1px solid ${options.activeBorderColor};
        border-right: 1px solid ${options.activeBorderColor};
      }
      .slick-row.last-row .slick-cell.${location.columnId}:not(.primary-column):not(.active) {
        border-bottom: 1px solid ${options.activeBorderColor};
      }
    `
  }
}
