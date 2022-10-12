/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import GradebookGrid from '../GradebookGrid/index'
import type {GradebookGridOptions} from '../GradebookGrid/index'
import CellFormatterFactory from '../GradebookGrid/formatters/CellFormatterFactory'
import ColumnHeaderRenderer from '../GradebookGrid/headers/ColumnHeaderRenderer'
import type Gradebook from '../Gradebook'
import type {GridData} from '../grid.d'

type Props = {
  gradebook: Gradebook
  gridData: GridData
  gradebookGridNode: HTMLElement
  gradebookIsEditable: boolean
  onLoad: (grid: GradebookGrid) => void
}

export default function GradebookGridComponent({
  gradebook,
  gridData,
  gradebookGridNode,
  gradebookIsEditable,
  onLoad,
}: Props) {
  useEffect(() => {
    const formatterFactory = new CellFormatterFactory(gradebook)
    const columnHeaderRenderer = new ColumnHeaderRenderer(gradebook)
    const options: GradebookGridOptions = {
      $container: gradebookGridNode,
      activeBorderColor: '#1790DF', // $active-border-color
      data: gridData,
      editable: gradebookIsEditable,
      formatterFactory,
      columnHeaderRenderer,
    }
    const gradebookGrid = new GradebookGrid(options)
    onLoad(gradebookGrid)
  }, [gradebook, gridData, gradebookGridNode, gradebookIsEditable, onLoad])

  return <></>
}
