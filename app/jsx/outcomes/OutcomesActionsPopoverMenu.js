/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import I18n from 'i18n!outcomes'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import Button from 'instructure-ui/lib/components/Button'
import { MenuItem } from 'instructure-ui/lib/components/Menu'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'
import AddToCourseModal from '../outcomes/AddToCourseModal'

export default React.createClass({
    propTypes: {
      contextUrlRoot: PropTypes.string,
      permissions: PropTypes.object
    },
    getInitialState: function () {
      this._applicationContainer = document.querySelector("#application");
      var menuItems = [];
      if (this._hasPermission(this.props.permissions, "manage_rubrics")) {
        menuItems.push({
          key: "manage-rubrics",
          onSelect: this.onManageRubricsSelected,
          name: I18n.t("Manage Rubrics")
        });
      }

      // TODO Enable this option once we continue work on OUT-402
      // if (this._hasPermission(this.props.permissions, "manage_courses")) {
      //   menuItems.push({
      //     key: "add-to-course",
      //     onSelect: this.onAddToCourseSelected,
      //     name: I18n.t("Add to course...")
      //   });
      // }

      return {
        menuItems: menuItems
      };
    },
    render: function () {
      if (this.state.menuItems.length > 0) {
        var renderedMenuItems = this.state.menuItems.map(function (menuItem) {
          return <MenuItem key={menuItem.key} onSelect={menuItem.onSelect}>{menuItem.name}</MenuItem>
        });

        return (
          <span>
            <PopoverMenu ref="popovermenu" trigger={<Button><ScreenReaderContent>{I18n.t("Additional outcomes options")}</ScreenReaderContent>&hellip;</Button>}>
              {renderedMenuItems}
            </PopoverMenu>
            <AddToCourseModal ref={this._saveModal} onClose={this._handleModalClose} onReady={this._handleModalReady} />
          </span>
        );
      }
      return null;
    },
    onManageRubricsSelected: function () {
      window.location.href = this.props.contextUrlRoot + "/rubrics";
    },
    onAddToCourseSelected: function () {
      this._addToCourseModal.open();
    },
    _hasPermission: function (permissions, permissionName) {
      return permissions && permissions[permissionName];
    },
    _saveModal: function (modal) {
      this._addToCourseModal = modal;
    },
    _handleModalReady: function () {
      this._applicationContainer.setAttribute('aria-hidden', 'true')
    },
    _handleModalClose: function () {
      this._applicationContainer.removeAttribute('aria-hidden');
      this.refs.popovermenu.focus();
    }
  });
