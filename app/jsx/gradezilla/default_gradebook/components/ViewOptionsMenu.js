import React from 'react'
import _ from 'underscore'
import IconMiniArrowDownSolid from 'instructure-icons/react/Solid/IconMiniArrowDownSolid'
import Button from 'instructure-ui/lib/components/Button'
import { MenuItem, MenuItemGroup, MenuItemSeparator } from 'instructure-ui/lib/components/Menu'
import PopoverMenu from 'instructure-ui/lib/components/PopoverMenu'
import Typography from 'instructure-ui/lib/components/Typography'
import I18n from 'i18n!gradebook'

const { bool, func, shape } = React.PropTypes;

function renderTriggerButton () {
  return (
    <Button variant="link">
      <Typography color="primary">
        {I18n.t('View')} <IconMiniArrowDownSolid />
      </Typography>
    </Button>
  );
}

class ViewOptionsMenu extends React.Component {
  static propTypes = {
    teacherNotes: shape({
      disabled: bool.isRequired,
      onSelect: func.isRequired,
      selected: bool.isRequired
    }).isRequired
  };

  constructor (props) {
    super(props);
    this.bindOptionsMenuContent = (ref) => { this.optionsMenuContent = ref };
  }

  render () {
    return (
      <PopoverMenu
        trigger={renderTriggerButton()}
        contentRef={this.bindOptionsMenuContent}
      >
        <MenuItemGroup label={I18n.t('Arrange By')}>
          <MenuItem defaultSelected>
            { I18n.t('Assignment Name') }
          </MenuItem>

          <MenuItem>
            { I18n.t('Due Date') }
          </MenuItem>

          <MenuItem>
            { I18n.t('Points') }
          </MenuItem>
        </MenuItemGroup>

        <MenuItemSeparator />

        <MenuItemGroup label={I18n.t('Columns')}>
          <MenuItem
            disabled={this.props.teacherNotes.disabled}
            onSelect={this.props.teacherNotes.onSelect}
            selected={this.props.teacherNotes.selected}
          >
            <span data-menu-item-id="show-notes-column">{I18n.t('Notes')}</span>
          </MenuItem>

          <MenuItem>
            { I18n.t('Unpublished Assignments') }
          </MenuItem>
        </MenuItemGroup>
      </PopoverMenu>
    );
  }
}

export default ViewOptionsMenu
