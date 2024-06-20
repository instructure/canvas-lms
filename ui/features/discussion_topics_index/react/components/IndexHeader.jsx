/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import actions from '../actions'
import {bindActionCreators} from 'redux'
import {bool, func, string, arrayOf} from 'prop-types'
import {connect} from 'react-redux'
import {debounce} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import propTypes from '../propTypes'
import React, {Component} from 'react'
import select from '@canvas/obj-select'

import {Button} from '@instructure/ui-buttons'
import DiscussionSettings from './DiscussionSettings'
import {FormField} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import ReactDOM from 'react-dom'
import ContentTypeExternalToolTray from '@canvas/trays/react/ContentTypeExternalToolTray'
import {ltiState} from '@canvas/lti/jquery/messages'
import {SimpleSelect} from '@instructure/ui-simple-select'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {HeadingMenu} from '@canvas/discussions/react/components/HeadingMenu'
import {SearchField} from '@canvas/discussions/react/components/SearchField'

const I18n = useI18nScope('discussions_v2')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav
const SEARCH_DELAY = 750
const getFilters = () => ({
  all: instUINavEnabled() ? I18n.t('All Discussions') : I18n.t('All'),
  unread: instUINavEnabled() ? I18n.t('Unread Discussions') : I18n.t('Unread'),
})

export default class IndexHeader extends Component {
  static propTypes = {
    breakpoints: breakpointsShape.isRequired,
    contextId: string,
    contextType: string,
    courseSettings: propTypes.courseSettings,
    discussionTopicIndexMenuTools: arrayOf(propTypes.discussionTopicMenuTools),
    fetchCourseSettings: func.isRequired,
    fetchUserSettings: func.isRequired,
    isSavingSettings: bool.isRequired,
    isSettingsModalOpen: bool.isRequired,
    permissions: propTypes.permissions.isRequired,
    saveSettings: func.isRequired,
    searchDiscussions: func.isRequired,
    toggleModalOpen: func.isRequired,
    userSettings: propTypes.userSettings.isRequired,
    searchInputRef: func,
  }

  static defaultProps = {
    searchInputRef: null,
    courseSettings: {},
    breakpoints: {},
  }

  state = {
    filter: 'all',
  }

  componentDidMount() {
    this.props.fetchUserSettings()
    if (this.props.contextType === 'course' && this.props.permissions.change_settings) {
      this.props.fetchCourseSettings()
    }
  }

  onFilterChange = data => {
    this.setState({filter: data.value}, this.props.searchDiscussions({filter: data.value}))
  }

  onSearchChange = data => {
    this.props.searchDiscussions({searchTerm: data.searchTerm})
  }

  renderTrayToolsMenu = () => {
    if (this.props.discussionTopicIndexMenuTools?.length > 0) {
      return (
        <Flex.Item>
          <div className="inline-block">
            {/* TODO: use InstUI button */}
            {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
            <a
              className="al-trigger btn"
              id="discussion_menu_link"
              role="button"
              tabIndex="0"
              title={I18n.t('Discussions Menu')}
              aria-label={I18n.t('Discussions Menu')}
            >
              <i className="icon-more" aria-hidden="true" />
              <span className="screenreader-only">{I18n.t('Discussions Menu')}</span>
            </a>
            <ul className="al-options" role="menu">
              {this.props.discussionTopicIndexMenuTools.map(tool => (
                <li key={tool.id} role="menuitem">
                  {/* TODO: use InstUI button */}
                  {/* eslint-disable-next-line jsx-a11y/anchor-is-valid */}
                  <a aria-label={tool.title} href="#" onClick={this.onLaunchTrayTool(tool)}>
                    {this.iconForTrayTool(tool)}
                    {tool.title}
                  </a>
                </li>
              ))}
            </ul>
            <div id="external-tool-mount-point" />
          </div>
        </Flex.Item>
      )
    }
  }

  iconForTrayTool(tool) {
    if (tool.canvas_icon_class) {
      return <i className={tool.canvas_icon_class} />
    } else if (tool.icon_url) {
      return <img className="icon lti_tool_icon" alt="" src={tool.icon_url} />
    }
  }

  onLaunchTrayTool = tool => e => {
    if (e != null) {
      e.preventDefault()
    }
    this.setExternalToolTray(tool, document.getElementById('discussion_settings'))
  }

  setExternalToolTray(tool, returnFocusTo) {
    const handleDismiss = () => {
      this.setExternalToolTray(null)
      returnFocusTo.focus()
      if (ltiState?.tray?.refreshOnClose) {
        window.location.reload()
      }
    }
    ReactDOM.render(
      <ContentTypeExternalToolTray
        tool={tool}
        placement="discussion_topic_index_menu"
        acceptedResourceTypes={['discussion_topic']}
        targetResourceType="discussion_topic"
        allowItemSelection={false}
        selectableItems={[]}
        onDismiss={handleDismiss}
        open={tool !== null}
      />,
      document.getElementById('external-tool-mount-point')
    )
  }

  renderActionButtons() {
    const buttonsDirection = !instUINavEnabled() ? 'row' : 'row-reverse'

    return (
      <Flex wrap="no-wrap" direction={buttonsDirection} gap="small" justifyItems="end">
        {this.props.permissions.create && (
          <Flex.Item>
            <Button
              href={`/${this.props.contextType}s/${this.props.contextId}/discussion_topics/new`}
              color="primary"
              id="add_discussion"
              renderIcon={IconPlusLine}
            >
              <ScreenReaderContent>{I18n.t('Add discussion')}</ScreenReaderContent>
              <PresentationContent>{I18n.t('Discussion')}</PresentationContent>
            </Button>
          </Flex.Item>
        )}
        {Object.keys(this.props.userSettings).length ? (
          <Flex.Item>
            <DiscussionSettings
              courseSettings={this.props.courseSettings}
              userSettings={this.props.userSettings}
              permissions={this.props.permissions}
              saveSettings={this.props.saveSettings}
              toggleModalOpen={this.props.toggleModalOpen}
              isSettingsModalOpen={this.props.isSettingsModalOpen}
              isSavingSettings={this.props.isSavingSettings}
            />
          </Flex.Item>
        ) : null}
        {this.renderTrayToolsMenu()}
      </Flex>
    )
  }

  renderOldHeader(breakpoints) {
    const ddSize = breakpoints.desktopOnly ? '100px' : '100%'
    const containerSize = breakpoints.tablet ? 'auto' : '100%'
    const {searchInputRef, searchDiscussions} = this.props

    return (
      <View>
        <View margin="0 0 medium" display="block" data-testid="discussions-index-container">
          <Flex wrap="wrap" justifyItems="end" gap="small">
            <Flex.Item size={ddSize} shouldGrow={true} shouldShrink={true}>
              <FormField
                id="discussion-filter"
                label={<ScreenReaderContent>{I18n.t('Discussion Filter')}</ScreenReaderContent>}
              >
                <SimpleSelect
                  renderLabel=""
                  id="discussion-filter"
                  name="filter-dropdown"
                  onChange={(_e, data) =>
                    this.setState(
                      {filter: data.value},
                      debounce(() => this.props.searchDiscussions(this.state), SEARCH_DELAY, {
                        leading: false,
                        trailing: true,
                      })
                    )
                  }
                >
                  {Object.keys(getFilters()).map(filter => (
                    <SimpleSelect.Option key={filter} id={filter} value={filter}>
                      {getFilters()[filter]}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
              </FormField>
            </Flex.Item>
            <Flex.Item size={containerSize} shouldGrow={true} shouldShrink={true} margin="0">
              <SearchField
                name="discussion_search"
                searchInputRef={searchInputRef}
                onSearchEvent={searchDiscussions}
              />
            </Flex.Item>
            <Flex.Item>{this.renderActionButtons()}</Flex.Item>
          </Flex>
        </View>
      </View>
    )
  }

  render() {
    const {breakpoints, searchInputRef} = this.props
    const containerSize = breakpoints.tablet ? 'auto' : '100%'

    if (!instUINavEnabled()) {
      return this.renderOldHeader(breakpoints)
    }

    let flexBasis = 'auto'
    let flexDirection = 'row'
    let headerShrink = false

    if (breakpoints.mobileOnly) {
      flexBasis = '100%'
      flexDirection = 'column-reverse'
      headerShrink = true
    }

    return (
      <Flex direction="column" as="div" gap="medium">
        <Flex.Item dmargin="0 0 large" overflow="hidden">
          <Flex as="div" direction="row" justifyItems="space-between" wrap="wrap" gap="small">
            <Flex.Item width={flexBasis} shouldGrow={true} shouldShrink={headerShrink}>
              <HeadingMenu
                name={I18n.t('Discussion Filter')}
                filters={getFilters()}
                defaultSelectedFilter="all"
                onSelectFilter={this.onFilterChange}
              />
            </Flex.Item>
            <Flex.Item width={flexBasis} overflowX="hidden" overflowY="hidden">
              <Flex direction={flexDirection}>
                <Flex.Item size={containerSize}>{this.renderActionButtons()}</Flex.Item>
              </Flex>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <SearchField
          name="discussion_search"
          searchInputRef={searchInputRef}
          onSearchEvent={this.onSearchChange}
        />
        <Flex.Item margin="large 0 0 0" />
      </Flex>
    )
  }
}

const connectState = state => ({
  ...select(state, [
    'contextType',
    'contextId',
    'discussionTopicIndexMenuTools',
    'permissions',
    'userSettings',
    'courseSettings',
    'isSavingSettings',
    'isSettingsModalOpen',
  ]),
})
const selectedActions = [
  'fetchUserSettings',
  'searchDiscussions',
  'fetchCourseSettings',
  'saveSettings',
  'toggleModalOpen',
]
const connectActions = dispatch => bindActionCreators(select(actions, selectedActions), dispatch)
export const ConnectedIndexHeader = WithBreakpoints(
  connect(connectState, connectActions)(IndexHeader)
)
