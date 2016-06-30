define([
  'jquery',
  'compiled/views/courses/roster/RosterUserView',
  'compiled/models/RosterUser'
], ($, RosterUserView, RosterUser) => {

  let rosterViewOne;
  let rosterViewTwo;
  let existingENV;
  let server;

  module('RosterUserViewSpec', {
    setup () {
      window.ENV = window.ENV || {};
      existingENV = window.ENV;
      window.ENV.permissions = {
        manage_admin_users: true,
        manage_students: true
      };

      rosterViewOne = new RosterUserView({
        model: new RosterUser({
          id: 1,
          enrollments: [{
            id: 1
          }]
        })
      });

      rosterViewTwo = new RosterUserView({
        model: new RosterUser({
          id: 2,
          enrollments: [{
            id: 1
          }]
        })
      });

      server = sinon.fakeServer.create();

      server.respondWith('POST', /unenroll/, [200, { 'Content-Type': 'application/json' }, '']);

      $('#fixtures').append($('<button id="addUsers">'));
      const $listContainer = $('<div id="lists">')
      $listContainer.append(rosterViewOne.render().el);
      $listContainer.append(rosterViewTwo.render().el);
      $('#fixtures').append($listContainer);

      sinon.stub(window, 'confirm').returns(true);

    },
    teardown () {
      rosterViewOne = null;
      rosterViewTwo = null;
      window.confirm.restore();
      window.ENV = existingENV;
      server.restore();
      $('#fixtures').empty();
    }
  });

  test('moves focus to previous user when deleting a user in the middle', () => {
    rosterViewTwo.removeFromCourse();
    server.respond();
    equal(document.activeElement, $('.al-trigger')[0], 'focus is set to the previous cog.');
  });

  test('moves focus to "+ People" button when deleting the top user', () => {
    rosterViewOne.removeFromCourse();
    server.respond();
    equal(document.activeElement, $('#addUsers')[0], 'focus is set to + People button');
  });

});
