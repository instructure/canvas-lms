define([
  'react',
  'i18n!new_user_tutorial',
  'instructure-ui',
  '../NewUserTutorialToggleButton',
  'jsx/shared/proptypes/plainStoreShape'
], (React, I18n, { Tray }, NewUserTutorialToggleButton, plainStoreShape) => {
  class TutorialTray extends React.Component {

    static propTypes = {
      // Used as a label for the content (screenreader-only)
      label: React.PropTypes.string.isRequired,
      // The specific tray that will be wrapped, unusable without this.
      children: React.PropTypes.node.isRequired,
      // The store to control the status of everything
      store: React.PropTypes.shape(plainStoreShape).isRequired,
      // Should return an element that focus can be set to
      returnFocusToFunc: React.PropTypes.func.isRequired
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

    handleStoreChange = () => {
      this.setState(this.props.store.getState());
    }

    handleToggleClick = () => {
      this.props.store.setState({
        isCollapsed: !this.state.isCollapsed
      });
    }

    handleEntering = () => {
      this.toggleButton.focus()
    }

    handleExiting = () => {
      this.props.returnFocusToFunc().focus();
    }

    render () {
      return (
        <Tray
          label={this.props.label}
          isDismissable={false}
          isOpen={!this.state.isCollapsed}
          placement="right"
          zIndex="100"
          onEntering={this.handleEntering}
          onExiting={this.handleExiting}
        >
          <div className="NewUserTutorialTray">
            <div className="NewUserTutorialTray__ButtonContainer">
              <NewUserTutorialToggleButton
                ref={(c) => { this.toggleButton = c; }}
                onClick={this.handleToggleClick}
                store={this.props.store}
              />
            </div>
            {this.props.children}
          </div>
        </Tray>
      );
    }
  }

  return TutorialTray;
});
