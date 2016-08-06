define([
  'react',
  'react-dom',
  'page',
  'qs',
  'redux',
  'jsx/collaborations/CollaborationsApp',
  'jsx/collaborations/CollaborationsToolLaunch',
  'jsx/collaborations/actions/collaborationsActions',
  'jsx/collaborations/store/store',
  'compiled/str/splitAssetString'
], function (React, ReactDOM, page, qs, redux, CollaborationsApp, CollaborationsToolLaunch, actions, store, splitAssetString) {

  $(window).on('externalContentReady', (e, data) => store.dispatch(actions.externalContentReady(e, data)));

  let unsubscribe
  /**
   * Route Handlers
   */
  function renderShowCollaborations (ctx) {
    store.dispatch(actions.getLTICollaborators(ctx.params.context, ctx.params.contextId));
    store.dispatch(actions.getCollaborations(`/api/v1/${ctx.params.context}/${ctx.params.contextId}/collaborations`, true));

    let view = () => {
      let state = store.getState();
      ReactDOM.render(<CollaborationsApp applicationState={state} actions={actions} />, document.getElementById('content'));
    };
    unsubscribe = store.subscribe(view);
    view();
  }

  function renderLaunchTool (ctx) {
    let view = () => {
      ReactDOM.render(<CollaborationsToolLaunch launchUrl={ctx.path.replace('/lti_collaborations', '')} />, document.getElementById('content'))
    }
    view()
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
  page.exit('/:context(courses|groups)/:contextId/lti_collaborations', (ctx, next) => {
    unsubscribe()
    next()
  })

  page('/:context(courses|groups)/:contextId/lti_collaborations/external_tools*', renderLaunchTool);

  return {
    start () {
      page.start();
    }
  };

});
