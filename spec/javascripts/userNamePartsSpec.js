define(['js!user_utils.js'], function() {
  module('UserNameParts');
  test("should infer name parts", function() {
    deepEqual(userUtils.nameParts('Cody Cutrer'), ['Cody', 'Cutrer', null]);
    deepEqual(userUtils.nameParts('  Cody  Cutrer   '), ['Cody', 'Cutrer', null]);
    deepEqual(userUtils.nameParts('Cutrer, Cody'), ['Cody', 'Cutrer', null]);
    deepEqual(userUtils.nameParts('Cutrer, Cody Houston'), ['Cody Houston', 'Cutrer', null]);
    deepEqual(userUtils.nameParts('St. Clair, John'), ['John', 'St. Clair', null]);
    // sorry, can't figure this out
    deepEqual(userUtils.nameParts('John St. Clair'), ['John St.', 'Clair', null]);
    deepEqual(userUtils.nameParts('Jefferson Thomas Cutrer, IV'), ['Jefferson Thomas', 'Cutrer', 'IV']);
    deepEqual(userUtils.nameParts('Jefferson Thomas Cutrer IV'), ['Jefferson Thomas', 'Cutrer', 'IV']);
    deepEqual(userUtils.nameParts(null), [null, null, null]);
    deepEqual(userUtils.nameParts('Bob'), ['Bob', null, null]);
    deepEqual(userUtils.nameParts('Ho, Chi, Min'), ['Chi Min', 'Ho', null]);
    // sorry, don't understand cultures that put the surname first
    // they should just manually specify their sort name
    deepEqual(userUtils.nameParts('Ho Chi Min'), ['Ho Chi', 'Min', null]);
    deepEqual(userUtils.nameParts(''), [null, null, null]);
    deepEqual(userUtils.nameParts('John Doe'), ['John', 'Doe', null]);
    deepEqual(userUtils.nameParts('Junior'), ['Junior', null, null]);
    deepEqual(userUtils.nameParts('John St. Clair', 'St. Clair'), ['John', 'St. Clair', null])
    deepEqual(userUtils.nameParts('John St. Clair', 'Cutrer'), ['John St.', 'Clair', null])
    deepEqual(userUtils.nameParts('St. Clair', 'St. Clair'), [null, 'St. Clair', null])
    deepEqual(userUtils.nameParts('St. Clair,'), [null, 'St. Clair', null])
  });
});
