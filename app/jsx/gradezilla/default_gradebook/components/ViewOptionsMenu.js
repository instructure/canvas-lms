import React from 'react'
import _ from 'underscore'
import IconMiniArrowDownSolid from 'instructure-icons/react/Solid/IconMiniArrowDownSolid'
import Button from 'instructure-ui/Button'
import { MenuItem, MenuItemSeparator } from 'instructure-ui/Menu'
import PopoverMenu from 'instructure-ui/PopoverMenu'
import Typography from 'instructure-ui/Typography'
import I18n from 'i18n!gradebook'

  function renderTriggerButton () {
    return (
      <Button variant="link">
        <Typography color="primary">
          {I18n.t('View')} <IconMiniArrowDownSolid />
        </Typography>
      </Button>
    );
  }

  const ViewOptionsMenu = () =>
    <PopoverMenu trigger={renderTriggerButton()}>
      <MenuItem disabled>Arrange</MenuItem>
      <MenuItem type="radio" defaultSelected>Assignment Name</MenuItem>
      <MenuItem type="radio">Due Date</MenuItem>
      <MenuItem type="radio">Points</MenuItem>
    </PopoverMenu>

export default ViewOptionsMenu
