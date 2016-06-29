define([
  'react',
  'react-dom',
  'page',
  'qs',
  'compiled/react_files/modules/filesEnv',
  'jsx/files/FilesApp',
  'jsx/files/ShowFolder',
  'jsx/files/SearchResults'
], function (React, ReactDOM, page, qs, filesEnv, FilesApp, ShowFolder, SearchResults) {

  /**
   * Route Handlers
   */
  function renderShowFolder (ctx) {
    ReactDOM.render(
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
    ReactDOM.render(
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

  function getFolderSplat (ctx, next) {
    /* This function only gets called when hitting the /folder/*
     * route so we make that assumption here with many of the
     * things being done.
     */
    const PATH_PREFIX = '/folder/';
    const index = ctx.pathname.indexOf(PATH_PREFIX) + PATH_PREFIX.length;
    const rawSplat = ctx.pathname.slice(index);
    ctx.splat = rawSplat.split('/').map((part) => window.encodeURIComponent(part)).join('/');
    next();
  }

  function getSplat (ctx, next) {
    ctx.splat = '';
    next();
  }

  /**
   * Route Configuration
   */
  page.base(filesEnv.baseUrl);
  page('*', getSplat); // Generally this will overridden by the folder route's middleware
  page('*', parseQueryString); // Middleware to parse querystring to object
  page('/', renderShowFolder);
  page('/search', renderSearchResults);
  page('/folder', '/');
  page('/folder/*', getFolderSplat, renderShowFolder);

  return {
    start () {
      page.start();
    },
    getFolderSplat // Export getSplat for testing
  };

});
