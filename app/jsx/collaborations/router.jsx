define([
  'react',
  'page',
  'qs',
  'jsx/collaborations/CollaborationsApp'
], function (React, page, qs, CollaborationsApp) {

  /**
   * Route Handlers
   */
  function renderShowCollaborations (ctx) {
    React.render(
      <CollaborationsApp />
    , document.getElementById('content'));
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
