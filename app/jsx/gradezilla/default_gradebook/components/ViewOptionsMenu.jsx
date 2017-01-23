define([
  'react',
  'underscore',
  'instructure-icons/react/Solid/IconMiniArrowDownSolid',
  'instructure-ui/Button',
  'instructure-ui/Menu',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Typography',
  'i18n!gradebook'
], (React, _, { default: IconMiniArrowDownSolid }, { default: Button }, { MenuItem, MenuItemSeparator },
  { default: PopoverMenu }, { default: Typography }, I18n) => {
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

  return ViewOptionsMenu;
});

