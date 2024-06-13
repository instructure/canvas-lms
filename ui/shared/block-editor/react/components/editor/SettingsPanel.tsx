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

// components/SettingsPanel.js
import React from 'react'
import {useEditor} from '@craftjs/core'

import {Pill} from '@instructure/ui-pill'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'

type SelectedNodeData = {
  id: string
  name: string
  settings: React.ElementType<any> | null
  isDeletable: boolean
}

export const SettingsPanel = () => {
  const {actions, selected} = useEditor((state, query) => {
    let selectedData: SelectedNodeData | undefined

    let [currentNodeId] = state.events.selected

    // to constrain the types of components that can be dropped into a container component
    // we have to create a Container with a child component that holds the craft.rules
    // constraints. When the user selects it in the UI, we get the child as currentNodeId.
    // In this case isDeletable() returns false because it's a "linked"
    // As a convention, we set craft.custom.innerNode=true in the child.
    // If the child is selected, we use its parent as current Node.
    if (currentNodeId) {
      let currentNode = query.node(currentNodeId).get()
      if (currentNode.data.custom.isInnerNode === true && currentNode.data.parent) {
        currentNodeId = currentNode.data.parent
        currentNode = query.node(currentNodeId).get()
      }

      if (currentNode) {
        selectedData = {
          id: currentNodeId,
          name:
            currentNode.data.custom?.displayName ||
            currentNode.data.displayName ||
            currentNode.data.name,
          settings: currentNode.related && currentNode.related.settings,
          isDeletable: query.node(currentNodeId).isDeletable(),
        }
      }
    }

    return {
      selected: selectedData,
    }
  })

  return selected ? (
    <View
      as="div"
      background="secondary"
      padding="small"
      minWidth="320px"
      borderWidth="0 0 0 small"
      className="settings-panel"
    >
      <Flex direction="column" gap="small" alignItems="center">
        <Pill color="success" margin="0 0 small 0">
          {selected.name}
        </Pill>
        {selected.settings && React.createElement(selected.settings)}
        {selected.isDeletable ? (
          <Button color="danger" margin="small 0 0 0" onClick={() => actions.delete(selected.id)}>
            Delete
          </Button>
        ) : null}
      </Flex>
    </View>
  ) : null
}
