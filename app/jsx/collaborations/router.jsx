define([
  'react',
  'page',
  'qs',
  'redux',
  'jsx/collaborations/CollaborationsApp',
  'jsx/collaborations/actions/collaborationsActions',
  'jsx/collaborations/store/store',
  'compiled/str/splitAssetString'
], function (React, page, qs, redux, CollaborationsApp, actions, store, splitAssetString) {
  /**
   * Route Handlers
   */
  function renderShowCollaborations (ctx) {
    store.dispatch(actions.getLTICollaborators(ctx.params.context, ctx.params.contextId));
    store.dispatch(actions.getCollaborations(`/api/v1/${ctx.params.context}/${ctx.params.contextId}/collaborations`));

    let view = () => {
      let state = store.getState();
      React.render(<CollaborationsApp applicationState={state} actions={actions} />, document.getElementById('content'));
    };
    store.subscribe(view);
    view();
  }

  /**
   * Middlewares
   */

  function parseQueryString (ctx, next) {
    ctx.query = qs.parse(ctx.querystring);
    next();
  }

  /**
   * Route Configuration
   */
  page('*', parseQueryString); // Middleware to parse querystring to object
  page('/:context(courses|groups)/:contextId/lti_collaborations', renderShowCollaborations);

  return {
    start () {
      page.start();
    }
  };

});
