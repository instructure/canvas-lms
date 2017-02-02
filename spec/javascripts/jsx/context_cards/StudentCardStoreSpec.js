define(['jsx/context_cards/StudentCardStore'], (StudentCardStore) => {
  const gradedSubmission = {graded_at: new Date(), id: 2, grade: '5'};

  QUnit.module('StudentCardStore', {
    setup () {
      this.server = sinon.fakeServer.create();

      this.server.respondWith(
        /\/api\/v1\/courses\/\d+/,
        JSON.stringify({name: 'Awesome Course'})
      );
      this.server.respondWith(
        /\/api\/v1\/courses\/\d+\/permissions/,
        JSON.stringify({
          manage_grades: true,
          send_messages: true,
          view_all_grades: true,
          view_analytics: true
        })
      );
      this.server.respondWith(
        /\/api\/v1\/courses\/\d+\/users/,
        JSON.stringify({name: 'Student Name'})
      );
      this.server.respondWith(
        /\/api\/v1\/courses\/\d+\/students\/submissions/,
        JSON.stringify([
          {graded_at: new Date(), id: 3, grade: null},
          {graded_at: null, id: 1},
          gradedSubmission,
        ])
      );
      this.server.respondWith(
        /\/api\/v1\/courses\/\d+\/analytics/,
        JSON.stringify(['stuff'])
      );
      this.server.autoRespond = true
    },

    teardown() {
      this.server.restore();
    }
  });


  test('starts out loading', function () {
    const store = new StudentCardStore(2, 1);
    ok(store.getState().loading);
  })

  test('state is updated as ajax calls complete', function (assert) {
    const done = assert.async();
    const store = new StudentCardStore(2, 1);
    const spy = sinon.spy(() => {
      if (spy.callCount === 6) {
        ok(true, 'onChange is called as state updates');
        done();
      }
    });
    store.onChange = spy;
    store.load()
  });

  test('state is correct after loading', function (assert) {
    const store = new StudentCardStore(2, 1);
    store.load()
    const done = assert.async();
    store.onChange = (state) => {
      if (state.loading === false) {
        equal(state.submissions.length, 1);
        equal(state.submissions[0].id, gradedSubmission.id);
        equal(state.analytics, 'stuff');
        done();
      }
    }
  });
});
