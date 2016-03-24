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
    const index = ctx.pathname.indexOf(ctx.params[0]);
    if (index) {
      ctx.unencodedSplat = ctx.pathname.slice(index);
      ctx.splat = ctx.unencodedSplat.split('/').map((component) => {
        return encodeURIComponent(component)
      }).join('/');
    } else {
      ctx.splat = '';
      ctx.unencodedSplat = '';
    }
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

    goToPath (pathToGoTo) {
      page(pathToGoTo);
    }
  };

});