API: `transition` (object)
==========================

This object is sent to the [transition hooks][transition-hooks] as the
first argument.

Methods
-------

### `abort()`

Aborts a transition.

### `redirect(to, params, query)`

Redirect to another route.

### `retry()`

Retries a transition. Typically you save off a transition you care to
return to, finish the workflow, then retry. This does not create a new
entry in the browser history.

### `wait(promise)`

Will pause the transition until the promise resolves.

  [transition-hooks]:/docs/api/components/RouteHandler.md#static-lifecycle-methods

