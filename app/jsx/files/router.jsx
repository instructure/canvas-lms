define([
  'react',
  'page',
  'qs',
  'compiled/react_files/modules/filesEnv',
  'jsx/files/FilesApp',
  'jsx/files/ShowFolder',
  'jsx/files/SearchResults'
], function (React, page, qs, filesEnv, FilesApp, ShowFolder, SearchResults) {

  /**
   * Route Handlers
   */
  function renderShowFolder (ctx) {
    React.render(
      <FilesApp
        query={ctx.query}
        params={ctx.params}
        splat={ctx.splat}
        pathname={ctx.pathname}
        contextAssetString={window.ENV.context_asset_string}
      >
        <ShowFolder />
      </FilesApp>
    , document.getElementById('content'));
  }

  function renderSearchResults (ctx) {
    React.render(
      <FilesApp
        query={ctx.query}
        params={ctx.params}
        splat={ctx.splat}
        pathname={ctx.pathname}
        contextAssetString={window.ENV.context_asset_string}
      >
        <SearchResults />
      </FilesApp>
    , document.getElementById('content'));
  }

  /**
   * Middlewares
   */

  function parseQueryString (ctx, next) {
    ctx.query = qs.parse(ctx.querystring);
    next();
  }

  function getSplat (ctx, next) {
    /* This function only gets called when hitting the /folder/*
     * route so we make that assumption here with many of the
     * things being done.
     */
    const PATH_PREFIX = '/folder/';
    const index = ctx.path.indexOf(PATH_PREFIX) + PATH_PREFIX.length
    ctx.splat = ctx.path.slice(index)
    next();
  }

  /**
   * Route Configuration
   */
  page.base(filesEnv.baseUrl);
  page('*', parseQueryString); // Middleware to parse querystring to object
  page('/', renderShowFolder);
  page('/search', renderSearchResults);
  page('/folder', '/');
  page('/folder/*', getSplat, renderShowFolder);

  return {
    start () {
      page.start();
    },
    getSplat // Export getSplat for testing
  };

});