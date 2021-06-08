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

import React, {Suspense, useCallback, useEffect, useRef, useState} from 'react'
import {bool, func, instanceOf, shape, string} from 'prop-types'
import {Tray} from '@instructure/ui-tray'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'

import ErrorBoundary from './ErrorBoundary'
import Bridge from '../../../bridge/Bridge'
import formatMessage from '../../../format-message'
import Filter, {useFilterSettings} from './Filter'
import {StoreProvider} from './StoreContext'
import {getTrayHeight} from './trayUtils'

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
      if (contentType === 'course_files') return formatMessage('Course Images')
      if (contentType === 'group_files') return formatMessage('Group Images')
      return formatMessage('User Images')
    case 'media':
      if (contentType === 'course_files') return formatMessage('Course Media')
      if (contentType === 'group_files') return formatMessage('Group Media')
      return formatMessage('User Media')
    case 'documents':
      if (contentType === 'course_files') return formatMessage('Course Documents')
      if (contentType === 'group_files') return formatMessage('Group Documents')
      return formatMessage('User Documents')
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
    sortDir: 'desc',
    searchString: ''
  },
  course_documents: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_documents: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'documents',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  user_images: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_images: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_images: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'images',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  user_media: {
    contextType: 'user',
    contentType: 'user_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_media: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_media: {
    contextType: 'group',
    contentType: 'group_files',
    contentSubtype: 'media',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  course_links: {
    contextType: 'course',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  group_links: {
    contextType: 'group',
    contentType: 'links',
    contentSubtype: 'all',
    sortValue: 'date_added',
    sortDir: 'desc',
    searchString: ''
  },
  all: {
    contextType: 'course',
    contentType: 'course_files',
    contentSubtype: 'all',
    sortValue: 'alphabetical',
    sortDir: 'asc',
    searchString: ''
  }
}

function isLoading(cprops) {
  return (
    cprops.collections.announcements?.isLoading ||
    cprops.collections.assignments?.isLoading ||
    cprops.collections.discussions?.isLoading ||
    cprops.collections.modules?.isLoading ||
    cprops.collections.quizzes?.isLoading ||
    cprops.collections.wikiPages?.isLoading ||
    cprops.documents.course?.isLoading ||
    cprops.documents.user?.isLoading ||
    cprops.documents.group?.isLoading ||
    cprops.media.course?.isLoading ||
    cprops.media.user?.isLoading ||
    cprops.media.group?.isLoading ||
    cprops.all_files?.isLoading
  )
}

/**
 * This component is used within various plugins to handle loading in content
 * from Canvas.  It is essentially the main component.
 */
export default function CanvasContentTray(props) {
  // should the tray be rendered open?
  const [isOpen, setIsOpen] = useState(false)
  // has the tray fully opened. we use this to defer rendering the content
  // until the tray is open.
  const [hasOpened, setHasOpened] = useState(false)
  // should we close the tray after the user clicks on something in it?
  const [hidingTrayOnAction, setHidingTrayOnAction] = useState(true)

  const trayRef = useRef(null)
  const scrollingAreaRef = useRef(null)
  const [filterSettings, setFilterSettings] = useFilterSettings()

  const {bridge, editor, onTrayClosing} = {...props}

  const handleDismissTray = useCallback(() => {
    // return focus to the RCE if focus was on this tray
    if (trayRef.current && trayRef.current.contains(document.activeElement)) {
      bridge.focusActiveEditor(false)
    }

    onTrayClosing && onTrayClosing(CanvasContentTray.globalOpenCount) // tell RCEWrapper we're closing if we're open
    setIsOpen(false)
  }, [bridge, onTrayClosing])

  useEffect(() => {
    const controller = {
      showTrayForPlugin(plugin) {
        // increment a counter that's used as the key when rendering
        // this gets us a new instance everytime, which is necessary
        // to get the queries run so we have up to date data.
        ++CanvasContentTray.globalOpenCount
        setFilterSettings(FILTER_SETTINGS_BY_PLUGIN[plugin])
        setIsOpen(true)
      },
      hideTray(forceClose) {
        if (forceClose || hidingTrayOnAction) {
          handleDismissTray()
        }
      }
    }

    bridge.attachController(controller, editor.id)

    return () => {
      bridge.detachController(editor.id)
    }
    // it's OK the setFilterSettings is not a dependency
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [editor.id, bridge, handleDismissTray, hidingTrayOnAction])

  useEffect(() => {
    if (
      hasOpened &&
      scrollingAreaRef.current &&
      !scrollingAreaRef.current.style.overscrollBehaviorY
    ) {
      scrollingAreaRef.current.style.overscrollBehaviorY = 'contain'
    }
  }, [hasOpened])

  function handleOpenTray() {
    bridge.focusEditor(editor)
    setHasOpened(true)
  }

  function handleExitTray() {
    onTrayClosing && onTrayClosing(true) // tell RCEWrapper we're closing
  }

  function handleCloseTray() {
    setHasOpened(false)
    onTrayClosing && onTrayClosing(false) // tell RCEWrapper we're closed
  }

  function handleFilterChange(newFilter, onChangeContext, onChangeSearchString, onChangeSortBy) {
    const newFilterSettings = {...newFilter}
    if (newFilterSettings.sortValue) {
      newFilterSettings.sortDir = newFilterSettings.sortValue === 'alphabetical' ? 'asc' : 'desc'
      onChangeSortBy({sort: newFilterSettings.sortValue, dir: newFilterSettings.sortDir})
    }

    if (
      'searchString' in newFilterSettings &&
      filterSettings.searchString !== newFilterSettings.searchString
    ) {
      onChangeSearchString(newFilterSettings.searchString)
    }

    setFilterSettings(newFilterSettings)
    if (newFilterSettings.contentType) {
      let contextType, contextId
      switch (newFilterSettings.contentType) {
        case 'user_files':
          contextType = 'user'
          contextId = props.containingContext.userId
          break
        case 'group_files':
          contextType = 'group'
          contextId = props.containingContext.contextId
          break
        case 'course_files':
          contextType = props.contextType
          contextId = props.containingContext.contextId
          break
        case 'links':
          contextType = props.containingContext.contextType
          contextId = props.containingContext.contextId
      }
      onChangeContext({contextType, contextId})
    }
  }
  return (
    <StoreProvider
      {...props}
      key={CanvasContentTray.globalOpenCount}
      contextType={filterSettings.contextType || props.contextType}
    >
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
          shouldCloseOnDocumentClick={false}
          onDismiss={handleDismissTray}
          onClose={handleCloseTray}
          onExit={handleExitTray}
          onOpen={handleOpenTray}
          onEntered={() => {
            const c = document.querySelector('[role="main"]')
            let target_w = 0
            if (c) {
              const margin =
                window.getComputedStyle(c).direction === 'ltr'
                  ? document.body.getBoundingClientRect().right - c.getBoundingClientRect().right
                  : c.getBoundingClientRect().left

              target_w = c.offsetWidth - trayRef.current?.offsetWidth + margin

              if (target_w >= 320 && target_w < c.offsetWidth) {
                c.style.boxSizing = 'border-box'
                c.style.width = `${target_w}px`
              }
            }
            setHidingTrayOnAction(target_w < 320)
          }}
          onExiting={() => {
            const c = document.querySelector('[role="main"]')
            if (c) c.style.width = ''
          }}
          contentRef={el => (trayRef.current = el)}
        >
          {isOpen && hasOpened ? (
            <Flex
              direction="column"
              as="div"
              height={getTrayHeight()}
              overflowY="hidden"
              tabIndex="-1"
              data-canvascontenttray-content
            >
              <Flex.Item padding="medium" shadow="above">
                <Flex margin="none none medium none">
                  <Flex.Item grow shrink>
                    <Heading level="h2">{formatMessage('Add')}</Heading>
                  </Flex.Item>

                  <Flex.Item>
                    <CloseButton
                      placement="static"
                      variant="icon"
                      onClick={handleDismissTray}
                      data-testid="CloseButton_ContentTray"
                    >
                      {formatMessage('Close')}
                    </CloseButton>
                  </Flex.Item>
                </Flex>

                <Filter
                  {...filterSettings}
                  userContextType={props.contextType}
                  containingContextType={props.containingContext.contextType}
                  onChange={newFilter => {
                    handleFilterChange(
                      newFilter,
                      contentProps.onChangeContext,
                      contentProps.onChangeSearchString,
                      contentProps.onChangeSortBy
                    )
                  }}
                  isContentLoading={isLoading(contentProps)}
                />
              </Flex.Item>

              <Flex.Item
                grow
                shrink
                margin="xx-small xxx-small 0"
                elementRef={el => (scrollingAreaRef.current = el)}
              >
                <ErrorBoundary>
                  <DynamicPanel
                    contentType={filterSettings.contentType}
                    contentSubtype={filterSettings.contentSubtype}
                    sortBy={{sort: filterSettings.sortValue, order: filterSettings.sortDir}}
                    searchString={filterSettings.searchString}
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

CanvasContentTray.globalOpenCount = 0

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
  containingContext: shape({
    contextType: string.isRequired,
    contextId: string.isRequired,
    userId: string.isRequired
  }),
  filesTabDisabled: bool,
  host: requiredWithoutSource,
  jwt: requiredWithoutSource,
  refreshToken: func,
  source: shape({
    fetchImages: func.isRequired
  }),
  themeUrl: string
}

export const trayPropTypes = shape(trayPropsMap)

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
