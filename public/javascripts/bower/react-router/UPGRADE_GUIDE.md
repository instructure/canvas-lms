Upgrade Guide
=============

To see discussion around these API changes, please refer to the
[changelog](/CHANGELOG.md) and visit the commits and issues they
reference.

0.7.x -> 0.9.x
--------------

### `ActiveState` mixin `isActive`

`isActive` is now an instance method.

```js
// 0.7.x
var SomethingActive = React.createClass({
  mixins: [ActiveState],

  render: function () {
    var isActive = SomethingActive.isActive(...);
  }
});

// 0.9.x
var SomethingActive = React.createClass({
  mixins: [ActiveState],

  render: function () {
    var isActive = this.isActive(...);
  }
});
```

### `<Routes onActiveStateChange/>` -> `<Routes onChange />`

```js
// 0.7.x
<Routes onActiveStateChange={fn} />

function fn(nextState) {}

// 0.9.x
<Routes onChange={fn} />

function fn() {
  // no arguments
  // `this` is the routes instance
  // here are some useful methods to get at the data you probably need
  this.getCurrentPath();
  this.getActiveRoutes();
  this.getActiveParams();
  this.getActiveQuery();
}
```

### `.` in params support

`.` used to be a delimiter like `/`, but now its a valid character in
your params.

### `transition.retry()`

`transition.retry()` used to use `transitionTo`, creating a new history
entry, it now uses `replaceWith`.

```js
// 0.7.x
React.createClass({
  login: function() {
    // ...
    transition.retry();
  }
});

// 0.9.x
React.createClass({
  mixins: [Navigation],
  login: function() {
    // ...
    this.transitionTo(transition.path);
  }
});
```

### Returning promises from transition hooks

Transition hooks are now sync, unless you opt-in to async with
`transition.wait(promise)`.

```js
// 0.7.x
React.createClass({
  statics: {
    willTransitionTo: function(transition) {
      return somePromise();
    }
  }
});

// 0.9.x
React.createClass({
  statics: {
    willTransitionTo: function(transition) {
      transition.wait(somePromise());
    }
  }
});
```

### `preserveScrollPosition` -> `scrollBehavior`

`preserveScrollPosition` was totally broken and should have been named
`perverseScrollPosition`.


There are now three scroll behaviors you can use:

- `'browser'`
- `'scrollToTop'`
- `'none'`

`browser` is the default, and imitates what browsers do in a typical
page reload scenario (preserves scroll positions when using the back
button, scrolls up when you come to a new page, etc.) Also, you can no
longer specify scroll behavior per `<Route/>` anymore, only `<Routes/>`

```
<Routes scrollBehavior="scrollToTop"/>
```

### RouteStore

This was not a public module, but we know some people were using it.
It's gone now. We have made getting at the current routes incredibly
convenient now with additions to the `ActiveState` mixin.

### `Router.transitionTo, replaceWith, goBack`

These methods have been moved to mixins.

```js
var Router = require('react-router');

// 0.7.x
React.createClass({
  whenever: function() {
    Router.transitionTo('something');
    Router.replaceWith('something');
    Router.goBack();
  }
});

// 0.9.x
var Navigation = Router.Navigation;

React.createClass({
  mixins: [Navigation],
  whenever: function() {
    this.transitionTo('something');
    this.replaceWith('something');
    this.goBack();
  }
});
```

### `<Routes onTransitionError onAbortedTransition/>`

These were removed, there is no upgrade path in `0.9.0` but we will have
something soon. These weren't intended to be used.

### `ActiveState` lifecycle method `updateActiveState` removed

We didn't actually need this. Just use `this.isActive(to, params,
query)`.

### `AsyncState` mixin removed

There is no upgrade path. Just use `comoponentDidMount` to request
state. This was some groundwork for server-side rendering but we are
going a different direction now (using props passed in to route
handlers) so we've removed it.

0.7.x -> 0.8.x
--------------

Please don't upgrade to `0.8.0`, just skip to `0.9.x`.

`0.8.0` had some transient mixins we didn't intend to document, but had
some miscommunication :( If you were one of three people who used some
of these mixins and need help upgrading from `0.8.0 -> 0.9.x` find us on
freenode in `#rackt` or open a ticket. Thanks!

0.6.x -> 0.7.x
--------------

The package root modules were removed. Please import modules from the
`Router` default export.

```js
// 0.6.x
var Link = require('react-router/Link');

// 0.7.x
var Router = require('react-router');
var Link = Router.Link;
```

0.5.x -> 0.6.x
--------------

### Path Matching

Paths that start with `/` are absolute and work exactly as they used to.
Paths that don't start with `/` are now relative, meaning they extend
their parent route.

Simply add `/` in front of all your paths to keep things working.

```xml
<!-- 0.5.x -->
<Route path="/foo">
  <Route path="bar"/>
</Route>

<!-- 0.6.x -->
<Route path="/foo">
  <Route path="/bar"/>
</Route>
```

Though, you may want to embrace this new feature:

```xml
<!-- 0.5.x -->
<Route path="/course/:courseId">
  <Route path="/course/:courseId/assignments"/>
  <Route path="/course/:courseId/announcements"/>
</Route>

<!-- 0.6.x -->
<Route path="/course/:courseId">
  <Route path="assignments"/>
  <Route path="announcements"/>
</Route>
```

Also `.` is no longer matched in dynamic segments.

```xml
<!-- 0.5.x -->
<Route path="/file/:filename" />

<!-- 0.6.x -->
<Route path="/file/:filename.?:ext?" />

<!--
  or for a looser match to allow for multiple `.` note that the data
  will be available on `this.props.params.splat` instead of
  `this.props.params.filename`
-->
<Route path="/file/*" />
```

### Link params

Links should now pass their params in the `params` property, though the
old behavior will still work, you should update your code soon because
it will be removed by `v1.0`

```js
// 0.5.x
<Link to="user" userId="123"/>

// 0.6.x
<Link to="user" params={{userId: "123"}}/>
```

### Dynamic Segments, keys, and lifecycle methods

If you have dynamic segments and are depending on `getInitialState`,
`componentWillMount`, or `componentDidMount` to fire between transitions
to the same route--like `users/123` and `users/456`--then you have two
options:

- add `addHandlerKey={true}` to your route and keep the previous
  behavior (but lose out on performance), or
- implement `componentWillReceiveProps`.

```js
// 0.5.x
<Route handler={User} path="/user/:userId"/>

// 0.6.x
<Route handler={User} path="/user/:userId" addHandlerKey={true} />

// 0.5.x
var User = React.createClass({
  getInitialState: function() {
    return {
      user: getUser(this.props.params.userId);
    }
  }
});

// 0.6.x
var User = React.createClass({
  getInitialState: function() {
    return this.getState();
  },

  componentWillReceiveProps: function(newProps) {
    this.setState(this.getState(newProps));
  },

  getState: function(props) {
    props = props || this.props;
    return {
      user: getUser(props.params.userId)
    };
  }
});
```

0.4.x -> 0.5.x
--------------

We brought back `<Routes/>`.

```js
// 0.4.x
var routes = (
  <Route handler={App} location="history">
    <Route name="about" handler="about"/>
  </Route>
);

// 0.5.x
var routes = (
  <Routes location="history">
    <Route handler={App}>
      <Route name="about" handler="about"/>
    </Route>
  </Routes>
);
```

0.3.x -> 0.4.x
--------------

NPM users should point their apps to `react-router` instead of
`react-nested-router`. Make sure to `npm prune`!

0.2.x -> 0.3.x
--------------

- React `0.11.x` is now required.
- `this.props.activeRoute` became `this.props.activeRouteHandler()`

```js
// 0.2.x

var App = React.createClass({
  render: function() {
    return (
      <div>
        {this.props.activeRoute}
      </div>
    );
  }
});

// 0.3.x
var App = React.createClass({
  render: function() {
    // now you can send extra props to the active route handler
    // and use the new jsx syntax
    // <this.props.activeRouteHandler extraProp={something}/>
    return (
      <div>
        {this.props.activeRouteHandler()}
      </div>
    );
  }
});
```

0.1.x -> 0.2.x
--------------

The `Router` function was removed.

```js
// 0.1.x
var router = Router(routes);
router.renderComponent(element);

// 0.2.x
React.renderComponent(routes, element);
```

