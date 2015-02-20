API: `Route` (component)
=========================

Configuration component to declare your application's routes and entry
view hierarchy.

Props
-----

### `name`

The name of the route, used in the `Link` component and the router's
transition methods.

### `path`

The path used in the URL. If left undefined, the path will be defined by
the `name`, and if there is no name, will default to `/`.

Please refer to the [Path Matching Guide][path-matching] to learn more
about supported path matching syntax.

### `handler`

The component to be rendered when the route is active.

### `children`

Routes can be nested. When a child route path matches, the parent route
is also activated. Please refer to the [overview][overview] since this
is a very critical part of the router's design.

Example
-------

```xml
<!-- `path` defaults to '/' since no name or path provided -->
<Route handler={App}>
  <!-- path is automatically assigned to the name since it is omitted -->
  <Route name="about" handler={About}/>
  <Route name="users" handler={Users}>
    <!--
      note the dynamic segment in the path, and that it starts with `/`,
      which makes it "absolute", or rather, it doesn't inherit the path
      from the parent route
    -->
    <Route name="user" handler={User} path="/user/:id"/>
  </Route>
</Route>
```

  [overview]:/docs/guides/overview.md
  [path-matching]:/docs/guides/path-matching.md
