define([
  'react',
  'jsx/external_apps/lib/regularizePathname',
], (React, regularizePathname) => {

  module('External Apps Client-side Router', {
    before () {
      window.ENV = window.ENV || {};
      window.ENV.TESTING_PATH = '/settings/something';
    }
  });

  test('regularizePathname removes trailing slash', () => {

    const fakeCtx = {
      pathname: '/app/something/else/',
    };

    // No op for next().
    const fakeNext = () => {};

    regularizePathname(fakeCtx, fakeNext);

    equal(fakeCtx.pathname, '/app/something/else', 'trailing slash is gone');

  });

});