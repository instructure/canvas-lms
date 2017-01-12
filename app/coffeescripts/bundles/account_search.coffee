require [
  'jquery'
], ($) ->
  $('.account_search_form').submit ->
    $(this).loadingImage(horizontal: 'middle');
    $(this).find('button').prop('disabled', true)