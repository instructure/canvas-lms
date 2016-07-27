define(['jquery', 'str/htmlEscape'], ($, htmlEscape) => {
  return function submitHtmlForm(action, method, md5) {
    $(`
      <form hidden action="${htmlEscape(action)}" method="POST">
        <input name="_method" type="hidden" value="${htmlEscape(method)}" />
        <input name="authenticity_token" type="hidden" value="${htmlEscape($.cookie('_csrf_token'))}" />
        <input name="${htmlEscape(md5 == undefined ? 'ignorethis' : 'brand_config_md5')}" value="${htmlEscape(md5 ? md5 : '')}" />
      </form>
    `).appendTo('body').submit()
  }
})