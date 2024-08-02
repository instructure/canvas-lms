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
import {Element, useEditor} from '@craftjs/core'

import {Container} from '../../blocks/Container'
import {NoSections} from '../../common'
import {ColumnsSectionToolbar} from './ColumnsSectionToolbar'
import {useClassNames} from '../../../../utils'
import {SectionMenu} from '../../../editor/SectionMenu'
import {type ColumnsSectionProps} from './types'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor/columns-section')

export const ColumnsSection = ({columns, variant}: ColumnsSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('columns-section') // uid('columns-section', 2)
  const clazz = useClassNames(enabled, {empty: false}, [
    'section',
    'columns-section',
    variant || ColumnsSection.craft.defaultProps.variant,
    `columns-${columns}`,
  ])

  const renderCols = () => {
    if (variant === 'fixed') {
      const cols: JSX.Element[] = []
      for (let i = 0; i < columns; i++) {
        cols.push(
          <Element
            key={`${cid}-${i}`}
            id={`${cid}-${i}`}
            is={NoSections}
            canvas={true}
            className="columns-section__inner"
          />
        )
      }
      return cols
    } else {
      return <Element id={cid} is={NoSections} canvas={true} className="columns-section__inner" />
    }
  }

  return <Container className={clazz}>{renderCols()}</Container>
}

ColumnsSection.craft = {
  displayName: I18n.t('Columns'),
  defaultProps: {
    columns: 2,
    variant: 'fixed',
  },
  custom: {
    isSection: true,
  },
  related: {
    toolbar: ColumnsSectionToolbar,
    sectionMenu: SectionMenu,
  },
}
