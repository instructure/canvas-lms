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
import EditExternalToolButton from '../../external_apps/components/EditExternalToolButton'
import ManageUpdateExternalToolButton from '../../external_apps/components/ManageUpdateExternalToolButton'
import ExternalToolPlacementButton from '../../external_apps/components/ExternalToolPlacementButton'
import DeleteExternalToolButton from '../../external_apps/components/DeleteExternalToolButton'
import ConfigureExternalToolButton from '../../external_apps/components/ConfigureExternalToolButton'
import ReregisterExternalToolButton from '../../external_apps/components/ReregisterExternalToolButton'
import classMunger from '../../external_apps/lib/classMunger'
import 'jquery.instructure_misc_helpers'

export default React.createClass({
    displayName: 'ExternalToolsTableRow',

    propTypes: {
      tool: PropTypes.object.isRequired,
      canAddEdit: PropTypes.bool.isRequired
    },

    onModalClose () {
      this.button.focus()
    },

    renderButtons() {
      if (this.props.tool.installed_locally && !this.props.tool.restricted_by_master_course) {
        var configureButton, updateBadge, updateOption, dimissUpdateOption = null;
        var reregistrationButton = null;

        if (this.props.tool.tool_configuration) {
          configureButton = <ConfigureExternalToolButton ref="configureExternalToolButton" tool={this.props.tool} />;
        }

        if(this.props.tool.has_update) {
          var badgeAriaLabel = I18n.t('An update is available for %{toolName}', { toolName: this.props.tool.name });
          updateBadge = <i className="icon-upload tool-update-badge" aria-label={badgeAriaLabel}></i>;
        }

        return (
          <td className="links text-right" nowrap="nowrap">
            {updateBadge}
            <div className={"al-dropdown__container"} >
              <a className={"al-trigger btn"} role="button" href="#" ref={(c) => { this.button = c }}>
                <i className={"icon-settings"}></i>
                <i className={"icon-mini-arrow-down"}></i>
                <span className={"screenreader-only"}>{ this.props.tool.name + ' ' + I18n.t('Settings') }</span>
              </a>
              <ul className={"al-options"} role="menu" tabIndex="0" aria-hidden="true" aria-expanded="false" >
                {configureButton}
                <ManageUpdateExternalToolButton tool={this.props.tool} />
                <EditExternalToolButton ref="editExternalToolButton" tool={this.props.tool} canAddEdit={this.props.canAddEdit}/>
                <ExternalToolPlacementButton ref="externalToolPlacementButton" tool={this.props.tool} onClose={this.onModalClose} />
                <ReregisterExternalToolButton ref="reregisterExternalToolButton" tool={this.props.tool} canAddEdit={this.props.canAddEdit}/>
                <DeleteExternalToolButton ref="deleteExternalToolButton" tool={this.props.tool} canAddEdit={this.props.canAddEdit} />
              </ul>
            </div>
          </td>
        )
      } else {
        return (
          <td className="links text-right e-tool-table-data" nowrap="nowrap" >
            <ExternalToolPlacementButton ref="externalToolPlacementButton" tool={this.props.tool} type="button"/>
          </td>
        );
      }
    },

    nameClassNames() {
      return classMunger('external_tool', {'muted': this.props.tool.enabled === false});
    },

    disabledFlag() {
      if (this.props.tool.enabled === false) {
        return I18n.t('(disabled)');
      }
    },

    locked() {
      if (!this.props.tool.installed_locally) {
        return (
          <span className="text-muted">
            <i
              className="icon-lock"
              ref="lockIcon"
              data-tooltip="top"
              title={I18n.t('%{app} was installed by Admin and is locked', {app: this.props.tool.name})}
            />
          </span>
        );
      } else if (this.props.tool.is_master_course_child_content) {
        if (this.props.tool.restricted_by_master_course) {
          return (
            <span className="master-course-cell">
              <i
                className="icon-blueprint-lock"
                data-tooltip="top"
                title={I18n.t('%{app} was installed by the master course and is locked', {app: this.props.tool.name})}
              />
            </span>
          );
        } else {
          return (
            <span className="master-course-cell">
              <i
                className="icon-blueprint"
                data-tooltip="top"
                title={I18n.t('%{app} was installed by the master course', {app: this.props.tool.name})}
              />
            </span>
          );
        }
      }
    },

    render() {
      return (
        <tr className="ExternalToolsTableRow external_tool_item">
          <td className="e-tool-table-data center-text">{this.locked()}</td>
          <td scope="row" nowrap="nowrap" className={this.nameClassNames() + " e-tool-table-data"} title={this.props.tool.name}>
            {this.props.tool.name} {this.disabledFlag()}
          </td>
          {this.renderButtons()}
        </tr>
      );
    }
  });
