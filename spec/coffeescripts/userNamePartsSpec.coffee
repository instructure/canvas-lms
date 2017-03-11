define [ 'user_utils' ], (userUtils) ->

  QUnit.module "UserNameParts"
  test "should infer name parts", ->
    deepEqual userUtils.nameParts("Cody Cutrer"), [ "Cody", "Cutrer", null ]
    deepEqual userUtils.nameParts("  Cody  Cutrer   "), [ "Cody", "Cutrer", null ]
    deepEqual userUtils.nameParts("Cutrer, Cody"), [ "Cody", "Cutrer", null ]
    deepEqual userUtils.nameParts("Cutrer, Cody Houston"), [ "Cody Houston", "Cutrer", null ]
    deepEqual userUtils.nameParts("St. Clair, John"), [ "John", "St. Clair", null ]
    deepEqual userUtils.nameParts("John St. Clair"), [ "John St.", "Clair", null ]
    deepEqual userUtils.nameParts("Jefferson Thomas Cutrer, IV"), [ "Jefferson Thomas", "Cutrer", "IV" ]
    deepEqual userUtils.nameParts("Jefferson Thomas Cutrer IV"), [ "Jefferson Thomas", "Cutrer", "IV" ]
    deepEqual userUtils.nameParts(null), [ null, null, null ]
    deepEqual userUtils.nameParts("Bob"), [ "Bob", null, null ]
    deepEqual userUtils.nameParts("Ho, Chi, Min"), [ "Chi Min", "Ho", null ]
    deepEqual userUtils.nameParts("Ho Chi Min"), [ "Ho Chi", "Min", null ]
    deepEqual userUtils.nameParts(""), [ null, null, null ]
    deepEqual userUtils.nameParts("John Doe"), [ "John", "Doe", null ]
    deepEqual userUtils.nameParts("Junior"), [ "Junior", null, null ]

  test "should use prior_surname", ->
    deepEqual userUtils.nameParts("John St. Clair", "St. Clair"), [ "John", "St. Clair", null ]
    deepEqual userUtils.nameParts("John St. Clair", "Cutrer"), [ "John St.", "Clair", null ]
    deepEqual userUtils.nameParts("St. Clair", "St. Clair"), [ null, "St. Clair", null ]

  test "should infer surname with no given name", ->
    deepEqual userUtils.nameParts("St. Clair,"), [ null, "St. Clair", null ]
