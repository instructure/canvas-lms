define([
  'jquery',
  'jsx/theme_editor/submitHtmlForm'
], (jQuery, submitHtmlForm) => {

  let action, method, md5, csrfToken, form

  module('submitHtmlForm', {
    setup () {
      this.spy(jQuery.fn, 'appendTo')
      this.stub(jQuery.fn, 'submit')
      action = '/foo'
      method = 'PUT'
      md5 = '0123456789abcdef0123456789abcdef'
      csrfToken = 'csrftoken'
      this.stub(jQuery, 'cookie').returns(csrfToken)
    }
  })

  function getForm() {
    submitHtmlForm(action, method, md5)
    return jQuery.fn.appendTo.firstCall.thisValue
  }

  test('sets action', () => {
    const form = getForm()
    equal(form.attr('action'), action, 'form has the right action')
  })

  test('uses post', () => {
    const form = getForm()
    equal(form.attr('method'), 'POST', 'form method is post')
  })

  test('sets _method', () => {
    const input = getForm().find('input[name=_method]')
    equal(input.val(), method, 'the _method field is set')
  })

  test('sets authenticity_token', () => {
    const input = getForm().find('input[name=authenticity_token]')
    equal(input.val(), csrfToken, 'the csrf token is set')
  })

  test('sets brand config md5 if defined', () => {
    const input = getForm().find('input[name=brand_config_md5]')
    equal(input.val(), md5, 'the md5 is set')
  })

  test('does not set brand config md5 if not defined', () => {
    md5 = undefined
    const input = getForm().find('input[name=brand_config_md5]')
    equal(input.size(), 0, 'the md5 is not set')
  })

  test('appends form to body', () => {
    submitHtmlForm(action, method, md5)
    ok(jQuery.fn.appendTo.calledWith('body'), 'appends form to body')
  })

  test('submits the form', () => {
    const form = getForm()
    ok(jQuery.fn.submit.calledOn(form), 'submits the form')
  })
})
