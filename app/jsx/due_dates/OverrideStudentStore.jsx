define([
  'react',
  'underscore',
  'jsx/shared/helpers/createStore',
  'jquery',
  'compiled/backbone-ext/DefaultUrlMixin',
  'compiled/fn/parseLinkHeader',
], (React, _, createStore, $, DefaultUrlMixin, parseLinkHeader) => {

  // -------------------
  //     Initialize
  // -------------------

  var initialStoreState = {
    students: {},
    searchedNames: {},
    currentlySearching: false,
    allStudentsFetched: false
  }

  var OverrideStudentStore = createStore($.extend(true, {}, initialStoreState))

  // -------------------
  //   Private Methods
  // -------------------

  function studentEnrollments(student) {
    return _.filter(student.enrollments, function(enrollment) {
      return enrollment.type === "StudentEnrollment" || enrollment.type === "StudentViewEnrollment";
    });
  }

  function sectionIDs(enrollments) {
    return _.map(enrollments, enrollment => enrollment.course_section_id);
  }

  // -------------------
  //      Fetching
  // -------------------

  // ---- by ID ----

  OverrideStudentStore.fetchStudentsByID = function(givenIds) {
    if (typeof givenIds === 'undefined' || givenIds.length === 0) {
      return null
    }

    var getUsersPath = this.getContextPath() + "/users"
    $.getJSON(getUsersPath,
      {user_ids: givenIds, enrollment_type: "student", include: ["enrollments", "group_ids"]},
      this._fetchStudentsByIDSuccessHandler.bind(this, {})
    )
  }

  OverrideStudentStore._fetchStudentsByIDSuccessHandler = function(opts, items, status, xhr){
    this.addStudents(items)
  }

  // ---- by name ----

  OverrideStudentStore.fetchStudentsByName = function(nameString) {
    if( $.trim(nameString) === "" ||
        this.allStudentsFetched() ||
        this.alreadySearchedForName(nameString)){
      return true
    }

    var searchUsersPath = this.getContextPath() + "/search_users"

    this.setState({
      currentlySearching: true
    })

    $.getJSON(searchUsersPath,
      {search_term: nameString, enrollment_type: "student", include_inactive: false, include: ["enrollments", "group_ids"]},
      this._fetchStudentsByNameSuccessHandler.bind(this, {nameString: nameString}),
      this._fetchStudentsByNameErrorHandler.bind(this, {nameString: nameString})
    )
  }

  OverrideStudentStore.allStudentsFetched = function(){
    return this.getState().allStudentsFetched
  }

  OverrideStudentStore._fetchStudentsByNameSuccessHandler = function(opts, items, status, xhr){
    this.doneSearching()
    this.markNameSearched(opts["nameString"])
    this.addStudents(items)
  }

  OverrideStudentStore._fetchStudentsByNameErrorHandler = function(opts){
    this.doneSearching()
  }

  // ---- by course ----

  var PAGES_OF_STUDENTS_TO_FETCH = 4
  var STUDENTS_FETCHED_PER_PAGE = 50

  OverrideStudentStore.fetchStudentsForCourse = function(){
    _.times(PAGES_OF_STUDENTS_TO_FETCH,(i) => {
      var pageNumber = i + 1
      this.fetchPageOfStudents(pageNumber)
    })
  },

  OverrideStudentStore.fetchPageOfStudents = function(pageNumber) {
    var path = this.getContextPath() + "/users"

    $.getJSON(path,
      {per_page: STUDENTS_FETCHED_PER_PAGE, page: pageNumber, enrollment_type: "student", include_inactive: false, include: ["enrollments", "group_ids"]},
      this._fetchStudentsForCourseSuccessHandler.bind(this, {})
    )
  }

  OverrideStudentStore._fetchStudentsForCourseSuccessHandler = function(opts, items, status, xhr){
    this.addStudents(items)

    var links = parseLinkHeader(xhr)
    if(!links.next){
      this.setState({allStudentsFetched: true})
    }
  }

  // -------------------
  //   Set & Get State
  // -------------------

  OverrideStudentStore.getStudents = function(){
    return OverrideStudentStore.getState().students
  }

  OverrideStudentStore.addStudents = function(newlyFetchedStudents){
    _.each(newlyFetchedStudents, (student) => {
      student.enrollments = studentEnrollments(student);
      student.sections = sectionIDs(student.enrollments);
    });
    let newStudentsHash = _.indexBy(newlyFetchedStudents, (student) => student.id)
    let newStudentState = _.extend(newStudentsHash, this.getState().students)
    this.setState({
      students: newStudentState
    })
  }

  OverrideStudentStore.doneSearching = function(){
    this.setState({
      currentlySearching: false
    })
  }

  OverrideStudentStore.currentlySearching = function(){
    return this.getState().currentlySearching
  }

  // -------------------
  //       Helpers
  // -------------------

  OverrideStudentStore.getContextPath = function(){
    return "/api/v1/" + DefaultUrlMixin._contextPath()
  }

  // test helper
  OverrideStudentStore.reset = function(){
    this.setState($.extend(true, {}, initialStoreState))
  }

  // ----------------------
  // Marking Name Searched
  // ----------------------

  OverrideStudentStore.alreadySearchedForName = function(name){
    return !!this.getState().searchedNames[name]
  }

  OverrideStudentStore.alreadySearchingForName = function(name){
    return _.contains(this.getState().activeNameSearches, name)
  }

  OverrideStudentStore.markNameSearched = function(name){
    var searchedNames = this.getState().searchedNames
    searchedNames[name] = true
    this.setState({
      searchedNames: searchedNames
    })
  }

  return OverrideStudentStore
});
