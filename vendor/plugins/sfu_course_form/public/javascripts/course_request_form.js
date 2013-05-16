/*jshint camelcase:false, indent:4 */
/*global Spinner*/

(function() {
    define(['jquery', 'vendor/spin'], function() {
        return function() {

            var sep = ":::";
            var sep2 = ":_:";

            var spinnerOpts = {
                lines: 13, // The number of lines to draw
                length: 6, // The length of each line
                width: 2, // The line thickness
                radius: 8, // The radius of the inner circle
                corners: 1, // Corner roundness (0..1)
                rotate: 0, // The rotation offset
                color: '#000', // #rgb or #rrggbb
                speed: 1, // Rounds per second
                trail: 60, // Afterglow percentage
                shadow: false, // Whether to render a shadow
                hwaccel: false, // Whether to use hardware acceleration
                className: 'spinner', // The CSS class to assign to the spinner
                zIndex: 2e9, // The z-index (defaults to 2000000000)
                top: 'auto', // Top position relative to parent in px
                left: 'auto' // Left position relative to parent in px
            };

            // jquery spinner plugin
            $.fn.spin = function(opts) {
                this.each(function() {
                    var $this = $(this),
                        data = $this.data();
                    if (data.spinner) {
                        data.spinner.stop();
                        delete data.spinner;
                    }
                    if (opts !== false) {
                        data.spinner = new Spinner($.extend({color: $this.css('color')}, opts)).spin(this);
                    }
                });
                return this;
            };

            $(document).ready(function () {
                $("#create_course_btn").click(function() {
                    $("#create_course_btn").toggleClass("btn-primary btn-success").attr("value","Submitting...");
                    $("#button-container").spin(spinnerOpts);
                });

                $('#course_list').on('click', 'input[type="checkbox"]', function() {
                    enable_submit_crosslist();
                    if (this.id.indexOf('sandbox') === -1) {
                        cross_list_course_title();
                    }
                });

                $('#course_search_list').on('click', 'input[type="checkbox"]', function() {
                    enable_submit_crosslist();
                    if (this.id.indexOf('sandbox') === -1) {
                        cross_list_course_title();
                    }
                });

                $('.new_course_container').on('click', '#cross_list', function() {
                    cross_list_course_title();
                });

                $("#update_course_list").click(function() {
                    var sfu_id = username();
                    $("#enroll_me_div").hide();
                    $("#course_list").html("<h5>Retrieving course list...</h5>");
                    $("#course_list").spin(spinnerOpts);

                    $.ajax({
                        url: "/sfu/api/v1/amaint/user/" + sfu_id,
                        dataType: "json",
                        success: function(data) {
                            course_list(sfu_id);
                        },
                        error: function(xhr) {
                            var statusCode = xhr.status;
                            if (statusCode === 404) {
                                $("#course_list").html("<h5>Invalid SFU Computing ID</h5>");
                            } else {
                                $("#course_list").html("<h5>An unknown error occurred</h5>");
                            }
                        }
                    });
                });

                $("#username").keypress(function(ev){
                    if (ev.keyCode === 10 || ev.keyCode === 13) {
                        ev.preventDefault();
                        $('#update_course_list').trigger('click')
                    }
                });

                $( "#course_search" ).autocomplete({
                    source: function ( request, response ) {
                        var search = $( "#course_search" ).val();
                        var term_select = $( "#term_select" ).val();
                        var search_url = "/sfu/api/v1/course-data/"+ term_select +"/"+ search;
                        $.ajax({
                            url: search_url,
                            dataType: "json",
                            success: function(data) {
                                response ( $.map( data, function( item ) {
                                    var course_info = item.split( sep2 );
                                    return {
                                        label: course_info[1],
                                        value: course_info[0]
                                    }
                                }));
                            },
                            error: function(XMLHttpRequest, textStatus, errorThrown) {
                                console.log( "Error getting course list: " + errorThrown );
                            }
                        });
                    },
                    focus: function ( event, ui ) {
                        $( "#course_search" ).val( ui.item.label );
                        return false;
                    },
                    minLength: 3,
                    select: function ( event, ui ) {
                        add_course(ui.item.value, ui.item.label);
			return false;
                    } //select end
                }); //autocomplete end

                $("#term_select").change(function() {
                    // When changing the term, clear the search field
                    $("#course_search").val("");
                });

                $("#enroll_me_div").hide();
                $("#course_list").html("<h5>Retrieving course list...</h5>").spin(spinnerOpts);
                course_list();
            });

            function course_list() {
                toggle_enroll_me();
                var sfu_id = $("#username").val();
                $("#course_list").html("");
                $.ajax({
                    url: "/sfu/api/v1/amaint/user/" + sfu_id + "/term",
                    dataType: "json",
                    success: function(data) {
                        $.each(data, function (index, term) {
                            if (term_exists(term.peopleSoftCode)) {
                                $("#course_list").append('<div id="' + term.peopleSoftCode + '"><h4>' + term.formatted1 + '</h4><div id="' + term.peopleSoftCode + '_courses"></div></div>');
                                $("#"+term.peopleSoftCode+"_courses").html("<label> Retrieving courses... </label>");
                                courses_for_terms(sfu_id, term.peopleSoftCode);
                            }
                        });
                        sandbox_course();
                    },
                    error: function(xhr) {
                        var statusCode = xhr.status;
                        if (statusCode === 404) {
                            //$("#course_list").html("<h5>No courses found</h5>");
                            sandbox_course();
                        } else {
                            $("#course_list").html("<h5>An unknown error occurred</h5>");
                        }
                    }
                })
            }

            function courses_for_terms(sfu_id, term) {
                $("#" + term + "_courses").spin(spinnerOpts);
                $.ajax({
                    url: "/sfu/api/v1/amaint/user/" + sfu_id + "/term/" + term,
                    dataType: 'json',
                    success: function(data) {
                        var num = 1;
                        $("#"+term+"_courses").html("");
                        $.each(data, function (index, course) {
                            var section_tutorials = course.sectionTutorials;
                            var course_display = course.name + course.number + " - " + course.section + " " + course.title;
                            if (section_tutorials) {
                                course_display += "<label> (Includes section tutorials: " + section_tutorials  + ") </label>";
                            }
                            var course_value = course.key;
                            var checkbox_html = '<label class="checkbox"><input type="checkbox" name="selected_course_'+ num +'_'+ term +'" id="selected_course_'+ num +'_'+ term +'" value="'+ course_value + '">' + course_display +'</label>';
                            $("#"+term+"_courses").append(checkbox_html);
                            num++;
                        });
                    },
                    error: function(xhr) {
                        var statusCode = xhr.status;
                        if (statusCode === 404) {
                            $("#"+term+"_courses").html("<h5>No courses found</h5>");
                        } else {
                            $("#course_list").html("<h5>An unknown error occurred</h5>");
                        }
                    }
                });
            }

            function enable_submit_crosslist() {
                var num_selected_courses = "";
                var selected_terms = [];
                $('input[type="checkbox"]:checked').each(function() {
                    if ($(this).attr('id').match(/^selected_course_/)) {
                        num_selected_courses++;
                        var checkbox_id_arr = $(this).attr('id').split("_");
                        selected_terms.push(checkbox_id_arr[checkbox_id_arr.length-1]);
                    }
                }).get();

                if ( (num_selected_courses > 2) || (num_selected_courses > 1 && !$("#selected_course_sandbox").is(':checked')) ) {
                    $("#create_course_btn").removeAttr("disabled");
                    $("#enroll_me").removeAttr("disabled");
                    enable_cross_list(true);
                } else if (num_selected_courses > 0) {
                    $("#create_course_btn").removeAttr("disabled");
                    $("#enroll_me").removeAttr("disabled");
                    enable_cross_list(false);
                } else {
                    $("#create_course_btn").attr("disabled", "disabled");
                    enable_cross_list(false);
                }

                if (jQuery.unique(selected_terms).length > 1) enable_cross_list(false); // Cannot cross-list across terms
            }

            function cross_list_course_title() {
                // Disable Sandbox checkbox since it should not be cross-listed
                if ($("#cross_list").is(':checked')) {
                    $("#cross-list-course").html("");
                    $("#selected_course_sandbox").removeAttr("checked");
                    $("#selected_course_sandbox").attr("disabled", "disabled");
                    //var checked = $("input[type='checkbox']:checked");
                    var cross_list_title = "";
                    $('input[type="checkbox"]:checked').each(function() {
                        if ($(this).attr('id').match(/^selected_course_/) && $(this).attr('id') !== "selected_course_sandbox" ) {
                            var course_info = $(this).val().split(":::");
                            cross_list_title += course_info[1].toUpperCase() + course_info[2] + " - " + course_info[3].toUpperCase() + " / ";
                        }
                    }).get();
                    $("#cross-list-course").html("&nbsp;&nbsp;&quot;" + cross_list_title.slice(0,-3) + "&quot;");
                    $("#create_course_btn").attr("value","Create Cross-List Course");
                } else {
                    $("#selected_course_sandbox").removeAttr("disabled");
                    $("#cross-list-course").html("");
                    $("#create_course_btn").attr("value","Create Courses");
                }
            }

            function toggle_enroll_me(){
                if ($("#username").val() !== $("#enroll_me").val()) {
                    $("#enroll_me_div").show();
                } else {
                    $("#enroll_me_div").hide();
                }
            }

            function enable_cross_list(enable){
                if (enable) {
                    $("#cross_list").removeAttr("disabled");
                } else {
                    $("#cross_list").removeAttr("checked");
                    $("#cross_list").attr("disabled", "disabled");
                    $("#cross-list-course").html("");
                }
            }

            function sandbox_course() {
                var sfu_id = $("#username").val();
                var title = "Sandbox - " + sfu_id + " - " + today();
                var sis_id = "sandbox-" + sfu_id + "-" + today();
                $("#course_list").append("<div id='sandbox'><h4>Other</h4></div>");
                var checkbox_html = '<label class="checkbox"><input type="checkbox" name="selected_course_sandbox_'+ today() +'" id="selected_course_sandbox_'+ today() +'" value="'+ sis_id +'">'+ title +'</label>';
                $("#sandbox").append(checkbox_html);
            }            

            function username() {
                var value = $("#username").val();
                if (value.indexOf("@") > 0) {
                    value = value.split("@")[0];
                    $("#username").val(value);
                }
                return value;
            }

            function today() {
                var now = new Date();
                var dateString = (now.getMonth()+1).toString() + now.getDate().toString() + (now.getYear()-100).toString() + (now.getTime()).toString().substr(10);
                return dateString;
            }

            // Functions below for course search form //
            function add_course(course_value, course_display){
                var term_select = $("#term_select").val();
                var secs = new Date().getTime();
                var info = course_display.split(" - ");
                var course_id = course_value + sep + info[1];
                var tutorials = "";
                var tutorial_text_display = "";
                var disabled = "";
                var course_exists_text = "";
                info = course_value.split(":::");
                var section = info[3];
                if (section.indexOf("00") > 0) {
                    tutorials = section_tutorials(course_id);
                    if (tutorials) {
                        tutorial_text_display = "<br><label> (Includes section tutorials:" + tutorials +") </label>";
                        tutorials = sep + tutorials.replace(/\s+/g,"").toLowerCase();
                    }
                }
                if (course_exists(course_id)){
                    disabled = "disabled";
		    course_exists_text = "<label class=\"error_text\"><strong>This course already exists on Canvas, and cannot be added again.</strong></label>";
                }
                var checkbox_html = '<label class="checkbox"><input type="checkbox" name="selected_course_manual_'+ secs +'_'+ term_select +'" id="selected_course_manual_'+ secs +'_'+ term_select +'" value="'+ course_id + tutorials +'" '+ disabled +' >' + course_display + term_display(term_select) + course_exists_text + tutorial_text_display +'</label>';

                $("#course_search_list").append(checkbox_html);
                $('#course_search').val("");
            }

            function section_tutorials(course_id){
                var url = "/sfu/api/v1/amaint/course/"+ course_id +"/sectionTutorials";
                var tutorials;
                $.ajax({
                    type: "GET",
                    url: url,
                    async: false,
                    contentType: "application/json",
                    dataType: "json",
                    success: function (data) {
                        tutorials = data.sectionTutorials;
                    },
                    error: function (e) {
                        console.log("No section tutorials found for " + course_id);
                    }
                });
                return tutorials;
            }

            function course_exists(course_id){
                var course_info = course_id.split(":::");
                var sis_id = course_info[0] +"-"+ course_info[1] +"-"+ course_info[2] +"-"+ course_info[3];
                var url = "/sfu/api/v1/course/"+ sis_id;
                var exists = false;
                $.ajax({
                    type: "GET",
                    url: url,
                    async: false,
                    contentType: "application/json",
                    dataType: "json",
                    success: function (data) {
                        exists = true;
                    },
                    error: function (e) {
                        exists = false;
                        console.log("Course doesn't exist: " + sis_id);
                    }
                });
                return exists;
            }

            function term_display(term_code) {
                var year = Number(term_code.substr(0,3)) + Number(1900);
                var term = "";
                if (term_code.substr(3) == 1) {
                    term = "Spring";
                } else if (term_code.substr(3) == 4) {
                    term = "Summer";
                } else if (term_code.substr(3) == 7) {
                    term = "Fall";
                }
                return " ("+ term +" "+ year +")";
            }

            function term_exists(term_code) {
                var url = "/sfu/api/v1/terms/"+ term_code;
                var exists = false;
                $.ajax({
                    type: "GET",
                    url: url,
                    async: false,
                    contentType: "application/json",
                    dataType: "json",
                    success: function (data) {
                        exists = true;
                    },
                    error: function (e) {
                        exists = false;
                        console.log("Term doesn't exist: " + term_code);
                    }
                });
                return exists;
            }


        };
    });
})();
