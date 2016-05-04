import React from 'react';
import ReactDOM from 'react-dom';
import Tray from '../../lib/main';
import cx from 'classnames';

const App = React.createClass({
  getInitialState() {
    return {
      orientation: 'left',
      isTrayOpen: false
    };
  },

  handleNavClick(e) {
    const type = e.target.getAttribute('data-type');
    this.openTray(type);
  },

  handleNavKeyPress(e) {
    if (e.which === 13 || e.which === 32) {
      const type = e.target.getAttribute('data-type');
      this.openTray(type);
    }
  },

  handleOrientationChange(e) {
    this.setState({
      orientation: e.target.value
    });
  },

  renderTrayContent() {
    switch (this.state.type) {
    case 'foo':
      return (
        <div>
          <h2>Foo</h2>
          <div>Content for foo</div>
          <nav role="navigation">
            <div><a href="#">A</a></div>
            <div><a href="#">B</a></div>
            <div><a href="#">C</a></div>
          </nav>
        </div>
      );
    case 'bar':
      return (
        <div>
          <h2>Bar</h2>
          <div>Lorem Ipsum</div>
          <nav role="navigation">
            <div><a href="#">A</a></div>
            <div><a href="#">B</a></div>
            <div><a href="#">C</a></div>
          </nav>
        </div>
      );
    case 'baz':
      return (
        <div>
          <h2>Baz</h2>
          <div>Other stuff here</div>
          <nav role="navigation">
            <div><a href="#">A</a></div>
            <div><a href="#">B</a></div>
            <div><a href="#">C</a></div>
          </nav>
        </div>
      );
    default:
      return (
        <h1>You shouldn't see me</h1>
      );
    }
  },

  render() {
    return (
      <div>
        <ul role="menu" className={cx({
          'navigation': true,
          'navigation-left': this.state.orientation === 'left',
          'navigation-right': this.state.orientation === 'right'
        })}
        >
          <li role="menuitem"
              className={cx({ active: this.state.type === 'foo' })}
          >
            <a tabIndex={0}
                role="button"
                aria-haspopup
                data-type="foo"
                onKeyPress={this.handleNavKeyPress}
                onClick={this.handleNavClick}>Foo</a>
          </li>
          <li role="menuitem"
              className={cx({ active: this.state.type === 'bar' })}
          >
            <a tabIndex={0}
                role="button"
                aria-haspopup
                data-type="bar"
                onKeyPress={this.handleNavKeyPress}
                onClick={this.handleNavClick}>Bar</a>
          </li>
          <li role="menuitem"
              className={cx({ active: this.state.type === 'baz' })}
          >
            <a tabIndex={0}
                role="button"
                aria-haspopup
                data-type="baz"
                onKeyPress={this.handleNavKeyPress}
                onClick={this.handleNavClick}>Baz</a>
          </li>
        </ul>
        <Tray isOpen={this.state.isTrayOpen}
              onBlur={this.closeTray}
              closeTimeoutMS={150}
              className={cx({
                'tray-left': this.state.orientation === 'left',
                'tray-right': this.state.orientation === 'right'
              })}
        >
          {this.renderTrayContent()}
        </Tray>
        <div className="content">
          <select onChange={this.handleOrientationChange}>
            <option value="left">Left</option>
            <option value="right">Right</option>
          </select>
        </div>
      </div>
    );
  },

  openTray(type) {
    this.setState({
      type: type,
      isTrayOpen: true
    });
  },

  closeTray() {
    this.setState({
      isTrayOpen: false
    }, () => {
      setTimeout(() => {
        this.setState({
          type: null
        });
      }, 150);
    });
  }
});

ReactDOM.render(<App/>, document.getElementById('example'));
