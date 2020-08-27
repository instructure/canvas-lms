/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {Suspense, useCallback, useEffect, useState} from 'react'
import {bool, func, instanceOf, shape, string} from 'prop-types'
import {Tray} from '@instructure/ui-overlays'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-layout'

import ErrorBoundary from './ErrorBoundary'
import Bridge from '../../../bridge/Bridge'
import formatMessage from '../../../format-message'
import Filter, {useFilterSettings} from './Filter'
import {StoreProvider} from './StoreContext'

/**
 * Returns the translated tray label
 * @param {string} contentType - The type of content showing on tray
 * @param {string} contentSubtype - The current subtype of content loaded in the tray
 * @param {string} contextType - The user's context
 * @returns {string}
 */
function getTrayLabel(contentType, contentSubtype, contextType) {
  if (contentType === 'links' && contextType === 'course') {
    return formatMessage('Course Links')
  } else if (contentType === 'links' && contextType === 'group') {
    return formatMessage('Group Links')
  }

  switch (contentSubtype) {
    case 'images':
      return contentType === 'course_files'
        ? formatMessage('Course Images')
        : formatMessage('User Images')
    case 'media':
      return contentType === 'course_files'
        ? formatMessage('Course Media')
        : formatMessage('User Media')
    case 'documents':
      return contentType === 'course_files'
        ? formatMessage('Course Documents')
        : formatMessage('User Documents')
    default:
      return formatMessage('Tray') // Shouldn't ever get here
  }
}

const thePanels = {
  links: React.lazy(() => import('../instructure_links/components/LinksPanel')),
  images: React.lazy(() => import('../instructure_image/Images')),
  documents: React.lazy(() => import('../instructure_documents/components/DocumentsPanel')),
  media: React.lazy(() => import('../instructure_record/MediaPanel')),
  all: React.lazy(() => import('./FileBrowser')),
  unknown: React.lazy(() => import('./UnknownFileTypePanel'))
}

// Returns a Suspense wrapped lazy loaded component
// pulled from useLazy's cache
function DynamicPanel(props) {
  let key = ''
  if (props.contentType === 'links') {
    key = 'links'
  } else {
    key = props.contentSubtype in thePanels ? props.contentSubtype : 'unknown'
  }
  const Component = thePanels[key]
  return (
    <Suspense fallback={<Spinner renderTitle={renderLoading} size="large" />}>
      <Component {...props} />
    </Suspense>
  )
}

function renderLoading() {
  return formatMessage('Loading')
}

const FILTER_SETTINGS_BY_PLUGIN = {
  user_documents: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  course_documents: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  user_images: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  course_images: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  user_media: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  course_media: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  course_links: {
    contextType: 'course',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  group_links: {
    contextType: 'group',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc'
  },
  all: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'all',
    sortValue: 'alphabetical',
    sortDir: 'asc'
  }
}

/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */
export default function CanvasContentTray(props) {
  const [isOpen, setIsOpen] = useState(false)
  const [openCount, setOpenCount] = useState(0)
  const [hasOpened, setHasOpened] = useState(false)

  const [filterSettings, setFilterSettings] = useFilterSettings()

  const {bridge, editor, onTrayClosing} = {...props}

  const handleDismissTray = useCallback(() => {
    bridge.focusEditor(editor)
    onTrayClosing && onTrayClosing(true) // tell RCEWrapper we're closing
    setIsOpen(false)
  }, [editor, bridge, onTrayClosing])

  useEffect(() => {
    const controller = {
      showTrayForPlugin(plugin) {
        setFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin])
        setIsOpen(true)
      },
      hideTray() {
        handleDismissTray()
      }
    }

    bridge.attachController(controller, editor.id)

    return () => {
      bridge.detachController(editor.id)
    }
    // it's OK the setFilterSettings is not a dependency
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor.id, bridge, handleDismissTray])

  function handleExitTray() {
    onTrayClosing && onTrayClosing(true) // tell RCEWrapper we're closing
  }

  function handleCloseTray() {
    bridge.focusActiveEditor(false)
    // increment a counter that's used a the key when rendering
    // this gets us a new instance everytime, which is necessary
    // to get the queries run so we have up to date data.
    setOpenCount(openCount + 1)
    setHasOpened(false)
    onTrayClosing && onTrayClosing(false) // tell RCEWrapper we're closed
  }

  function handleFilterChange(newFilter, onChangeContext) {
    const newFilterSettings = {...newFilter}
    if (newFilterSettings.sortValue) {
      newFilterSettings.sortDir = newFilterSettings.sortValue === 'alphabetical' ? 'asc' : 'desc'
    }
    setFilterSettings(newFilterSettings)

    if (newFilterSettings.contentType) {
      let contextType, contextId
      switch (newFilterSettings.contentType) {
        case 'user_files':
          contextType = 'user'
          contextId = props.containingContext.userId
          break
        case 'course_files':
        case 'links':
          contextType = props.contextType
          contextId = props.containingContext.contextId
      }
      onChangeContext({contextType, contextId})
    }
  }

  return (
    <StoreProvider {...props} key={openCount}>
      {contentProps => (
        <Tray
          data-mce-component
          data-testid="CanvasContentTray"
          label={getTrayLabel(
            filterSettings.contentType,
            filterSettings.contentSubtype,
            contentProps.contextType
          )}
          open={isOpen}
          placement="end"
          size="regular"
          shouldContainFocus
          shouldReturnFocus={false}
          shouldCloseOnDocumentClick
          onDismiss={handleDismissTray}
          onClose={handleCloseTray}
          onExit={handleExitTray}
          onOpen={() => {
            bridge.focusEditor(editor)
            setHasOpened(true)
          }}
        >
          {isOpen && hasOpened ? (
            <Flex direction="column" display="block" height="100vh" overflowY="hidden">
              <Flex.Item padding="medium" shadow="above">
                <Flex margin="none none medium none">
                  <Flex.Item grow shrink>
                    <Heading level="h2">{formatMessage('Add')}</Heading>
                  </Flex.Item>

                  <Flex.Item>
                    <CloseButton placement="static" variant="icon" onClick={handleDismissTray}>
                      {formatMessage('Close')}
                    </CloseButton>
                  </Flex.Item>
                </Flex>

                <Filter
                  {...filterSettings}
                  userContextType={props.contextType}
                  onChange={newFilter => {
                    handleFilterChange(newFilter, contentProps.onChangeContext)
                  }}
                />
              </Flex.Item>

              <Flex.Item grow shrink margin="xx-small 0 0 0">
                <ErrorBoundary>
                  <DynamicPanel
                    contentType={filterSettings.contentType}
                    contentSubtype={filterSettings.contentSubtype}
                    sortBy={{sort: filterSettings.sortValue, order: filterSettings.sortDir}}
                    {...contentProps}
                  />
                </ErrorBoundary>
              </Flex.Item>
            </Flex>
          ) : null}
        </Tray>
      )}
    </StoreProvider>
  )
}

function requiredWithoutSource(props, propName, componentName) {
  if (props.source == null && props[propName] == null) {
    throw new Error(
      `The prop \`${propName}\` is marked as required in \`${componentName}\`, but its value is \`${props[propName]}\`.`
    )
  }
}

const trayPropsMap = {
  canUploadFiles: bool.isRequired,
  contextId: string.isRequired, // initial value indicating the user's context (e.g. student v teacher), not the tray's
  contextType: string.isRequired, // initial value indicating the user's context, not the tray's
  filesTabDisabled: bool,
  host: requiredWithoutSource,
  jwt: requiredWithoutSource,
  refreshToken: func,
  source: shape({
    fetchImages: func.isRequired
  }),
  themeUrl: string
}

export const trayProps = shape(trayPropsMap)

CanvasContentTray.propTypes = {
  bridge: instanceOf(Bridge).isRequired,
  editor: shape({id: string}).isRequired,
  onTrayClosing: func, // called with true when the tray starts closing, false once closed
  ...trayPropsMap
}

// the way we define trayProps, eslint doesn't recognize the following as props
/* eslint-disable react/default-props-match-prop-types */
CanvasContentTray.defaultProps = {
  canUploadFiles: false,
  filesTabDisabled: false,
  refreshToken: null,
  source: null,
  themeUrl: null
}
/* eslint-enable react/default-props-match-prop-types */
