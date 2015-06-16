define([
  'i18n!accounts' /* I18n.t */,
  'jquery' /* $ */,
  'str/htmlEscape',
  'compiled/behaviors/authenticity_token',
  'jquery.ajaxJSON' /* getJSON */,
  'jqueryui/dialog'
], function(I18n, $, h, authenticity_token) {

  function testLDAP() {
    clearTestLDAP();
    $("#test_ldap_dialog").dialog({
      title: I18n.t('test_ldap_dialog_title', "Test LDAP Settings"),
      width: 600
    });
    ENV.LDAP_TESTS[0].js_function();
  }
  function clearTestLDAP() {
    $.each(ENV.LDAP_TESTS, function(i, test) {
      $("#ldap_" + test.test_type + "_result").html("");
      $("#ldap_" + test.test_type + "_help .server_error").remove();
      $("#ldap_" + test.test_type + "_help").hide();
    });
    $("#ldap_login_result").html("");
    $("#ldap_login_form").hide();
  }
  $.each(ENV.LDAP_TESTS, function(i, test) {
    test.js_function = function() {
      $("#ldap_" + test.test_type + "_result").html("<img src='/images/ajax-loader.gif'/>");
      $.getJSON(test.url, function(data) {
        var success = true;
        var server_error = "";
        $.each(data, function(i, config) {
          if (!config['ldap_' + test.test_type + '_test']) {
            success = false;
            if(config['errors'][0] && config['errors'][0]['ldap_' + test.test_type + '_test']) {
              server_error = config['errors'][0]['ldap_' + test.test_type + '_test'];
            }
          }
        });
        if (success) {
          $("#ldap_" + test.test_type + "_result").html("<h4 style='color:green'>" + h(I18n.t('test_ldap_result_ok', 'OK')) + "</h4>");
          if (ENV.LDAP_TESTS[i+1]) {
            // proceed to the next test
            ENV.LDAP_TESTS[i+1].js_function();
          } else {
            // show login test tool
            $("#ldap_login_form").show('blind');
          }
        } else {
          $("#ldap_" + test.test_type + "_result").html("<h4 style='color:red'>" + h(I18n.t('test_ldap_result_failed', 'Failed')) + "</h4>");
          $("#ldap_" + test.test_type + "_help").show();
          $server_error = $('<p></p>').addClass("server_error").css("color", "red").text(server_error);
          $("#ldap_" + test.test_type + "_help").append($server_error);

          $.each(ENV.LDAP_TESTS.slice(i + 1), function(i, next_test) {
            $("#ldap_" + next_test.test_type + "_result").html("<h4 style='color:red'>" + h(I18n.t('test_ldap_result_canceled', 'Canceled')) + "</h4>");
          });
          $("#ldap_login_result").html("<h4 style='color:red'>" + h(I18n.t('test_ldap_result_canceled', 'Canceled')) + "</h4>");
        }
      });
    }
  });
  function testLDAPLogin() {
    $("#ldap_test_login").attr('disabled', 'true').attr('value', I18n.t('testing', 'Testing...'));
    $("#ldap_login_result").html("<img src='/images/ajax-loader.gif'/>");
    var username = $("#ldap_test_login_user").val();
    var password = $("#ldap_test_login_pass").val();
    $.post(ENV.LOGIN_TEST_URL, {'username': username, 'password': password, authenticity_token: authenticity_token()}, function(data) {
      var success = true;
      var message = "";
      $.each(data, function(i, config) {
        if (!config['ldap_login_test']) {
          success = false;
        }
        if (config['errors']) {
          $.each(config['errors'], function(i, m) {
            $.each(m, function(err, msg) {
              message += msg;
            })
          });
        }
      });
      if (success) {
        $("#ldap_login_help_error").hide();
        $("#ldap_login_result").html("<h4 style='color:green'>" + h(I18n.t('test_ldap_result_ok', 'OK')) + "</h4>");
        $("#ldap_test_login").attr('disabled', '').attr('value', I18n.t('test_login', 'Test Login'));
      } else {
        $("#ldap_login_result").html("<h4 style='color:red'>" + h(I18n.t('test_ldap_result_failed', 'Failed')) + "</h4>");
        $("#ldap_login_help").show();
        $("#ldap_test_login").attr('disabled', '').attr('value', I18n.t('retry_login', 'Retry Login'));
        $("#ldap_login_help_error").text(message);
      }
    });
  }

  $(document).ready(function() {
    $(".test_ldap_link").click(function(event) {
      event.preventDefault();
      // kick off our test
      testLDAP();
    });
    $(".ldap_test_close").click(function(event) {
      event.preventDefault();
      $("#test_ldap_dialog").dialog('close')
    });
    $("#ldap_test_login_form").submit(function(event) {
      event.preventDefault();
      testLDAPLogin();
    });
  });
});

