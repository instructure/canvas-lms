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
import {NoSections} from '../../common'
import {Container} from '../../blocks/Container'
import {SectionMenu} from '../../../editor/SectionMenu'
import {useClassNames} from '../../../../utils'

export const BlankSection = () => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('blank-section') // uid('columns-section', 2)
  const clazz = useClassNames(enabled, {empty: false}, ['section', 'blank-section'])

  return (
    <Container className={clazz}>
      <Element
        id={`${cid}_nosection1`}
        is={NoSections}
        canvas={true}
        className="blank-section__inner"
      />
    </Container>
  )
}

BlankSection.craft = {
  displayName: 'Blank Section',
  custom: {
    isSection: true,
  },
  related: {
    sectionMenu: SectionMenu,
  },
}
