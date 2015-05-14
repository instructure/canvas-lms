/** @jsx React.DOM */
var React = require('react');
var Tray = require('../../lib/main');

function cx(map) {
  var className = [];
  Object.keys(map).forEach(function (key) {
    if (map[key]) {
      className.push(key);
    }
  });
  return className.join(' ');
}

var App = React.createClass({
  getInitialState: function () {
    return {
      orientation: 'left',
      isTrayOpen: false
    };
  },

  handleNavClick: function (e) {
    var type = e.target.getAttribute('data-type');
    this.openTray(type);
  },

  handleNavKeyPress: function (e) {
    if (e.which === 13 || e.which === 32) {
      var type = e.target.getAttribute('data-type');
      this.openTray(type);
    }
  },

  handleOrientationChange: function (e) {
    this.setState({
      orientation: e.target.value
    });
  },

  openTray: function (type) {
    this.setState({
      type: type,
      isTrayOpen: true
    });
  },

  closeTray: function () {
    this.setState({
      isTrayOpen: false
    }, function () {
      setTimeout(function () {
        this.setState({
          type: null
        });
      }.bind(this), 150);
    });
  },

  renderTrayContent: function () {
    switch (this.state.type) {
      case 'foo':
        return (
          <div>
            <h2>Foo</h2>
            <div>Content for foo</div>
            <nav role="navigation">
              <div><a href="javascript://">A</a></div>
              <div><a href="javascript://">B</a></div>
              <div><a href="javascript://">C</a></div>
            </nav>
          </div>
        );
        break;
      case 'bar':
        return (
          <div>
            <h2>Bar</h2>
            <div>Lorem Ipsum</div>
            <nav role="navigation">
              <div><a href="javascript://">A</a></div>
              <div><a href="javascript://">B</a></div>
              <div><a href="javascript://">C</a></div>
            </nav>
          </div>
        );
        break;
      case 'baz':
        return (
          <div>
            <h2>Baz</h2>
            <div>Other stuff here</div>
            <nav role="navigation">
              <div><a href="javascript://">A</a></div>
              <div><a href="javascript://">B</a></div>
              <div><a href="javascript://">C</a></div>
            </nav>
          </div>
        );
        break;
      default:
        return (
          <h1>You shouldn't see me</h1>
        );
    }
  },
 
  render: function () {
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
                aria-haspopup={true}
                data-type="foo"
                onKeyPress={this.handleNavKeyPress}
                onClick={this.handleNavClick}>Foo</a>
          </li>
          <li role="menuitem"
              className={cx({ active: this.state.type === 'bar' })}
          >
            <a tabIndex={0}
                role="button"
                aria-haspopup={true}
                data-type="bar"
                onKeyPress={this.handleNavKeyPress}
                onClick={this.handleNavClick}>Bar</a>
          </li>
          <li role="menuitem"
              className={cx({ active: this.state.type === 'baz' })}
          >
            <a tabIndex={0}
                role="button"
                aria-haspopup={true}
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
  }
});

React.render(<App/>, document.getElementById('example'));
