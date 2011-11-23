(function() {
  define(['user_utils'], function() {
    module("UserNameParts");
    test("should infer name parts", function() {
      deepEqual(userUtils.nameParts("Cody Cutrer"), ["Cody", "Cutrer", null]);
      deepEqual(userUtils.nameParts("  Cody  Cutrer   "), ["Cody", "Cutrer", null]);
      deepEqual(userUtils.nameParts("Cutrer, Cody"), ["Cody", "Cutrer", null]);
      deepEqual(userUtils.nameParts("Cutrer, Cody Houston"), ["Cody Houston", "Cutrer", null]);
      deepEqual(userUtils.nameParts("St. Clair, John"), ["John", "St. Clair", null]);
      deepEqual(userUtils.nameParts("John St. Clair"), ["John St.", "Clair", null]);
      deepEqual(userUtils.nameParts("Jefferson Thomas Cutrer, IV"), ["Jefferson Thomas", "Cutrer", "IV"]);
      deepEqual(userUtils.nameParts("Jefferson Thomas Cutrer IV"), ["Jefferson Thomas", "Cutrer", "IV"]);
      deepEqual(userUtils.nameParts(null), [null, null, null]);
      deepEqual(userUtils.nameParts("Bob"), ["Bob", null, null]);
      deepEqual(userUtils.nameParts("Ho, Chi, Min"), ["Chi Min", "Ho", null]);
      deepEqual(userUtils.nameParts("Ho Chi Min"), ["Ho Chi", "Min", null]);
      deepEqual(userUtils.nameParts(""), [null, null, null]);
      deepEqual(userUtils.nameParts("John Doe"), ["John", "Doe", null]);
      return deepEqual(userUtils.nameParts("Junior"), ["Junior", null, null]);
    });
    test("should use prior_surname", function() {
      deepEqual(userUtils.nameParts("John St. Clair", "St. Clair"), ["John", "St. Clair", null]);
      deepEqual(userUtils.nameParts("John St. Clair", "Cutrer"), ["John St.", "Clair", null]);
      return deepEqual(userUtils.nameParts("St. Clair", "St. Clair"), [null, "St. Clair", null]);
    });
    return test("should infer surname with no given name", function() {
      return deepEqual(userUtils.nameParts("St. Clair,"), [null, "St. Clair", null]);
    });
  });
}).call(this);
