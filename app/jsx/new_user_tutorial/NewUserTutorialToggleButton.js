import React from 'react'
import I18n from 'i18n!new_user_tutorial'
import Button from 'instructure-ui/Button'
import IconMoveLeftLine from 'instructure-icons/react/Line/IconMoveLeftLine'
import IconMoveRightLine from 'instructure-icons/react/Line/IconMoveRightLine'
import plainStoreShape from 'jsx/shared/proptypes/plainStoreShape'

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
            (<IconMoveLeftLine title={I18n.t('Expand tutorial tray')} />) :
            (<IconMoveRightLine title={I18n.t('Collapse tutorial tray')} />)
          }
        </Button>
      );
    }
  }

export default NewUserTutorialToggleButton;

