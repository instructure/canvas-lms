!(function (e) {
  if (typeof exports === 'object' && typeof module !== 'undefined') module.exports = e();
  else if (typeof define === 'function' && define.amd) define(['old_version_of_react_used_by_canvas_quizzes_client_apps'], e);
  else {
    let f;
    typeof window !== 'undefined' ? f = window : typeof global !== 'undefined' ? f = global : typeof self !== 'undefined' && (f = self), f.ReactRouter = e()
  }
}(() => {
  let define,
    module,
    exports;
  return (function e (t, n, r) {
    function s (o, u) {
      if (!n[o]) {
        if (!t[o]) {
          // INSTRUCTURE put this line to make it work for webpack
          if (o === 'old_version_of_react_used_by_canvas_quizzes_client_apps') return require('old_version_of_react_used_by_canvas_quizzes_client_apps');
          const a = typeof require === 'function' && require;
          if (!u && a) return a(o, !0);
          if (i) return i(o, !0);
          throw new Error(`Cannot find module '${o}'`)
        }
        const f = n[o] = {
          exports: {}
        };
        t[o][0].call(f.exports, (e) => {
          const n = t[o][1][e];
          return s(n || e)
        }, f, f.exports, e, t, n, r)
      }
      return n[o].exports
    }
    var i = typeof require === 'function' && require;
    for (let o = 0; o < r.length; o++) s(r[o]);
    return s
  }({ 1: [function (_dereq_, module, exports) {
/**
 * Actions that modify the URL.
 */
    const LocationActions = {

  /**
   * Indicates a new location is being pushed to the history stack.
   */
      PUSH: 'push',

  /**
   * Indicates the current location should be replaced.
   */
      REPLACE: 'replace',

  /**
   * Indicates the most recent entry should be removed from the history stack.
   */
      POP: 'pop'

    };

    module.exports = LocationActions;
  }, {}],
    2: [function (_dereq_, module, exports) {
      const LocationActions = _dereq_('../actions/LocationActions');

/**
 * A scroll behavior that attempts to imitate the default behavior
 * of modern browsers.
 */
      const ImitateBrowserBehavior = {

        updateScrollPosition (position, actionType) {
          switch (actionType) {
            case LocationActions.PUSH:
            case LocationActions.REPLACE:
              window.scrollTo(0, 0);
              break;
            case LocationActions.POP:
              if (position) {
                window.scrollTo(position.x, position.y);
              } else {
                window.scrollTo(0, 0);
              }
              break;
          }
        }

      };

      module.exports = ImitateBrowserBehavior;
    }, { '../actions/LocationActions': 1 }],
    3: [function (_dereq_, module, exports) {
/**
 * A scroll behavior that always scrolls to the top of the page
 * after a transition.
 */
      const ScrollToTopBehavior = {

        updateScrollPosition () {
          window.scrollTo(0, 0);
        }

      };

      module.exports = ScrollToTopBehavior;
    }, {}],
    4: [function (_dereq_, module, exports) {
      const merge = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge');
      const Route = _dereq_('./Route');

/**
 * A <DefaultRoute> component is a special kind of <Route> that
 * renders when its parent matches but none of its siblings do.
 * Only one such route may be used at any given level in the
 * route hierarchy.
 */
      function DefaultRoute (props) {
        return Route(
    merge(props, {
      path: null,
      isDefault: true
    })
  );
      }

      module.exports = DefaultRoute;
    }, { './Route': 8, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge': 71 }],
    5: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const classSet = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/cx');
      const merge = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge');
      const ActiveState = _dereq_('../mixins/ActiveState');
      const Navigation = _dereq_('../mixins/Navigation');

      function isLeftClickEvent (event) {
        return event.button === 0;
      }

      function isModifiedEvent (event) {
        return !!(event.metaKey || event.altKey || event.ctrlKey || event.shiftKey);
      }

/**
 * <Link> components are used to create an <a> element that links to a route.
 * When that route is active, the link gets an "active" class name (or the
 * value of its `activeClassName` prop).
 *
 * For example, assuming you have the following route:
 *
 *   <Route name="showPost" path="/posts/:postID" handler={Post}/>
 *
 * You could use the following component to link to that route:
 *
 *   <Link to="showPost" params={{ postID: "123" }} />
 *
 * In addition to params, links may pass along query string parameters
 * using the `query` prop.
 *
 *   <Link to="showPost" params={{ postID: "123" }} query={{ show:true }}/>
 */
      const Link = React.createClass({

        displayName: 'Link',

        mixins: [ActiveState, Navigation],

        propTypes: {
          activeClassName: React.PropTypes.string.isRequired,
          to: React.PropTypes.string.isRequired,
          params: React.PropTypes.object,
          query: React.PropTypes.object,
          onClick: React.PropTypes.func
        },

        getDefaultProps () {
          return {
            activeClassName: 'active'
          };
        },

        handleClick (event) {
          let allowTransition = true;
          let clickResult;

          if (this.props.onClick) { clickResult = this.props.onClick(event); }

          if (isModifiedEvent(event) || !isLeftClickEvent(event)) { return; }

          if (clickResult === false || event.defaultPrevented === true) { allowTransition = false; }

          event.preventDefault();

          if (allowTransition) { this.transitionTo(this.props.to, this.props.params, this.props.query); }
        },

  /**
   * Returns the value of the "href" attribute to use on the DOM element.
   */
        getHref () {
          return this.makeHref(this.props.to, this.props.params, this.props.query);
        },

  /**
   * Returns the value of the "class" attribute to use on the DOM element, which contains
   * the value of the activeClassName property when this <Link> is active.
   */
        getClassName () {
          const classNames = {};

          if (this.props.className) { classNames[this.props.className] = true; }

          if (this.isActive(this.props.to, this.props.params, this.props.query)) { classNames[this.props.activeClassName] = true; }

          return classSet(classNames);
        },

        render () {
          const props = merge(this.props, {
            href: this.getHref(),
            className: this.getClassName(),
            onClick: this.handleClick
          });

          return React.DOM.a(props, this.props.children);
        }

      });

      module.exports = Link;
    }, { '../mixins/ActiveState': 15, '../mixins/Navigation': 18, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/cx': 61, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge': 71 }],
    6: [function (_dereq_, module, exports) {
      const merge = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge');
      const Route = _dereq_('./Route');

/**
 * A <NotFoundRoute> is a special kind of <Route> that
 * renders when the beginning of its parent's path matches
 * but none of its siblings do, including any <DefaultRoute>.
 * Only one such route may be used at any given level in the
 * route hierarchy.
 */
      function NotFoundRoute (props) {
        return Route(
    merge(props, {
      path: null,
      catchAll: true
    })
  );
      }

      module.exports = NotFoundRoute;
    }, { './Route': 8, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/merge': 71 }],
    7: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const Route = _dereq_('./Route');

      function createRedirectHandler (to, _params, _query) {
        return React.createClass({
          statics: {
            willTransitionTo (transition, params, query) {
              transition.redirect(to, _params || params, _query || query);
            }
          },

          render () {
            return null;
          }
        });
      }

/**
 * A <Redirect> component is a special kind of <Route> that always
 * redirects to another route when it matches.
 */
      function Redirect (props) {
        return Route({
          name: props.name,
          path: props.from || props.path || '*',
          handler: createRedirectHandler(props.to, props.params, props.query)
        });
      }

      module.exports = Redirect;
    }, { './Route': 8 }],
    8: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const withoutProperties = _dereq_('../utils/withoutProperties');

/**
 * A map of <Route> component props that are reserved for use by the
 * router and/or React. All other props are considered "static" and
 * are passed through to the route handler.
 */
      const RESERVED_PROPS = {
        handler: true,
        path: true,
        defaultRoute: true,
        notFoundRoute: true,
        paramNames: true,
        children: true // ReactChildren
      };

/**
 * <Route> components specify components that are rendered to the page when the
 * URL matches a given pattern.
 *
 * Routes are arranged in a nested tree structure. When a new URL is requested,
 * the tree is searched depth-first to find a route whose path matches the URL.
 * When one is found, all routes in the tree that lead to it are considered
 * "active" and their components are rendered into the DOM, nested in the same
 * order as they are in the tree.
 *
 * The preferred way to configure a router is using JSX. The XML-like syntax is
 * a great way to visualize how routes are laid out in an application.
 *
 *   React.renderComponent((
 *     <Routes handler={App}>
 *       <Route name="login" handler={Login}/>
 *       <Route name="logout" handler={Logout}/>
 *       <Route name="about" handler={About}/>
 *     </Routes>
 *   ), document.body);
 *
 * If you don't use JSX, you can also assemble a Router programmatically using
 * the standard React component JavaScript API.
 *
 *   React.renderComponent((
 *     Routes({ handler: App },
 *       Route({ name: 'login', handler: Login }),
 *       Route({ name: 'logout', handler: Logout }),
 *       Route({ name: 'about', handler: About })
 *     )
 *   ), document.body);
 *
 * Handlers for Route components that contain children can render their active
 * child route using the activeRouteHandler prop.
 *
 *   var App = React.createClass({
 *     render: function () {
 *       return (
 *         <div class="application">
 *           {this.props.activeRouteHandler()}
 *         </div>
 *       );
 *     }
 *   });
 */
      const Route = React.createClass({

        displayName: 'Route',

        statics: {

          getUnreservedProps (props) {
            return withoutProperties(props, RESERVED_PROPS);
          }

        },

        propTypes: {
          handler: React.PropTypes.any.isRequired,
          path: React.PropTypes.string,
          name: React.PropTypes.string,
          ignoreScrollBehavior: React.PropTypes.bool
        },

        render () {
          throw new Error(
      'The <Route> component should not be rendered directly. You may be ' +
      'missing a <Routes> wrapper around your list of routes.'
    );
        }

      });

      module.exports = Route;
    }, { '../utils/withoutProperties': 30 }],
    9: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const warning = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/warning');
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const copyProperties = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties');
      const HashLocation = _dereq_('../locations/HashLocation');
      const ActiveContext = _dereq_('../mixins/ActiveContext');
      const LocationContext = _dereq_('../mixins/LocationContext');
      const RouteContext = _dereq_('../mixins/RouteContext');
      const ScrollContext = _dereq_('../mixins/ScrollContext');
      const reversedArray = _dereq_('../utils/reversedArray');
      const Transition = _dereq_('../utils/Transition');
      const Redirect = _dereq_('../utils/Redirect');
      const Path = _dereq_('../utils/Path');
      const Route = _dereq_('./Route');

      function makeMatch (route, params) {
        return { route, params };
      }

      function getRootMatch (matches) {
        return matches[matches.length - 1];
      }

      function findMatches (path, routes, defaultRoute, notFoundRoute) {
        let matches = null,
          route,
          params;

        for (let i = 0, len = routes.length; i < len; ++i) {
          route = routes[i];

    // Check the subtree first to find the most deeply-nested match.
          matches = findMatches(path, route.props.children, route.props.defaultRoute, route.props.notFoundRoute);

          if (matches != null) {
            var rootParams = getRootMatch(matches).params;

            params = route.props.paramNames.reduce((params, paramName) => {
              params[paramName] = rootParams[paramName];
              return params;
            }, {});

            matches.unshift(makeMatch(route, params));

            return matches;
          }

    // No routes in the subtree matched, so check this route.
          params = Path.extractParams(route.props.path, path);

          if (params) { return [makeMatch(route, params)]; }
        }

  // No routes matched, so try the default route if there is one.
        if (defaultRoute && (params = Path.extractParams(defaultRoute.props.path, path))) { return [makeMatch(defaultRoute, params)]; }

  // Last attempt: does the "not found" route match?
        if (notFoundRoute && (params = Path.extractParams(notFoundRoute.props.path, path))) { return [makeMatch(notFoundRoute, params)]; }

        return matches;
      }

      function hasMatch (matches, match) {
        return matches.some((m) => {
          if (m.route !== match.route) { return false; }

          for (const property in m.params) { if (m.params[property] !== match.params[property]) { return false; } }

          return true;
        });
      }

/**
 * Calls the willTransitionFrom hook of all handlers in the given matches
 * serially in reverse with the transition object and the current instance of
 * the route's handler, so that the deepest nested handlers are called first.
 * Calls callback(error) when finished.
 */
      function runTransitionFromHooks (matches, transition, callback) {
        const hooks = reversedArray(matches).map(match => function () {
          const handler = match.route.props.handler;

          if (!transition.isAborted && handler.willTransitionFrom) { return handler.willTransitionFrom(transition, match.component); }

          const promise = transition.promise;
          delete transition.promise;

          return promise;
        });

        runHooks(hooks, callback);
      }

/**
 * Calls the willTransitionTo hook of all handlers in the given matches
 * serially with the transition object and any params that apply to that
 * handler. Calls callback(error) when finished.
 */
      function runTransitionToHooks (matches, transition, query, callback) {
        const hooks = matches.map(match => function () {
          const handler = match.route.props.handler;

          if (!transition.isAborted && handler.willTransitionTo) { handler.willTransitionTo(transition, match.params, query); }

          const promise = transition.promise;
          delete transition.promise;

          return promise;
        });

        runHooks(hooks, callback);
      }

/**
 * Runs all hook functions serially and calls callback(error) when finished.
 * A hook may return a promise if it needs to execute asynchronously.
 */
      function runHooks (hooks, callback) {
        try {
          var promise = hooks.reduce((promise, hook) =>
      // The first hook to use transition.wait makes the rest
      // of the transition async from that point forward.
       promise ? promise.then(hook) : hook(), null);
        } catch (error) {
          return callback(error); // Sync error.
        }

        if (promise) {
    // Use setTimeout to break the promise chain.
          promise.then(() => {
            setTimeout(callback);
          }, (error) => {
            setTimeout(() => {
              callback(error);
            });
          });
        } else {
          callback();
        }
      }

      function updateMatchComponents (matches, refs) {
        let match;
        for (let i = 0, len = matches.length; i < len; ++i) {
          match = matches[i];
          match.component = refs.__activeRoute__;

          if (match.component == null) { break; } // End of the tree.

          refs = match.component.refs;
        }
      }

      function shouldUpdateScroll (currentMatches, previousMatches) {
        const commonMatches = currentMatches.filter(match => previousMatches.indexOf(match) !== -1);

        return !commonMatches.some(match => match.route.props.ignoreScrollBehavior);
      }

      function returnNull () {
        return null;
      }

      function routeIsActive (activeRoutes, routeName) {
        return activeRoutes.some(route => route.props.name === routeName);
      }

      function paramsAreActive (activeParams, params) {
        for (const property in params) {
          if (String(activeParams[property]) !== String(params[property])) { return false; }
        }

        return true;
      }

      function queryIsActive (activeQuery, query) {
        for (const property in query) {
          if (String(activeQuery[property]) !== String(query[property])) { return false; }
        }

        return true;
      }

      function defaultTransitionErrorHandler (error) {
  // Throw so we don't silently swallow async errors.
        throw error; // This error probably originated in a transition hook.
      }

/**
 * The <Routes> component configures the route hierarchy and renders the
 * route matching the current location when rendered into a document.
 *
 * See the <Route> component for more details.
 */
      const Routes = React.createClass({

        displayName: 'Routes',

        mixins: [RouteContext, ActiveContext, LocationContext, ScrollContext],

        propTypes: {
          initialPath: React.PropTypes.string,
          initialMatches: React.PropTypes.array,
          onChange: React.PropTypes.func,
          onError: React.PropTypes.func.isRequired
        },

        getDefaultProps () {
          return {
            initialPath: null,
            initialMatches: [],
            onError: defaultTransitionErrorHandler
          };
        },

        getInitialState () {
          return {
            path: this.props.initialPath,
            matches: this.props.initialMatches
          };
        },

        componentDidMount () {
          warning(
      this._owner == null,
      '<Routes> should be rendered directly using React.renderComponent, not ' +
      'inside some other component\'s render method'
    );

          this._handleStateChange();
        },

        componentDidUpdate () {
          this._handleStateChange();
        },

  /**
   * Performs a depth-first search for the first route in the tree that matches on
   * the given path. Returns an array of all routes in the tree leading to the one
   * that matched in the format { route, params } where params is an object that
   * contains the URL parameters relevant to that route. Returns null if no route
   * in the tree matches the path.
   *
   *   React.renderComponent(
   *     <Routes>
   *       <Route handler={App}>
   *         <Route name="posts" handler={Posts}/>
   *         <Route name="post" path="/posts/:id" handler={Post}/>
   *       </Route>
   *     </Routes>
   *   ).match('/posts/123'); => [ { route: <AppRoute>, params: {} },
   *                               { route: <PostRoute>, params: { id: '123' } } ]
   */
        match (path) {
          const routes = this.getRoutes();
          return findMatches(Path.withoutQuery(path), routes, this.props.defaultRoute, this.props.notFoundRoute);
        },

        updateLocation (path, actionType) {
          if (this.state.path === path) { return; } // Nothing to do!

          if (this.state.path) { this.recordScroll(this.state.path); }

          this.dispatch(path, function (error, abortReason, nextState) {
            if (error) {
              this.props.onError.call(this, error);
            } else if (abortReason instanceof Redirect) {
            this.replaceWith(abortReason.to, abortReason.params, abortReason.query);
          } else if (abortReason) {
        this.goBack();
      } else {
        this._nextStateChangeHandler = this._finishTransitionTo.bind(this, path, actionType, this.state.matches);
        this.setState(nextState);
      }
          });
        },

        _handleStateChange () {
          if (this._nextStateChangeHandler) {
            this._nextStateChangeHandler();
            delete this._nextStateChangeHandler;
          }
        },

        _finishTransitionTo (path, actionType, previousMatches) {
          const currentMatches = this.state.matches;
          updateMatchComponents(currentMatches, this.refs);

          if (shouldUpdateScroll(currentMatches, previousMatches)) { this.updateScroll(path, actionType); }

          if (this.props.onChange) { this.props.onChange.call(this); }
        },

  /**
   * Performs a transition to the given path and calls callback(error, abortReason, nextState)
   * when the transition is finished. If there was an error, the first argument will not be null.
   * Otherwise, if the transition was aborted for some reason, it will be given in the second arg.
   *
   * In a transition, the router first determines which routes are involved by beginning with the
   * current route, up the route tree to the first parent route that is shared with the destination
   * route, and back down the tree to the destination route. The willTransitionFrom hook is invoked
   * on all route handlers we're transitioning away from, in reverse nesting order. Likewise, the
   * willTransitionTo hook is invoked on all route handlers we're transitioning to.
   *
   * Both willTransitionFrom and willTransitionTo hooks may either abort or redirect the transition.
   * To resolve asynchronously, they may use transition.wait(promise). If no hooks wait, the
   * transition will be synchronous.
   */
        dispatch (path, callback) {
          const transition = new Transition(this, path);
          const currentMatches = this.state ? this.state.matches : []; // No state server-side.
          const nextMatches = this.match(path) || [];

          warning(
      nextMatches.length,
      'No route matches path "%s". Make sure you have <Route path="%s"> somewhere in your <Routes>',
      path, path
    );

          let fromMatches,
            toMatches;
          if (currentMatches.length) {
            fromMatches = currentMatches.filter(match => !hasMatch(nextMatches, match));

            toMatches = nextMatches.filter(match => !hasMatch(currentMatches, match));
          } else {
            fromMatches = [];
            toMatches = nextMatches;
          }

          const callbackScope = this;
          const query = Path.extractQuery(path) || {};

          runTransitionFromHooks(fromMatches, transition, (error) => {
            if (error || transition.isAborted) { return callback.call(callbackScope, error, transition.abortReason); }

            runTransitionToHooks(toMatches, transition, query, (error) => {
              if (error || transition.isAborted) { return callback.call(callbackScope, error, transition.abortReason); }

              const matches = currentMatches.slice(0, currentMatches.length - fromMatches.length).concat(toMatches);
              const rootMatch = getRootMatch(matches);
              const params = (rootMatch && rootMatch.params) || {};
              const routes = matches.map(match => match.route);

              callback.call(callbackScope, null, null, {
              path,
              matches,
              activeRoutes: routes,
              activeParams: params,
              activeQuery: query
            });
            });
          });
        },

  /**
   * Returns the props that should be used for the top-level route handler.
   */
        getHandlerProps () {
          const matches = this.state.matches;
          const query = this.state.activeQuery;
          let handler = returnNull;
          let props = {
            ref: null,
            params: null,
            query: null,
            activeRouteHandler: handler,
            key: null
          };

          reversedArray(matches).forEach(function (match) {
            const route = match.route;

            props = Route.getUnreservedProps(route.props);

            props.ref = '__activeRoute__';
            props.params = match.params;
            props.query = query;
            props.activeRouteHandler = handler;

      // TODO: Can we remove addHandlerKey?
            if (route.props.addHandlerKey) { props.key = Path.injectParams(route.props.path, match.params); }

            handler = function (props, addedProps) {
              if (arguments.length > 2 && typeof arguments[2] !== 'undefined') { throw new Error('Passing children to a route handler is not supported'); }

              return route.props.handler(
          copyProperties(props, addedProps)
        );
            }.bind(this, props);
          });

          return props;
        },

  /**
   * Returns a reference to the active route handler's component instance.
   */
        getActiveComponent () {
          return this.refs.__activeRoute__;
        },

  /**
   * Returns the current URL path.
   */
        getCurrentPath () {
          return this.state.path;
        },

  /**
   * Returns an absolute URL path created from the given route
   * name, URL parameters, and query values.
   */
        makePath (to, params, query) {
          let path;
          if (Path.isAbsolute(to)) {
            path = Path.normalize(to);
          } else {
            const namedRoutes = this.getNamedRoutes();
            const route = namedRoutes[to];

            invariant(
        route,
        'Unable to find a route named "%s". Make sure you have <Route name="%s"> somewhere in your <Routes>',
        to, to
      );

            path = route.props.path;
          }

          return Path.withQuery(Path.injectParams(path, params), query);
        },

  /**
   * Returns a string that may safely be used as the href of a
   * link to the route with the given name.
   */
        makeHref (to, params, query) {
          const path = this.makePath(to, params, query);

          if (this.getLocation() === HashLocation) { return `#${path}`; }

          return path;
        },

    /**
   * Transitions to the URL specified in the arguments by pushing
   * a new URL onto the history stack.
   */
        transitionTo (to, params, query) {
          const location = this.getLocation();

          invariant(
      location,
      'You cannot use transitionTo without a location'
    );

          location.push(this.makePath(to, params, query));
        },

  /**
   * Transitions to the URL specified in the arguments by replacing
   * the current URL in the history stack.
   */
        replaceWith (to, params, query) {
          const location = this.getLocation();

          invariant(
      location,
      'You cannot use replaceWith without a location'
    );

          location.replace(this.makePath(to, params, query));
        },

  /**
   * Transitions to the previous URL.
   */
        goBack () {
          const location = this.getLocation();

          invariant(
      location,
      'You cannot use goBack without a location'
    );

          location.pop();
        },

  /**
   * Returns true if the given route, params, and query are active.
   */
        isActive (to, params, query) {
          if (Path.isAbsolute(to)) { return to === this.getCurrentPath(); }

          return routeIsActive(this.getActiveRoutes(), to) &&
      paramsAreActive(this.getActiveParams(), params) &&
      (query == null || queryIsActive(this.getActiveQuery(), query));
        },

        render () {
          const match = this.state.matches[0];

          if (match == null) { return null; }

          return match.route.props.handler(
      this.getHandlerProps()
    );
        },

        childContextTypes: {
          currentPath: React.PropTypes.string,
          makePath: React.PropTypes.func.isRequired,
          makeHref: React.PropTypes.func.isRequired,
          transitionTo: React.PropTypes.func.isRequired,
          replaceWith: React.PropTypes.func.isRequired,
          goBack: React.PropTypes.func.isRequired,
          isActive: React.PropTypes.func.isRequired
        },

        getChildContext () {
          return {
            currentPath: this.getCurrentPath(),
            makePath: this.makePath,
            makeHref: this.makeHref,
            transitionTo: this.transitionTo,
            replaceWith: this.replaceWith,
            goBack: this.goBack,
            isActive: this.isActive
          };
        }

      });

      module.exports = Routes;
    }, { '../locations/HashLocation': 11, '../mixins/ActiveContext': 14, '../mixins/LocationContext': 17, '../mixins/RouteContext': 19, '../mixins/ScrollContext': 20, '../utils/Path': 22, '../utils/Redirect': 24, '../utils/Transition': 26, '../utils/reversedArray': 28, './Route': 8, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties': 60, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/warning': 76 }],
    10: [function (_dereq_, module, exports) {
      exports.DefaultRoute = _dereq_('./components/DefaultRoute');
      exports.Link = _dereq_('./components/Link');
      exports.NotFoundRoute = _dereq_('./components/NotFoundRoute');
      exports.Redirect = _dereq_('./components/Redirect');
      exports.Route = _dereq_('./components/Route');
      exports.Routes = _dereq_('./components/Routes');

      exports.ActiveState = _dereq_('./mixins/ActiveState');
      exports.CurrentPath = _dereq_('./mixins/CurrentPath');
      exports.Navigation = _dereq_('./mixins/Navigation');

      exports.renderRoutesToString = _dereq_('./utils/ServerRendering').renderRoutesToString;
      exports.renderRoutesToStaticMarkup = _dereq_('./utils/ServerRendering').renderRoutesToStaticMarkup;
    }, { './components/DefaultRoute': 4, './components/Link': 5, './components/NotFoundRoute': 6, './components/Redirect': 7, './components/Route': 8, './components/Routes': 9, './mixins/ActiveState': 15, './mixins/CurrentPath': 16, './mixins/Navigation': 18, './utils/ServerRendering': 25 }],
    11: [function (_dereq_, module, exports) {
      const LocationActions = _dereq_('../actions/LocationActions');
      const getWindowPath = _dereq_('../utils/getWindowPath');

      function getHashPath () {
        return window.location.hash.substr(1);
      }

      let _actionType;

      function ensureSlash () {
        const path = getHashPath();

        if (path.charAt(0) === '/') { return true; }

        HashLocation.replace(`/${path}`);

        return false;
      }

      let _onChange;

      function onHashChange () {
        if (ensureSlash()) {
          const path = getHashPath();

          _onChange({
      // If we don't have an _actionType then all we know is the hash
      // changed. It was probably caused by the user clicking the Back
      // button, but may have also been the Forward button or manual
      // manipulation. So just guess 'pop'.
            type: _actionType || LocationActions.POP,
            path: getHashPath()
          });

          _actionType = null;
        }
      }

/**
 * A Location that uses `window.location.hash`.
 */
      var HashLocation = {

        setup (onChange) {
          _onChange = onChange;

    // Do this BEFORE listening for hashchange.
          ensureSlash();

          if (window.addEventListener) {
            window.addEventListener('hashchange', onHashChange, false);
          } else {
            window.attachEvent('onhashchange', onHashChange);
          }
        },

        teardown () {
          if (window.removeEventListener) {
            window.removeEventListener('hashchange', onHashChange, false);
          } else {
            window.detachEvent('onhashchange', onHashChange);
          }
        },

        push (path) {
          _actionType = LocationActions.PUSH;
          window.location.hash = path;
        },

        replace (path) {
          _actionType = LocationActions.REPLACE;
          window.location.replace(`${getWindowPath()}#${path}`);
        },

        pop () {
          _actionType = LocationActions.POP;
          window.history.back();
        },

        getCurrentPath: getHashPath,

        toString () {
          return '<HashLocation>';
        }

      };

      module.exports = HashLocation;
    }, { '../actions/LocationActions': 1, '../utils/getWindowPath': 27 }],
    12: [function (_dereq_, module, exports) {
      const LocationActions = _dereq_('../actions/LocationActions');
      const getWindowPath = _dereq_('../utils/getWindowPath');

      let _onChange;

      function onPopState () {
        _onChange({
          type: LocationActions.POP,
          path: getWindowPath()
        });
      }

/**
 * A Location that uses HTML5 history.
 */
      const HistoryLocation = {

        setup (onChange) {
          _onChange = onChange;

          if (window.addEventListener) {
            window.addEventListener('popstate', onPopState, false);
          } else {
            window.attachEvent('popstate', onPopState);
          }
        },

        teardown () {
          if (window.removeEventListener) {
            window.removeEventListener('popstate', onPopState, false);
          } else {
            window.detachEvent('popstate', onPopState);
          }
        },

        push (path) {
          window.history.pushState({ path }, '', path);

          _onChange({
            type: LocationActions.PUSH,
            path: getWindowPath()
          });
        },

        replace (path) {
          window.history.replaceState({ path }, '', path);

          _onChange({
            type: LocationActions.REPLACE,
            path: getWindowPath()
          });
        },

        pop () {
          window.history.back();
        },

        getCurrentPath: getWindowPath,

        toString () {
          return '<HistoryLocation>';
        }

      };

      module.exports = HistoryLocation;
    }, { '../actions/LocationActions': 1, '../utils/getWindowPath': 27 }],
    13: [function (_dereq_, module, exports) {
      const getWindowPath = _dereq_('../utils/getWindowPath');

/**
 * A Location that uses full page refreshes. This is used as
 * the fallback for HistoryLocation in browsers that do not
 * support the HTML5 history API.
 */
      const RefreshLocation = {

        push (path) {
          window.location = path;
        },

        replace (path) {
          window.location.replace(path);
        },

        pop () {
          window.history.back();
        },

        getCurrentPath: getWindowPath,

        toString () {
          return '<RefreshLocation>';
        }

      };

      module.exports = RefreshLocation;
    }, { '../utils/getWindowPath': 27 }],
    14: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const copyProperties = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties');

/**
 * A mixin for components that store the active state of routes,
 * URL parameters, and query.
 */
      const ActiveContext = {

        propTypes: {
          initialActiveRoutes: React.PropTypes.array.isRequired,
          initialActiveParams: React.PropTypes.object.isRequired,
          initialActiveQuery: React.PropTypes.object.isRequired
        },

        getDefaultProps () {
          return {
            initialActiveRoutes: [],
            initialActiveParams: {},
            initialActiveQuery: {}
          };
        },

        getInitialState () {
          return {
            activeRoutes: this.props.initialActiveRoutes,
            activeParams: this.props.initialActiveParams,
            activeQuery: this.props.initialActiveQuery
          };
        },

  /**
   * Returns a read-only array of the currently active routes.
   */
        getActiveRoutes () {
          return this.state.activeRoutes.slice(0);
        },

  /**
   * Returns a read-only object of the currently active URL parameters.
   */
        getActiveParams () {
          return copyProperties({}, this.state.activeParams);
        },

  /**
   * Returns a read-only object of the currently active query parameters.
   */
        getActiveQuery () {
          return copyProperties({}, this.state.activeQuery);
        },

        childContextTypes: {
          activeRoutes: React.PropTypes.array.isRequired,
          activeParams: React.PropTypes.object.isRequired,
          activeQuery: React.PropTypes.object.isRequired
        },

        getChildContext () {
          return {
            activeRoutes: this.getActiveRoutes(),
            activeParams: this.getActiveParams(),
            activeQuery: this.getActiveQuery()
          };
        }

      };

      module.exports = ActiveContext;
    }, { 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties': 60 }],
    15: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');

/**
 * A mixin for components that need to know the routes, URL
 * params and query that are currently active.
 *
 * Example:
 *
 *   var AboutLink = React.createClass({
 *     mixins: [ Router.ActiveState ],
 *     render: function () {
 *       var className = this.props.className;
 *
 *       if (this.isActive('about'))
 *         className += ' is-active';
 *
 *       return React.DOM.a({ className: className }, this.props.children);
 *     }
 *   });
 */
      const ActiveState = {

        contextTypes: {
          activeRoutes: React.PropTypes.array.isRequired,
          activeParams: React.PropTypes.object.isRequired,
          activeQuery: React.PropTypes.object.isRequired,
          isActive: React.PropTypes.func.isRequired
        },

  /**
   * Returns an array of the routes that are currently active.
   */
        getActiveRoutes () {
          return this.context.activeRoutes;
        },

  /**
   * Returns an object of the URL params that are currently active.
   */
        getActiveParams () {
          return this.context.activeParams;
        },

  /**
   * Returns an object of the query params that are currently active.
   */
        getActiveQuery () {
          return this.context.activeQuery;
        },

  /**
   * A helper method to determine if a given route, params, and query
   * are active.
   */
        isActive (to, params, query) {
          return this.context.isActive(to, params, query);
        }

      };

      module.exports = ActiveState;
    }, {}],
    16: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');

/**
 * A mixin for components that need to know the current URL path.
 *
 * Example:
 *
 *   var ShowThePath = React.createClass({
 *     mixins: [ Router.CurrentPath ],
 *     render: function () {
 *       return (
 *         <div>The current path is: {this.getCurrentPath()}</div>
 *       );
 *     }
 *   });
 */
      const CurrentPath = {

        contextTypes: {
          currentPath: React.PropTypes.string.isRequired
        },

  /**
   * Returns the current URL path.
   */
        getCurrentPath () {
          return this.context.currentPath;
        }

      };

      module.exports = CurrentPath;
    }, {}],
    17: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const canUseDOM = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ExecutionEnvironment').canUseDOM;
      const HashLocation = _dereq_('../locations/HashLocation');
      const HistoryLocation = _dereq_('../locations/HistoryLocation');
      const RefreshLocation = _dereq_('../locations/RefreshLocation');
      const PathStore = _dereq_('../stores/PathStore');
      const supportsHistory = _dereq_('../utils/supportsHistory');

/**
 * A hash of { name: location } pairs.
 */
      const NAMED_LOCATIONS = {
        none: null,
        hash: HashLocation,
        history: HistoryLocation,
        refresh: RefreshLocation
      };

/**
 * A mixin for components that manage location.
 */
      const LocationContext = {

        propTypes: {
          location (props, propName, componentName) {
            const location = props[propName];

            if (typeof location === 'string' && !(location in NAMED_LOCATIONS)) { return new Error(`Unknown location "${location}", see ${componentName}`); }
          }
        },

        getDefaultProps () {
          return {
            location: canUseDOM ? HashLocation : null
          };
        },

        componentWillMount () {
          const location = this.getLocation();

          invariant(
      location == null || canUseDOM,
      'Cannot use location without a DOM'
    );

          if (location) {
            PathStore.setup(location);
            PathStore.addChangeListener(this.handlePathChange);

            if (this.updateLocation) { this.updateLocation(PathStore.getCurrentPath(), PathStore.getCurrentActionType()); }
          }
        },

        componentWillUnmount () {
          if (this.getLocation()) { PathStore.removeChangeListener(this.handlePathChange); }
        },

        handlePathChange () {
          if (this.updateLocation) { this.updateLocation(PathStore.getCurrentPath(), PathStore.getCurrentActionType()); }
        },

  /**
   * Returns the location object this component uses.
   */
        getLocation () {
          if (this._location == null) {
            let location = this.props.location;

            if (typeof location === 'string') { location = NAMED_LOCATIONS[location]; }

      // Automatically fall back to full page refreshes in
      // browsers that do not support HTML5 history.
            if (location === HistoryLocation && !supportsHistory()) { location = RefreshLocation; }

            this._location = location;
          }

          return this._location;
        },

        childContextTypes: {
          location: React.PropTypes.object // Not required on the server.
        },

        getChildContext () {
          return {
            location: this.getLocation()
          };
        }

      };

      module.exports = LocationContext;
    }, { '../locations/HashLocation': 11, '../locations/HistoryLocation': 12, '../locations/RefreshLocation': 13, '../stores/PathStore': 21, '../utils/supportsHistory': 29, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ExecutionEnvironment': 42, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    18: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');

/**
 * A mixin for components that modify the URL.
 */
      const Navigation = {

        contextTypes: {
          makePath: React.PropTypes.func.isRequired,
          makeHref: React.PropTypes.func.isRequired,
          transitionTo: React.PropTypes.func.isRequired,
          replaceWith: React.PropTypes.func.isRequired,
          goBack: React.PropTypes.func.isRequired
        },

  /**
   * Returns an absolute URL path created from the given route
   * name, URL parameters, and query values.
   */
        makePath (to, params, query) {
          return this.context.makePath(to, params, query);
        },

  /**
   * Returns a string that may safely be used as the href of a
   * link to the route with the given name.
   */
        makeHref (to, params, query) {
          return this.context.makeHref(to, params, query);
        },

  /**
   * Transitions to the URL specified in the arguments by pushing
   * a new URL onto the history stack.
   */
        transitionTo (to, params, query) {
          this.context.transitionTo(to, params, query);
        },

  /**
   * Transitions to the URL specified in the arguments by replacing
   * the current URL in the history stack.
   */
        replaceWith (to, params, query) {
          this.context.replaceWith(to, params, query);
        },

  /**
   * Transitions to the previous URL.
   */
        goBack () {
          this.context.goBack();
        }

      };

      module.exports = Navigation;
    }, {}],
    19: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const Path = _dereq_('../utils/Path');

/**
 * Performs some normalization and validation on a <Route> component and
 * all of its children.
 */
      function processRoute (route, container, namedRoutes) {
  // Note: parentRoute may be a <Route> _or_ a <Routes>.
        const props = route.props;

        invariant(
    React.isValidClass(props.handler),
    'The handler for the "%s" route must be a valid React class',
    props.name || props.path
  );

        const parentPath = (container && container.props.path) || '/';

        if ((props.path || props.name) && !props.isDefault && !props.catchAll) {
          let path = props.path || props.name;

    // Relative paths extend their parent.
          if (!Path.isAbsolute(path)) { path = Path.join(parentPath, path); }

          props.path = Path.normalize(path);
        } else {
          props.path = parentPath;

          if (props.catchAll) { props.path += '*'; }
        }

        props.paramNames = Path.extractParamNames(props.path);

  // Make sure the route's path has all params its parent needs.
        if (container && Array.isArray(container.props.paramNames)) {
          container.props.paramNames.forEach((paramName) => {
            invariant(
        props.paramNames.indexOf(paramName) !== -1,
        'The nested route path "%s" is missing the "%s" parameter of its parent path "%s"',
        props.path, paramName, container.props.path
      );
          });
        }

  // Make sure the route can be looked up by <Link>s.
        if (props.name) {
          const existingRoute = namedRoutes[props.name];

          invariant(
      !existingRoute || route === existingRoute,
      'You cannot use the name "%s" for more than one route',
      props.name
    );

          namedRoutes[props.name] = route;
        }

  // Handle <NotFoundRoute>.
        if (props.catchAll) {
          invariant(
      container,
      '<NotFoundRoute> must have a parent <Route>'
    );

          invariant(
      container.props.notFoundRoute == null,
      'You may not have more than one <NotFoundRoute> per <Route>'
    );

          container.props.notFoundRoute = route;

          return null;
        }

  // Handle <DefaultRoute>.
        if (props.isDefault) {
          invariant(
      container,
      '<DefaultRoute> must have a parent <Route>'
    );

          invariant(
      container.props.defaultRoute == null,
      'You may not have more than one <DefaultRoute> per <Route>'
    );

          container.props.defaultRoute = route;

          return null;
        }

  // Make sure children is an array.
        props.children = processRoutes(props.children, route, namedRoutes);

        return route;
      }

/**
 * Processes many children <Route>s at once, always returning an array.
 */
      function processRoutes (children, container, namedRoutes) {
        const routes = [];

        React.Children.forEach(children, (child) => {
    // Exclude <DefaultRoute>s and <NotFoundRoute>s.
          if (child = processRoute(child, container, namedRoutes)) { routes.push(child); }
        });

        return routes;
      }

/**
 * A mixin for components that have <Route> children.
 */
      const RouteContext = {

        _processRoutes () {
          this._namedRoutes = {};
          this._routes = processRoutes(this.props.children, this, this._namedRoutes);
        },

  /**
   * Returns an array of <Route>s in this container.
   */
        getRoutes () {
          if (this._routes == null) { this._processRoutes(); }

          return this._routes;
        },

  /**
   * Returns a hash { name: route } of all named <Route>s in this container.
   */
        getNamedRoutes () {
          if (this._namedRoutes == null) { this._processRoutes(); }

          return this._namedRoutes;
        },

  /**
   * Returns the route with the given name.
   */
        getRouteByName (routeName) {
          const namedRoutes = this.getNamedRoutes();
          return namedRoutes[routeName] || null;
        },

        childContextTypes: {
          routes: React.PropTypes.array.isRequired,
          namedRoutes: React.PropTypes.object.isRequired
        },

        getChildContext () {
          return {
            routes: this.getRoutes(),
            namedRoutes: this.getNamedRoutes(),
          };
        }

      };

      module.exports = RouteContext;
    }, { '../utils/Path': 22, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    20: [function (_dereq_, module, exports) {
      const React = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps');
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const canUseDOM = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ExecutionEnvironment').canUseDOM;
      const ImitateBrowserBehavior = _dereq_('../behaviors/ImitateBrowserBehavior');
      const ScrollToTopBehavior = _dereq_('../behaviors/ScrollToTopBehavior');

      function getWindowScrollPosition () {
        invariant(
    canUseDOM,
    'Cannot get current scroll position without a DOM'
  );

        return {
          x: window.scrollX,
          y: window.scrollY
        };
      }

/**
 * A hash of { name: scrollBehavior } pairs.
 */
      const NAMED_SCROLL_BEHAVIORS = {
        none: null,
        browser: ImitateBrowserBehavior,
        imitateBrowser: ImitateBrowserBehavior,
        scrollToTop: ScrollToTopBehavior
      };

/**
 * A mixin for components that manage scroll position.
 */
      const ScrollContext = {

        propTypes: {
          scrollBehavior (props, propName, componentName) {
            const behavior = props[propName];

            if (typeof behavior === 'string' && !(behavior in NAMED_SCROLL_BEHAVIORS)) { return new Error(`Unknown scroll behavior "${behavior}", see ${componentName}`); }
          }
        },

        getDefaultProps () {
          return {
            scrollBehavior: canUseDOM ? ImitateBrowserBehavior : null
          };
        },

        componentWillMount () {
          invariant(
      this.getScrollBehavior() == null || canUseDOM,
      'Cannot use scroll behavior without a DOM'
    );
        },

        recordScroll (path) {
          const positions = this.getScrollPositions();
          positions[path] = getWindowScrollPosition();
        },

        updateScroll (path, actionType) {
          const behavior = this.getScrollBehavior();
          const position = this.getScrollPosition(path) || null;

          if (behavior) { behavior.updateScrollPosition(position, actionType); }
        },

  /**
   * Returns the scroll behavior object this component uses.
   */
        getScrollBehavior () {
          if (this._scrollBehavior == null) {
            let behavior = this.props.scrollBehavior;

            if (typeof behavior === 'string') { behavior = NAMED_SCROLL_BEHAVIORS[behavior]; }

            this._scrollBehavior = behavior;
          }

          return this._scrollBehavior;
        },

  /**
   * Returns a hash of URL paths to their last known scroll positions.
   */
        getScrollPositions () {
          if (this._scrollPositions == null) { this._scrollPositions = {}; }

          return this._scrollPositions;
        },

  /**
   * Returns the last known scroll position for the given URL path.
   */
        getScrollPosition (path) {
          const positions = this.getScrollPositions();
          return positions[path];
        },

        childContextTypes: {
          scrollBehavior: React.PropTypes.object // Not required on the server.
        },

        getChildContext () {
          return {
            scrollBehavior: this.getScrollBehavior()
          };
        }

      };

      module.exports = ScrollContext;
    }, { '../behaviors/ImitateBrowserBehavior': 2, '../behaviors/ScrollToTopBehavior': 3, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ExecutionEnvironment': 42, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    21: [function (_dereq_, module, exports) {
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const EventEmitter = _dereq_('events').EventEmitter;
      const LocationActions = _dereq_('../actions/LocationActions');

      const CHANGE_EVENT = 'change';
      const _events = new EventEmitter();

      function notifyChange () {
        _events.emit(CHANGE_EVENT);
      }

      let _currentLocation,
        _currentActionType;
      let _currentPath = '/';

      function handleLocationChangeAction (action) {
        if (_currentPath !== action.path) {
          _currentPath = action.path;
          _currentActionType = action.type;
          notifyChange();
        }
      }

/**
 * The PathStore keeps track of the current URL path.
 */
      var PathStore = {

        addChangeListener (listener) {
          _events.addListener(CHANGE_EVENT, listener);
        },

        removeChangeListener (listener) {
          _events.removeListener(CHANGE_EVENT, listener);
        },

        removeAllChangeListeners () {
          _events.removeAllListeners(CHANGE_EVENT);
        },

  /**
   * Setup the PathStore to use the given location.
   */
        setup (location) {
          invariant(
      _currentLocation == null || _currentLocation === location,
      'You cannot use %s and %s on the same page',
      _currentLocation, location
    );

          if (_currentLocation !== location) {
            if (location.setup) { location.setup(handleLocationChangeAction); }

            _currentPath = location.getCurrentPath();
          }

          _currentLocation = location;
        },

  /**
   * Tear down the PathStore. Really only used for testing.
   */
        teardown () {
          if (_currentLocation && _currentLocation.teardown) { _currentLocation.teardown(); }

          _currentLocation = _currentActionType = null;
          _currentPath = '/';

          PathStore.removeAllChangeListeners();
        },

  /**
   * Returns the current URL path.
   */
        getCurrentPath () {
          return _currentPath;
        },

  /**
   * Returns the type of the action that changed the URL.
   */
        getCurrentActionType () {
          return _currentActionType;
        }

      };

      module.exports = PathStore;
    }, { '../actions/LocationActions': 1, events: 31, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    22: [function (_dereq_, module, exports) {
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');
      const merge = _dereq_('qs/lib/utils').merge;
      const qs = _dereq_('qs');

      function encodeURL (url) {
        return encodeURIComponent(url).replace(/%20/g, '+');
      }

      function decodeURL (url) {
        return decodeURIComponent(url.replace(/\+/g, ' '));
      }

      function encodeURLPath (path) {
        return String(path).split('/').map(encodeURL).join('/');
      }

      const paramCompileMatcher = /:([a-zA-Z_$][a-zA-Z0-9_$]*)|[*.()\[\]\\+|{}^$]/g;
      const paramInjectMatcher = /:([a-zA-Z_$][a-zA-Z0-9_$?]*[?]?)|[*]/g;
      const paramInjectTrailingSlashMatcher = /\/\/\?|\/\?/g;
      const queryMatcher = /\?(.+)/;

      const _compiledPatterns = {};

      function compilePattern (pattern) {
        if (!(pattern in _compiledPatterns)) {
          const paramNames = [];
          const source = pattern.replace(paramCompileMatcher, (match, paramName) => {
            if (paramName) {
              paramNames.push(paramName);
              return '([^/?#]+)';
            } else if (match === '*') {
            paramNames.push('splat');
            return '(.*?)';
          }
            return `\\${match}`;
          });

          _compiledPatterns[pattern] = {
            matcher: new RegExp(`^${source}$`, 'i'),
            paramNames
          };
        }

        return _compiledPatterns[pattern];
      }

      var Path = {

  /**
   * Returns an array of the names of all parameters in the given pattern.
   */
        extractParamNames (pattern) {
          return compilePattern(pattern).paramNames;
        },

  /**
   * Extracts the portions of the given URL path that match the given pattern
   * and returns an object of param name => value pairs. Returns null if the
   * pattern does not match the given path.
   */
        extractParams (pattern, path) {
          const object = compilePattern(pattern);
          const match = decodeURL(path).match(object.matcher);

          if (!match) { return null; }

          const params = {};

          object.paramNames.forEach((paramName, index) => {
            params[paramName] = match[index + 1];
          });

          return params;
        },

  /**
   * Returns a version of the given route path with params interpolated. Throws
   * if there is a dynamic segment of the route path for which there is no param.
   */
        injectParams (pattern, params) {
          params = params || {};

          let splatIndex = 0;

          return pattern.replace(paramInjectMatcher, (match, paramName) => {
            paramName = paramName || 'splat';

      // If param is optional don't check for existence
            if (paramName.slice(-1) !== '?') {
              invariant(
          params[paramName] != null,
          `Missing "${paramName}" parameter for path "${pattern}"`
        );
            } else {
              paramName = paramName.slice(0, -1)
              if (params[paramName] == null) {
              return '';
            }
            }

            let segment;
            if (paramName === 'splat' && Array.isArray(params[paramName])) {
              segment = params[paramName][splatIndex++];

              invariant(
          segment != null,
          `Missing splat # ${splatIndex} for path "${pattern}"`
        );
            } else {
              segment = params[paramName];
            }

            return encodeURLPath(segment);
          }).replace(paramInjectTrailingSlashMatcher, '/');
        },

  /**
   * Returns an object that is the result of parsing any query string contained
   * in the given path, null if the path contains no query string.
   */
        extractQuery (path) {
          const match = path.match(queryMatcher);
          return match && qs.parse(match[1]);
        },

  /**
   * Returns a version of the given path without the query string.
   */
        withoutQuery (path) {
          return path.replace(queryMatcher, '');
        },

  /**
   * Returns a version of the given path with the parameters in the given
   * query merged into the query string.
   */
        withQuery (path, query) {
          const existingQuery = Path.extractQuery(path);

          if (existingQuery) { query = query ? merge(existingQuery, query) : existingQuery; }

          const queryString = query && qs.stringify(query);

          if (queryString) { return `${Path.withoutQuery(path)}?${queryString}`; }

          return path;
        },

  /**
   * Returns true if the given path is absolute.
   */
        isAbsolute (path) {
          return path.charAt(0) === '/';
        },

  /**
   * Returns a normalized version of the given path.
   */
        normalize (path, parentRoute) {
          return path.replace(/^\/*/, '/');
        },

  /**
   * Joins two URL paths together.
   */
        join (a, b) {
          return a.replace(/\/*$/, '/') + b;
        }

      };

      module.exports = Path;
    }, { qs: 32, 'qs/lib/utils': 36, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    23: [function (_dereq_, module, exports) {
      const Promise = _dereq_('when/lib/Promise');

// TODO: Use process.env.NODE_ENV check + envify to enable
// when's promise monitor here when in dev.

      module.exports = Promise;
    }, { 'when/lib/Promise': 77 }],
    24: [function (_dereq_, module, exports) {
/**
 * Encapsulates a redirect to the given route.
 */
      function Redirect (to, params, query) {
        this.to = to;
        this.params = params;
        this.query = query;
      }

      module.exports = Redirect;
    }, {}],
    25: [function (_dereq_, module, exports) {
      const ReactDescriptor = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactDescriptor');
      const ReactInstanceHandles = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactInstanceHandles');
      const ReactMarkupChecksum = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactMarkupChecksum');
      const ReactServerRenderingTransaction = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactServerRenderingTransaction');

      const cloneWithProps = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/cloneWithProps');
      const copyProperties = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties');
      const instantiateReactComponent = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/instantiateReactComponent');
      const invariant = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant');

      function cloneRoutesForServerRendering (routes) {
        return cloneWithProps(routes, {
          location: 'none',
          scrollBehavior: 'none'
        });
      }

      function mergeStateIntoInitialProps (state, props) {
        copyProperties(props, {
          initialPath: state.path,
          initialMatches: state.matches,
          initialActiveRoutes: state.activeRoutes,
          initialActiveParams: state.activeParams,
          initialActiveQuery: state.activeQuery
        });
      }

/**
 * Renders a <Routes> component to a string of HTML at the given URL
 * path and calls callback(error, abortReason, html) when finished.
 *
 * If there was an error during the transition, it is passed to the
 * callback. Otherwise, if the transition was aborted for some reason,
 * it is given in the abortReason argument (with the exception of
 * internal redirects which are transparently handled for you).
 *
 * TODO: <NotFoundRoute> should be handled specially so servers know
 * to use a 404 status code.
 */
      function renderRoutesToString (routes, path, callback) {
        invariant(
    ReactDescriptor.isValidDescriptor(routes),
    'You must pass a valid ReactComponent to renderRoutesToString'
  );

        const component = instantiateReactComponent(
    cloneRoutesForServerRendering(routes)
  );

        component.dispatch(path, (error, abortReason, nextState) => {
          if (error || abortReason) { return callback(error, abortReason); }

          mergeStateIntoInitialProps(nextState, component.props);

          let transaction;
          try {
            const id = ReactInstanceHandles.createReactRootID();
            transaction = ReactServerRenderingTransaction.getPooled(false);

            transaction.perform(() => {
              const markup = component.mountComponent(id, transaction, 0);
              callback(null, null, ReactMarkupChecksum.addChecksumToMarkup(markup));
            }, null);
          } finally {
            ReactServerRenderingTransaction.release(transaction);
          }
        });
      }

/**
 * Renders a <Routes> component to static markup at the given URL
 * path and calls callback(error, abortReason, markup) when finished.
 */
      function renderRoutesToStaticMarkup (routes, path, callback) {
        invariant(
    ReactDescriptor.isValidDescriptor(routes),
    'You must pass a valid ReactComponent to renderRoutesToStaticMarkup'
  );

        const component = instantiateReactComponent(
    cloneRoutesForServerRendering(routes)
  );

        component.dispatch(path, (error, abortReason, nextState) => {
          if (error || abortReason) { return callback(error, abortReason); }

          mergeStateIntoInitialProps(nextState, component.props);

          let transaction;
          try {
            const id = ReactInstanceHandles.createReactRootID();
            transaction = ReactServerRenderingTransaction.getPooled(false);

            transaction.perform(() => {
              callback(null, null, component.mountComponent(id, transaction, 0));
            }, null);
          } finally {
            ReactServerRenderingTransaction.release(transaction);
          }
        });
      }

      module.exports = {
        renderRoutesToString,
        renderRoutesToStaticMarkup
      };
    }, { 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactDescriptor': 47, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactInstanceHandles': 49, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactMarkupChecksum': 50, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/ReactServerRenderingTransaction': 54, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/cloneWithProps': 59, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/copyProperties': 60, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/instantiateReactComponent': 65, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/invariant': 66 }],
    26: [function (_dereq_, module, exports) {
      const mixInto = _dereq_('old_version_of_react_used_by_canvas_quizzes_client_apps/lib/mixInto');
      const Promise = _dereq_('./Promise');
      const Redirect = _dereq_('./Redirect');

/**
 * Encapsulates a transition to a given path.
 *
 * The willTransitionTo and willTransitionFrom handlers receive
 * an instance of this class as their first argument.
 */
      function Transition (routesComponent, path) {
        this.routesComponent = routesComponent;
        this.path = path;
        this.abortReason = null;
        this.isAborted = false;
      }

      mixInto(Transition, {

        abort (reason) {
          this.abortReason = reason;
          this.isAborted = true;
        },

        redirect (to, params, query) {
          this.abort(new Redirect(to, params, query));
        },

        wait (value) {
          this.promise = Promise.resolve(value);
        },

        retry () {
          this.routesComponent.replaceWith(this.path);
        }

      });

      module.exports = Transition;
    }, { './Promise': 23, './Redirect': 24, 'old_version_of_react_used_by_canvas_quizzes_client_apps/lib/mixInto': 74 }],
    27: [function (_dereq_, module, exports) {
/**
 * Returns the current URL path from `window.location`, including query string
 */
      function getWindowPath () {
        return window.location.pathname + window.location.search;
      }

      module.exports = getWindowPath;
    }, {}],
    28: [function (_dereq_, module, exports) {
      function reversedArray (array) {
        return array.slice(0).reverse();
      }

      module.exports = reversedArray;
    }, {}],
    29: [function (_dereq_, module, exports) {
      function supportsHistory () {
  /*! taken from modernizr
   * https://github.com/Modernizr/Modernizr/blob/master/LICENSE
   * https://github.com/Modernizr/Modernizr/blob/master/feature-detects/history.js
   */
        const ua = navigator.userAgent;
        if ((ua.indexOf('Android 2.') !== -1 ||
      (ua.indexOf('Android 4.0') !== -1)) &&
      ua.indexOf('Mobile Safari') !== -1 &&
      ua.indexOf('Chrome') === -1) {
          return false;
        }
        return (window.history && 'pushState' in window.history);
      }

      module.exports = supportsHistory;
    }, {}],
    30: [function (_dereq_, module, exports) {
      function withoutProperties (object, properties) {
        const result = {};

        for (const property in object) {
          if (object.hasOwnProperty(property) && !properties[property]) { result[property] = object[property]; }
        }

        return result;
      }

      module.exports = withoutProperties;
    }, {}],
    31: [function (_dereq_, module, exports) {
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

      function EventEmitter () {
        this._events = this._events || {};
        this._maxListeners = this._maxListeners || undefined;
      }
      module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
      EventEmitter.EventEmitter = EventEmitter;

      EventEmitter.prototype._events = undefined;
      EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
      EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
      EventEmitter.prototype.setMaxListeners = function (n) {
        if (!isNumber(n) || n < 0 || isNaN(n)) { throw TypeError('n must be a positive number'); }
        this._maxListeners = n;
        return this;
      };

      EventEmitter.prototype.emit = function (type) {
        let er,
          handler,
          len,
          args,
          i,
          listeners;

        if (!this._events) { this._events = {}; }

  // If there is no 'error' event listener then throw.
        if (type === 'error') {
          if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
            er = arguments[1];
            if (er instanceof Error) {
              throw er; // Unhandled 'error' event
            } else {
              throw TypeError('Uncaught, unspecified "error" event.');
            }
            return false;
          }
        }

        handler = this._events[type];

        if (isUndefined(handler)) { return false; }

        if (isFunction(handler)) {
          switch (arguments.length) {
      // fast cases
            case 1:
              handler.call(this);
              break;
            case 2:
              handler.call(this, arguments[1]);
              break;
            case 3:
              handler.call(this, arguments[1], arguments[2]);
              break;
      // slower
            default:
              len = arguments.length;
              args = new Array(len - 1);
              for (i = 1; i < len; i++) { args[i - 1] = arguments[i]; }
              handler.apply(this, args);
          }
        } else if (isObject(handler)) {
          len = arguments.length;
          args = new Array(len - 1);
          for (i = 1; i < len; i++) { args[i - 1] = arguments[i]; }

          listeners = handler.slice();
          len = listeners.length;
          for (i = 0; i < len; i++) { listeners[i].apply(this, args); }
        }

        return true;
      };

      EventEmitter.prototype.addListener = function (type, listener) {
        var m;

        if (!isFunction(listener)) { throw TypeError('listener must be a function'); }

        if (!this._events) { this._events = {}; }

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
        if (this._events.newListener) {
          this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);
        }

        if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    { this._events[type] = listener; } else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    { this._events[type].push(listener); } else
    // Adding the second element, need to change to array.
    { this._events[type] = [this._events[type], listener]; }

  // Check for listener leak
        if (isObject(this._events[type]) && !this._events[type].warned) {
          var m;
          if (!isUndefined(this._maxListeners)) {
            m = this._maxListeners;
          } else {
            m = EventEmitter.defaultMaxListeners;
          }

          if (m && m > 0 && this._events[type].length > m) {
            this._events[type].warned = true;
            console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
            if (typeof console.trace === 'function') {
        // not supported in IE 10
              console.trace();
            }
          }
        }

        return this;
      };

      EventEmitter.prototype.on = EventEmitter.prototype.addListener;

      EventEmitter.prototype.once = function (type, listener) {
        if (!isFunction(listener)) { throw TypeError('listener must be a function'); }

        let fired = false;

        function g () {
          this.removeListener(type, g);

          if (!fired) {
            fired = true;
            listener.apply(this, arguments);
          }
        }

        g.listener = listener;
        this.on(type, g);

        return this;
      };

// emits a 'removeListener' event iff the listener was removed
      EventEmitter.prototype.removeListener = function (type, listener) {
        let list,
          position,
          length,
          i;

        if (!isFunction(listener)) { throw TypeError('listener must be a function'); }

        if (!this._events || !this._events[type]) { return this; }

        list = this._events[type];
        length = list.length;
        position = -1;

        if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
          delete this._events[type];
          if (this._events.removeListener) { this.emit('removeListener', type, listener); }
        } else if (isObject(list)) {
          for (i = length; i-- > 0;) {
            if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
            position = i;
            break;
          }
          }

          if (position < 0) { return this; }

          if (list.length === 1) {
            list.length = 0;
            delete this._events[type];
          } else {
            list.splice(position, 1);
          }

          if (this._events.removeListener) { this.emit('removeListener', type, listener); }
        }

        return this;
      };

      EventEmitter.prototype.removeAllListeners = function (type) {
        let key,
          listeners;

        if (!this._events) { return this; }

  // not listening for removeListener, no need to emit
        if (!this._events.removeListener) {
          if (arguments.length === 0) { this._events = {}; } else if (this._events[type]) { delete this._events[type]; }
          return this;
        }

  // emit removeListener for all listeners on all events
        if (arguments.length === 0) {
          for (key in this._events) {
            if (key === 'removeListener') continue;
            this.removeAllListeners(key);
          }
          this.removeAllListeners('removeListener');
          this._events = {};
          return this;
        }

        listeners = this._events[type];

        if (isFunction(listeners)) {
          this.removeListener(type, listeners);
        } else {
    // LIFO order
          while (listeners.length) { this.removeListener(type, listeners[listeners.length - 1]); }
        }
        delete this._events[type];

        return this;
      };

      EventEmitter.prototype.listeners = function (type) {
        let ret;
        if (!this._events || !this._events[type]) { ret = []; } else if (isFunction(this._events[type])) { ret = [this._events[type]]; } else { ret = this._events[type].slice(); }
        return ret;
      };

      EventEmitter.listenerCount = function (emitter, type) {
        let ret;
        if (!emitter._events || !emitter._events[type]) { ret = 0; } else if (isFunction(emitter._events[type])) { ret = 1; } else { ret = emitter._events[type].length; }
        return ret;
      };

      function isFunction (arg) {
        return typeof arg === 'function';
      }

      function isNumber (arg) {
        return typeof arg === 'number';
      }

      function isObject (arg) {
        return typeof arg === 'object' && arg !== null;
      }

      function isUndefined (arg) {
        return arg === void 0;
      }
    }, {}],
    32: [function (_dereq_, module, exports) {
      module.exports = _dereq_('./lib');
    }, { './lib': 33 }],
    33: [function (_dereq_, module, exports) {
// Load modules

      const Stringify = _dereq_('./stringify');
      const Parse = _dereq_('./parse');


// Declare internals

      const internals = {};


      module.exports = {
        stringify: Stringify,
        parse: Parse
      };
    }, { './parse': 34, './stringify': 35 }],
    34: [function (_dereq_, module, exports) {
// Load modules

      const Utils = _dereq_('./utils');


// Declare internals

      const internals = {
        delimiter: '&',
        depth: 5,
        arrayLimit: 20,
        parameterLimit: 1000
      };


      internals.parseValues = function (str, options) {
        const obj = {};
        const parts = str.split(options.delimiter, options.parameterLimit === Infinity ? undefined : options.parameterLimit);

        for (let i = 0, il = parts.length; i < il; ++i) {
          const part = parts[i];
          const pos = part.indexOf(']=') === -1 ? part.indexOf('=') : part.indexOf(']=') + 1;

          if (pos === -1) {
            obj[Utils.decode(part)] = '';
          } else {
            const key = Utils.decode(part.slice(0, pos));
            const val = Utils.decode(part.slice(pos + 1));

            if (!obj[key]) {
              obj[key] = val;
            } else {
              obj[key] = [].concat(obj[key]).concat(val);
            }
          }
        }

        return obj;
      };


      internals.parseObject = function (chain, val, options) {
        if (!chain.length) {
          return val;
        }

        const root = chain.shift();

        let obj = {};
        if (root === '[]') {
          obj = [];
          obj = obj.concat(internals.parseObject(chain, val, options));
        } else {
          const cleanRoot = root[0] === '[' && root[root.length - 1] === ']' ? root.slice(1, root.length - 1) : root;
          const index = parseInt(cleanRoot, 10);
          if (!isNaN(index) &&
            root !== cleanRoot &&
            index <= options.arrayLimit) {
            obj = [];
            obj[index] = internals.parseObject(chain, val, options);
          } else {
            obj[cleanRoot] = internals.parseObject(chain, val, options);
          }
        }

        return obj;
      };


      internals.parseKeys = function (key, val, options) {
        if (!key) {
          return;
        }

    // The regex chunks

        const parent = /^([^\[\]]*)/;
        const child = /(\[[^\[\]]*\])/g;

    // Get the parent

        let segment = parent.exec(key);

    // Don't allow them to overwrite object prototype properties

        if (Object.prototype.hasOwnProperty(segment[1])) {
          return;
        }

    // Stash the parent if it exists

        const keys = [];
        if (segment[1]) {
          keys.push(segment[1]);
        }

    // Loop through children appending to the array until we hit depth

        let i = 0;
        while ((segment = child.exec(key)) !== null && i < options.depth) {
          ++i;
          if (!Object.prototype.hasOwnProperty(segment[1].replace(/\[|\]/g, ''))) {
            keys.push(segment[1]);
          }
        }

    // If there's a remainder, just add whatever is left

        if (segment) {
          keys.push(`[${key.slice(segment.index)}]`);
        }

        return internals.parseObject(keys, val, options);
      };


      module.exports = function (str, options) {
        if (str === '' ||
        str === null ||
        typeof str === 'undefined') {
          return {};
        }

        options = options || {};
        options.delimiter = typeof options.delimiter === 'string' || Utils.isRegExp(options.delimiter) ? options.delimiter : internals.delimiter;
        options.depth = typeof options.depth === 'number' ? options.depth : internals.depth;
        options.arrayLimit = typeof options.arrayLimit === 'number' ? options.arrayLimit : internals.arrayLimit;
        options.parameterLimit = typeof options.parameterLimit === 'number' ? options.parameterLimit : internals.parameterLimit;

        const tempObj = typeof str === 'string' ? internals.parseValues(str, options) : str;
        let obj = {};

    // Iterate over the keys and setup the new object

        const keys = Object.keys(tempObj);
        for (let i = 0, il = keys.length; i < il; ++i) {
          const key = keys[i];
          const newObj = internals.parseKeys(key, tempObj[key], options);
          obj = Utils.merge(obj, newObj);
        }

        return Utils.compact(obj);
      };
    }, { './utils': 36 }],
    35: [function (_dereq_, module, exports) {
// Load modules

      const Utils = _dereq_('./utils');


// Declare internals

      const internals = {
        delimiter: '&'
      };


      internals.stringify = function (obj, prefix) {
        if (Utils.isBuffer(obj)) {
          obj = obj.toString();
        } else if (obj instanceof Date) {
          obj = obj.toISOString();
        } else if (obj === null) {
          obj = '';
        }

        if (typeof obj === 'string' ||
        typeof obj === 'number' ||
        typeof obj === 'boolean') {
          return [`${encodeURIComponent(prefix)}=${encodeURIComponent(obj)}`];
        }

        let values = [];

        for (const key in obj) {
          if (obj.hasOwnProperty(key)) {
            values = values.concat(internals.stringify(obj[key], `${prefix}[${key}]`));
          }
        }

        return values;
      };


      module.exports = function (obj, options) {
        options = options || {};
        const delimiter = typeof options.delimiter === 'undefined' ? internals.delimiter : options.delimiter;

        let keys = [];

        for (const key in obj) {
          if (obj.hasOwnProperty(key)) {
            keys = keys.concat(internals.stringify(obj[key], key));
          }
        }

        return keys.join(delimiter);
      };
    }, { './utils': 36 }],
    36: [function (_dereq_, module, exports) {
// Load modules


// Declare internals

      const internals = {};


      exports.arrayToObject = function (source) {
        const obj = {};
        for (let i = 0, il = source.length; i < il; ++i) {
          if (typeof source[i] !== 'undefined') {
            obj[i] = source[i];
          }
        }

        return obj;
      };


      exports.merge = function (target, source) {
        if (!source) {
          return target;
        }

        if (Array.isArray(source)) {
          for (let i = 0, il = source.length; i < il; ++i) {
            if (typeof source[i] !== 'undefined') {
              if (typeof target[i] === 'object') {
              target[i] = exports.merge(target[i], source[i]);
            } else {
              target[i] = source[i];
            }
            }
          }

          return target;
        }

        if (Array.isArray(target)) {
          if (typeof source !== 'object') {
            target.push(source);
            return target;
          }

          target = exports.arrayToObject(target);
        }

        const keys = Object.keys(source);
        for (let k = 0, kl = keys.length; k < kl; ++k) {
          const key = keys[k];
          const value = source[key];

          if (value &&
            typeof value === 'object') {
            if (!target[key]) {
              target[key] = value;
            } else {
              target[key] = exports.merge(target[key], value);
            }
          } else {
            target[key] = value;
          }
        }

        return target;
      };


      exports.decode = function (str) {
        try {
          return decodeURIComponent(str.replace(/\+/g, ' '));
        } catch (e) {
          return str;
        }
      };


      exports.compact = function (obj, refs) {
        if (typeof obj !== 'object' ||
        obj === null) {
          return obj;
        }

        refs = refs || [];
        const lookup = refs.indexOf(obj);
        if (lookup !== -1) {
          return refs[lookup];
        }

        refs.push(obj);

        if (Array.isArray(obj)) {
          const compacted = [];

          for (var i = 0, l = obj.length; i < l; ++i) {
            if (typeof obj[i] !== 'undefined') {
              compacted.push(obj[i]);
            }
          }

          return compacted;
        }

        const keys = Object.keys(obj);
        for (var i = 0, il = keys.length; i < il; ++i) {
          const key = keys[i];
          obj[key] = exports.compact(obj[key], refs);
        }

        return obj;
      };


      exports.isRegExp = function (obj) {
        return Object.prototype.toString.call(obj) === '[object RegExp]';
      };


      exports.isBuffer = function (obj) {
        if (typeof Buffer !== 'undefined') {
          return Buffer.isBuffer(obj);
        }

        return false;
      };
    }, {}],
    37: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule CallbackQueue
 */


      const PooledClass = _dereq_('./PooledClass');

      const invariant = _dereq_('./invariant');
      const mixInto = _dereq_('./mixInto');

/**
 * A specialized pseudo-event module to help keep track of components waiting to
 * be notified when their DOM representations are available for use.
 *
 * This implements `PooledClass`, so you should never need to instantiate this.
 * Instead, use `CallbackQueue.getPooled()`.
 *
 * @class ReactMountReady
 * @implements PooledClass
 * @internal
 */
      function CallbackQueue () {
        this._callbacks = null;
        this._contexts = null;
      }

      mixInto(CallbackQueue, {

  /**
   * Enqueues a callback to be invoked when `notifyAll` is invoked.
   *
   * @param {function} callback Invoked when `notifyAll` is invoked.
   * @param {?object} context Context to call `callback` with.
   * @internal
   */
        enqueue (callback, context) {
          this._callbacks = this._callbacks || [];
          this._contexts = this._contexts || [];
          this._callbacks.push(callback);
          this._contexts.push(context);
        },

  /**
   * Invokes all enqueued callbacks and clears the queue. This is invoked after
   * the DOM representation of a component has been created or updated.
   *
   * @internal
   */
        notifyAll () {
          const callbacks = this._callbacks;
          const contexts = this._contexts;
          if (callbacks) {
            ('production' !== 'production' ? invariant(
        callbacks.length === contexts.length,
        'Mismatched list of contexts in callback queue'
      ) : invariant(callbacks.length === contexts.length));
            this._callbacks = null;
            this._contexts = null;
            for (let i = 0, l = callbacks.length; i < l; i++) {
              callbacks[i].call(contexts[i]);
            }
            callbacks.length = 0;
            contexts.length = 0;
          }
        },

  /**
   * Resets the internal queue.
   *
   * @internal
   */
        reset () {
          this._callbacks = null;
          this._contexts = null;
        },

  /**
   * `PooledClass` looks for this.
   */
        destructor () {
          this.reset();
        }

      });

      PooledClass.addPoolingTo(CallbackQueue);

      module.exports = CallbackQueue;
    }, { './PooledClass': 43, './invariant': 66, './mixInto': 74 }],
    38: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule EventConstants
 */


      const keyMirror = _dereq_('./keyMirror');

      const PropagationPhases = keyMirror({ bubbled: null, captured: null });

/**
 * Types of raw signals from the browser caught at the top level.
 */
      const topLevelTypes = keyMirror({
        topBlur: null,
        topChange: null,
        topClick: null,
        topCompositionEnd: null,
        topCompositionStart: null,
        topCompositionUpdate: null,
        topContextMenu: null,
        topCopy: null,
        topCut: null,
        topDoubleClick: null,
        topDrag: null,
        topDragEnd: null,
        topDragEnter: null,
        topDragExit: null,
        topDragLeave: null,
        topDragOver: null,
        topDragStart: null,
        topDrop: null,
        topError: null,
        topFocus: null,
        topInput: null,
        topKeyDown: null,
        topKeyPress: null,
        topKeyUp: null,
        topLoad: null,
        topMouseDown: null,
        topMouseMove: null,
        topMouseOut: null,
        topMouseOver: null,
        topMouseUp: null,
        topPaste: null,
        topReset: null,
        topScroll: null,
        topSelectionChange: null,
        topSubmit: null,
        topTextInput: null,
        topTouchCancel: null,
        topTouchEnd: null,
        topTouchMove: null,
        topTouchStart: null,
        topWheel: null
      });

      const EventConstants = {
        topLevelTypes,
        PropagationPhases
      };

      module.exports = EventConstants;
    }, { './keyMirror': 69 }],
    39: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule EventPluginHub
 */


      const EventPluginRegistry = _dereq_('./EventPluginRegistry');
      const EventPluginUtils = _dereq_('./EventPluginUtils');

      const accumulate = _dereq_('./accumulate');
      const forEachAccumulated = _dereq_('./forEachAccumulated');
      const invariant = _dereq_('./invariant');
      const isEventSupported = _dereq_('./isEventSupported');
      const monitorCodeUse = _dereq_('./monitorCodeUse');

/**
 * Internal store for event listeners
 */
      let listenerBank = {};

/**
 * Internal queue of events that have accumulated their dispatches and are
 * waiting to have their dispatches executed.
 */
      let eventQueue = null;

/**
 * Dispatches an event and releases it back into the pool, unless persistent.
 *
 * @param {?object} event Synthetic event to be dispatched.
 * @private
 */
      const executeDispatchesAndRelease = function (event) {
        if (event) {
          let executeDispatch = EventPluginUtils.executeDispatch;
    // Plugins can provide custom behavior when dispatching events.
          const PluginModule = EventPluginRegistry.getPluginModuleForEvent(event);
          if (PluginModule && PluginModule.executeDispatch) {
            executeDispatch = PluginModule.executeDispatch;
          }
          EventPluginUtils.executeDispatchesInOrder(event, executeDispatch);

          if (!event.isPersistent()) {
            event.constructor.release(event);
          }
        }
      };

/**
 * - `InstanceHandle`: [required] Module that performs logical traversals of DOM
 *   hierarchy given ids of the logical DOM elements involved.
 */
      let InstanceHandle = null;

      function validateInstanceHandle () {
        const invalid = !InstanceHandle ||
    !InstanceHandle.traverseTwoPhase ||
    !InstanceHandle.traverseEnterLeave;
        if (invalid) {
          throw new Error('InstanceHandle not injected before use!');
        }
      }

/**
 * This is a unified interface for event plugins to be installed and configured.
 *
 * Event plugins can implement the following properties:
 *
 *   `extractEvents` {function(string, DOMEventTarget, string, object): *}
 *     Required. When a top-level event is fired, this method is expected to
 *     extract synthetic events that will in turn be queued and dispatched.
 *
 *   `eventTypes` {object}
 *     Optional, plugins that fire events must publish a mapping of registration
 *     names that are used to register listeners. Values of this mapping must
 *     be objects that contain `registrationName` or `phasedRegistrationNames`.
 *
 *   `executeDispatch` {function(object, function, string)}
 *     Optional, allows plugins to override how an event gets dispatched. By
 *     default, the listener is simply invoked.
 *
 * Each plugin that is injected into `EventsPluginHub` is immediately operable.
 *
 * @public
 */
      const EventPluginHub = {

  /**
   * Methods for injecting dependencies.
   */
        injection: {

    /**
     * @param {object} InjectedMount
     * @public
     */
          injectMount: EventPluginUtils.injection.injectMount,

    /**
     * @param {object} InjectedInstanceHandle
     * @public
     */
          injectInstanceHandle (InjectedInstanceHandle) {
            InstanceHandle = InjectedInstanceHandle;
            if ('production' !== 'production') {
              validateInstanceHandle();
            }
          },

          getInstanceHandle () {
            if ('production' !== 'production') {
              validateInstanceHandle();
            }
            return InstanceHandle;
          },

    /**
     * @param {array} InjectedEventPluginOrder
     * @public
     */
          injectEventPluginOrder: EventPluginRegistry.injectEventPluginOrder,

    /**
     * @param {object} injectedNamesToPlugins Map from names to plugin modules.
     */
          injectEventPluginsByName: EventPluginRegistry.injectEventPluginsByName

        },

        eventNameDispatchConfigs: EventPluginRegistry.eventNameDispatchConfigs,

        registrationNameModules: EventPluginRegistry.registrationNameModules,

  /**
   * Stores `listener` at `listenerBank[registrationName][id]`. Is idempotent.
   *
   * @param {string} id ID of the DOM element.
   * @param {string} registrationName Name of listener (e.g. `onClick`).
   * @param {?function} listener The callback to store.
   */
        putListener (id, registrationName, listener) {
          ('production' !== 'production' ? invariant(
      !listener || typeof listener === 'function',
      'Expected %s listener to be a function, instead got type %s',
      registrationName, typeof listener
    ) : invariant(!listener || typeof listener === 'function'));

          if ('production' !== 'production') {
      // IE8 has no API for event capturing and the `onScroll` event doesn't
      // bubble.
            if (registrationName === 'onScroll' &&
          !isEventSupported('scroll', true)) {
              monitorCodeUse('react_no_scroll_event');
              console.warn('This browser doesn\'t support the `onScroll` event');
            }
          }
          const bankForRegistrationName =
      listenerBank[registrationName] || (listenerBank[registrationName] = {});
          bankForRegistrationName[id] = listener;
        },

  /**
   * @param {string} id ID of the DOM element.
   * @param {string} registrationName Name of listener (e.g. `onClick`).
   * @return {?function} The stored callback.
   */
        getListener (id, registrationName) {
          const bankForRegistrationName = listenerBank[registrationName];
          return bankForRegistrationName && bankForRegistrationName[id];
        },

  /**
   * Deletes a listener from the registration bank.
   *
   * @param {string} id ID of the DOM element.
   * @param {string} registrationName Name of listener (e.g. `onClick`).
   */
        deleteListener (id, registrationName) {
          const bankForRegistrationName = listenerBank[registrationName];
          if (bankForRegistrationName) {
            delete bankForRegistrationName[id];
          }
        },

  /**
   * Deletes all listeners for the DOM element with the supplied ID.
   *
   * @param {string} id ID of the DOM element.
   */
        deleteAllListeners (id) {
          for (const registrationName in listenerBank) {
            delete listenerBank[registrationName][id];
          }
        },

  /**
   * Allows registered plugins an opportunity to extract events from top-level
   * native browser events.
   *
   * @param {string} topLevelType Record from `EventConstants`.
   * @param {DOMEventTarget} topLevelTarget The listening component root node.
   * @param {string} topLevelTargetID ID of `topLevelTarget`.
   * @param {object} nativeEvent Native browser event.
   * @return {*} An accumulation of synthetic events.
   * @internal
   */
        extractEvents (
          topLevelType,
          topLevelTarget,
          topLevelTargetID,
          nativeEvent) {
          let events;
          const plugins = EventPluginRegistry.plugins;
          for (let i = 0, l = plugins.length; i < l; i++) {
      // Not every plugin in the ordering may be loaded at runtime.
            const possiblePlugin = plugins[i];
            if (possiblePlugin) {
              const extractedEvents = possiblePlugin.extractEvents(
          topLevelType,
          topLevelTarget,
          topLevelTargetID,
          nativeEvent
        );
              if (extractedEvents) {
              events = accumulate(events, extractedEvents);
            }
            }
          }
          return events;
        },

  /**
   * Enqueues a synthetic event that should be dispatched when
   * `processEventQueue` is invoked.
   *
   * @param {*} events An accumulation of synthetic events.
   * @internal
   */
        enqueueEvents (events) {
          if (events) {
            eventQueue = accumulate(eventQueue, events);
          }
        },

  /**
   * Dispatches all synthetic events on the event queue.
   *
   * @internal
   */
        processEventQueue () {
    // Set `eventQueue` to null before processing it so that we can tell if more
    // events get enqueued while processing.
          const processingEventQueue = eventQueue;
          eventQueue = null;
          forEachAccumulated(processingEventQueue, executeDispatchesAndRelease);
          ('production' !== 'production' ? invariant(
      !eventQueue,
      'processEventQueue(): Additional events were enqueued while processing ' +
      'an event queue. Support for this has not yet been implemented.'
    ) : invariant(!eventQueue));
        },

  /**
   * These are needed for tests only. Do not use!
   */
        __purge () {
          listenerBank = {};
        },

        __getListenerBank () {
          return listenerBank;
        }

      };

      module.exports = EventPluginHub;
    }, { './EventPluginRegistry': 40, './EventPluginUtils': 41, './accumulate': 57, './forEachAccumulated': 63, './invariant': 66, './isEventSupported': 67, './monitorCodeUse': 75 }],
    40: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule EventPluginRegistry
 * @typechecks static-only
 */


      const invariant = _dereq_('./invariant');

/**
 * Injectable ordering of event plugins.
 */
      let EventPluginOrder = null;

/**
 * Injectable mapping from names to event plugin modules.
 */
      const namesToPlugins = {};

/**
 * Recomputes the plugin list using the injected plugins and plugin ordering.
 *
 * @private
 */
      function recomputePluginOrdering () {
        if (!EventPluginOrder) {
    // Wait until an `EventPluginOrder` is injected.
          return;
        }
        for (const pluginName in namesToPlugins) {
          const PluginModule = namesToPlugins[pluginName];
          const pluginIndex = EventPluginOrder.indexOf(pluginName);
          ('production' !== 'production' ? invariant(
      pluginIndex > -1,
      'EventPluginRegistry: Cannot inject event plugins that do not exist in ' +
      'the plugin ordering, `%s`.',
      pluginName
    ) : invariant(pluginIndex > -1));
          if (EventPluginRegistry.plugins[pluginIndex]) {
            continue;
          }
          ('production' !== 'production' ? invariant(
      PluginModule.extractEvents,
      'EventPluginRegistry: Event plugins must implement an `extractEvents` ' +
      'method, but `%s` does not.',
      pluginName
    ) : invariant(PluginModule.extractEvents));
          EventPluginRegistry.plugins[pluginIndex] = PluginModule;
          const publishedEvents = PluginModule.eventTypes;
          for (const eventName in publishedEvents) {
            ('production' !== 'production' ? invariant(
        publishEventForPlugin(
          publishedEvents[eventName],
          PluginModule,
          eventName
        ),
        'EventPluginRegistry: Failed to publish event `%s` for plugin `%s`.',
        eventName,
        pluginName
      ) : invariant(publishEventForPlugin(
        publishedEvents[eventName],
        PluginModule,
        eventName
      )));
          }
        }
      }

/**
 * Publishes an event so that it can be dispatched by the supplied plugin.
 *
 * @param {object} dispatchConfig Dispatch configuration for the event.
 * @param {object} PluginModule Plugin publishing the event.
 * @return {boolean} True if the event was successfully published.
 * @private
 */
      function publishEventForPlugin (dispatchConfig, PluginModule, eventName) {
        ('production' !== 'production' ? invariant(
    !EventPluginRegistry.eventNameDispatchConfigs.hasOwnProperty(eventName),
    'EventPluginHub: More than one plugin attempted to publish the same ' +
    'event name, `%s`.',
    eventName
  ) : invariant(!EventPluginRegistry.eventNameDispatchConfigs.hasOwnProperty(eventName)));
        EventPluginRegistry.eventNameDispatchConfigs[eventName] = dispatchConfig;

        const phasedRegistrationNames = dispatchConfig.phasedRegistrationNames;
        if (phasedRegistrationNames) {
          for (const phaseName in phasedRegistrationNames) {
            if (phasedRegistrationNames.hasOwnProperty(phaseName)) {
              const phasedRegistrationName = phasedRegistrationNames[phaseName];
              publishRegistrationName(
          phasedRegistrationName,
          PluginModule,
          eventName
        );
            }
          }
          return true;
        } else if (dispatchConfig.registrationName) {
          publishRegistrationName(
      dispatchConfig.registrationName,
      PluginModule,
      eventName
    );
          return true;
        }
        return false;
      }

/**
 * Publishes a registration name that is used to identify dispatched events and
 * can be used with `EventPluginHub.putListener` to register listeners.
 *
 * @param {string} registrationName Registration name to add.
 * @param {object} PluginModule Plugin publishing the event.
 * @private
 */
      function publishRegistrationName (registrationName, PluginModule, eventName) {
        ('production' !== 'production' ? invariant(
    !EventPluginRegistry.registrationNameModules[registrationName],
    'EventPluginHub: More than one plugin attempted to publish the same ' +
    'registration name, `%s`.',
    registrationName
  ) : invariant(!EventPluginRegistry.registrationNameModules[registrationName]));
        EventPluginRegistry.registrationNameModules[registrationName] = PluginModule;
        EventPluginRegistry.registrationNameDependencies[registrationName] =
    PluginModule.eventTypes[eventName].dependencies;
      }

/**
 * Registers plugins so that they can extract and dispatch events.
 *
 * @see {EventPluginHub}
 */
      var EventPluginRegistry = {

  /**
   * Ordered list of injected plugins.
   */
        plugins: [],

  /**
   * Mapping from event name to dispatch config
   */
        eventNameDispatchConfigs: {},

  /**
   * Mapping from registration name to plugin module
   */
        registrationNameModules: {},

  /**
   * Mapping from registration name to event name
   */
        registrationNameDependencies: {},

  /**
   * Injects an ordering of plugins (by plugin name). This allows the ordering
   * to be decoupled from injection of the actual plugins so that ordering is
   * always deterministic regardless of packaging, on-the-fly injection, etc.
   *
   * @param {array} InjectedEventPluginOrder
   * @internal
   * @see {EventPluginHub.injection.injectEventPluginOrder}
   */
        injectEventPluginOrder (InjectedEventPluginOrder) {
          ('production' !== 'production' ? invariant(
      !EventPluginOrder,
      'EventPluginRegistry: Cannot inject event plugin ordering more than ' +
      'once. You are likely trying to load more than one copy of React.'
    ) : invariant(!EventPluginOrder));
    // Clone the ordering so it cannot be dynamically mutated.
          EventPluginOrder = Array.prototype.slice.call(InjectedEventPluginOrder);
          recomputePluginOrdering();
        },

  /**
   * Injects plugins to be used by `EventPluginHub`. The plugin names must be
   * in the ordering injected by `injectEventPluginOrder`.
   *
   * Plugins can be injected as part of page initialization or on-the-fly.
   *
   * @param {object} injectedNamesToPlugins Map from names to plugin modules.
   * @internal
   * @see {EventPluginHub.injection.injectEventPluginsByName}
   */
        injectEventPluginsByName (injectedNamesToPlugins) {
          let isOrderingDirty = false;
          for (const pluginName in injectedNamesToPlugins) {
            if (!injectedNamesToPlugins.hasOwnProperty(pluginName)) {
              continue;
            }
            const PluginModule = injectedNamesToPlugins[pluginName];
            if (!namesToPlugins.hasOwnProperty(pluginName) ||
          namesToPlugins[pluginName] !== PluginModule) {
              ('production' !== 'production' ? invariant(
          !namesToPlugins[pluginName],
          'EventPluginRegistry: Cannot inject two different event plugins ' +
          'using the same name, `%s`.',
          pluginName
        ) : invariant(!namesToPlugins[pluginName]));
              namesToPlugins[pluginName] = PluginModule;
              isOrderingDirty = true;
            }
          }
          if (isOrderingDirty) {
            recomputePluginOrdering();
          }
        },

  /**
   * Looks up the plugin for the supplied event.
   *
   * @param {object} event A synthetic event.
   * @return {?object} The plugin that created the supplied event.
   * @internal
   */
        getPluginModuleForEvent (event) {
          const dispatchConfig = event.dispatchConfig;
          if (dispatchConfig.registrationName) {
            return EventPluginRegistry.registrationNameModules[
        dispatchConfig.registrationName
      ] || null;
          }
          for (const phase in dispatchConfig.phasedRegistrationNames) {
            if (!dispatchConfig.phasedRegistrationNames.hasOwnProperty(phase)) {
              continue;
            }
            const PluginModule = EventPluginRegistry.registrationNameModules[
        dispatchConfig.phasedRegistrationNames[phase]
      ];
            if (PluginModule) {
              return PluginModule;
            }
          }
          return null;
        },

  /**
   * Exposed for unit testing.
   * @private
   */
        _resetEventPlugins () {
          EventPluginOrder = null;
          for (const pluginName in namesToPlugins) {
            if (namesToPlugins.hasOwnProperty(pluginName)) {
              delete namesToPlugins[pluginName];
            }
          }
          EventPluginRegistry.plugins.length = 0;

          const eventNameDispatchConfigs = EventPluginRegistry.eventNameDispatchConfigs;
          for (const eventName in eventNameDispatchConfigs) {
            if (eventNameDispatchConfigs.hasOwnProperty(eventName)) {
              delete eventNameDispatchConfigs[eventName];
            }
          }

          const registrationNameModules = EventPluginRegistry.registrationNameModules;
          for (const registrationName in registrationNameModules) {
            if (registrationNameModules.hasOwnProperty(registrationName)) {
              delete registrationNameModules[registrationName];
            }
          }
        }

      };

      module.exports = EventPluginRegistry;
    }, { './invariant': 66 }],
    41: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule EventPluginUtils
 */


      const EventConstants = _dereq_('./EventConstants');

      const invariant = _dereq_('./invariant');

/**
 * Injected dependencies:
 */

/**
 * - `Mount`: [required] Module that can convert between React dom IDs and
 *   actual node references.
 */
      var injection = {
        Mount: null,
        injectMount (InjectedMount) {
          injection.Mount = InjectedMount;
          if ('production' !== 'production') {
            ('production' !== 'production' ? invariant(
        InjectedMount && InjectedMount.getNode,
        'EventPluginUtils.injection.injectMount(...): Injected Mount module ' +
        'is missing getNode.'
      ) : invariant(InjectedMount && InjectedMount.getNode));
          }
        }
      };

      const topLevelTypes = EventConstants.topLevelTypes;

      function isEndish (topLevelType) {
        return topLevelType === topLevelTypes.topMouseUp ||
         topLevelType === topLevelTypes.topTouchEnd ||
         topLevelType === topLevelTypes.topTouchCancel;
      }

      function isMoveish (topLevelType) {
        return topLevelType === topLevelTypes.topMouseMove ||
         topLevelType === topLevelTypes.topTouchMove;
      }
      function isStartish (topLevelType) {
        return topLevelType === topLevelTypes.topMouseDown ||
         topLevelType === topLevelTypes.topTouchStart;
      }


      let validateEventDispatches;
      if ('production' !== 'production') {
        validateEventDispatches = function (event) {
          const dispatchListeners = event._dispatchListeners;
          const dispatchIDs = event._dispatchIDs;

          const listenersIsArr = Array.isArray(dispatchListeners);
          const idsIsArr = Array.isArray(dispatchIDs);
          const IDsLen = idsIsArr ? dispatchIDs.length : dispatchIDs ? 1 : 0;
          const listenersLen = listenersIsArr ?
      dispatchListeners.length :
      dispatchListeners ? 1 : 0;

          ('production' !== 'production' ? invariant(
      idsIsArr === listenersIsArr && IDsLen === listenersLen,
      'EventPluginUtils: Invalid `event`.'
    ) : invariant(idsIsArr === listenersIsArr && IDsLen === listenersLen));
        };
      }

/**
 * Invokes `cb(event, listener, id)`. Avoids using call if no scope is
 * provided. The `(listener,id)` pair effectively forms the "dispatch" but are
 * kept separate to conserve memory.
 */
      function forEachEventDispatch (event, cb) {
        const dispatchListeners = event._dispatchListeners;
        const dispatchIDs = event._dispatchIDs;
        if ('production' !== 'production') {
          validateEventDispatches(event);
        }
        if (Array.isArray(dispatchListeners)) {
          for (let i = 0; i < dispatchListeners.length; i++) {
            if (event.isPropagationStopped()) {
              break;
            }
      // Listeners and IDs are two parallel arrays that are always in sync.
            cb(event, dispatchListeners[i], dispatchIDs[i]);
          }
        } else if (dispatchListeners) {
          cb(event, dispatchListeners, dispatchIDs);
        }
      }

/**
 * Default implementation of PluginModule.executeDispatch().
 * @param {SyntheticEvent} SyntheticEvent to handle
 * @param {function} Application-level callback
 * @param {string} domID DOM id to pass to the callback.
 */
      function executeDispatch (event, listener, domID) {
        event.currentTarget = injection.Mount.getNode(domID);
        const returnValue = listener(event, domID);
        event.currentTarget = null;
        return returnValue;
      }

/**
 * Standard/simple iteration through an event's collected dispatches.
 */
      function executeDispatchesInOrder (event, executeDispatch) {
        forEachEventDispatch(event, executeDispatch);
        event._dispatchListeners = null;
        event._dispatchIDs = null;
      }

/**
 * Standard/simple iteration through an event's collected dispatches, but stops
 * at the first dispatch execution returning true, and returns that id.
 *
 * @return id of the first dispatch execution who's listener returns true, or
 * null if no listener returned true.
 */
      function executeDispatchesInOrderStopAtTrueImpl (event) {
        const dispatchListeners = event._dispatchListeners;
        const dispatchIDs = event._dispatchIDs;
        if ('production' !== 'production') {
          validateEventDispatches(event);
        }
        if (Array.isArray(dispatchListeners)) {
          for (let i = 0; i < dispatchListeners.length; i++) {
            if (event.isPropagationStopped()) {
              break;
            }
      // Listeners and IDs are two parallel arrays that are always in sync.
            if (dispatchListeners[i](event, dispatchIDs[i])) {
              return dispatchIDs[i];
            }
          }
        } else if (dispatchListeners) {
          if (dispatchListeners(event, dispatchIDs)) {
            return dispatchIDs;
          }
        }
        return null;
      }

/**
 * @see executeDispatchesInOrderStopAtTrueImpl
 */
      function executeDispatchesInOrderStopAtTrue (event) {
        const ret = executeDispatchesInOrderStopAtTrueImpl(event);
        event._dispatchIDs = null;
        event._dispatchListeners = null;
        return ret;
      }

/**
 * Execution of a "direct" dispatch - there must be at most one dispatch
 * accumulated on the event or it is considered an error. It doesn't really make
 * sense for an event with multiple dispatches (bubbled) to keep track of the
 * return values at each dispatch execution, but it does tend to make sense when
 * dealing with "direct" dispatches.
 *
 * @return The return value of executing the single dispatch.
 */
      function executeDirectDispatch (event) {
        if ('production' !== 'production') {
          validateEventDispatches(event);
        }
        const dispatchListener = event._dispatchListeners;
        const dispatchID = event._dispatchIDs;
        ('production' !== 'production' ? invariant(
    !Array.isArray(dispatchListener),
    'executeDirectDispatch(...): Invalid `event`.'
  ) : invariant(!Array.isArray(dispatchListener)));
        const res = dispatchListener ?
    dispatchListener(event, dispatchID) :
    null;
        event._dispatchListeners = null;
        event._dispatchIDs = null;
        return res;
      }

/**
 * @param {SyntheticEvent} event
 * @return {bool} True iff number of dispatches accumulated is greater than 0.
 */
      function hasDispatches (event) {
        return !!event._dispatchListeners;
      }

/**
 * General utilities that are useful in creating custom Event Plugins.
 */
      const EventPluginUtils = {
        isEndish,
        isMoveish,
        isStartish,

        executeDirectDispatch,
        executeDispatch,
        executeDispatchesInOrder,
        executeDispatchesInOrderStopAtTrue,
        hasDispatches,
        injection,
        useTouchEvents: false
      };

      module.exports = EventPluginUtils;
    }, { './EventConstants': 38, './invariant': 66 }],
    42: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ExecutionEnvironment
 */

/* jslint evil: true */


      const canUseDOM = !!(
  typeof window !== 'undefined' &&
  window.document &&
  window.document.createElement
);

/**
 * Simple, lightweight module assisting with the detection and context of
 * Worker. Helps avoid circular dependencies and allows code to reason about
 * whether or not they are in a Worker, even if they never include the main
 * `ReactWorker` dependency.
 */
      const ExecutionEnvironment = {

        canUseDOM,

        canUseWorkers: typeof Worker !== 'undefined',

        canUseEventListeners:
    canUseDOM && !!(window.addEventListener || window.attachEvent),

        canUseViewport: canUseDOM && !!window.screen,

        isInWorker: !canUseDOM // For now, this is true - might change in the future.

      };

      module.exports = ExecutionEnvironment;
    }, {}],
    43: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule PooledClass
 */


      const invariant = _dereq_('./invariant');

/**
 * Static poolers. Several custom versions for each potential number of
 * arguments. A completely generic pooler is easy to implement, but would
 * require accessing the `arguments` object. In each of these, `this` refers to
 * the Class itself, not an instance. If any others are needed, simply add them
 * here, or in their own files.
 */
      const oneArgumentPooler = function (copyFieldsFrom) {
        const Klass = this;
        if (Klass.instancePool.length) {
          const instance = Klass.instancePool.pop();
          Klass.call(instance, copyFieldsFrom);
          return instance;
        }
        return new Klass(copyFieldsFrom);
      };

      const twoArgumentPooler = function (a1, a2) {
        const Klass = this;
        if (Klass.instancePool.length) {
          const instance = Klass.instancePool.pop();
          Klass.call(instance, a1, a2);
          return instance;
        }
        return new Klass(a1, a2);
      };

      const threeArgumentPooler = function (a1, a2, a3) {
        const Klass = this;
        if (Klass.instancePool.length) {
          const instance = Klass.instancePool.pop();
          Klass.call(instance, a1, a2, a3);
          return instance;
        }
        return new Klass(a1, a2, a3);
      };

      const fiveArgumentPooler = function (a1, a2, a3, a4, a5) {
        const Klass = this;
        if (Klass.instancePool.length) {
          const instance = Klass.instancePool.pop();
          Klass.call(instance, a1, a2, a3, a4, a5);
          return instance;
        }
        return new Klass(a1, a2, a3, a4, a5);
      };

      const standardReleaser = function (instance) {
        const Klass = this;
        ('production' !== 'production' ? invariant(
    instance instanceof Klass,
    'Trying to release an instance into a pool of a different type.'
  ) : invariant(instance instanceof Klass));
        if (instance.destructor) {
          instance.destructor();
        }
        if (Klass.instancePool.length < Klass.poolSize) {
          Klass.instancePool.push(instance);
        }
      };

      const DEFAULT_POOL_SIZE = 10;
      const DEFAULT_POOLER = oneArgumentPooler;

/**
 * Augments `CopyConstructor` to be a poolable class, augmenting only the class
 * itself (statically) not adding any prototypical fields. Any CopyConstructor
 * you give this may have a `poolSize` property, and will look for a
 * prototypical `destructor` on instances (optional).
 *
 * @param {Function} CopyConstructor Constructor that can be used to reset.
 * @param {Function} pooler Customizable pooler.
 */
      const addPoolingTo = function (CopyConstructor, pooler) {
        const NewKlass = CopyConstructor;
        NewKlass.instancePool = [];
        NewKlass.getPooled = pooler || DEFAULT_POOLER;
        if (!NewKlass.poolSize) {
          NewKlass.poolSize = DEFAULT_POOL_SIZE;
        }
        NewKlass.release = standardReleaser;
        return NewKlass;
      };

      const PooledClass = {
        addPoolingTo,
        oneArgumentPooler,
        twoArgumentPooler,
        threeArgumentPooler,
        fiveArgumentPooler
      };

      module.exports = PooledClass;
    }, { './invariant': 66 }],
    44: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactBrowserEventEmitter
 * @typechecks static-only
 */


      const EventConstants = _dereq_('./EventConstants');
      const EventPluginHub = _dereq_('./EventPluginHub');
      const EventPluginRegistry = _dereq_('./EventPluginRegistry');
      const ReactEventEmitterMixin = _dereq_('./ReactEventEmitterMixin');
      const ViewportMetrics = _dereq_('./ViewportMetrics');

      const isEventSupported = _dereq_('./isEventSupported');
      const merge = _dereq_('./merge');

/**
 * Summary of `ReactBrowserEventEmitter` event handling:
 *
 *  - Top-level delegation is used to trap most native browser events. This
 *    may only occur in the main thread and is the responsibility of
 *    ReactEventListener, which is injected and can therefore support pluggable
 *    event sources. This is the only work that occurs in the main thread.
 *
 *  - We normalize and de-duplicate events to account for browser quirks. This
 *    may be done in the worker thread.
 *
 *  - Forward these native events (with the associated top-level type used to
 *    trap it) to `EventPluginHub`, which in turn will ask plugins if they want
 *    to extract any synthetic events.
 *
 *  - The `EventPluginHub` will then process each event by annotating them with
 *    "dispatches", a sequence of listeners and IDs that care about that event.
 *
 *  - The `EventPluginHub` then dispatches the events.
 *
 * Overview of React and the event system:
 *
 * +------------+    .
 * |    DOM     |    .
 * +------------+    .
 *       |           .
 *       v           .
 * +------------+    .
 * | ReactEvent |    .
 * |  Listener  |    .
 * +------------+    .                         +-----------+
 *       |           .               +--------+|SimpleEvent|
 *       |           .               |         |Plugin     |
 * +-----|------+    .               v         +-----------+
 * |     |      |    .    +--------------+                    +------------+
 * |     +-----------.--->|EventPluginHub|                    |    Event   |
 * |            |    .    |              |     +-----------+  | Propagators|
 * | ReactEvent |    .    |              |     |TapEvent   |  |------------|
 * |  Emitter   |    .    |              |<---+|Plugin     |  |other plugin|
 * |            |    .    |              |     +-----------+  |  utilities |
 * |     +-----------.--->|              |                    +------------+
 * |     |      |    .    +--------------+
 * +-----|------+    .                ^        +-----------+
 *       |           .                |        |Enter/Leave|
 *       +           .                +-------+|Plugin     |
 * +-------------+   .                         +-----------+
 * | application |   .
 * |-------------|   .
 * |             |   .
 * |             |   .
 * +-------------+   .
 *                   .
 *    React Core     .  General Purpose Event Plugin System
 */

      const alreadyListeningTo = {};
      let isMonitoringScrollValue = false;
      let reactTopListenersCounter = 0;

// For events like 'submit' which don't consistently bubble (which we trap at a
// lower node than `document`), binding at `document` would cause duplicate
// events so we don't include them here
      const topEventMapping = {
        topBlur: 'blur',
        topChange: 'change',
        topClick: 'click',
        topCompositionEnd: 'compositionend',
        topCompositionStart: 'compositionstart',
        topCompositionUpdate: 'compositionupdate',
        topContextMenu: 'contextmenu',
        topCopy: 'copy',
        topCut: 'cut',
        topDoubleClick: 'dblclick',
        topDrag: 'drag',
        topDragEnd: 'dragend',
        topDragEnter: 'dragenter',
        topDragExit: 'dragexit',
        topDragLeave: 'dragleave',
        topDragOver: 'dragover',
        topDragStart: 'dragstart',
        topDrop: 'drop',
        topFocus: 'focus',
        topInput: 'input',
        topKeyDown: 'keydown',
        topKeyPress: 'keypress',
        topKeyUp: 'keyup',
        topMouseDown: 'mousedown',
        topMouseMove: 'mousemove',
        topMouseOut: 'mouseout',
        topMouseOver: 'mouseover',
        topMouseUp: 'mouseup',
        topPaste: 'paste',
        topScroll: 'scroll',
        topSelectionChange: 'selectionchange',
        topTextInput: 'textInput',
        topTouchCancel: 'touchcancel',
        topTouchEnd: 'touchend',
        topTouchMove: 'touchmove',
        topTouchStart: 'touchstart',
        topWheel: 'wheel'
      };

/**
 * To ensure no conflicts with other potential React instances on the page
 */
      const topListenersIDKey = `_reactListenersID${String(Math.random()).slice(2)}`;

      function getListeningForDocument (mountAt) {
  // In IE8, `mountAt` is a host object and doesn't have `hasOwnProperty`
  // directly.
        if (!Object.prototype.hasOwnProperty.call(mountAt, topListenersIDKey)) {
          mountAt[topListenersIDKey] = reactTopListenersCounter++;
          alreadyListeningTo[mountAt[topListenersIDKey]] = {};
        }
        return alreadyListeningTo[mountAt[topListenersIDKey]];
      }

/**
 * `ReactBrowserEventEmitter` is used to attach top-level event listeners. For
 * example:
 *
 *   ReactBrowserEventEmitter.putListener('myID', 'onClick', myFunction);
 *
 * This would allocate a "registration" of `('onClick', myFunction)` on 'myID'.
 *
 * @internal
 */
      var ReactBrowserEventEmitter = merge(ReactEventEmitterMixin, {

  /**
   * Injectable event backend
   */
        ReactEventListener: null,

        injection: {
    /**
     * @param {object} ReactEventListener
     */
          injectReactEventListener (ReactEventListener) {
            ReactEventListener.setHandleTopLevel(
        ReactBrowserEventEmitter.handleTopLevel
      );
            ReactBrowserEventEmitter.ReactEventListener = ReactEventListener;
          }
        },

  /**
   * Sets whether or not any created callbacks should be enabled.
   *
   * @param {boolean} enabled True if callbacks should be enabled.
   */
        setEnabled (enabled) {
          if (ReactBrowserEventEmitter.ReactEventListener) {
            ReactBrowserEventEmitter.ReactEventListener.setEnabled(enabled);
          }
        },

  /**
   * @return {boolean} True if callbacks are enabled.
   */
        isEnabled () {
          return !!(
      ReactBrowserEventEmitter.ReactEventListener &&
      ReactBrowserEventEmitter.ReactEventListener.isEnabled()
    );
        },

  /**
   * We listen for bubbled touch events on the document object.
   *
   * Firefox v8.01 (and possibly others) exhibited strange behavior when
   * mounting `onmousemove` events at some node that was not the document
   * element. The symptoms were that if your mouse is not moving over something
   * contained within that mount point (for example on the background) the
   * top-level listeners for `onmousemove` won't be called. However, if you
   * register the `mousemove` on the document object, then it will of course
   * catch all `mousemove`s. This along with iOS quirks, justifies restricting
   * top-level listeners to the document object only, at least for these
   * movement types of events and possibly all events.
   *
   * @see http://www.quirksmode.org/blog/archives/2010/09/click_event_del.html
   *
   * Also, `keyup`/`keypress`/`keydown` do not bubble to the window on IE, but
   * they bubble to document.
   *
   * @param {string} registrationName Name of listener (e.g. `onClick`).
   * @param {object} contentDocumentHandle Document which owns the container
   */
        listenTo (registrationName, contentDocumentHandle) {
          const mountAt = contentDocumentHandle;
          const isListening = getListeningForDocument(mountAt);
          const dependencies = EventPluginRegistry
      .registrationNameDependencies[registrationName];

          const topLevelTypes = EventConstants.topLevelTypes;
          for (let i = 0, l = dependencies.length; i < l; i++) {
            const dependency = dependencies[i];
            if (!(
            isListening.hasOwnProperty(dependency) &&
            isListening[dependency]
          )) {
              if (dependency === topLevelTypes.topWheel) {
              if (isEventSupported('wheel')) {
              ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topWheel,
              'wheel',
              mountAt
            );
            } else if (isEventSupported('mousewheel')) {
            ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topWheel,
              'mousewheel',
              mountAt
            );
          } else {
            // Firefox needs to capture a different mouse scroll event.
            // @see http://www.quirksmode.org/dom/events/tests/scroll.html
            ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topWheel,
              'DOMMouseScroll',
              mountAt
            );
          }
            } else if (dependency === topLevelTypes.topScroll) {
            if (isEventSupported('scroll', true)) {
            ReactBrowserEventEmitter.ReactEventListener.trapCapturedEvent(
              topLevelTypes.topScroll,
              'scroll',
              mountAt
            );
          } else {
            ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topScroll,
              'scroll',
              ReactBrowserEventEmitter.ReactEventListener.WINDOW_HANDLE
            );
          }
          } else if (dependency === topLevelTypes.topFocus ||
            dependency === topLevelTypes.topBlur) {
          if (isEventSupported('focus', true)) {
            ReactBrowserEventEmitter.ReactEventListener.trapCapturedEvent(
              topLevelTypes.topFocus,
              'focus',
              mountAt
            );
            ReactBrowserEventEmitter.ReactEventListener.trapCapturedEvent(
              topLevelTypes.topBlur,
              'blur',
              mountAt
            );
          } else if (isEventSupported('focusin')) {
            // IE has `focusin` and `focusout` events which bubble.
            // @see http://www.quirksmode.org/blog/archives/2008/04/delegating_the.html
            ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topFocus,
              'focusin',
              mountAt
            );
            ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
              topLevelTypes.topBlur,
              'focusout',
              mountAt
            );
          }

          // to make sure blur and focus event listeners are only attached once
          isListening[topLevelTypes.topBlur] = true;
          isListening[topLevelTypes.topFocus] = true;
        } else if (topEventMapping.hasOwnProperty(dependency)) {
          ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
            dependency,
            topEventMapping[dependency],
            mountAt
          );
        }

              isListening[dependency] = true;
            }
          }
        },

        trapBubbledEvent (topLevelType, handlerBaseName, handle) {
          return ReactBrowserEventEmitter.ReactEventListener.trapBubbledEvent(
      topLevelType,
      handlerBaseName,
      handle
    );
        },

        trapCapturedEvent (topLevelType, handlerBaseName, handle) {
          return ReactBrowserEventEmitter.ReactEventListener.trapCapturedEvent(
      topLevelType,
      handlerBaseName,
      handle
    );
        },

  /**
   * Listens to window scroll and resize events. We cache scroll values so that
   * application code can access them without triggering reflows.
   *
   * NOTE: Scroll events do not bubble.
   *
   * @see http://www.quirksmode.org/dom/events/scroll.html
   */
        ensureScrollValueMonitoring () {
          if (!isMonitoringScrollValue) {
            const refresh = ViewportMetrics.refreshScrollValues;
            ReactBrowserEventEmitter.ReactEventListener.monitorScrollValue(refresh);
            isMonitoringScrollValue = true;
          }
        },

        eventNameDispatchConfigs: EventPluginHub.eventNameDispatchConfigs,

        registrationNameModules: EventPluginHub.registrationNameModules,

        putListener: EventPluginHub.putListener,

        getListener: EventPluginHub.getListener,

        deleteListener: EventPluginHub.deleteListener,

        deleteAllListeners: EventPluginHub.deleteAllListeners

      });

      module.exports = ReactBrowserEventEmitter;
    }, { './EventConstants': 38, './EventPluginHub': 39, './EventPluginRegistry': 40, './ReactEventEmitterMixin': 48, './ViewportMetrics': 56, './isEventSupported': 67, './merge': 71 }],
    45: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactContext
 */


      const merge = _dereq_('./merge');

/**
 * Keeps track of the current context.
 *
 * The context is automatically passed down the component ownership hierarchy
 * and is accessible via `this.context` on ReactCompositeComponents.
 */
      var ReactContext = {

  /**
   * @internal
   * @type {object}
   */
        current: {},

  /**
   * Temporarily extends the current context while executing scopedCallback.
   *
   * A typical use case might look like
   *
   *  render: function() {
   *    var children = ReactContext.withContext({foo: 'foo'} () => (
   *
   *    ));
   *    return <div>{children}</div>;
   *  }
   *
   * @param {object} newContext New context to merge into the existing context
   * @param {function} scopedCallback Callback to run with the new context
   * @return {ReactComponent|array<ReactComponent>}
   */
        withContext (newContext, scopedCallback) {
          let result;
          const previousContext = ReactContext.current;
          ReactContext.current = merge(previousContext, newContext);
          try {
            result = scopedCallback();
          } finally {
            ReactContext.current = previousContext;
          }
          return result;
        }

      };

      module.exports = ReactContext;
    }, { './merge': 71 }],
    46: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactCurrentOwner
 */


/**
 * Keeps track of the current owner.
 *
 * The current owner is the component who should own any components that are
 * currently being constructed.
 *
 * The depth indicate how many composite components are above this render level.
 */
      const ReactCurrentOwner = {

  /**
   * @internal
   * @type {ReactComponent}
   */
        current: null

      };

      module.exports = ReactCurrentOwner;
    }, {}],
    47: [function (_dereq_, module, exports) {
/**
 * Copyright 2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactDescriptor
 */


      const ReactContext = _dereq_('./ReactContext');
      const ReactCurrentOwner = _dereq_('./ReactCurrentOwner');

      const merge = _dereq_('./merge');
      const warning = _dereq_('./warning');

/**
 * Warn for mutations.
 *
 * @internal
 * @param {object} object
 * @param {string} key
 */
      function defineWarningProperty (object, key) {
        Object.defineProperty(object, key, {

          configurable: false,
          enumerable: true,

          get () {
            if (!this._store) {
              return null;
            }
            return this._store[key];
          },

          set (value) {
            ('production' !== 'production' ? warning(
        false,
        `Don't set the ${key} property of the component. ` +
        'Mutate the existing props object instead.'
      ) : null);
            this._store[key] = value;
          }

        });
      }

/**
 * This is updated to true if the membrane is successfully created.
 */
      let useMutationMembrane = false;

/**
 * Warn for mutations.
 *
 * @internal
 * @param {object} descriptor
 */
      function defineMutationMembrane (prototype) {
        try {
          const pseudoFrozenProperties = {
            props: true
          };
          for (const key in pseudoFrozenProperties) {
            defineWarningProperty(prototype, key);
          }
          useMutationMembrane = true;
        } catch (x) {
    // IE will fail on defineProperty
        }
      }

/**
 * Transfer static properties from the source to the target. Functions are
 * rebound to have this reflect the original source.
 */
      function proxyStaticMethods (target, source) {
        if (typeof source !== 'function') {
          return;
        }
        for (const key in source) {
          if (source.hasOwnProperty(key)) {
            const value = source[key];
            if (typeof value === 'function') {
              const bound = value.bind(source);
        // Copy any properties defined on the function, such as `isRequired` on
        // a PropTypes validator. (mergeInto refuses to work on functions.)
              for (const k in value) {
            if (value.hasOwnProperty(k)) {
              bound[k] = value[k];
            }
          }
              target[key] = bound;
            } else {
              target[key] = value;
            }
          }
        }
      }

/**
 * Base constructor for all React descriptors. This is only used to make this
 * work with a dynamic instanceof check. Nothing should live on this prototype.
 *
 * @param {*} type
 * @internal
 */
      const ReactDescriptor = function () {};

      if ('production' !== 'production') {
        defineMutationMembrane(ReactDescriptor.prototype);
      }

      ReactDescriptor.createFactory = function (type) {
        const descriptorPrototype = Object.create(ReactDescriptor.prototype);

        const factory = function (props, children) {
    // For consistency we currently allocate a new object for every descriptor.
    // This protects the descriptor from being mutated by the original props
    // object being mutated. It also protects the original props object from
    // being mutated by children arguments and default props. This behavior
    // comes with a performance cost and could be deprecated in the future.
    // It could also be optimized with a smarter JSX transform.
          if (props == null) {
            props = {};
          } else if (typeof props === 'object') {
            props = merge(props);
          }

    // Children can be more than one argument, and those are transferred onto
    // the newly allocated props object.
          const childrenLength = arguments.length - 1;
          if (childrenLength === 1) {
            props.children = children;
          } else if (childrenLength > 1) {
            const childArray = Array(childrenLength);
            for (let i = 0; i < childrenLength; i++) {
          childArray[i] = arguments[i + 1];
        }
            props.children = childArray;
          }

    // Initialize the descriptor object
          const descriptor = Object.create(descriptorPrototype);

    // Record the component responsible for creating this descriptor.
          descriptor._owner = ReactCurrentOwner.current;

    // TODO: Deprecate withContext, and then the context becomes accessible
    // through the owner.
          descriptor._context = ReactContext.current;

          if ('production' !== 'production') {
      // The validation flag and props are currently mutative. We put them on
      // an external backing store so that we can freeze the whole object.
      // This can be replaced with a WeakMap once they are implemented in
      // commonly used development environments.
            descriptor._store = { validated: false, props };

      // We're not allowed to set props directly on the object so we early
      // return and rely on the prototype membrane to forward to the backing
      // store.
            if (useMutationMembrane) {
              Object.freeze(descriptor);
              return descriptor;
            }
          }

          descriptor.props = props;
          return descriptor;
        };

  // Currently we expose the prototype of the descriptor so that
  // <Foo /> instanceof Foo works. This is controversial pattern.
        factory.prototype = descriptorPrototype;

  // Expose the type on the factory and the prototype so that it can be
  // easily accessed on descriptors. E.g. <Foo />.type === Foo.type and for
  // static methods like <Foo />.type.staticMethod();
  // This should not be named constructor since this may not be the function
  // that created the descriptor, and it may not even be a constructor.
        factory.type = type;
        descriptorPrototype.type = type;

        proxyStaticMethods(factory, type);

  // Expose a unique constructor on the prototype is that this works with type
  // systems that compare constructor properties: <Foo />.constructor === Foo
  // This may be controversial since it requires a known factory function.
        descriptorPrototype.constructor = factory;

        return factory;
      };

      ReactDescriptor.cloneAndReplaceProps = function (oldDescriptor, newProps) {
        const newDescriptor = Object.create(oldDescriptor.constructor.prototype);
  // It's important that this property order matches the hidden class of the
  // original descriptor to maintain perf.
        newDescriptor._owner = oldDescriptor._owner;
        newDescriptor._context = oldDescriptor._context;

        if ('production' !== 'production') {
          newDescriptor._store = {
            validated: oldDescriptor._store.validated,
            props: newProps
          };
          if (useMutationMembrane) {
            Object.freeze(newDescriptor);
            return newDescriptor;
          }
        }

        newDescriptor.props = newProps;
        return newDescriptor;
      };

/**
 * Checks if a value is a valid descriptor constructor.
 *
 * @param {*}
 * @return {boolean}
 * @public
 */
      ReactDescriptor.isValidFactory = function (factory) {
        return typeof factory === 'function' &&
         factory.prototype instanceof ReactDescriptor;
      };

/**
 * @param {?object} object
 * @return {boolean} True if `object` is a valid component.
 * @final
 */
      ReactDescriptor.isValidDescriptor = function (object) {
        return object instanceof ReactDescriptor;
      };

      module.exports = ReactDescriptor;
    }, { './ReactContext': 45, './ReactCurrentOwner': 46, './merge': 71, './warning': 76 }],
    48: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactEventEmitterMixin
 */


      const EventPluginHub = _dereq_('./EventPluginHub');

      function runEventQueueInBatch (events) {
        EventPluginHub.enqueueEvents(events);
        EventPluginHub.processEventQueue();
      }

      const ReactEventEmitterMixin = {

  /**
   * Streams a fired top-level event to `EventPluginHub` where plugins have the
   * opportunity to create `ReactEvent`s to be dispatched.
   *
   * @param {string} topLevelType Record from `EventConstants`.
   * @param {object} topLevelTarget The listening component root node.
   * @param {string} topLevelTargetID ID of `topLevelTarget`.
   * @param {object} nativeEvent Native environment event.
   */
        handleTopLevel (
          topLevelType,
          topLevelTarget,
          topLevelTargetID,
          nativeEvent) {
          const events = EventPluginHub.extractEvents(
      topLevelType,
      topLevelTarget,
      topLevelTargetID,
      nativeEvent
    );

          runEventQueueInBatch(events);
        }
      };

      module.exports = ReactEventEmitterMixin;
    }, { './EventPluginHub': 39 }],
    49: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactInstanceHandles
 * @typechecks static-only
 */


      const ReactRootIndex = _dereq_('./ReactRootIndex');

      const invariant = _dereq_('./invariant');

      const SEPARATOR = '.';
      const SEPARATOR_LENGTH = SEPARATOR.length;

/**
 * Maximum depth of traversals before we consider the possibility of a bad ID.
 */
      const MAX_TREE_DEPTH = 100;

/**
 * Creates a DOM ID prefix to use when mounting React components.
 *
 * @param {number} index A unique integer
 * @return {string} React root ID.
 * @internal
 */
      function getReactRootIDString (index) {
        return SEPARATOR + index.toString(36);
      }

/**
 * Checks if a character in the supplied ID is a separator or the end.
 *
 * @param {string} id A React DOM ID.
 * @param {number} index Index of the character to check.
 * @return {boolean} True if the character is a separator or end of the ID.
 * @private
 */
      function isBoundary (id, index) {
        return id.charAt(index) === SEPARATOR || index === id.length;
      }

/**
 * Checks if the supplied string is a valid React DOM ID.
 *
 * @param {string} id A React DOM ID, maybe.
 * @return {boolean} True if the string is a valid React DOM ID.
 * @private
 */
      function isValidID (id) {
        return id === '' || (
    id.charAt(0) === SEPARATOR && id.charAt(id.length - 1) !== SEPARATOR
  );
      }

/**
 * Checks if the first ID is an ancestor of or equal to the second ID.
 *
 * @param {string} ancestorID
 * @param {string} descendantID
 * @return {boolean} True if `ancestorID` is an ancestor of `descendantID`.
 * @internal
 */
      function isAncestorIDOf (ancestorID, descendantID) {
        return (
    descendantID.indexOf(ancestorID) === 0 &&
    isBoundary(descendantID, ancestorID.length)
        );
      }

/**
 * Gets the parent ID of the supplied React DOM ID, `id`.
 *
 * @param {string} id ID of a component.
 * @return {string} ID of the parent, or an empty string.
 * @private
 */
      function getParentID (id) {
        return id ? id.substr(0, id.lastIndexOf(SEPARATOR)) : '';
      }

/**
 * Gets the next DOM ID on the tree path from the supplied `ancestorID` to the
 * supplied `destinationID`. If they are equal, the ID is returned.
 *
 * @param {string} ancestorID ID of an ancestor node of `destinationID`.
 * @param {string} destinationID ID of the destination node.
 * @return {string} Next ID on the path from `ancestorID` to `destinationID`.
 * @private
 */
      function getNextDescendantID (ancestorID, destinationID) {
        ('production' !== 'production' ? invariant(
    isValidID(ancestorID) && isValidID(destinationID),
    'getNextDescendantID(%s, %s): Received an invalid React DOM ID.',
    ancestorID,
    destinationID
  ) : invariant(isValidID(ancestorID) && isValidID(destinationID)));
        ('production' !== 'production' ? invariant(
    isAncestorIDOf(ancestorID, destinationID),
    'getNextDescendantID(...): React has made an invalid assumption about ' +
    'the DOM hierarchy. Expected `%s` to be an ancestor of `%s`.',
    ancestorID,
    destinationID
  ) : invariant(isAncestorIDOf(ancestorID, destinationID)));
        if (ancestorID === destinationID) {
          return ancestorID;
        }
  // Skip over the ancestor and the immediate separator. Traverse until we hit
  // another separator or we reach the end of `destinationID`.
        const start = ancestorID.length + SEPARATOR_LENGTH;
        for (var i = start; i < destinationID.length; i++) {
          if (isBoundary(destinationID, i)) {
            break;
          }
        }
        return destinationID.substr(0, i);
      }

/**
 * Gets the nearest common ancestor ID of two IDs.
 *
 * Using this ID scheme, the nearest common ancestor ID is the longest common
 * prefix of the two IDs that immediately preceded a "marker" in both strings.
 *
 * @param {string} oneID
 * @param {string} twoID
 * @return {string} Nearest common ancestor ID, or the empty string if none.
 * @private
 */
      function getFirstCommonAncestorID (oneID, twoID) {
        const minLength = Math.min(oneID.length, twoID.length);
        if (minLength === 0) {
          return '';
        }
        let lastCommonMarkerIndex = 0;
  // Use `<=` to traverse until the "EOL" of the shorter string.
        for (let i = 0; i <= minLength; i++) {
          if (isBoundary(oneID, i) && isBoundary(twoID, i)) {
            lastCommonMarkerIndex = i;
          } else if (oneID.charAt(i) !== twoID.charAt(i)) {
            break;
          }
        }
        const longestCommonID = oneID.substr(0, lastCommonMarkerIndex);
        ('production' !== 'production' ? invariant(
    isValidID(longestCommonID),
    'getFirstCommonAncestorID(%s, %s): Expected a valid React DOM ID: %s',
    oneID,
    twoID,
    longestCommonID
  ) : invariant(isValidID(longestCommonID)));
        return longestCommonID;
      }

/**
 * Traverses the parent path between two IDs (either up or down). The IDs must
 * not be the same, and there must exist a parent path between them. If the
 * callback returns `false`, traversal is stopped.
 *
 * @param {?string} start ID at which to start traversal.
 * @param {?string} stop ID at which to end traversal.
 * @param {function} cb Callback to invoke each ID with.
 * @param {?boolean} skipFirst Whether or not to skip the first node.
 * @param {?boolean} skipLast Whether or not to skip the last node.
 * @private
 */
      function traverseParentPath (start, stop, cb, arg, skipFirst, skipLast) {
        start = start || '';
        stop = stop || '';
        ('production' !== 'production' ? invariant(
    start !== stop,
    'traverseParentPath(...): Cannot traverse from and to the same ID, `%s`.',
    start
  ) : invariant(start !== stop));
        const traverseUp = isAncestorIDOf(stop, start);
        ('production' !== 'production' ? invariant(
    traverseUp || isAncestorIDOf(start, stop),
    'traverseParentPath(%s, %s, ...): Cannot traverse from two IDs that do ' +
    'not have a parent path.',
    start,
    stop
  ) : invariant(traverseUp || isAncestorIDOf(start, stop)));
  // Traverse from `start` to `stop` one depth at a time.
        let depth = 0;
        const traverse = traverseUp ? getParentID : getNextDescendantID;
        for (let id = start; /* until break */; id = traverse(id, stop)) {
          var ret;
          if ((!skipFirst || id !== start) && (!skipLast || id !== stop)) {
            ret = cb(id, traverseUp, arg);
          }
          if (ret === false || id === stop) {
      // Only break //after// visiting `stop`.
            break;
          }
          ('production' !== 'production' ? invariant(
      depth++ < MAX_TREE_DEPTH,
      'traverseParentPath(%s, %s, ...): Detected an infinite loop while ' +
      'traversing the React DOM ID tree. This may be due to malformed IDs: %s',
      start, stop
    ) : invariant(depth++ < MAX_TREE_DEPTH));
        }
      }

/**
 * Manages the IDs assigned to DOM representations of React components. This
 * uses a specific scheme in order to traverse the DOM efficiently (e.g. in
 * order to simulate events).
 *
 * @internal
 */
      const ReactInstanceHandles = {

  /**
   * Constructs a React root ID
   * @return {string} A React root ID.
   */
        createReactRootID () {
          return getReactRootIDString(ReactRootIndex.createReactRootIndex());
        },

  /**
   * Constructs a React ID by joining a root ID with a name.
   *
   * @param {string} rootID Root ID of a parent component.
   * @param {string} name A component's name (as flattened children).
   * @return {string} A React ID.
   * @internal
   */
        createReactID (rootID, name) {
          return rootID + name;
        },

  /**
   * Gets the DOM ID of the React component that is the root of the tree that
   * contains the React component with the supplied DOM ID.
   *
   * @param {string} id DOM ID of a React component.
   * @return {?string} DOM ID of the React component that is the root.
   * @internal
   */
        getReactRootIDFromNodeID (id) {
          if (id && id.charAt(0) === SEPARATOR && id.length > 1) {
            const index = id.indexOf(SEPARATOR, 1);
            return index > -1 ? id.substr(0, index) : id;
          }
          return null;
        },

  /**
   * Traverses the ID hierarchy and invokes the supplied `cb` on any IDs that
   * should would receive a `mouseEnter` or `mouseLeave` event.
   *
   * NOTE: Does not invoke the callback on the nearest common ancestor because
   * nothing "entered" or "left" that element.
   *
   * @param {string} leaveID ID being left.
   * @param {string} enterID ID being entered.
   * @param {function} cb Callback to invoke on each entered/left ID.
   * @param {*} upArg Argument to invoke the callback with on left IDs.
   * @param {*} downArg Argument to invoke the callback with on entered IDs.
   * @internal
   */
        traverseEnterLeave (leaveID, enterID, cb, upArg, downArg) {
          const ancestorID = getFirstCommonAncestorID(leaveID, enterID);
          if (ancestorID !== leaveID) {
            traverseParentPath(leaveID, ancestorID, cb, upArg, false, true);
          }
          if (ancestorID !== enterID) {
            traverseParentPath(ancestorID, enterID, cb, downArg, true, false);
          }
        },

  /**
   * Simulates the traversal of a two-phase, capture/bubble event dispatch.
   *
   * NOTE: This traversal happens on IDs without touching the DOM.
   *
   * @param {string} targetID ID of the target node.
   * @param {function} cb Callback to invoke.
   * @param {*} arg Argument to invoke the callback with.
   * @internal
   */
        traverseTwoPhase (targetID, cb, arg) {
          if (targetID) {
            traverseParentPath('', targetID, cb, arg, true, false);
            traverseParentPath(targetID, '', cb, arg, false, true);
          }
        },

  /**
   * Traverse a node ID, calling the supplied `cb` for each ancestor ID. For
   * example, passing `.0.$row-0.1` would result in `cb` getting called
   * with `.0`, `.0.$row-0`, and `.0.$row-0.1`.
   *
   * NOTE: This traversal happens on IDs without touching the DOM.
   *
   * @param {string} targetID ID of the target node.
   * @param {function} cb Callback to invoke.
   * @param {*} arg Argument to invoke the callback with.
   * @internal
   */
        traverseAncestors (targetID, cb, arg) {
          traverseParentPath('', targetID, cb, arg, true, false);
        },

  /**
   * Exposed for unit testing.
   * @private
   */
        _getFirstCommonAncestorID: getFirstCommonAncestorID,

  /**
   * Exposed for unit testing.
   * @private
   */
        _getNextDescendantID: getNextDescendantID,

        isAncestorIDOf,

        SEPARATOR

      };

      module.exports = ReactInstanceHandles;
    }, { './ReactRootIndex': 53, './invariant': 66 }],
    50: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactMarkupChecksum
 */


      const adler32 = _dereq_('./adler32');

      var ReactMarkupChecksum = {
        CHECKSUM_ATTR_NAME: 'data-react-checksum',

  /**
   * @param {string} markup Markup string
   * @return {string} Markup string with checksum attribute attached
   */
        addChecksumToMarkup (markup) {
          const checksum = adler32(markup);
          return markup.replace(
      '>',
      ` ${ReactMarkupChecksum.CHECKSUM_ATTR_NAME}="${checksum}">`
    );
        },

  /**
   * @param {string} markup to use
   * @param {DOMElement} element root React element
   * @returns {boolean} whether or not the markup is the same
   */
        canReuseMarkup (markup, element) {
          let existingChecksum = element.getAttribute(
      ReactMarkupChecksum.CHECKSUM_ATTR_NAME
    );
          existingChecksum = existingChecksum && parseInt(existingChecksum, 10);
          const markupChecksum = adler32(markup);
          return markupChecksum === existingChecksum;
        }
      };

      module.exports = ReactMarkupChecksum;
    }, { './adler32': 58 }],
    51: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactPropTransferer
 */


      const emptyFunction = _dereq_('./emptyFunction');
      const invariant = _dereq_('./invariant');
      const joinClasses = _dereq_('./joinClasses');
      const merge = _dereq_('./merge');

/**
 * Creates a transfer strategy that will merge prop values using the supplied
 * `mergeStrategy`. If a prop was previously unset, this just sets it.
 *
 * @param {function} mergeStrategy
 * @return {function}
 */
      function createTransferStrategy (mergeStrategy) {
        return function (props, key, value) {
          if (!props.hasOwnProperty(key)) {
            props[key] = value;
          } else {
            props[key] = mergeStrategy(props[key], value);
          }
        };
      }

      const transferStrategyMerge = createTransferStrategy((a, b) =>
  // `merge` overrides the first object's (`props[key]` above) keys using the
  // second object's (`value`) keys. An object's style's existing `propA` would
  // get overridden. Flip the order here.
   merge(b, a));

/**
 * Transfer strategies dictate how props are transferred by `transferPropsTo`.
 * NOTE: if you add any more exceptions to this list you should be sure to
 * update `cloneWithProps()` accordingly.
 */
      const TransferStrategies = {
  /**
   * Never transfer `children`.
   */
        children: emptyFunction,
  /**
   * Transfer the `className` prop by merging them.
   */
        className: createTransferStrategy(joinClasses),
  /**
   * Never transfer the `key` prop.
   */
        key: emptyFunction,
  /**
   * Never transfer the `ref` prop.
   */
        ref: emptyFunction,
  /**
   * Transfer the `style` prop (which is an object) by merging them.
   */
        style: transferStrategyMerge
      };

/**
 * Mutates the first argument by transferring the properties from the second
 * argument.
 *
 * @param {object} props
 * @param {object} newProps
 * @return {object}
 */
      function transferInto (props, newProps) {
        for (const thisKey in newProps) {
          if (!newProps.hasOwnProperty(thisKey)) {
            continue;
          }

          const transferStrategy = TransferStrategies[thisKey];

          if (transferStrategy && TransferStrategies.hasOwnProperty(thisKey)) {
            transferStrategy(props, thisKey, newProps[thisKey]);
          } else if (!props.hasOwnProperty(thisKey)) {
            props[thisKey] = newProps[thisKey];
          }
        }
        return props;
      }

/**
 * ReactPropTransferer are capable of transferring props to another component
 * using a `transferPropsTo` method.
 *
 * @class ReactPropTransferer
 */
      const ReactPropTransferer = {

        TransferStrategies,

  /**
   * Merge two props objects using TransferStrategies.
   *
   * @param {object} oldProps original props (they take precedence)
   * @param {object} newProps new props to merge in
   * @return {object} a new object containing both sets of props merged.
   */
        mergeProps (oldProps, newProps) {
          return transferInto(merge(oldProps), newProps);
        },

  /**
   * @lends {ReactPropTransferer.prototype}
   */
        Mixin: {

    /**
     * Transfer props from this component to a target component.
     *
     * Props that do not have an explicit transfer strategy will be transferred
     * only if the target component does not already have the prop set.
     *
     * This is usually used to pass down props to a returned root component.
     *
     * @param {ReactDescriptor} descriptor Component receiving the properties.
     * @return {ReactDescriptor} The supplied `component`.
     * @final
     * @protected
     */
          transferPropsTo (descriptor) {
            ('production' !== 'production' ? invariant(
        descriptor._owner === this,
        '%s: You can\'t call transferPropsTo() on a component that you ' +
        'don\'t own, %s. This usually means you are calling ' +
        'transferPropsTo() on a component passed in as props or children.',
        this.constructor.displayName,
        descriptor.type.displayName
      ) : invariant(descriptor._owner === this));

      // Because descriptors are immutable we have to merge into the existing
      // props object rather than clone it.
            transferInto(descriptor.props, this.props);

            return descriptor;
          }

        }
      };

      module.exports = ReactPropTransferer;
    }, { './emptyFunction': 62, './invariant': 66, './joinClasses': 68, './merge': 71 }],
    52: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactPutListenerQueue
 */


      const PooledClass = _dereq_('./PooledClass');
      const ReactBrowserEventEmitter = _dereq_('./ReactBrowserEventEmitter');

      const mixInto = _dereq_('./mixInto');

      function ReactPutListenerQueue () {
        this.listenersToPut = [];
      }

      mixInto(ReactPutListenerQueue, {
        enqueuePutListener (rootNodeID, propKey, propValue) {
          this.listenersToPut.push({
            rootNodeID,
            propKey,
            propValue
          });
        },

        putListeners () {
          for (let i = 0; i < this.listenersToPut.length; i++) {
            const listenerToPut = this.listenersToPut[i];
            ReactBrowserEventEmitter.putListener(
        listenerToPut.rootNodeID,
        listenerToPut.propKey,
        listenerToPut.propValue
      );
          }
        },

        reset () {
          this.listenersToPut.length = 0;
        },

        destructor () {
          this.reset();
        }
      });

      PooledClass.addPoolingTo(ReactPutListenerQueue);

      module.exports = ReactPutListenerQueue;
    }, { './PooledClass': 43, './ReactBrowserEventEmitter': 44, './mixInto': 74 }],
    53: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactRootIndex
 * @typechecks
 */


      const ReactRootIndexInjection = {
  /**
   * @param {function} _createReactRootIndex
   */
        injectCreateReactRootIndex (_createReactRootIndex) {
          ReactRootIndex.createReactRootIndex = _createReactRootIndex;
        }
      };

      var ReactRootIndex = {
        createReactRootIndex: null,
        injection: ReactRootIndexInjection
      };

      module.exports = ReactRootIndex;
    }, {}],
    54: [function (_dereq_, module, exports) {
/**
 * Copyright 2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ReactServerRenderingTransaction
 * @typechecks
 */


      const PooledClass = _dereq_('./PooledClass');
      const CallbackQueue = _dereq_('./CallbackQueue');
      const ReactPutListenerQueue = _dereq_('./ReactPutListenerQueue');
      const Transaction = _dereq_('./Transaction');

      const emptyFunction = _dereq_('./emptyFunction');
      const mixInto = _dereq_('./mixInto');

/**
 * Provides a `CallbackQueue` queue for collecting `onDOMReady` callbacks
 * during the performing of the transaction.
 */
      const ON_DOM_READY_QUEUEING = {
  /**
   * Initializes the internal `onDOMReady` queue.
   */
        initialize () {
          this.reactMountReady.reset();
        },

        close: emptyFunction
      };

      const PUT_LISTENER_QUEUEING = {
        initialize () {
          this.putListenerQueue.reset();
        },

        close: emptyFunction
      };

/**
 * Executed within the scope of the `Transaction` instance. Consider these as
 * being member methods, but with an implied ordering while being isolated from
 * each other.
 */
      const TRANSACTION_WRAPPERS = [
        PUT_LISTENER_QUEUEING,
        ON_DOM_READY_QUEUEING
      ];

/**
 * @class ReactServerRenderingTransaction
 * @param {boolean} renderToStaticMarkup
 */
      function ReactServerRenderingTransaction (renderToStaticMarkup) {
        this.reinitializeTransaction();
        this.renderToStaticMarkup = renderToStaticMarkup;
        this.reactMountReady = CallbackQueue.getPooled(null);
        this.putListenerQueue = ReactPutListenerQueue.getPooled();
      }

      const Mixin = {
  /**
   * @see Transaction
   * @abstract
   * @final
   * @return {array} Empty list of operation wrap proceedures.
   */
        getTransactionWrappers () {
          return TRANSACTION_WRAPPERS;
        },

  /**
   * @return {object} The queue to collect `onDOMReady` callbacks with.
   */
        getReactMountReady () {
          return this.reactMountReady;
        },

        getPutListenerQueue () {
          return this.putListenerQueue;
        },

  /**
   * `PooledClass` looks for this, and will invoke this before allowing this
   * instance to be resused.
   */
        destructor () {
          CallbackQueue.release(this.reactMountReady);
          this.reactMountReady = null;

          ReactPutListenerQueue.release(this.putListenerQueue);
          this.putListenerQueue = null;
        }
      };


      mixInto(ReactServerRenderingTransaction, Transaction.Mixin);
      mixInto(ReactServerRenderingTransaction, Mixin);

      PooledClass.addPoolingTo(ReactServerRenderingTransaction);

      module.exports = ReactServerRenderingTransaction;
    }, { './CallbackQueue': 37, './PooledClass': 43, './ReactPutListenerQueue': 52, './Transaction': 55, './emptyFunction': 62, './mixInto': 74 }],
    55: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule Transaction
 */


      const invariant = _dereq_('./invariant');

/**
 * `Transaction` creates a black box that is able to wrap any method such that
 * certain invariants are maintained before and after the method is invoked
 * (Even if an exception is thrown while invoking the wrapped method). Whoever
 * instantiates a transaction can provide enforcers of the invariants at
 * creation time. The `Transaction` class itself will supply one additional
 * automatic invariant for you - the invariant that any transaction instance
 * should not be run while it is already being run. You would typically create a
 * single instance of a `Transaction` for reuse multiple times, that potentially
 * is used to wrap several different methods. Wrappers are extremely simple -
 * they only require implementing two methods.
 *
 * <pre>
 *                       wrappers (injected at creation time)
 *                                      +        +
 *                                      |        |
 *                    +-----------------|--------|--------------+
 *                    |                 v        |              |
 *                    |      +---------------+   |              |
 *                    |   +--|    wrapper1   |---|----+         |
 *                    |   |  +---------------+   v    |         |
 *                    |   |          +-------------+  |         |
 *                    |   |     +----|   wrapper2  |--------+   |
 *                    |   |     |    +-------------+  |     |   |
 *                    |   |     |                     |     |   |
 *                    |   v     v                     v     v   | wrapper
 *                    | +---+ +---+   +---------+   +---+ +---+ | invariants
 * perform(anyMethod) | |   | |   |   |         |   |   | |   | | maintained
 * +----------------->|-|---|-|---|-->|anyMethod|---|---|-|---|-|-------->
 *                    | |   | |   |   |         |   |   | |   | |
 *                    | |   | |   |   |         |   |   | |   | |
 *                    | |   | |   |   |         |   |   | |   | |
 *                    | +---+ +---+   +---------+   +---+ +---+ |
 *                    |  initialize                    close    |
 *                    +-----------------------------------------+
 * </pre>
 *
 * Use cases:
 * - Preserving the input selection ranges before/after reconciliation.
 *   Restoring selection even in the event of an unexpected error.
 * - Deactivating events while rearranging the DOM, preventing blurs/focuses,
 *   while guaranteeing that afterwards, the event system is reactivated.
 * - Flushing a queue of collected DOM mutations to the main UI thread after a
 *   reconciliation takes place in a worker thread.
 * - Invoking any collected `componentDidUpdate` callbacks after rendering new
 *   content.
 * - (Future use case): Wrapping particular flushes of the `ReactWorker` queue
 *   to preserve the `scrollTop` (an automatic scroll aware DOM).
 * - (Future use case): Layout calculations before and after DOM upates.
 *
 * Transactional plugin API:
 * - A module that has an `initialize` method that returns any precomputation.
 * - and a `close` method that accepts the precomputation. `close` is invoked
 *   when the wrapped process is completed, or has failed.
 *
 * @param {Array<TransactionalWrapper>} transactionWrapper Wrapper modules
 * that implement `initialize` and `close`.
 * @return {Transaction} Single transaction for reuse in thread.
 *
 * @class Transaction
 */
      const Mixin = {
  /**
   * Sets up this instance so that it is prepared for collecting metrics. Does
   * so such that this setup method may be used on an instance that is already
   * initialized, in a way that does not consume additional memory upon reuse.
   * That can be useful if you decide to make your subclass of this mixin a
   * "PooledClass".
   */
        reinitializeTransaction () {
          this.transactionWrappers = this.getTransactionWrappers();
          if (!this.wrapperInitData) {
            this.wrapperInitData = [];
          } else {
            this.wrapperInitData.length = 0;
          }
          this._isInTransaction = false;
        },

        _isInTransaction: false,

  /**
   * @abstract
   * @return {Array<TransactionWrapper>} Array of transaction wrappers.
   */
        getTransactionWrappers: null,

        isInTransaction () {
          return !!this._isInTransaction;
        },

  /**
   * Executes the function within a safety window. Use this for the top level
   * methods that result in large amounts of computation/mutations that would
   * need to be safety checked.
   *
   * @param {function} method Member of scope to call.
   * @param {Object} scope Scope to invoke from.
   * @param {Object?=} args... Arguments to pass to the method (optional).
   *                           Helps prevent need to bind in many cases.
   * @return Return value from `method`.
   */
        perform (method, scope, a, b, c, d, e, f) {
          ('production' !== 'production' ? invariant(
      !this.isInTransaction(),
      'Transaction.perform(...): Cannot initialize a transaction when there ' +
      'is already an outstanding transaction.'
    ) : invariant(!this.isInTransaction()));
          let errorThrown;
          let ret;
          try {
            this._isInTransaction = true;
      // Catching errors makes debugging more difficult, so we start with
      // errorThrown set to true before setting it to false after calling
      // close -- if it's still set to true in the finally block, it means
      // one of these calls threw.
            errorThrown = true;
            this.initializeAll(0);
            ret = method.call(scope, a, b, c, d, e, f);
            errorThrown = false;
          } finally {
            try {
              if (errorThrown) {
          // If `method` throws, prefer to show that stack trace over any thrown
          // by invoking `closeAll`.
            try {
            this.closeAll(0);
          } catch (err) {
          }
          } else {
          // Since `method` didn't throw, we don't want to silence the exception
          // here.
            this.closeAll(0);
          }
            } finally {
              this._isInTransaction = false;
            }
          }
          return ret;
        },

        initializeAll (startIndex) {
          const transactionWrappers = this.transactionWrappers;
          for (let i = startIndex; i < transactionWrappers.length; i++) {
            const wrapper = transactionWrappers[i];
            try {
        // Catching errors makes debugging more difficult, so we start with the
        // OBSERVED_ERROR state before overwriting it with the real return value
        // of initialize -- if it's still set to OBSERVED_ERROR in the finally
        // block, it means wrapper.initialize threw.
              this.wrapperInitData[i] = Transaction.OBSERVED_ERROR;
              this.wrapperInitData[i] = wrapper.initialize ?
          wrapper.initialize.call(this) :
          null;
            } finally {
              if (this.wrapperInitData[i] === Transaction.OBSERVED_ERROR) {
          // The initializer for wrapper i threw an error; initialize the
          // remaining wrappers but silence any exceptions from them to ensure
          // that the first error is the one to bubble up.
            try {
            this.initializeAll(i + 1);
          } catch (err) {
          }
          }
            }
          }
        },

  /**
   * Invokes each of `this.transactionWrappers.close[i]` functions, passing into
   * them the respective return values of `this.transactionWrappers.init[i]`
   * (`close`rs that correspond to initializers that failed will not be
   * invoked).
   */
        closeAll (startIndex) {
          ('production' !== 'production' ? invariant(
      this.isInTransaction(),
      'Transaction.closeAll(): Cannot close transaction when none are open.'
    ) : invariant(this.isInTransaction()));
          const transactionWrappers = this.transactionWrappers;
          for (let i = startIndex; i < transactionWrappers.length; i++) {
            const wrapper = transactionWrappers[i];
            const initData = this.wrapperInitData[i];
            var errorThrown;
            try {
        // Catching errors makes debugging more difficult, so we start with
        // errorThrown set to true before setting it to false after calling
        // close -- if it's still set to true in the finally block, it means
        // wrapper.close threw.
              errorThrown = true;
              if (initData !== Transaction.OBSERVED_ERROR) {
            wrapper.close && wrapper.close.call(this, initData);
          }
              errorThrown = false;
            } finally {
              if (errorThrown) {
          // The closer for wrapper i threw an error; close the remaining
          // wrappers but silence any exceptions from them to ensure that the
          // first error is the one to bubble up.
            try {
            this.closeAll(i + 1);
          } catch (e) {
          }
          }
            }
          }
          this.wrapperInitData.length = 0;
        }
      };

      var Transaction = {

        Mixin,

  /**
   * Token to look for to determine if an error occured.
   */
        OBSERVED_ERROR: {}

      };

      module.exports = Transaction;
    }, { './invariant': 66 }],
    56: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule ViewportMetrics
 */


      const getUnboundedScrollPosition = _dereq_('./getUnboundedScrollPosition');

      var ViewportMetrics = {

        currentScrollLeft: 0,

        currentScrollTop: 0,

        refreshScrollValues () {
          const scrollPosition = getUnboundedScrollPosition(window);
          ViewportMetrics.currentScrollLeft = scrollPosition.x;
          ViewportMetrics.currentScrollTop = scrollPosition.y;
        }

      };

      module.exports = ViewportMetrics;
    }, { './getUnboundedScrollPosition': 64 }],
    57: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule accumulate
 */


      const invariant = _dereq_('./invariant');

/**
 * Accumulates items that must not be null or undefined.
 *
 * This is used to conserve memory by avoiding array allocations.
 *
 * @return {*|array<*>} An accumulation of items.
 */
      function accumulate (current, next) {
        ('production' !== 'production' ? invariant(
    next != null,
    'accumulate(...): Accumulated items must be not be null or undefined.'
  ) : invariant(next != null));
        if (current == null) {
          return next;
        }
    // Both are not empty. Warning: Never call x.concat(y) when you are not
    // certain that x is an Array (x could be a string with concat method).
        const currentIsArray = Array.isArray(current);
        const nextIsArray = Array.isArray(next);
        if (currentIsArray) {
          return current.concat(next);
        } else if (nextIsArray) {
          return [current].concat(next);
        }
        return [current, next];
      }

      module.exports = accumulate;
    }, { './invariant': 66 }],
    58: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule adler32
 */

/* jslint bitwise:true */


      const MOD = 65521;

// This is a clean-room implementation of adler32 designed for detecting
// if markup is not what we expect it to be. It does not need to be
// cryptographically strong, only reasonable good at detecting if markup
// generated on the server is different than that on the client.
      function adler32 (data) {
        let a = 1;
        let b = 0;
        for (let i = 0; i < data.length; i++) {
          a = (a + data.charCodeAt(i)) % MOD;
          b = (b + a) % MOD;
        }
        return a | (b << 16);
      }

      module.exports = adler32;
    }, {}],
    59: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @typechecks
 * @providesModule cloneWithProps
 */


      const ReactPropTransferer = _dereq_('./ReactPropTransferer');

      const keyOf = _dereq_('./keyOf');
      const warning = _dereq_('./warning');

      const CHILDREN_PROP = keyOf({ children: null });

/**
 * Sometimes you want to change the props of a child passed to you. Usually
 * this is to add a CSS class.
 *
 * @param {object} child child component you'd like to clone
 * @param {object} props props you'd like to modify. They will be merged
 * as if you used `transferPropsTo()`.
 * @return {object} a clone of child with props merged in.
 */
      function cloneWithProps (child, props) {
        if ('production' !== 'production') {
          ('production' !== 'production' ? warning(
      !child.props.ref,
      'You are calling cloneWithProps() on a child with a ref. This is ' +
      'dangerous because you\'re creating a new child which will not be ' +
      'added as a ref to its parent.'
    ) : null);
        }

        const newProps = ReactPropTransferer.mergeProps(props, child.props);

  // Use `child.props.children` if it is provided.
        if (!newProps.hasOwnProperty(CHILDREN_PROP) &&
      child.props.hasOwnProperty(CHILDREN_PROP)) {
          newProps.children = child.props.children;
        }

  // The current API doesn't retain _owner and _context, which is why this
  // doesn't use ReactDescriptor.cloneAndReplaceProps.
        return child.constructor(newProps);
      }

      module.exports = cloneWithProps;
    }, { './ReactPropTransferer': 51, './keyOf': 70, './warning': 76 }],
    60: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule copyProperties
 */

/**
 * Copy properties from one or more objects (up to 5) into the first object.
 * This is a shallow copy. It mutates the first object and also returns it.
 *
 * NOTE: `arguments` has a very significant performance penalty, which is why
 * we don't support unlimited arguments.
 */
      function copyProperties (obj, a, b, c, d, e, f) {
        obj = obj || {};

        if ('production' !== 'production') {
          if (f) {
            throw new Error('Too many arguments passed to copyProperties');
          }
        }

        const args = [a, b, c, d, e];
        let ii = 0,
          v;
        while (args[ii]) {
          v = args[ii++];
          for (const k in v) {
            obj[k] = v[k];
          }

    // IE ignores toString in object iteration.. See:
    // webreflection.blogspot.com/2007/07/quick-fix-internet-explorer-and.html
          if (v.hasOwnProperty && v.hasOwnProperty('toString') &&
        (typeof v.toString !== 'undefined') && (obj.toString !== v.toString)) {
            obj.toString = v.toString;
          }
        }

        return obj;
      }

      module.exports = copyProperties;
    }, {}],
    61: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule cx
 */

/**
 * This function is used to mark string literals representing CSS class names
 * so that they can be transformed statically. This allows for modularization
 * and minification of CSS class names.
 *
 * In static_upstream, this function is actually implemented, but it should
 * eventually be replaced with something more descriptive, and the transform
 * that is used in the main stack should be ported for use elsewhere.
 *
 * @param string|object className to modularize, or an object of key/values.
 *                      In the object case, the values are conditions that
 *                      determine if the className keys should be included.
 * @param [string ...]  Variable list of classNames in the string case.
 * @return string       Renderable space-separated CSS className.
 */
      function cx (classNames) {
        if (typeof classNames === 'object') {
          return Object.keys(classNames).filter(className => classNames[className]).join(' ');
        }
        return Array.prototype.join.call(arguments, ' ');
      }

      module.exports = cx;
    }, {}],
    62: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule emptyFunction
 */

      const copyProperties = _dereq_('./copyProperties');

      function makeEmptyFunction (arg) {
        return function () {
          return arg;
        };
      }

/**
 * This function accepts and discards inputs; it has no side effects. This is
 * primarily useful idiomatically for overridable function endpoints which
 * always need to be callable, since JS lacks a null-call idiom ala Cocoa.
 */
      function emptyFunction () {}

      copyProperties(emptyFunction, {
        thatReturns: makeEmptyFunction,
        thatReturnsFalse: makeEmptyFunction(false),
        thatReturnsTrue: makeEmptyFunction(true),
        thatReturnsNull: makeEmptyFunction(null),
        thatReturnsThis () { return this; },
        thatReturnsArgument (arg) { return arg; }
      });

      module.exports = emptyFunction;
    }, { './copyProperties': 60 }],
    63: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule forEachAccumulated
 */


/**
 * @param {array} an "accumulation" of items which is either an Array or
 * a single item. Useful when paired with the `accumulate` module. This is a
 * simple utility that allows us to reason about a collection of items, but
 * handling the case when there is exactly one item (and we do not need to
 * allocate an array).
 */
      const forEachAccumulated = function (arr, cb, scope) {
        if (Array.isArray(arr)) {
          arr.forEach(cb, scope);
        } else if (arr) {
          cb.call(scope, arr);
        }
      };

      module.exports = forEachAccumulated;
    }, {}],
    64: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule getUnboundedScrollPosition
 * @typechecks
 */


/**
 * Gets the scroll position of the supplied element or window.
 *
 * The return values are unbounded, unlike `getScrollPosition`. This means they
 * may be negative or exceed the element boundaries (which is possible using
 * inertial scrolling).
 *
 * @param {DOMWindow|DOMElement} scrollable
 * @return {object} Map with `x` and `y` keys.
 */
      function getUnboundedScrollPosition (scrollable) {
        if (scrollable === window) {
          return {
            x: window.pageXOffset || document.documentElement.scrollLeft,
            y: window.pageYOffset || document.documentElement.scrollTop
          };
        }
        return {
          x: scrollable.scrollLeft,
          y: scrollable.scrollTop
        };
      }

      module.exports = getUnboundedScrollPosition;
    }, {}],
    65: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule instantiateReactComponent
 * @typechecks static-only
 */


      const invariant = _dereq_('./invariant');

/**
 * Validate a `componentDescriptor`. This should be exposed publicly in a follow
 * up diff.
 *
 * @param {object} descriptor
 * @return {boolean} Returns true if this is a valid descriptor of a Component.
 */
      function isValidComponentDescriptor (descriptor) {
        return (
    descriptor &&
    typeof descriptor.type === 'function' &&
    typeof descriptor.type.prototype.mountComponent === 'function' &&
    typeof descriptor.type.prototype.receiveComponent === 'function'
        );
      }

/**
 * Given a `componentDescriptor` create an instance that will actually be
 * mounted. Currently it just extracts an existing clone from composite
 * components but this is an implementation detail which will change.
 *
 * @param {object} descriptor
 * @return {object} A new instance of componentDescriptor's constructor.
 * @protected
 */
      function instantiateReactComponent (descriptor) {
  // TODO: Make warning
  // if (__DEV__) {
        ('production' !== 'production' ? invariant(
      isValidComponentDescriptor(descriptor),
      'Only React Components are valid for mounting.'
    ) : invariant(isValidComponentDescriptor(descriptor)));
  // }

        return new descriptor.type(descriptor);
      }

      module.exports = instantiateReactComponent;
    }, { './invariant': 66 }],
    66: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule invariant
 */


/**
 * Use invariant() to assert state which your program assumes to be true.
 *
 * Provide sprintf-style format (only %s is supported) and arguments
 * to provide information about what broke and what you were
 * expecting.
 *
 * The invariant message will be stripped in production, but the invariant
 * will remain to ensure logic does not differ in production.
 */

      const invariant = function (condition, format, a, b, c, d, e, f) {
        if ('production' !== 'production') {
          if (format === undefined) {
            throw new Error('invariant requires an error message argument');
          }
        }

        if (!condition) {
          let error;
          if (format === undefined) {
            error = new Error(
        'Minified exception occurred; use the non-minified dev environment ' +
        'for the full error message and additional helpful warnings.'
      );
          } else {
            const args = [a, b, c, d, e, f];
            let argIndex = 0;
            error = new Error(
        `Invariant Violation: ${
        format.replace(/%s/g, () => args[argIndex++])}`
      );
          }

          error.framesToPop = 1; // we don't care about invariant's own frame
          throw error;
        }
      };

      module.exports = invariant;
    }, {}],
    67: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule isEventSupported
 */


      const ExecutionEnvironment = _dereq_('./ExecutionEnvironment');

      let useHasFeature;
      if (ExecutionEnvironment.canUseDOM) {
        useHasFeature =
    document.implementation &&
    document.implementation.hasFeature &&
    // always returns true in newer browsers as per the standard.
    // @see http://dom.spec.whatwg.org/#dom-domimplementation-hasfeature
    document.implementation.hasFeature('', '') !== true;
      }

/**
 * Checks if an event is supported in the current execution environment.
 *
 * NOTE: This will not work correctly for non-generic events such as `change`,
 * `reset`, `load`, `error`, and `select`.
 *
 * Borrows from Modernizr.
 *
 * @param {string} eventNameSuffix Event name, e.g. "click".
 * @param {?boolean} capture Check if the capture phase is supported.
 * @return {boolean} True if the event is supported.
 * @internal
 * @license Modernizr 3.0.0pre (Custom Build) | MIT
 */
      function isEventSupported (eventNameSuffix, capture) {
        if (!ExecutionEnvironment.canUseDOM ||
      capture && !('addEventListener' in document)) {
          return false;
        }

        const eventName = `on${eventNameSuffix}`;
        let isSupported = eventName in document;

        if (!isSupported) {
          const element = document.createElement('div');
          element.setAttribute(eventName, 'return;');
          isSupported = typeof element[eventName] === 'function';
        }

        if (!isSupported && useHasFeature && eventNameSuffix === 'wheel') {
    // This is the only way to test support for the `wheel` event in IE9+.
          isSupported = document.implementation.hasFeature('Events.wheel', '3.0');
        }

        return isSupported;
      }

      module.exports = isEventSupported;
    }, { './ExecutionEnvironment': 42 }],
    68: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule joinClasses
 * @typechecks static-only
 */


/**
 * Combines multiple className strings into one.
 * http://jsperf.com/joinclasses-args-vs-array
 *
 * @param {...?string} classes
 * @return {string}
 */
      function joinClasses (className/* , ... */) {
        if (!className) {
          className = '';
        }
        let nextClass;
        const argLength = arguments.length;
        if (argLength > 1) {
          for (let ii = 1; ii < argLength; ii++) {
            nextClass = arguments[ii];
            nextClass && (className += ` ${nextClass}`);
          }
        }
        return className;
      }

      module.exports = joinClasses;
    }, {}],
    69: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule keyMirror
 * @typechecks static-only
 */


      const invariant = _dereq_('./invariant');

/**
 * Constructs an enumeration with keys equal to their value.
 *
 * For example:
 *
 *   var COLORS = keyMirror({blue: null, red: null});
 *   var myColor = COLORS.blue;
 *   var isColorValid = !!COLORS[myColor];
 *
 * The last line could not be performed if the values of the generated enum were
 * not equal to their keys.
 *
 *   Input:  {key1: val1, key2: val2}
 *   Output: {key1: key1, key2: key2}
 *
 * @param {object} obj
 * @return {object}
 */
      const keyMirror = function (obj) {
        const ret = {};
        let key;
        ('production' !== 'production' ? invariant(
    obj instanceof Object && !Array.isArray(obj),
    'keyMirror(...): Argument must be an object.'
  ) : invariant(obj instanceof Object && !Array.isArray(obj)));
        for (key in obj) {
          if (!obj.hasOwnProperty(key)) {
            continue;
          }
          ret[key] = key;
        }
        return ret;
      };

      module.exports = keyMirror;
    }, { './invariant': 66 }],
    70: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule keyOf
 */

/**
 * Allows extraction of a minified key. Let's the build system minify keys
 * without loosing the ability to dynamically use key strings as values
 * themselves. Pass in an object with a single key/val pair and it will return
 * you the string key of that single record. Suppose you want to grab the
 * value for a key 'className' inside of an object. Key/val minification may
 * have aliased that key to be 'xa12'. keyOf({className: null}) will return
 * 'xa12' in that case. Resolve keys you want to use once at startup time, then
 * reuse those resolutions.
 */
      const keyOf = function (oneKeyObj) {
        let key;
        for (key in oneKeyObj) {
          if (!oneKeyObj.hasOwnProperty(key)) {
            continue;
          }
          return key;
        }
        return null;
      };


      module.exports = keyOf;
    }, {}],
    71: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule merge
 */


      const mergeInto = _dereq_('./mergeInto');

/**
 * Shallow merges two structures into a return value, without mutating either.
 *
 * @param {?object} one Optional object with properties to merge from.
 * @param {?object} two Optional object with properties to merge from.
 * @return {object} The shallow extension of one by two.
 */
      const merge = function (one, two) {
        const result = {};
        mergeInto(result, one);
        mergeInto(result, two);
        return result;
      };

      module.exports = merge;
    }, { './mergeInto': 73 }],
    72: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule mergeHelpers
 *
 * requiresPolyfills: Array.isArray
 */


      const invariant = _dereq_('./invariant');
      const keyMirror = _dereq_('./keyMirror');

/**
 * Maximum number of levels to traverse. Will catch circular structures.
 * @const
 */
      const MAX_MERGE_DEPTH = 36;

/**
 * We won't worry about edge cases like new String('x') or new Boolean(true).
 * Functions are considered terminals, and arrays are not.
 * @param {*} o The item/object/value to test.
 * @return {boolean} true iff the argument is a terminal.
 */
      const isTerminal = function (o) {
        return typeof o !== 'object' || o === null;
      };

      var mergeHelpers = {

        MAX_MERGE_DEPTH,

        isTerminal,

  /**
   * Converts null/undefined values into empty object.
   *
   * @param {?Object=} arg Argument to be normalized (nullable optional)
   * @return {!Object}
   */
        normalizeMergeArg (arg) {
          return arg === undefined || arg === null ? {} : arg;
        },

  /**
   * If merging Arrays, a merge strategy *must* be supplied. If not, it is
   * likely the caller's fault. If this function is ever called with anything
   * but `one` and `two` being `Array`s, it is the fault of the merge utilities.
   *
   * @param {*} one Array to merge into.
   * @param {*} two Array to merge from.
   */
        checkMergeArrayArgs (one, two) {
          ('production' !== 'production' ? invariant(
      Array.isArray(one) && Array.isArray(two),
      'Tried to merge arrays, instead got %s and %s.',
      one,
      two
    ) : invariant(Array.isArray(one) && Array.isArray(two)));
        },

  /**
   * @param {*} one Object to merge into.
   * @param {*} two Object to merge from.
   */
        checkMergeObjectArgs (one, two) {
          mergeHelpers.checkMergeObjectArg(one);
          mergeHelpers.checkMergeObjectArg(two);
        },

  /**
   * @param {*} arg
   */
        checkMergeObjectArg (arg) {
          ('production' !== 'production' ? invariant(
      !isTerminal(arg) && !Array.isArray(arg),
      'Tried to merge an object, instead got %s.',
      arg
    ) : invariant(!isTerminal(arg) && !Array.isArray(arg)));
        },

  /**
   * @param {*} arg
   */
        checkMergeIntoObjectArg (arg) {
          ('production' !== 'production' ? invariant(
      (!isTerminal(arg) || typeof arg === 'function') && !Array.isArray(arg),
      'Tried to merge into an object, instead got %s.',
      arg
    ) : invariant((!isTerminal(arg) || typeof arg === 'function') && !Array.isArray(arg)));
        },

  /**
   * Checks that a merge was not given a circular object or an object that had
   * too great of depth.
   *
   * @param {number} Level of recursion to validate against maximum.
   */
        checkMergeLevel (level) {
          ('production' !== 'production' ? invariant(
      level < MAX_MERGE_DEPTH,
      'Maximum deep merge depth exceeded. You may be attempting to merge ' +
      'circular structures in an unsupported way.'
    ) : invariant(level < MAX_MERGE_DEPTH));
        },

  /**
   * Checks that the supplied merge strategy is valid.
   *
   * @param {string} Array merge strategy.
   */
        checkArrayStrategy (strategy) {
          ('production' !== 'production' ? invariant(
      strategy === undefined || strategy in mergeHelpers.ArrayStrategies,
      'You must provide an array strategy to deep merge functions to ' +
      'instruct the deep merge how to resolve merging two arrays.'
    ) : invariant(strategy === undefined || strategy in mergeHelpers.ArrayStrategies));
        },

  /**
   * Set of possible behaviors of merge algorithms when encountering two Arrays
   * that must be merged together.
   * - `clobber`: The left `Array` is ignored.
   * - `indexByIndex`: The result is achieved by recursively deep merging at
   *   each index. (not yet supported.)
   */
        ArrayStrategies: keyMirror({
          Clobber: true,
          IndexByIndex: true
        })

      };

      module.exports = mergeHelpers;
    }, { './invariant': 66, './keyMirror': 69 }],
    73: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule mergeInto
 * @typechecks static-only
 */


      const mergeHelpers = _dereq_('./mergeHelpers');

      const checkMergeObjectArg = mergeHelpers.checkMergeObjectArg;
      const checkMergeIntoObjectArg = mergeHelpers.checkMergeIntoObjectArg;

/**
 * Shallow merges two structures by mutating the first parameter.
 *
 * @param {object|function} one Object to be merged into.
 * @param {?object} two Optional object with properties to merge from.
 */
      function mergeInto (one, two) {
        checkMergeIntoObjectArg(one);
        if (two != null) {
          checkMergeObjectArg(two);
          for (const key in two) {
            if (!two.hasOwnProperty(key)) {
              continue;
            }
            one[key] = two[key];
          }
        }
      }

      module.exports = mergeInto;
    }, { './mergeHelpers': 72 }],
    74: [function (_dereq_, module, exports) {
/**
 * Copyright 2013-2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule mixInto
 */


/**
 * Simply copies properties to the prototype.
 */
      const mixInto = function (constructor, methodBag) {
        let methodName;
        for (methodName in methodBag) {
          if (!methodBag.hasOwnProperty(methodName)) {
            continue;
          }
          constructor.prototype[methodName] = methodBag[methodName];
        }
      };

      module.exports = mixInto;
    }, {}],
    75: [function (_dereq_, module, exports) {
/**
 * Copyright 2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule monitorCodeUse
 */


      const invariant = _dereq_('./invariant');

/**
 * Provides open-source compatible instrumentation for monitoring certain API
 * uses before we're ready to issue a warning or refactor. It accepts an event
 * name which may only contain the characters [a-z0-9_] and an optional data
 * object with further information.
 */

      function monitorCodeUse (eventName, data) {
        ('production' !== 'production' ? invariant(
    eventName && !/[^a-z0-9_]/.test(eventName),
    'You must provide an eventName using only the characters [a-z0-9_]'
  ) : invariant(eventName && !/[^a-z0-9_]/.test(eventName)));
      }

      module.exports = monitorCodeUse;
    }, { './invariant': 66 }],
    76: [function (_dereq_, module, exports) {
/**
 * Copyright 2014 Facebook, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @providesModule warning
 */


      const emptyFunction = _dereq_('./emptyFunction');

/**
 * Similar to invariant but only logs a warning if the condition is not met.
 * This can be used to log issues in development environments in critical
 * paths. Removing the logging code for production environments will keep the
 * same logic and follow the same code paths.
 */

      let warning = emptyFunction;

      if ('production' !== 'production') {
        warning = function (condition, format) {
          const args = Array.prototype.slice.call(arguments, 2);
          if (format === undefined) {
            throw new Error(
        '`warning(condition, format, ...args)` requires a warning ' +
        'message argument'
      );
          }

          if (!condition) {
            let argIndex = 0;
            console.warn(`Warning: ${format.replace(/%s/g, () => args[argIndex++])}`);
          }
        };
      }

      module.exports = warning;
    }, { './emptyFunction': 62 }],
    77: [function (_dereq_, module, exports) {
/** @license MIT License (c) copyright 2010-2014 original author or authors */
/** @author Brian Cavalier */
/** @author John Hann */

      (function (define) {
        define((_dereq_) => {
          const makePromise = _dereq_('./makePromise');
          const Scheduler = _dereq_('./Scheduler');
          const async = _dereq_('./async');

          return makePromise({
            scheduler: new Scheduler(async)
          });
        });
      }(typeof define === 'function' && define.amd ? define : (factory) => { module.exports = factory(_dereq_); }));
    }, { './Scheduler': 79, './async': 80, './makePromise': 81 }],
    78: [function (_dereq_, module, exports) {
/** @license MIT License (c) copyright 2010-2014 original author or authors */
/** @author Brian Cavalier */
/** @author John Hann */

      (function (define) {
        define(() => {
  /**
   * Circular queue
   * @param {number} capacityPow2 power of 2 to which this queue's capacity
   *  will be set initially. eg when capacityPow2 == 3, queue capacity
   *  will be 8.
   * @constructor
   */
          function Queue (capacityPow2) {
            this.head = this.tail = this.length = 0;
            this.buffer = new Array(1 << capacityPow2);
          }

          Queue.prototype.push = function (x) {
            if (this.length === this.buffer.length) {
              this._ensureCapacity(this.length * 2);
            }

            this.buffer[this.tail] = x;
            this.tail = (this.tail + 1) & (this.buffer.length - 1);
            ++this.length;
            return this.length;
          };

          Queue.prototype.shift = function () {
            const x = this.buffer[this.head];
            this.buffer[this.head] = void 0;
            this.head = (this.head + 1) & (this.buffer.length - 1);
            --this.length;
            return x;
          };

          Queue.prototype._ensureCapacity = function (capacity) {
            let head = this.head;
            const buffer = this.buffer;
            const newBuffer = new Array(capacity);
            let i = 0;
            let len;

            if (head === 0) {
              len = this.length;
              for (; i < len; ++i) {
              newBuffer[i] = buffer[i];
            }
            } else {
              capacity = buffer.length;
              len = this.tail;
              for (; head < capacity; ++i, ++head) {
              newBuffer[i] = buffer[head];
            }

              for (head = 0; head < len; ++i, ++head) {
              newBuffer[i] = buffer[head];
            }
            }

            this.buffer = newBuffer;
            this.head = 0;
            this.tail = this.length;
          };

          return Queue;
        });
      }(typeof define === 'function' && define.amd ? define : (factory) => { module.exports = factory(); }));
    }, {}],
    79: [function (_dereq_, module, exports) {
/** @license MIT License (c) copyright 2010-2014 original author or authors */
/** @author Brian Cavalier */
/** @author John Hann */

      (function (define) {
        define((_dereq_) => {
          const Queue = _dereq_('./Queue');

  // Credit to Twisol (https://github.com/Twisol) for suggesting
  // this type of extensible queue + trampoline approach for next-tick conflation.

  /**
   * Async task scheduler
   * @param {function} async function to schedule a single async function
   * @constructor
   */
          function Scheduler (async) {
            this._async = async;
            this._queue = new Queue(15);
            this._afterQueue = new Queue(5);
            this._running = false;

            const self = this;
            this.drain = function () {
              self._drain();
            };
          }

  /**
   * Enqueue a task
   * @param {{ run:function }} task
   */
          Scheduler.prototype.enqueue = function (task) {
            this._add(this._queue, task);
          };

  /**
   * Enqueue a task to run after the main task queue
   * @param {{ run:function }} task
   */
          Scheduler.prototype.afterQueue = function (task) {
            this._add(this._afterQueue, task);
          };

  /**
   * Drain the handler queue entirely, and then the after queue
   */
          Scheduler.prototype._drain = function () {
            runQueue(this._queue);
            this._running = false;
            runQueue(this._afterQueue);
          };

  /**
   * Add a task to the q, and schedule drain if not already scheduled
   * @param {Queue} queue
   * @param {{run:function}} task
   * @private
   */
          Scheduler.prototype._add = function (queue, task) {
            queue.push(task);
            if (!this._running) {
              this._running = true;
              this._async(this.drain);
            }
          };

  /**
   * Run all the tasks in the q
   * @param queue
   */
          function runQueue (queue) {
            while (queue.length > 0) {
              queue.shift().run();
            }
          }

          return Scheduler;
        });
      }(typeof define === 'function' && define.amd ? define : (factory) => { module.exports = factory(_dereq_); }));
    }, { './Queue': 78 }],
    80: [function (_dereq_, module, exports) {
/** @license MIT License (c) copyright 2010-2014 original author or authors */
/** @author Brian Cavalier */
/** @author John Hann */

      (function (define) {
        define((_dereq_) => {
  // Sniff "best" async scheduling option
  // Prefer process.nextTick or MutationObserver, then check for
  // vertx and finally fall back to setTimeout

  /* jshint maxcomplexity:6*/
  /* global process,document,setTimeout,MutationObserver,WebKitMutationObserver*/
          let nextTick,
            MutationObs;

          if (typeof process !== 'undefined' && process !== null &&
    typeof process.nextTick === 'function') {
            nextTick = function (f) {
              process.nextTick(f);
            };
          } else if (MutationObs =
    (typeof MutationObserver === 'function' && MutationObserver) ||
    (typeof WebKitMutationObserver === 'function' && WebKitMutationObserver)) {
            nextTick = (function (document, MutationObserver) {
          let scheduled;
          const el = document.createElement('div');
          const o = new MutationObserver(run);
          o.observe(el, { attributes: true });

          function run () {
            const f = scheduled;
            scheduled = void 0;
            f();
          }

          return function (f) {
            scheduled = f;
            el.setAttribute('class', 'x');
          };
        }(document, MutationObs));
          } else {
            nextTick = (function (cjsRequire) {
          let vertx;
          try {
        // vert.x 1.x || 2.x
            vertx = cjsRequire('vertx');
          } catch (ignore) {}

          if (vertx) {
            if (typeof vertx.runOnLoop === 'function') {
              return vertx.runOnLoop;
            }
            if (typeof vertx.runOnContext === 'function') {
              return vertx.runOnContext;
            }
          }

      // capture setTimeout to avoid being caught by fake timers
      // used in time based tests
          const capturedSetTimeout = setTimeout;
          return function (t) {
            capturedSetTimeout(t, 0);
          };
        }(_dereq_));
          }

          return nextTick;
        });
      }(typeof define === 'function' && define.amd ? define : (factory) => { module.exports = factory(_dereq_); }));
    }, {}],
    81: [function (_dereq_, module, exports) {
/** @license MIT License (c) copyright 2010-2014 original author or authors */
/** @author Brian Cavalier */
/** @author John Hann */

      (function (define) {
        define(() => function makePromise (environment) {
          const tasks = environment.scheduler;

          const objectCreate = Object.create ||
      function (proto) {
        function Child () {}
        Child.prototype = proto;
        return new Child();
      };

    /**
     * Create a promise whose fate is determined by resolver
     * @constructor
     * @returns {Promise} promise
     * @name Promise
     */
          function Promise (resolver, handler) {
            this._handler = resolver === Handler ? handler : init(resolver);
          }

    /**
     * Run the supplied resolver
     * @param resolver
     * @returns {Pending}
     */
          function init (resolver) {
            const handler = new Pending();

            try {
              resolver(promiseResolve, promiseReject, promiseNotify);
            } catch (e) {
              promiseReject(e);
            }

            return handler;

      /**
       * Transition from pre-resolution state to post-resolution state, notifying
       * all listeners of the ultimate fulfillment or rejection
       * @param {*} x resolution value
       */
            function promiseResolve (x) {
              handler.resolve(x);
            }
      /**
       * Reject this promise with reason, which will be used verbatim
       * @param {Error|*} reason rejection reason, strongly suggested
       *   to be an Error type
       */
            function promiseReject (reason) {
              handler.reject(reason);
            }

      /**
       * Issue a progress event, notifying all progress listeners
       * @param {*} x progress event payload to pass to all listeners
       */
            function promiseNotify (x) {
              handler.notify(x);
            }
          }

    // Creation

          Promise.resolve = resolve;
          Promise.reject = reject;
          Promise.never = never;

          Promise._defer = defer;
          Promise._handler = getHandler;

    /**
     * Returns a trusted promise. If x is already a trusted promise, it is
     * returned, otherwise returns a new trusted Promise which follows x.
     * @param  {*} x
     * @return {Promise} promise
     */
          function resolve (x) {
            return isPromise(x) ? x
        : new Promise(Handler, new Async(getHandler(x)));
          }

    /**
     * Return a reject promise with x as its reason (x is used verbatim)
     * @param {*} x
     * @returns {Promise} rejected promise
     */
          function reject (x) {
            return new Promise(Handler, new Async(new Rejected(x)));
          }

    /**
     * Return a promise that remains pending forever
     * @returns {Promise} forever-pending promise.
     */
          function never () {
            return foreverPendingPromise; // Should be frozen
          }

    /**
     * Creates an internal {promise, resolver} pair
     * @private
     * @returns {Promise}
     */
          function defer () {
            return new Promise(Handler, new Pending());
          }

    // Transformation and flow control

    /**
     * Transform this promise's fulfillment value, returning a new Promise
     * for the transformed result.  If the promise cannot be fulfilled, onRejected
     * is called with the reason.  onProgress *may* be called with updates toward
     * this promise's fulfillment.
     * @param {function=} onFulfilled fulfillment handler
     * @param {function=} onRejected rejection handler
     * @deprecated @param {function=} onProgress progress handler
     * @return {Promise} new promise
     */
          Promise.prototype.then = function (onFulfilled, onRejected) {
            const parent = this._handler;
            const state = parent.join().state();

            if ((typeof onFulfilled !== 'function' && state > 0) ||
        (typeof onRejected !== 'function' && state < 0)) {
        // Short circuit: value will not change, simply share handler
              return new this.constructor(Handler, parent);
            }

            const p = this._beget();
            const child = p._handler;

            parent.chain(child, parent.receiver, onFulfilled, onRejected,
          arguments.length > 2 ? arguments[2] : void 0);

            return p;
          };

    /**
     * If this promise cannot be fulfilled due to an error, call onRejected to
     * handle the error. Shortcut for .then(undefined, onRejected)
     * @param {function?} onRejected
     * @return {Promise}
     */
          Promise.prototype.catch = function (onRejected) {
            return this.then(void 0, onRejected);
          };

    /**
     * Creates a new, pending promise of the same type as this promise
     * @private
     * @returns {Promise}
     */
          Promise.prototype._beget = function () {
            const parent = this._handler;
            const child = new Pending(parent.receiver, parent.join().context);
            return new this.constructor(Handler, child);
          };

    // Array combinators

          Promise.all = all;
          Promise.race = race;

    /**
     * Return a promise that will fulfill when all promises in the
     * input array have fulfilled, or will reject when one of the
     * promises rejects.
     * @param {array} promises array of promises
     * @returns {Promise} promise for array of fulfillment values
     */
          function all (promises) {
      /* jshint maxcomplexity:8*/
            const resolver = new Pending();
            let pending = promises.length >>> 0;
            const results = new Array(pending);

            let i,
              h,
              x,
              s;
            for (i = 0; i < promises.length; ++i) {
              x = promises[i];

              if (x === void 0 && !(i in promises)) {
            --pending;
            continue;
          }

              if (maybeThenable(x)) {
            h = getHandlerMaybeThenable(x);

            s = h.state();
            if (s === 0) {
              h.fold(settleAt, i, results, resolver);
            } else if (s > 0) {
              results[i] = h.value;
              --pending;
            } else {
              unreportRemaining(promises, i + 1, h);
              resolver.become(h);
              break;
            }
          } else {
            results[i] = x;
            --pending;
          }
            }

            if (pending === 0) {
              resolver.become(new Fulfilled(results));
            }

            return new Promise(Handler, resolver);

            function settleAt (i, x, resolver) {
        /* jshint validthis:true*/
              this[i] = x;
              if (--pending === 0) {
            resolver.become(new Fulfilled(this));
          }
            }
          }

          function unreportRemaining (promises, start, rejectedHandler) {
            let i,
              h,
              x;
            for (i = start; i < promises.length; ++i) {
              x = promises[i];
              if (maybeThenable(x)) {
            h = getHandlerMaybeThenable(x);

            if (h !== rejectedHandler) {
              h.visit(h, void 0, h._unreport);
            }
          }
            }
          }

    /**
     * Fulfill-reject competitive race. Return a promise that will settle
     * to the same state as the earliest input promise to settle.
     *
     * WARNING: The ES6 Promise spec requires that race()ing an empty array
     * must return a promise that is pending forever.  This implementation
     * returns a singleton forever-pending promise, the same singleton that is
     * returned by Promise.never(), thus can be checked with ===
     *
     * @param {array} promises array of promises to race
     * @returns {Promise} if input is non-empty, a promise that will settle
     * to the same outcome as the earliest input promise to settle. if empty
     * is empty, returns a promise that will never settle.
     */
          function race (promises) {
      // Sigh, race([]) is untestable unless we return *something*
      // that is recognizable without calling .then() on it.
            if (Object(promises) === promises && promises.length === 0) {
              return never();
            }

            const h = new Pending();
            let i,
              x;
            for (i = 0; i < promises.length; ++i) {
              x = promises[i];
              if (x !== void 0 && i in promises) {
            getHandler(x).visit(h, h.resolve, h.reject);
          }
            }
            return new Promise(Handler, h);
          }

    // Promise internals
    // Below this, everything is @private

    /**
     * Get an appropriate handler for x, without checking for cycles
     * @param {*} x
     * @returns {object} handler
     */
          function getHandler (x) {
            if (isPromise(x)) {
              return x._handler.join();
            }
            return maybeThenable(x) ? getHandlerUntrusted(x) : new Fulfilled(x);
          }

    /**
     * Get a handler for thenable x.
     * NOTE: You must only call this if maybeThenable(x) == true
     * @param {object|function|Promise} x
     * @returns {object} handler
     */
          function getHandlerMaybeThenable (x) {
            return isPromise(x) ? x._handler.join() : getHandlerUntrusted(x);
          }

    /**
     * Get a handler for potentially untrusted thenable x
     * @param {*} x
     * @returns {object} handler
     */
          function getHandlerUntrusted (x) {
            try {
              const untrustedThen = x.then;
              return typeof untrustedThen === 'function'
          ? new Thenable(untrustedThen, x)
          : new Fulfilled(x);
            } catch (e) {
              return new Rejected(e);
            }
          }

    /**
     * Handler for a promise that is pending forever
     * @constructor
     */
          function Handler () {}

          Handler.prototype.when
      = Handler.prototype.become
      = Handler.prototype.notify
      = Handler.prototype.fail
      = Handler.prototype._unreport
      = Handler.prototype._report
      = noop;

          Handler.prototype._state = 0;

          Handler.prototype.state = function () {
            return this._state;
          };

    /**
     * Recursively collapse handler chain to find the handler
     * nearest to the fully resolved value.
     * @returns {object} handler nearest the fully resolved value
     */
          Handler.prototype.join = function () {
            let h = this;
            while (h.handler !== void 0) {
              h = h.handler;
            }
            return h;
          };

          Handler.prototype.chain = function (to, receiver, fulfilled, rejected, progress) {
            this.when({
              resolver: to,
              receiver,
              fulfilled,
              rejected,
              progress
            });
          };

          Handler.prototype.visit = function (receiver, fulfilled, rejected, progress) {
            this.chain(failIfRejected, receiver, fulfilled, rejected, progress);
          };

          Handler.prototype.fold = function (f, z, c, to) {
            this.visit(to, function (x) {
              f.call(c, z, x, this);
            }, to.reject, to.notify);
          };

    /**
     * Handler that invokes fail() on any handler it becomes
     * @constructor
     */
          function FailIfRejected () {}

          inherit(Handler, FailIfRejected);

          FailIfRejected.prototype.become = function (h) {
            h.fail();
          };

          var failIfRejected = new FailIfRejected();

    /**
     * Handler that manages a queue of consumers waiting on a pending promise
     * @constructor
     */
          function Pending (receiver, inheritedContext) {
            Promise.createContext(this, inheritedContext);

            this.consumers = void 0;
            this.receiver = receiver;
            this.handler = void 0;
            this.resolved = false;
          }

          inherit(Handler, Pending);

          Pending.prototype._state = 0;

          Pending.prototype.resolve = function (x) {
            this.become(getHandler(x));
          };

          Pending.prototype.reject = function (x) {
            if (this.resolved) {
              return;
            }

            this.become(new Rejected(x));
          };

          Pending.prototype.join = function () {
            if (!this.resolved) {
              return this;
            }

            let h = this;

            while (h.handler !== void 0) {
              h = h.handler;
              if (h === this) {
            return this.handler = cycle();
          }
            }

            return h;
          };

          Pending.prototype.run = function () {
            const q = this.consumers;
            const handler = this.join();
            this.consumers = void 0;

            for (let i = 0; i < q.length; ++i) {
              handler.when(q[i]);
            }
          };

          Pending.prototype.become = function (handler) {
            if (this.resolved) {
              return;
            }

            this.resolved = true;
            this.handler = handler;
            if (this.consumers !== void 0) {
              tasks.enqueue(this);
            }

            if (this.context !== void 0) {
              handler._report(this.context);
            }
          };

          Pending.prototype.when = function (continuation) {
            if (this.resolved) {
              tasks.enqueue(new ContinuationTask(continuation, this.handler));
            } else if (this.consumers === void 0) {
          this.consumers = [continuation];
        } else {
          this.consumers.push(continuation);
        }
          };

          Pending.prototype.notify = function (x) {
            if (!this.resolved) {
              tasks.enqueue(new ProgressTask(x, this));
            }
          };

          Pending.prototype.fail = function (context) {
            const c = typeof context === 'undefined' ? this.context : context;
            this.resolved && this.handler.join().fail(c);
          };

          Pending.prototype._report = function (context) {
            this.resolved && this.handler.join()._report(context);
          };

          Pending.prototype._unreport = function () {
            this.resolved && this.handler.join()._unreport();
          };

    /**
     * Wrap another handler and force it into a future stack
     * @param {object} handler
     * @constructor
     */
          function Async (handler) {
            this.handler = handler;
          }

          inherit(Handler, Async);

          Async.prototype.when = function (continuation) {
            tasks.enqueue(new ContinuationTask(continuation, this));
          };

          Async.prototype._report = function (context) {
            this.join()._report(context);
          };

          Async.prototype._unreport = function () {
            this.join()._unreport();
          };

    /**
     * Handler that wraps an untrusted thenable and assimilates it in a future stack
     * @param {function} then
     * @param {{then: function}} thenable
     * @constructor
     */
          function Thenable (then, thenable) {
            Pending.call(this);
            tasks.enqueue(new AssimilateTask(then, thenable, this));
          }

          inherit(Pending, Thenable);

    /**
     * Handler for a fulfilled promise
     * @param {*} x fulfillment value
     * @constructor
     */
          function Fulfilled (x) {
            Promise.createContext(this);
            this.value = x;
          }

          inherit(Handler, Fulfilled);

          Fulfilled.prototype._state = 1;

          Fulfilled.prototype.fold = function (f, z, c, to) {
            runContinuation3(f, z, this, c, to);
          };

          Fulfilled.prototype.when = function (cont) {
            runContinuation1(cont.fulfilled, this, cont.receiver, cont.resolver);
          };

          let errorId = 0;

    /**
     * Handler for a rejected promise
     * @param {*} x rejection reason
     * @constructor
     */
          function Rejected (x) {
            Promise.createContext(this);

            this.id = ++errorId;
            this.value = x;
            this.handled = false;
            this.reported = false;

            this._report();
          }

          inherit(Handler, Rejected);

          Rejected.prototype._state = -1;

          Rejected.prototype.fold = function (f, z, c, to) {
            to.become(this);
          };

          Rejected.prototype.when = function (cont) {
            if (typeof cont.rejected === 'function') {
              this._unreport();
            }
            runContinuation1(cont.rejected, this, cont.receiver, cont.resolver);
          };

          Rejected.prototype._report = function (context) {
            tasks.afterQueue(new ReportTask(this, context));
          };

          Rejected.prototype._unreport = function () {
            this.handled = true;
            tasks.afterQueue(new UnreportTask(this));
          };

          Rejected.prototype.fail = function (context) {
            Promise.onFatalRejection(this, context === void 0 ? this.context : context);
          };

          function ReportTask (rejection, context) {
            this.rejection = rejection;
            this.context = context;
          }

          ReportTask.prototype.run = function () {
            if (!this.rejection.handled) {
              this.rejection.reported = true;
              Promise.onPotentiallyUnhandledRejection(this.rejection, this.context);
            }
          };

          function UnreportTask (rejection) {
            this.rejection = rejection;
          }

          UnreportTask.prototype.run = function () {
            if (this.rejection.reported) {
              Promise.onPotentiallyUnhandledRejectionHandled(this.rejection);
            }
          };

    // Unhandled rejection hooks
    // By default, everything is a noop

    // TODO: Better names: "annotate"?
          Promise.createContext
      = Promise.enterContext
      = Promise.exitContext
      = Promise.onPotentiallyUnhandledRejection
      = Promise.onPotentiallyUnhandledRejectionHandled
      = Promise.onFatalRejection
      = noop;

    // Errors and singletons

          const foreverPendingHandler = new Handler();
          var foreverPendingPromise = new Promise(Handler, foreverPendingHandler);

          function cycle () {
            return new Rejected(new TypeError('Promise cycle'));
          }

    // Task runners

    /**
     * Run a single consumer
     * @constructor
     */
          function ContinuationTask (continuation, handler) {
            this.continuation = continuation;
            this.handler = handler;
          }

          ContinuationTask.prototype.run = function () {
            this.handler.join().when(this.continuation);
          };

    /**
     * Run a queue of progress handlers
     * @constructor
     */
          function ProgressTask (value, handler) {
            this.handler = handler;
            this.value = value;
          }

          ProgressTask.prototype.run = function () {
            const q = this.handler.consumers;
            if (q === void 0) {
              return;
            }

            for (var c, i = 0; i < q.length; ++i) {
              c = q[i];
              runNotify(c.progress, this.value, this.handler, c.receiver, c.resolver);
            }
          };

    /**
     * Assimilate a thenable, sending it's value to resolver
     * @param {function} then
     * @param {object|function} thenable
     * @param {object} resolver
     * @constructor
     */
          function AssimilateTask (then, thenable, resolver) {
            this._then = then;
            this.thenable = thenable;
            this.resolver = resolver;
          }

          AssimilateTask.prototype.run = function () {
            const h = this.resolver;
            tryAssimilate(this._then, this.thenable, _resolve, _reject, _notify);

            function _resolve (x) { h.resolve(x); }
            function _reject (x) { h.reject(x); }
            function _notify (x) { h.notify(x); }
          };

          function tryAssimilate (then, thenable, resolve, reject, notify) {
            try {
              then.call(thenable, resolve, reject, notify);
            } catch (e) {
              reject(e);
            }
          }

    // Other helpers

    /**
     * @param {*} x
     * @returns {boolean} true iff x is a trusted Promise
     */
          function isPromise (x) {
            return x instanceof Promise;
          }

    /**
     * Test just enough to rule out primitives, in order to take faster
     * paths in some code
     * @param {*} x
     * @returns {boolean} false iff x is guaranteed *not* to be a thenable
     */
          function maybeThenable (x) {
            return (typeof x === 'object' || typeof x === 'function') && x !== null;
          }

          function runContinuation1 (f, h, receiver, next) {
            if (typeof f !== 'function') {
              return next.become(h);
            }

            Promise.enterContext(h);
            tryCatchReject(f, h.value, receiver, next);
            Promise.exitContext();
          }

          function runContinuation3 (f, x, h, receiver, next) {
            if (typeof f !== 'function') {
              return next.become(h);
            }

            Promise.enterContext(h);
            tryCatchReject3(f, x, h.value, receiver, next);
            Promise.exitContext();
          }

          function runNotify (f, x, h, receiver, next) {
            if (typeof f !== 'function') {
              return next.notify(x);
            }

            Promise.enterContext(h);
            tryCatchReturn(f, x, receiver, next);
            Promise.exitContext();
          }

    /**
     * Return f.call(thisArg, x), or if it throws return a rejected promise for
     * the thrown exception
     */
          function tryCatchReject (f, x, thisArg, next) {
            try {
              next.become(getHandler(f.call(thisArg, x)));
            } catch (e) {
              next.become(new Rejected(e));
            }
          }

    /**
     * Same as above, but includes the extra argument parameter.
     */
          function tryCatchReject3 (f, x, y, thisArg, next) {
            try {
              f.call(thisArg, x, y, next);
            } catch (e) {
              next.become(new Rejected(e));
            }
          }

    /**
     * Return f.call(thisArg, x), or if it throws, *return* the exception
     */
          function tryCatchReturn (f, x, thisArg, next) {
            try {
              next.notify(f.call(thisArg, x));
            } catch (e) {
              next.notify(e);
            }
          }

          function inherit (Parent, Child) {
            Child.prototype = objectCreate(Parent.prototype);
            Child.prototype.constructor = Child;
          }

          function noop () {}

          return Promise;
        });
      }(typeof define === 'function' && define.amd ? define : (factory) => { module.exports = factory(); }));
    }, {}] }, {}, [10]))(10)
}));
