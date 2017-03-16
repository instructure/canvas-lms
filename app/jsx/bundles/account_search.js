import $ from 'jquery'

$('.account_search_form').submit(function () {
  $(this).loadingImage({horizontal: 'middle'})
  $(this).find('button').prop('disabled', true)
})

