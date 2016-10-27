define([
  'react',
  'react-dom',
  'page',
  'jsx/external_apps/components/Root',
  'jsx/external_apps/components/AppList',
  'jsx/external_apps/components/AppDetails',
  'jsx/external_apps/components/Configurations',
  'jsx/external_apps/lib/AppCenterStore',
  'jsx/external_apps/lib/regularizePathname'
], function(React, ReactDOM, page, Root, AppList, AppDetails, Configurations,
  AppCenterStore, regularizePathname) {

  const currentPath = window.location.pathname;
  const re = /(.*\/settings|.*\/details)/;
  const matches = re.exec(currentPath);
  const baseUrl = matches[0];

  let targetNodeToRenderIn = null;


  /**
   * Route Handlers
   */
  const renderAppList = (ctx) => {
    if (!window.ENV.APP_CENTER.enabled) {
      page.redirect('/configurations');
    } else {
      ReactDOM.render(
        <Root>
          <AppList pathname={ctx.pathname} />
        </Root>
      , targetNodeToRenderIn);
    }
  };

  const renderAppDetails = (ctx) => {
    ReactDOM.render(
      <Root>
        <AppDetails
          shortName={ctx.params.shortName}
          pathname={ctx.pathname}
          baseUrl={baseUrl}
          store={AppCenterStore}
        />
      </Root>
    , targetNodeToRenderIn);
  };

  const renderConfigurations = (ctx) => {
    ReactDOM.render(
      <Root>
        <Configurations
          pathname={ctx.pathname}
          env={window.ENV} />
      </Root>
    , targetNodeToRenderIn);
  }

  /**
   * Route Configuration
   */
  page.base(baseUrl);
  page('*', regularizePathname);
  page('/', renderAppList);
  page('/app/:shortName', renderAppDetails);
  page('/configurations', renderConfigurations);

  return {
    start (targetNode) {
      targetNodeToRenderIn = targetNode;
      page.start();
    },
    stop () {
      page.stop();
    },
    regularizePathname
  };

});
