var React = require('react');
var div = React.DOM.div;
var cx = require('../helpers/classSet');
var focusManager = require('../helpers/focusManager');
var isLeavingNode = require('../helpers/isLeavingNode');

var styles = {
  overlay: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0
  },
  content: {
    position: 'absolute',
    background: '#fff'
  }
};

var CLASS_NAMES = {
  overlay: {
    base: 'ReactTray__Overlay',
    afterOpen: 'ReactTray__Overlay--after-open',
    beforeClose: 'ReactTray__Overlay--before-close'
  },
  content: {
    base: 'ReactTray__Content',
    afterOpen: 'ReactTray__Content--after-open',
    beforeClose: 'ReactTray__Content--before-close'
  }
};

function isChild(parent, child) {
  if (parent === child) {
    return true;
  }

  var node = child;
  while (node = node.parentNode) {
    if (node === parent) {
      return true;
    }
  }
  return false;
}

var TrayPortal = React.createClass({
  displayName: 'TrayPortal',

  getInitialState: function () {
    return {
      afterOpen: false,
      beforeClose: false
    };
  },

  componentDidMount: function () {
    if (this.props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    }
  },

  componentWillReceiveProps: function (props) {
    if (props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    } else if (this.props.isOpen && !props.isOpen) {
      this.close();
    }
  },

  componentDidUpdate: function () {
    if (this.focusAfterRender) {
      this.focusContent();
      this.setFocusAfterRender(false);
    }
  },

  setFocusAfterRender: function (focus) {
    this.focusAfterRender = focus;
  },

  focusContent: function () {
    this.refs.content.getDOMNode().focus();
  },

  handleOverlayClick: function (e) {
    if (!isChild(this.refs.content.getDOMNode(), e.target)) {
      this.props.onBlur();
    }
  },

  handleContentKeyDown: function (e) {
    // Treat ESC as blur/close
    if (e.keyCode === 27) {
      this.props.onBlur();
    }

    // Treat tabbing away from content as blur/close
    if (e.keyCode === 9 && isLeavingNode(this.refs.content.getDOMNode(), e)) {
      e.preventDefault();
      this.props.onBlur();
    }
  },
   
  open: function () {
    focusManager.markForFocusLater();
    this.setState({isOpen: true}, function () {
      this.setState({afterOpen: true});
    }.bind(this));
  },

  close: function () {
    if (this.props.closeTimeoutMS > 0) {
      this.closeWithTimeout();
    } else {
      this.closeWithoutTimeout();
    }
  },

  closeWithTimeout: function () {
    this.setState({beforeClose: true}, function () {
      setTimeout(this.closeWithoutTimeout, this.props.closeTimeoutMS);
    }.bind(this));
  },

  closeWithoutTimeout: function () {
    this.setState({
      afterOpen: false,
      beforeClose: false
    }, this.afterClose);
  },

  afterClose: function () {
    focusManager.returnFocus();
  },

  shouldBeClosed: function () {
    return !this.props.isOpen && !this.state.beforeClose;
  },

  buildClassName: function (which) {
    var className = CLASS_NAMES[which].base;
    if (this.state.afterOpen) {
      className += ' ' + CLASS_NAMES[which].afterOpen;
    }
    if (this.state.beforeClose) {
      className += ' ' + CLASS_NAMES[which].beforeClose;
    }
    return className;
  },

  render: function () {
    return this.shouldBeClosed() ? div() : (
      div({
        ref: 'overlay',
        style: styles.overlay,
        className: cx(this.buildClassName('overlay'), this.props.overlayClassName),
        onClick: this.handleOverlayClick
      },
        div({
          ref: 'content',
          style: styles.content,
          className: cx(this.buildClassName('content'), this.props.className),
          onKeyDown: this.handleContentKeyDown,
          tabIndex: '-1'
        },
          this.props.children
        )
      )
    );
  }
});

module.exports = TrayPortal;
