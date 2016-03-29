var React = require('react');
var TrayPortal = React.createFactory(require('./TrayPortal'));

var Tray = React.createClass({
  displayName: 'Tray',

  propTypes: {
    isOpen: React.PropTypes.bool,
    onBlur: React.PropTypes.func,
    closeTimeoutMS: React.PropTypes.number
  },

  getDefaultProps: function () {
    return {
      isOpen: false,
      closeTimeoutMS: 0
    };
  },

  componentDidMount: function () {
    this.node = document.createElement('div');
    this.node.className = 'ReactTrayPortal';
    document.body.appendChild(this.node);
    this.renderPortal(this.props);
  },

  componentWillReceiveProps: function (props) {
    this.renderPortal(props);
  },

  componentWillUnmount: function () {
    React.unmountComponentAtNode(this.node);
    document.body.removeChild(this.node);
  },

  renderPortal: function (props) {
    delete props.ref;

    if (this.portal) {
      this.portal.setProps(props);
    } else {
      this.portal = React.render(TrayPortal(props), this.node);
    }
  },

  render: function () {
    return null;
  }
});

module.exports = Tray;
