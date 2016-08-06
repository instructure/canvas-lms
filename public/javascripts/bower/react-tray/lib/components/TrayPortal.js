import React, { PropTypes } from 'react';
import cx from 'classnames';
import focusManager from '../helpers/focusManager';
import isLeavingNode from '../helpers/isLeavingNode';

const styles = {
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

const CLASS_NAMES = {
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

  let node = child;
  /* eslint no-cond-assign:0 */
  while (node = node.parentNode) {
    if (node === parent) {
      return true;
    }
  }
  return false;
}

export default React.createClass({
  displayName: 'TrayPortal',

  propTypes: {
    className: PropTypes.string,
    overlayClassName: PropTypes.string,
    isOpen: PropTypes.bool,
    onBlur: PropTypes.func,
    closeOnBlur: PropTypes.bool,
    closeTimeoutMS: PropTypes.number,
    children: PropTypes.any
  },

  getInitialState() {
    return {
      afterOpen: false,
      beforeClose: false
    };
  },

  componentDidMount() {
    if (this.props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    }
  },

  componentWillReceiveProps(props) {
    if (props.isOpen) {
      this.setFocusAfterRender(true);
      this.open();
    } else if (this.props.isOpen && !props.isOpen) {
      this.close();
    }
  },

  componentDidUpdate() {
    if (this.focusAfterRender) {
      this.focusContent();
      this.setFocusAfterRender(false);
    }
  },

  setFocusAfterRender(focus) {
    this.focusAfterRender = focus;
  },

  focusContent() {
    this.refs.content.focus();
  },

  handleOverlayClick(e) {
    if (!isChild(this.refs.content, e.target)) {
      this.props.onBlur();
    }
  },

  handleContentKeyDown(e) {
    // Treat ESC as blur/close
    if (e.keyCode === 27) {
      this.props.onBlur();
    }

    // Treat tabbing away from content as blur/close if closeOnBlur
    if (e.keyCode === 9 && this.props.closeOnBlur && isLeavingNode(this.refs.content, e)) {
      e.preventDefault();
      this.props.onBlur();
    }
  },

  open() {
    focusManager.markForFocusLater();
    this.setState({isOpen: true}, () => {
      this.setState({afterOpen: true});
    });
  },

  close() {
    if (this.props.closeTimeoutMS > 0) {
      this.closeWithTimeout();
    } else {
      this.closeWithoutTimeout();
    }
  },

  closeWithTimeout() {
    this.setState({beforeClose: true}, () => {
      setTimeout(this.closeWithoutTimeout, this.props.closeTimeoutMS);
    });
  },

  closeWithoutTimeout() {
    this.setState({
      afterOpen: false,
      beforeClose: false
    }, this.afterClose);
  },

  afterClose() {
    focusManager.returnFocus();
  },

  shouldBeClosed() {
    return !this.props.isOpen && !this.state.beforeClose;
  },

  buildClassName(which) {
    let className = CLASS_NAMES[which].base;
    if (this.state.afterOpen) {
      className += ' ' + CLASS_NAMES[which].afterOpen;
    }
    if (this.state.beforeClose) {
      className += ' ' + CLASS_NAMES[which].beforeClose;
    }
    return className;
  },

  render() {
    return this.shouldBeClosed() ? <div/> : (
      <div
        ref="overlay"
        style={styles.overlay}
        className={cx(
          this.buildClassName('overlay'),
          this.props.overlayClassName
        )}
        onClick={this.handleOverlayClick}
      >
        <div
          ref="content"
          style={styles.content}
          className={cx(
            this.buildClassName('content'),
            this.props.className
          )}
          onKeyDown={this.handleContentKeyDown}
          tabIndex="-1"
        >
          {this.props.children}
        </div>
      </div>
    );
  }
});
