/*jshint indent:4 */

(function() {
    define(['jquery'], function() {
        $("#course_list").click(function(){ window.location = "/courses"});
        $("#course_form").click(function(){ window.location = "/sfu/course/new"});
    });
})();