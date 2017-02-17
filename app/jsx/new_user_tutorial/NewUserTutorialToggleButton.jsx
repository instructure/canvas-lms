define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui/Button',
  'instructure-icons/react/Line/IconArrowOpenLeftLine',
  'instructure-icons/react/Line/IconArrowOpenRightLine',
  'jsx/shared/proptypes/plainStoreShape'
], (React, I18n, { default: Button }, { default: IconArrowOpenLeftLine }, { default: IconArrowOpenRightLine }, plainStoreShape) => {
  class NewUserTutorialToggleButton extends React.Component {

    static propTypes = {
      store: React.PropTypes.shape(plainStoreShape).isRequired
    }

    constructor (props) {
      super(props);
      this.state = props.store.getState();
    }

    componentDidMount () {
      this.props.store.addChangeListener(this.handleStoreChange)
    }

    componentWillUnmount () {
      this.props.store.removeChangeListener(this.handleStoreChange)
    }

    focus () {
      this.button.focus();
    }

    handleStoreChange = () => {
      this.setState(this.props.store.getState());
    }

    handleButtonClick = (event) => {
      event.preventDefault();

      this.props.store.setState({
        isCollapsed: !this.state.isCollapsed
      });
    }

    render () {
      return (
        <Button
          ref={(c) => { this.button = c; }}
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
