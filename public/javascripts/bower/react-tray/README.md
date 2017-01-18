# react-tray

An accessible tray component useful for navigation menus
See example at [http://instructure-react.github.io/react-tray](http://instructure-react.github.io/react-tray)

## Usage

```js
var React = require('react');
var Tray = require('react-tray');

var App = React.createClass({
  getInitialState: function () {
    return {
      isTrayOpen: false
    };
  },

  openTray: function () {
    this.setState({
      isTrayOpen: true
    });
  },

  closeTray: function () {
    this.setState({
      isTrayOpen: false
    });
  },


  render: function () {
    return (
      <div>
        <ul role="menu" className="navigation">
          <li role="menuitem">
            <a tabIndex={0}
                role="button"
                aria-haspopup={true}
                onClick={this.handleNavClick}>Menu</a>
          </li>
        </ul>
        <Tray isOpen={this.state.isTrayOpen}
              onBlur={this.closeTray}
              closeTimeoutMS={150}
        >
          <h1>Tray Content</h1>
          <div>Learn to drive and everything.</div>
        </Tray>
      </div>
    );
  }
});

React.render(<App/>, document.getElementById('content'));
```

