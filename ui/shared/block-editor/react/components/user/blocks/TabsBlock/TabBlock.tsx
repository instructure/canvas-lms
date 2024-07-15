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
import {Container} from '../Container'
import {NoSections} from '../../common'
import {useClassNames} from '../../../../utils'

type TabBlockProps = {
  tabId: string
}

const TabBlock = ({tabId}: TabBlockProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('tab-block')
  const clazz = useClassNames(enabled, {empty: false}, ['block', 'tab-block'])
  return (
    <Container id={tabId} className={clazz}>
      <Element
        id={`${cid}_nosection1`}
        is={NoSections}
        canvas={true}
        className="tab-block__inner"
      />
    </Container>
  )
}

TabBlock.craft = {
  displayName: 'Tab',
  custom: {
    noToolbar: true,
  },
}

export {TabBlock}
