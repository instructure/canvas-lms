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
import I18n from 'i18n!custom_help_link'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu';
import MenuItem from 'instructure-ui/lib/components/Menu/MenuItem';
import MenuItemGroup from 'instructure-ui/lib/components/Menu/MenuItemGroup';
import Button from 'instructure-ui/lib/components/Button';
import AccessibleContent from 'instructure-ui/lib/components/AccessibleContent';
import IconPlusLine from 'instructure-icons/lib/Line/IconPlusLine';
import CustomHelpLinkPropTypes from './CustomHelpLinkPropTypes'
import CustomHelpLinkConstants from './CustomHelpLinkConstants'

  const CustomHelpLinkMenu = React.createClass({
    propTypes: {
      links: PropTypes.arrayOf(CustomHelpLinkPropTypes.link).isRequired,
      onChange: PropTypes.func
    },
    handleChange (e, link) {
      if (link.is_disabled) {
        e.preventDefault();
        return;
      }
      if (typeof this.props.onChange === 'function') {
        e.preventDefault()
        this.props.onChange(link)
      }
    },
    focus () {
      this.refs.addButton.focus();
    },
    focusable () {
      return this.refs.addButton;
    },

    handleAddLinkSelection (e, selected) {
      const item = selected[0];
      if (item === 'add_custom_link') {
        this.handleChange(e, { ...CustomHelpLinkConstants.DEFAULT_LINK });
      } else {
        this.handleChange(e, this.props.links.filter(l => l.text === item)[0]);
      }
    },

    render () {
      return (
        <div className="HelpMenuOptions__Container">
          <PopoverMenu
            trigger={
              <Button>
                <AccessibleContent alt={I18n.t('Add Link')}>
                  <IconPlusLine className="HelpMenuOptions__ButtonIcon" />
                  &nbsp; {I18n.t('Link')}
                </AccessibleContent>
              </Button>
            }
          >
            <MenuItemGroup
              label={I18n.t('Add help menu links')}
              onSelect={this.handleAddLinkSelection}
            >
              <MenuItem
                key="add_custom_link"
                value="add_custom_link"
              >
                { I18n.t('Add Custom Link') }
              </MenuItem>
              {
                this.props.links.map(link => (
                  <MenuItem
                    key={link.text}
                    value={link.text}
                    disabled={link.is_disabled}
                  >
                    {link.text}
                  </MenuItem>
                )
              )}
            </MenuItemGroup>
          </PopoverMenu>
        </div>
      )
    }
  });

export default CustomHelpLinkMenu
