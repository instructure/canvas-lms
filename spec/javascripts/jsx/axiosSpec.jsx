define(['axios', 'moxios'], (axios, moxios) => {
  QUnit.module('Custom Axios Tests', {
    setup () {
      moxios.install();
    },
    teardown () {
      moxios.uninstall();
    }
  });

  test('Accept headers request stringified ids', (assert) => {
    const done = assert.async();

    moxios.stubRequest('/some/url', {
      status: 200,
      responseText: 'hello'
    });

    axios.get('/some/url').then((response) => {
      ok(response.config.headers.Accept.includes('application/json+canvas-string-ids'));
      done();
    });

    moxios.wait();
  });
});
