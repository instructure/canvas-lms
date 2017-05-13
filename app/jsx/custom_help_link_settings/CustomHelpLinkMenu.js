import React from 'react'
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
      links: React.PropTypes.arrayOf(CustomHelpLinkPropTypes.link).isRequired,
      onChange: React.PropTypes.func
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
