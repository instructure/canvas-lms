define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui/Button',
  'instructure-icons/react/Line/IconArrowOpenLeftLine',
  'instructure-icons/react/Line/IconArrowOpenRightLine',
], (React, I18n, { default: Button }, { default: IconArrowOpenLeftLine }, { default: IconArrowOpenRightLine }) => {
  class NewUserTutorialToggleButton extends React.Component {

    static propTypes = {
      initiallyCollapsed: React.PropTypes.bool,
      onClick: React.PropTypes.func
    }

    static defaultProps = {
      initiallyCollapsed: false,
      onClick () {}
    }

    constructor (props) {
      super(props);
      this.state = {
        isCollapsed: props.initiallyCollapsed
      }
    }

    handleButtonClick = (event) => {
      event.preventDefault();
      this.setState({
        isCollapsed: !this.state.isCollapsed
      }, () => {
        if (this.props.onClick) {
          this.props.onClick()
        }
      })
    }

    render () {
      return (
        <Button
          variant="icon"
          id="new_user_tutorial_toggle"
          onClick={this.handleButtonClick}
        >
          {
            (this.state.isCollapsed) ?
            (<IconArrowOpenLeftLine title={I18n.t('Expand tutorial tray')} />) :
            (<IconArrowOpenRightLine title={I18n.t('Collapse tutorial tray')} />)
          }
        </Button>
      );
    }
  }

  return NewUserTutorialToggleButton;
});
