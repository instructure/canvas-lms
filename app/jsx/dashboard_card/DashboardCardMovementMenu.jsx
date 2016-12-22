define([
  'react',
  'i18n!dashcards',
  'instructure-ui/PopoverMenu',
  'instructure-ui/Menu',
  'instructure-ui/ScreenReaderContent',
  'instructure-ui/Button'
], (React, I18n, { default: PopoverMenu }, { MenuItem, MenuItemSeparator }, { default: ScreenReaderContent }, { default: Button }) => {
  class DashboardCardMovementMenu extends React.Component {

    static propTypes = {
      cardTitle: React.PropTypes.string.isRequired,
      assetString: React.PropTypes.string.isRequired,
      handleMove: React.PropTypes.func.isRequired,
      menuOptions: React.PropTypes.shape({
        canMoveLeft: React.PropTypes.bool,
        canMoveRight: React.PropTypes.bool,
        canMoveToBeginning: React.PropTypes.bool,
        canMoveToEnd: React.PropTypes.bool
      }).isRequired,
      lastPosition: React.PropTypes.number,
      currentPosition: React.PropTypes.number
    };

    handleMoveCard = positionToMoveTo => () => this.props.handleMove(this.props.assetString, positionToMoveTo);

    render () {
      const menuLabel = (
        <div>
          <ScreenReaderContent>
            {I18n.t('Card Movement Menu for %{title}', { title: this.props.cardTitle })}
          </ScreenReaderContent>
          <i className="icon-more" />
        </div>
      );

      const popoverTrigger = (
        <Button
          variant="icon-inverse"
          size="small"
        >
          {menuLabel}
        </Button>
      );

      const {
        canMoveLeft,
        canMoveRight,
        canMoveToBeginning,
        canMoveToEnd
      } = this.props.menuOptions;

      return (
        <div className="DashboardCardMovementMenu">
          <PopoverMenu
            trigger={popoverTrigger}
          >
            {!!canMoveLeft && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.currentPosition - 1)}
              >
                {I18n.t('Move Left')}
              </MenuItem>
            )}
            {!!canMoveRight && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.currentPosition + 1)}
              >
                {I18n.t('Move Right')}
              </MenuItem>
            )}
            {(!!canMoveToBeginning || !!canMoveToEnd) && (
              <MenuItemSeparator />
            )}
            {!!canMoveToBeginning && (
              <MenuItem
                onSelect={this.handleMoveCard(0)}
              >
                {I18n.t('Move to the Beginning')}
              </MenuItem>
            )}
            {!!canMoveToEnd && (
              <MenuItem
                onSelect={this.handleMoveCard(this.props.lastPosition)}
              >
                {I18n.t('Move to the End')}
              </MenuItem>
            )}
          </PopoverMenu>
        </div>
      );
    }
  }

  return DashboardCardMovementMenu;
});
