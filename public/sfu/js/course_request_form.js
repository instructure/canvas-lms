/*jshint camelcase:false */
/*global Spinner*/

(function($) {

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
            $("#create_course_btn").toggleClass("btn btn-success");
            $("#create_course_btn").attr("value","Submitting...");
            $("#button-container").spin(spinnerOpts);
        });

        $('#course_list').on('click', 'input[type="checkbox"]', function() {
            enable_submit_crosslist();
			if (this.id.indexOf('sandbox') === -1) {
                cross_list_course_title();
			}
        });

		$('.new_course_container').on('click', '#cross_list', function() {
			cross_list_course_title();
        });

        $("#update_course_list").click(function() {
            var sfuid = $("#username").val();
            $("#enroll_me_div").hide();
            $("#course_list").html("<h5>Retrieving course list...</h5>");
            $("#course_list").spin(spinnerOpts);

            $.ajax({
              url: "/sfu/user/" + sfuid,
              dataType: "json",
              success: function(data) {
                if (data.login_id !== null && data.login_id !== undefined){
                    course_list(sfuid);
                } else {
                    $("#course_list").html("<h5>Invalid SFU Computing ID</h5>");
                }
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
       $("#enroll_me_div").hide();
       $("#course_list").html("<h5>Retrieving course list...</h5>").spin(spinnerOpts);
       course_list();
    });

    function course_list() {
        toggle_enroll_me();
        var sfuid = $("#username").val();

        $.ajax({
          url: "/sfu/terms/" + sfuid,
          dataType: "json",
          success: function(data) {
            $("#course_list").html("");

            $.each(data, function (index, term) {
                $("#course_list").append('<div id="' + term.peopleSoftCode + '"><h4>' + term.formatted1 + '</h4><div id="' + term.peopleSoftCode + '_courses"></div></div>');
                $("#"+term.peopleSoftCode+"_courses").html("<label> Retrieving courses... </label>");
                courses_for_terms(sfuid, term.peopleSoftCode);
            });
           sandbox_course(sfuid);
          },
          error: function(xhr) {
            var statusCode = xhr.status;
            if (statusCode === 404) {
                $("#course_list").html("<h5>Invalid SFU Computing ID</h5>");
            } else {
                $("#course_list").html("<h5>An unknown error occurred</h5>");
            }
          }
        })
    }

    function courses_for_terms(sfuid, term) {
        $("#" + term + "_courses").spin(spinnerOpts);
        $.ajax({
            url: "/sfu/courses/" + sfuid + "/" + term,
            dataType: 'json',
            success: function(data) {
                var num = 1;
                $("#"+term+"_courses").html("");
                $.each(data, function (index, course) {
                    var section_tutorials = course.sectionTutorials;
                    var course_display = course.name + course.number + " - " + course.section + " " + course.title;
                    if (section_tutorials) {
                        course_display += "<br><label> (Includes section tutorials: " + section_tutorials  + ") </label>";
                    }
                    var course_value = course.key;
                    var checkbox_html = '<label class="checkbox"><input type="checkbox" name="selected_course_'+ num +'_'+ term +'" id="selected_course_'+ num +'_'+ term +'" value="'+ course_value + '">' + course_display +'</label>';
                    $("#"+term+"_courses").append(checkbox_html);
                    num++;
                });
            },
            error: function() {  /* TODO: do something useful here */ }
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

    function sandbox_course(sfuid) {
        var title = "Sandbox - " + sfuid;
        $.ajax({
            url: "/sfu/sandbox/" + sfuid,
            dataType: 'json',
            success: function(data) {
                if (data.sis_source_id != "sandbox-" + sfuid + "-1:::course") {
                    $("#course_list").append("<div id='sandbox'><h4>Other</h4></div>");
                    var checkbox_html = '<label class="checkbox"><input type="checkbox" name="selected_course_sandbox" id="selected_course_sandbox" value="sandbox" onchange="enable_submit_crosslist();">'+ title +'</label>';
                    $("#sandbox").append(checkbox_html);
                }
            },
            error: function() {  /* TODO: do something useful here */ }
        });
    }

})(jQuery);