/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Element, useEditor, useNode, type Node} from '@craftjs/core'

import {Container} from '../../blocks/Container'
import {NoSections, type ColumnSectionVariant} from './NoSections'
import {ColumnsSectionSettings} from './ColumnsSectionSettings'
import {useClassNames} from '../../../../utils'

type ColumnsSectionProps = {
  columns: number
  variant?: ColumnSectionVariant
}

export const ColumnsSection = ({columns = 2, variant = 'fixed'}: ColumnsSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('columns-section') // uid('columns-section', 2)
  const clazz = useClassNames(enabled, {empty: false}, ['section', 'columns-section', variant])

  const renderCols = () => {
    if (variant === 'fixed') {
      const cols = []
      for (let i = 0; i < columns; i++) {
        cols.push(
          <Element
            key={`${cid}-${i}`}
            id={`${cid}-${i}`}
            is={NoSections}
            canvas={true}
            columns={columns}
            variant="fixed"
            className="columns-section__inner"
          />
        )
      }
      return cols
    } else {
      return (
        <Element
          id={cid}
          is={NoSections}
          canvas={true}
          columns={columns}
          variant="fluid"
          className="columns-section__inner"
        />
      )
    }
  }

  return (
    <Container className={clazz} style={{gridTemplateColumns: `repeat(${columns}, 1fr)`}}>
      {renderCols()}
    </Container>
  )
}

ColumnsSection.craft = {
  displayName: 'Columns',
  defaultProps: {
    columns: 2,
    variant: 'fixed',
  },
  custom: {
    isSection: true,
  },
  related: {
    settings: ColumnsSectionSettings,
  },
}
