/** @jsx React.DOM */

define([
  'react-router',
  'jsx/external_apps/components/Root',
  'jsx/external_apps/components/AppList',
  'jsx/external_apps/components/AppDetails',
  'jsx/external_apps/components/Configurations'
], function({Routes, Route, Redirect}, Root, AppList, AppDetails, Configurations) {

  var currentPath = window.location.pathname
    , re = new RegExp('\(.*\/settings)')
    , matches = re.exec(currentPath)
    , baseUrl = matches[0];

  return (
    <Route name='root' handler={Root}>
      <Route name='appList' path={baseUrl + '/?'} handler={AppList} />
      <Route name='appDetails' path={baseUrl + '/app/:shortName'} handler={AppDetails} />
      <Route name='configurations' path={baseUrl + '/configurations'} handler={Configurations} />
    </Route>
  );

});
