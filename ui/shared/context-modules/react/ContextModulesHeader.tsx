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

import React, {useEffect, useState} from 'react'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Button, IconButton} from '@instructure/ui-buttons'
import {
  IconAddLine,
  IconMoreLine,
  IconArrowOpenDownLine,
  IconExportLine,
} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Menu, MenuItem} from '@instructure/ui-menu'
import {Responsive, ResponsivePropsObject, QueriesMatching} from '@instructure/ui-responsive'

import ContextModulesPublishMenu from './ContextModulesPublishMenu'
import {
  setExpandAllButton,
  setExpandAllButtonHandler,
  resetExpandAllButtonBindings,
  openExternalTool,
} from '../jquery/utils'

type MenuToolsProps = {
  items: [
    {
      href: string
      'data-tool-id': number
      'data-tool-launch-type': string
      class: string
      icon: string
      title: string
    }
  ]
  visible: boolean
}

type ExportCourseContentProps = {
  label: string
  url: string
  visible: boolean
}

type PublishMenuProps = {
  courseId: string
  runningProgressId: string
  disabled: boolean
  visible: boolean
}

type Props = {
  title: string
  publishMenu: PublishMenuProps
  viewProgress: {
    label: string
    url: string
    visible: boolean
  }
  expandCollapseAll: {
    label: string
    dataUrl: string
    dataExpand: boolean
    ariaExpanded: boolean
    ariaLabel: string
  }
  addModule: {
    label: string
    visible: boolean
  }
  moreMenu: {
    label: string
    menuTools: MenuToolsProps
    exportCourseContent: ExportCourseContentProps
  }
  lastExport: {
    label: string
    url: string
    date: string
    visible: boolean
  }
}

type ContentProps = Props & {
  responsive: {
    props: ResponsivePropsObject
    matches: QueriesMatching
  }
}

type MoreMenuProps = {
  component: React.ReactNode
  items: {
    menuTools: MenuToolsProps
    exportCourseContent: ExportCourseContentProps
  }
}

const ContextModulesHeaderMoreMenu = ({component, items}: MoreMenuProps) => {
  const onClickToolHandler = (e, tool) => {
    e.target.href = tool.href
    e.target.dataset.toolId = tool['data-tool-id']
    e.target.dataset.toolLaunchType = tool['data-tool-launch-type']
    openExternalTool(e)
  }

  return (
    <Menu placement="bottom" trigger={component}>
      {items.exportCourseContent.visible && [
        <MenuItem
          key="export"
          href={items.exportCourseContent.url}
          id="context_modules_header_more_menu_export"
        >
          <IconExportLine /> {items.exportCourseContent.label}
        </MenuItem>,
        items.menuTools.visible && <Menu.Separator key="separator" />,
      ]}
      {items.menuTools.visible &&
        items.menuTools.items.map(tool => {
          return (
            <MenuItem key={tool.href} onClick={e => onClickToolHandler(e, tool)}>
              {tool.icon && <span dangerouslySetInnerHTML={{__html: tool.icon}} />} {tool.title}
            </MenuItem>
          )
        })}
    </Menu>
  )
}

const ContextModulesHeaderContent = ({responsive, ...props}: ContentProps) => {
  const [publishMenu, setPublishMenu] = useState<PublishMenuProps>(props.publishMenu)

  useEffect(() => {
    setExpandAllButton()
    setExpandAllButtonHandler()
  })

  useEffect(() => {
    window.addEventListener('update-publish-menu-disabled-state', ((e: CustomEvent) => {
      setPublishMenu((prev: PublishMenuProps) => ({
        ...prev,
        disabled: e.detail.disabled,
      }))
      // eslint-disable-next-line no-undef
    }) as EventListener)
  }, [])

  resetExpandAllButtonBindings()
  return (
    <>
      <Flex
        margin="0 0 medium"
        as="div"
        direction={responsive.props.direction}
        withVisualDebug={false}
        alignItems="stretch"
      >
        <Flex.Item
          shouldGrow={true}
          shouldShrink={false}
          margin={responsive.matches.includes('large') ? '0' : '0 0 medium 0'}
        >
          <Heading level="h1" margin="0 0 small 0">
            {props.title}
          </Heading>
          {props.lastExport.visible && (
            <Link href={props.lastExport.url}>
              {props.lastExport.label} {props.lastExport.date}
            </Link>
          )}
        </Flex.Item>

        <Flex.Item
          overflowY="visible"
          margin={responsive.matches.includes('large') ? 'x-small 0 0 0' : '0'}
        >
          <Flex
            gap="small"
            withVisualDebug={false}
            direction={responsive.matches.includes('small') ? 'column-reverse' : 'row'}
          >
            {props.moreMenu.menuTools.visible && (
              <Flex.Item overflowY="visible">
                <View
                  as="div"
                  display={responsive.props.display}
                  maxHeight="2.375rem"
                  className={
                    responsive.matches.includes('small')
                      ? 'context-modules-header-more-menu-responsive'
                      : null
                  }
                >
                  <ContextModulesHeaderMoreMenu
                    component={
                      responsive.matches.includes('small') ? (
                        <Button>
                          More <IconArrowOpenDownLine size="x-small" />
                        </Button>
                      ) : (
                        <IconButton screenReaderLabel="More">
                          <IconMoreLine />
                        </IconButton>
                      )
                    }
                    items={{
                      menuTools: props.moreMenu.menuTools,
                      exportCourseContent: props.moreMenu.exportCourseContent,
                    }}
                  />
                </View>
              </Flex.Item>
            )}

            <Flex.Item overflowY="visible">
              <Button
                id="expand_collapse_all"
                display={responsive.props.display}
                aria-expanded={props.expandCollapseAll.ariaExpanded}
                data-expand={props.expandCollapseAll.dataExpand}
                data-url={props.expandCollapseAll.dataUrl}
                aria-label={props.expandCollapseAll.ariaLabel}
              >
                {props.expandCollapseAll.label}
              </Button>
            </Flex.Item>

            {props.viewProgress.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  id="context-modules-header-view-progress-button"
                  display={responsive.props.display}
                  href={props.viewProgress.url}
                >
                  {props.viewProgress.label}
                </Button>
              </Flex.Item>
            )}

            {!props.moreMenu.menuTools.visible && props.moreMenu.exportCourseContent.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  renderIcon={IconExportLine}
                  href={props.moreMenu.exportCourseContent.url}
                  id="context-modules-header-export-course-button"
                  display={responsive.props.display}
                >
                  {props.moreMenu.exportCourseContent.label}
                </Button>
              </Flex.Item>
            )}

            {publishMenu.visible && (
              <Flex.Item overflowY="visible">
                <View
                  id="context-modules-publish-menu"
                  as="div"
                  display={responsive.props.display}
                  maxHeight="2.375rem"
                  className={
                    responsive.matches.includes('small')
                      ? 'context-modules-header-publish-menu-responsive'
                      : null
                  }
                  data-progress-id={publishMenu.runningProgressId}
                >
                  <ContextModulesPublishMenu {...publishMenu} />
                </View>
              </Flex.Item>
            )}

            {props.addModule.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  onClick={e => document.add_module_link_handler(e)}
                  id="context-modules-header-add-module-button"
                  color="primary"
                  renderIcon={IconAddLine}
                  display={responsive.props.display}
                >
                  {props.addModule.label}
                </Button>
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
      </Flex>
    </>
  )
}

const ContextModulesHeader = (props: Props) => {
  return (
    <Responsive
      query={{
        small: {maxWidth: '607px'},
        medium: {minWidth: '608px', maxWidth: '991px'},
        large: {minWidth: '992px'},
      }}
      props={{
        small: {direction: 'column', display: 'block'},
        medium: {direction: 'column', display: 'inline-block'},
        large: {direction: 'row', display: 'inline-block'},
      }}
      render={(_props, matches) => (
        <ContextModulesHeaderContent {...props} responsive={{props: _props, matches}} />
      )}
    />
  )
}

export default ContextModulesHeader
