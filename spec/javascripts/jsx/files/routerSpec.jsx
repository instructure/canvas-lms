define([
  'react',
  'jsx/files/router',
], (React, router) => {

  const TestUtils = React.addons.TestUtils

  module('Files Client-side Router');

  test('getSplat returns the proper splat on ctx given uri characters', () => {
    const fakeCtx = {
      path: '/folder/this%23could%2Bbe%20bad%3F%20maybe',
    };

    // No op for next().
    const fakeNext = () => {};

    router.getSplat(fakeCtx, fakeNext);

    equal(fakeCtx.splat, 'this%23could%2Bbe%20bad%3F%20maybe', 'splat is correctly encoded');

  });

});