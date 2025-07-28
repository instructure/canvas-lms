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
import {useNode, type Node} from '@craftjs/core'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {AddMediaButton} from './AddMediaButton'
import {useScope as createI18nScope} from '@canvas/i18n'
import BlockEditorVideoOptionsTray from './BlockEditorVideoOptionsTray'

const I18n = createI18nScope('block-editor')

const MediaBlockToolbar = () => {
  const {
    actions: {setProp},
    node,
  } = useNode((n: Node) => ({
    node: n,
    props: n.data.props,
  }))

  const [openTray, setOpenTray] = useState(false)

  return (
    <Flex gap="small">
      <AddMediaButton setProp={setProp} />
      <Button
        color="primary"
        onClick={() => {
          setOpenTray(true)
        }}
        size="small"
        withBackground={false}
      >
        {I18n.t('Media Options')}
      </Button>
      <BlockEditorVideoOptionsTray
        setProp={setProp}
        open={openTray}
        setOpenTray={setOpenTray as (args: boolean) => void}
        node={node}
      />
    </Flex>
  )
}

export {MediaBlockToolbar}
