import React from 'react';
import ReactDOM from 'react-dom';
import TrayPortal from './TrayPortal';
const renderSubtreeIntoContainer = ReactDOM.unstable_renderSubtreeIntoContainer;

export default React.createClass({
  displayName: 'Tray',

  propTypes: {
    isOpen: React.PropTypes.bool,
    onBlur: React.PropTypes.func,
    closeTimeoutMS: React.PropTypes.number,
    closeOnBlur: React.PropTypes.bool
  },

  getDefaultProps() {
    return {
      isOpen: false,
      closeTimeoutMS: 0,
      closeOnBlur: true
    };
  },

  componentDidMount() {
    this.node = document.createElement('div');
    this.node.className = 'ReactTrayPortal';
    document.body.appendChild(this.node);
    this.renderPortal(this.props);
  },

  componentWillReceiveProps(props) {
    this.renderPortal(props);
  },

  componentWillUnmount() {
    ReactDOM.unmountComponentAtNode(this.node);
    document.body.removeChild(this.node);
  },

  renderPortal(props) {
    delete props.ref;

    renderSubtreeIntoContainer(this, <TrayPortal {...props}/>, this.node);
  },

  render() {
    return null;
  }
});
