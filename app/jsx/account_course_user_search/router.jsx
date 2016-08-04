define([
  'page',
  './actions/TabActions'
], function(page, TabActions) {


  const router = {
    start: (store) => {
      const tabList = store.getState().tabList;

      page.base(tabList.basePath);

      tabList.tabs.forEach((tab, i) => {
        page(tab.path, (ctx) => {
          store.dispatch(TabActions.selectTab( i ));
        });
      });

      if (tabList.tabs.length)
        page('/', tabList.tabs[0].path);

      page.start();
    }
  };


  return router;
});
