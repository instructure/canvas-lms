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

/*
 * MIT License
 *
 * Copyright (c) 2020 Previnash Wong Sze Chuan
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import React, {useCallback, useEffect, useState} from 'react'
import ReactDOM from 'react-dom'
import {useNode, useEditor, type Node} from '@craftjs/core'

import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {type AddSectionPlacement, type RenderNodeProps} from './types'
import {TemplateEditor} from '../../types'
import {SectionBrowser} from './SectionBrowser'
import {mountNode} from '../../utils'
import {BlockResizer} from './BlockResizer'
import {
  getToolbarPos as getToolbarPosUtil,
  getMenuPos as getMenuPosUtil,
  findUpNode,
  findContainingSection,
} from '../../utils/renderNodeHelpers'
import {BlockToolbar} from './BlockToolbar'

interface RenderNodeComponent extends React.FC<RenderNodeProps> {
  globals: {
    selectedSectionId: string
    enableResizer: boolean
    templateEditor: TemplateEditor
  }
}

export const RenderNode: RenderNodeComponent = ({render}: RenderNodeProps) => {
  const {actions, query} = useEditor(state => {
    if (state.events.selected.size === 0) {
      RenderNode.globals.selectedSectionId = ''
    }
  })
  const {hovered, selected, node, name} = useNode((n: Node) => {
    return {
      node: n,
      hovered: n.events.hovered,
      selected: n.events.selected,
      name: n.data.custom.displayName || n.data.displayName,
      props: n.data.props,
    }
  })

  const [currentToolbarOrTagRef, setCurrentToolbarOrTagRef] = useState<HTMLDivElement | null>(null)
  const [currentMenuRef, setCurrentMenuRef] = useState<HTMLDivElement | null>(null)
  const [sectionBrowserOpen, setSectionBrowserOpen] = useState<AddSectionPlacement>(undefined)
  const [mountPoint, setMountPoint] = useState(mountNode())

  useEffect(() => {
    if (mountPoint === null) {
      setMountPoint(mountNode())
    }
  }, [mountPoint])

  // TODO: this commented out code is what implenents the click-once for section, again for the block
  // useEffect(() => {
  //   // get a newly dropped block selected
  //   // select once will select it's section
  //   // select again to get the block
  //   // (see the following useEffect for details)
  //   if (node.id !== 'ROOT') {
  //     actions.selectNode(node.id)
  //     requestAnimationFrame(() => {
  //       actions.selectNode(node.id)
  //     })
  //   }
  //   // eslint-disable-next-line react-hooks/exhaustive-deps
  // }, [])

  // // first click/select on a block will select its parent section
  // // if the section is selected, a click on a block will select the block
  // useEffect(() => {
  //   if (selected) {
  //     const parentSection = findContainingSection(node, query)
  //     if (parentSection) {
  //       const isMySectionSelected = RenderNode.globals.selectedSectionId === parentSection.id
  //       if (!isMySectionSelected) {
  //         RenderNode.globals.selectedSectionId = parentSection.id
  //         actions.selectNode(parentSection.id)
  //       } else if (node.data.custom?.noToolbar) {
  //         const upnode = findUpNode(node, query)
  //         if (upnode) {
  //           actions.selectNode(upnode.id)
  //         }
  //       }
  //     }
  //   }
  // }, [actions, node, nodeActions, query, selected])

  // TODO: while this gets newly dropped blocks selected,
  //       it interferes with kb nav selenium tests
  //       To get tests written, comment this out, return to figure
  //       out block focusing
  // useEffect(() => {
  //   // get a newly dropped block selected
  //   if (node.id !== 'ROOT') {
  //     actions.selectNode(node.id)
  //   }
  //   // eslint-disable-next-line react-hooks/exhaustive-deps
  // }, [])

  // the next 2 useEffects implemnt click just once to select the block
  useEffect(() => {
    if (selected && node.data.custom?.noToolbar) {
      const upnode = findUpNode(node, query)
      if (upnode && upnode.id !== node.id) {
        actions.selectNode(upnode.id)
      }
    }
  }, [actions, node, query, selected])

  useEffect(() => {
    if (node.dom) {
      if (selected) node.dom.classList.add('selected')
      else node.dom.classList.remove('selected')

      if (hovered) node.dom.classList.add('hovered')
      else node.dom.classList.remove('hovered')
    }
  }, [hovered, node.dom, selected])

  const getToolbarPos = useCallback(
    (includeOffset: boolean = true) => {
      return getToolbarPosUtil(node.dom, mountPoint, currentToolbarOrTagRef, includeOffset)
    },
    [currentToolbarOrTagRef, node.dom, mountPoint]
  )

  const getMenuPos = useCallback(() => {
    const {top, left} = getMenuPosUtil(node.dom, mountPoint, currentMenuRef)
    return {top: `${top}px`, left: `${left}px`}
  }, [currentMenuRef, node.dom, mountPoint])

  const renderBlockToolbar = () => {
    return ReactDOM.createPortal(
      <BlockToolbar templateEditor={RenderNode.globals.templateEditor} />,
      mountPoint
    )
  }

  const handleAddSection = useCallback((where: AddSectionPlacement) => {
    setSectionBrowserOpen(where)
  }, [])

  const renderSectionMenu = useCallback(() => {
    if (!mountPoint) return null
    if (node.related?.sectionMenu) {
      const {left, top} = getMenuPos()

      return ReactDOM.createPortal(
        <div
          ref={(el: HTMLDivElement) => setCurrentMenuRef(el)}
          className="section-menu"
          style={{left, top}}
        >
          {React.createElement(node.related.sectionMenu, {onAddSection: handleAddSection})}
        </div>,
        mountPoint
      )
    }
    return null
  }, [getMenuPos, handleAddSection, mountPoint, node.related.sectionMenu])

  const renderHoverTag = () => {
    if (node.data?.custom?.noToolbar) return null

    const parentSection = findContainingSection(node, query)
    if (!parentSection) return null

    const isMySectionSelected = RenderNode.globals.selectedSectionId === parentSection.id
    if (!isMySectionSelected) return null

    if (!mountPoint) return null

    const {left, top} = getToolbarPos()
    return ReactDOM.createPortal(
      <div
        ref={(el: HTMLDivElement) => setCurrentToolbarOrTagRef(el)}
        className="block-tag"
        style={{
          left: `${left}px`,
          top: `${top}px`,
        }}
      >
        <View as="div" background="secondary" padding="0 xx-small" borderRadius="small">
          <Text size="small">{name}</Text>
        </View>
      </div>,
      mountPoint
    )
  }

  const renderResizer = () => {
    if (!mountPoint) return null

    return ReactDOM.createPortal(<BlockResizer mountPoint={mountPoint} />, mountPoint)
  }

  const renderRelated = () => {
    return (
      <>
        {renderBlockToolbar()}
        {renderSectionMenu()}
      </>
    )
  }

  const renderSectionAdder = () => {
    return (
      !!sectionBrowserOpen && (
        <SectionBrowser
          open={true}
          onClose={() => setSectionBrowserOpen(undefined)}
          where={sectionBrowserOpen}
        />
      )
    )
  }

  return (
    <>
      {!selected && hovered && renderHoverTag()}
      {selected && node.related && renderRelated()}
      {RenderNode.globals.enableResizer &&
        selected &&
        node.data.custom?.isResizable &&
        renderResizer()}
      {render}
      {node.data.custom?.isSection && renderSectionAdder()}
    </>
  )
}

RenderNode.globals = {
  selectedSectionId: '',
  enableResizer: true,
  templateEditor: TemplateEditor.NONE,
}
