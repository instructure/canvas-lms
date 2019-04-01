/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import Checkbox from '@instructure/ui-forms/lib/components/Checkbox'
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent';
import IconLti from '@instructure/ui-icons/lib/Line/IconLti'
import { Tooltip } from '@instructure/ui-overlays'
import Button from '@instructure/ui-buttons/lib/components/Button'

import EditExternalToolButton from './EditExternalToolButton'
import ManageUpdateExternalToolButton from './ManageUpdateExternalToolButton'
import ExternalToolPlacementButton from './ExternalToolPlacementButton'
import DeleteExternalToolButton from './DeleteExternalToolButton'
import ConfigureExternalToolButton from './ConfigureExternalToolButton'
import ReregisterExternalToolButton from './ReregisterExternalToolButton'
import classMunger from '../lib/classMunger'
import 'jquery.instructure_misc_helpers'

export default class ExternalToolsTableRow extends React.Component {
  static propTypes = {
    tool: PropTypes.object.isRequired,
    canAddEdit: PropTypes.bool.isRequired,
    setFocusAbove: PropTypes.func.isRequired,
    store: PropTypes.shape({
      getState: PropTypes.func,
      filteredApps: PropTypes.func,
      installTool: PropTypes.func,
      removeTool: PropTypes.func
    }).isRequired
  }

  get is13Tool () {
    return this.props.tool.lti_version === "1.3";
  }

  onModalClose = () => {
    this.button.focus()
  }

  nameClassNames = () => classMunger('external_tool', {muted: (this.props.tool.enabled === false && !this.is13Tool)})

  disabledFlag = () => {
    if (this.props.tool.enabled === false && !this.is13Tool) {
      return I18n.t('(disabled)')
    }
  }

  show13 = () => {
    return <Tooltip
      tip={I18n.t("Is an LTI 1.3 Tool.")}
      on={['click', 'hover', 'focus']}
      >
        <Button variant="icon" icon={IconLti}>
          <ScreenReaderContent>{I18n.t("Toggle ToolTip")}</ScreenReaderContent>
        </Button>
      </Tooltip>
  }

  locked = () => {
    if(this.is13Tool) {
      return;
    }
    if (!this.props.tool.installed_locally) {
      return (
        <span className="text-muted">
          <i
            className="icon-lock"
            ref="lockIcon"
            data-tooltip="top"
            title={I18n.t('%{app} was installed by Admin and is locked', {
              app: this.props.tool.name
            })}
          />
        </span>
      )
    } else if (this.props.tool.is_master_course_child_content) {
      if (this.props.tool.restricted_by_master_course) {
        return (
          <span className="master-course-cell">
            <i
              className="icon-blueprint-lock"
              data-tooltip="top"
              title={I18n.t('%{app} was installed by the master course and is locked', {
                app: this.props.tool.name
              })}
            />
          </span>
        )
      } else {
        return (
          <span className="master-course-cell">
            <i
              className="icon-blueprint"
              data-tooltip="top"
              title={I18n.t('%{app} was installed by the master course', {
                app: this.props.tool.name
              })}
            />
          </span>
        )
      }
    }
  }

  returnFocus = (opts = {}) => {
    if (opts.passFocusUp) {
      this.props.setFocusAbove()
    } else {
      this.button.focus()
    }
  }

  onAppToggle = tool => () => {
    if (tool.installed_at_context_level) {
      this.props.store.removeTool(tool.app_id)
    } else {
      this.props.store.installTool(tool.app_id)
    }
  }

  focus () {
    this.button.focus()
  }

  get isDisabled () {
    const { tool } = this.props
    return !tool.installed_at_context_level && tool.installed_for_context
  }

  renderCheckbox () {
    const { tool } = this.props
    return <Checkbox
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
      checked={tool.installed_for_context}
      onChange={this.onAppToggle(tool)}
      disabled={this.isDisabled}
      ref={(node) => this.button = node}
    />
  }

  renderCheckboxWithToolTip () {
    return <Tooltip
      tip={I18n.t("Inherited tool from parent context.")}
      on={['click', 'hover', 'focus']}
    >
      {this.renderCheckbox()}
    </Tooltip>
  }

  renderButtons = () => {
    const { tool } = this.props
    if (tool.lti_version === '1.3') {
      return <td className="links text-right" nowrap="nowrap">
        <div style={{float: "right"}}>
          {this.isDisabled
            ? this.renderCheckboxWithToolTip()
            : this.renderCheckbox()
          }
        </div>
      </td>
    }
    if (tool.installed_locally && !tool.restricted_by_master_course) {
      let configureButton= null
      let updateBadge = null

      if (tool.tool_configuration) {
        configureButton = (
          <ConfigureExternalToolButton ref="configureExternalToolButton" tool={tool} returnFocus={this.returnFocus} />
        )
      }

      if (tool.has_update) {
        const badgeAriaLabel = I18n.t('An update is available for %{toolName}', {
          toolName: tool.name
        })
        updateBadge = <i className="icon-upload tool-update-badge" aria-label={badgeAriaLabel} />
      }

      return (
        <td className="links text-right" nowrap="nowrap">
          {updateBadge}
          <div className="al-dropdown__container">
            <a
              className="al-trigger btn"
              role="button"
              href="#"
              ref={c => {
                this.button = c
              }}
            >
              <i className="icon-settings" />
              <i className="icon-mini-arrow-down" />
              <span className="screenreader-only">{`${tool.name} ${I18n.t(
                'Settings'
              )}`}</span>
            </a>
            <ul
              className="al-options"
              role="menu"
              tabIndex="0"
              aria-hidden="true"
              aria-expanded="false"
            >
              {configureButton}
              <ManageUpdateExternalToolButton
                tool={tool}
                returnFocus={this.returnFocus}
              />
              <EditExternalToolButton
                ref="editExternalToolButton"
                tool={tool}
                canAddEdit={this.props.canAddEdit}
                returnFocus={this.returnFocus}
              />
              <ExternalToolPlacementButton
                ref="externalToolPlacementButton"
                tool={tool}
                onClose={this.onModalClose}
                returnFocus={this.returnFocus}
              />
              <ReregisterExternalToolButton
                ref="reregisterExternalToolButton"
                tool={tool}
                canAddEdit={this.props.canAddEdit}
                returnFocus={this.returnFocus}
              />
              <DeleteExternalToolButton
                ref="deleteExternalToolButton"
                tool={tool}
                canAddEdit={this.props.canAddEdit}
                returnFocus={this.returnFocus}
              />
            </ul>
          </div>
        </td>
      )
    } else {
      return (
        <td className="links text-right e-tool-table-data" nowrap="nowrap">
          <ExternalToolPlacementButton
            ref="externalToolPlacementButton"
            tool={tool}
            type="button"
            returnFocus={this.returnFocus}
          />
        </td>
      )
    }
  }

  render() {
    return (
      <tr className="ExternalToolsTableRow external_tool_item">
        {this.is13Tool
          ? <td className="e-tool-table-data center-text">{this.show13()}</td>
          : <td className="e-tool-table-data center-text">{this.locked()}</td>
        }
        <td
          nowrap="nowrap"
          className={`${this.nameClassNames()} e-tool-table-data`}
          title={this.props.tool.name}
        >
          {this.props.tool.name} {this.disabledFlag()}
        </td>
        {this.renderButtons()}
      </tr>
    )
  }
}
