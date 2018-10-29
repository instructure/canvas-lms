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

import I18n from 'i18n!external_tools'
import React from 'react'
import PropTypes from 'prop-types'
import Table from '@instructure/ui-elements/lib/components/Table'
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';

export default class Lti13Apps extends React.Component {
  static propTypes = {
    store: PropTypes.shape({
      getState: PropTypes.func,
      filteredApps: PropTypes.func,
      installTool: PropTypes.func,
      removeTool: PropTypes.func
    }).isRequired,
    contextType: PropTypes.string.isRequired
  }

  componentWillMount () {
    const { store } = this.props
    if (this.storeState.lti13LoadStatus !== 'success') {
      store.fetch13Tools()
    }
  }

  onAppToggle = tool => () => {
    if (tool.enabled) {
      this.props.store.removeTool(tool.app_id)
    } else {
      this.props.store.installTool(tool.app_id)
    }
  }

  get storeState () {
    return this.props.store.getState()
  }

  isDisabled({enabled, installed_in_current_course}) {
    const { contextType } = this.props
    return enabled && !installed_in_current_course && contextType === 'course'
  }

  renderLti13Tool (tool) {
    return (
      <tr key={tool.app_id}>
        <td>{tool.name}</td>
        <td>{tool.description}</td>
        <td>
          <Checkbox
            label={
              <ScreenReaderContent>
                {
                  tool.enabled
                    ? I18n.t('Disable %{toolName}', {toolName: tool.name})
                    : I18n.t('Enable %{toolName}', {toolName: tool.name})
                }
              </ScreenReaderContent>
            }
            variant="toggle"
            checked={tool.enabled}
            onChange={this.onAppToggle(tool)}
            disabled={this.isDisabled(tool)}
          />
        </td>
      </tr>
    )
  }

  render() {
    return (
      <Table striped="rows" caption={<ScreenReaderContent>{I18n.t('LTI 1.3 Tools List')}</ScreenReaderContent>}>
        <thead>
          <tr>
            <th>{I18n.t('Name')}</th>
            <th scope="col" style={{width: '66%'}}>{I18n.t('Description')}</th>
            <th>{I18n.t('Enable')}</th>
          </tr>
        </thead>
        <tbody>
          {
            this.props.store.filteredApps(this.storeState.lti13Tools).map(
              tool => (
                this.renderLti13Tool(tool)
              )
            )
          }
        </tbody>
      </Table>
    )
  }
}
