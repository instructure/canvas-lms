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
import {
  Responsive,
  type ResponsivePropsObject,
  type QueriesMatching,
} from '@instructure/ui-responsive'

import ContextModulesPublishMenu from './ContextModulesPublishMenu'
import {openExternalTool} from '../jquery/utils'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules')

type MenuToolsProps = {
  items: [
    {
      href: string
      'data-tool-id': number
      'data-tool-launch-type': string
      class: string
      icon: string
      title: string
    },
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

type OverridesProps = {
  hideTitle?: boolean
  publishMenu?: {
    onPublishComplete?: () => void
  }
  expandCollapseAll?: {
    onExpandCollapseAll?: () => void
    anyModuleExpanded?: boolean
    disabled?: boolean
  }
  handleAddModule?: () => void
  renderIconLegend?: () => JSX.Element
}

type Props = {
  title: string
  hideTitle?: boolean
  publishMenu: PublishMenuProps
  viewProgress: {
    label: string
    url: string
    visible: boolean
  }
  expandCollapseAll: {
    onExpandCollapseAll: () => void
    anyModuleExpanded: boolean
    disabled: boolean
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
  overrides?: OverridesProps
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
  // @ts-expect-error
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
    window.addEventListener('update-publish-menu-disabled-state', ((e: CustomEvent) => {
      setPublishMenu((prev: PublishMenuProps) => ({
        ...prev,
        disabled: e.detail.disabled,
      }))
    }) as EventListener)
  }, [])

  const expandCollapseAll = {...props.expandCollapseAll, ...props.overrides?.expandCollapseAll}

  return (
    <>
      <Flex
        margin="0 0 medium"
        as="div"
        direction={responsive.props.direction}
        withVisualDebug={false}
        alignItems="stretch"
      >
        {!props.overrides?.hideTitle && (
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
        )}

        <Flex.Item
          overflowY="visible"
          margin={responsive.matches.includes('large') ? 'x-small 0 0 0' : '0'}
        >
          <Flex gap="small" wrap="wrap" justifyItems="end" withVisualDebug={false}>
            {props.overrides?.renderIconLegend?.()}
            {props.moreMenu.menuTools.visible && (
              <Flex.Item overflowY="visible">
                <View
                  as="div"
                  display={responsive.props.display}
                  maxHeight="2.375rem"
                  // @ts-expect-error
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
                onClick={expandCollapseAll.onExpandCollapseAll}
                aria-label={
                  expandCollapseAll.anyModuleExpanded
                    ? I18n.t('Collapse All Modules')
                    : I18n.t('Expand All Modules')
                }
                interaction={expandCollapseAll.disabled ? 'disabled' : 'enabled'}
              >
                {expandCollapseAll.anyModuleExpanded
                  ? I18n.t('Collapse All')
                  : I18n.t('Expand All')}
              </Button>
            </Flex.Item>

            {props.viewProgress.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  id="context-modules-header-view-progress-button"
                  href={props.viewProgress.url}
                >
                  {props.viewProgress.label}
                </Button>
              </Flex.Item>
            )}

            {!props.moreMenu.menuTools.visible && props.moreMenu.exportCourseContent.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  // @ts-expect-error
                  renderIcon={IconExportLine}
                  href={props.moreMenu.exportCourseContent.url}
                  id="context-modules-header-export-course-button"
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
                  // @ts-expect-error
                  className={
                    responsive.matches.includes('small')
                      ? 'context-modules-header-publish-menu-responsive'
                      : null
                  }
                  data-progress-id={publishMenu.runningProgressId}
                >
                  <ContextModulesPublishMenu
                    {...publishMenu}
                    onPublishComplete={props.overrides?.publishMenu?.onPublishComplete}
                  />
                </View>
              </Flex.Item>
            )}

            {props.addModule.visible && (
              <Flex.Item overflowY="visible">
                <Button
                  onClick={
                    props.overrides?.handleAddModule
                      ? props.overrides.handleAddModule
                      : // @ts-expect-error
                        e => document.add_module_link_handler(e)
                  }
                  id="context-modules-header-add-module-button"
                  color="primary"
                  // @ts-expect-error
                  renderIcon={IconAddLine}
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
        small: {maxWidth: '787px'},
        medium: {minWidth: '788px', maxWidth: '991px'},
        large: {minWidth: '992px'},
      }}
      props={{
        small: {direction: 'column', display: 'block'},
        medium: {direction: 'column', display: 'inline-block'},
        large: {direction: 'row', display: 'inline-block'},
      }}
      render={(_props, matches) => (
        // @ts-expect-error
        <ContextModulesHeaderContent {...props} responsive={{props: _props, matches}} />
      )}
    />
  )
}

export default ContextModulesHeader
