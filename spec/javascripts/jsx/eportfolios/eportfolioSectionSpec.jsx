define([
  'jquery',
  'eportfolios/eportfolio_section',
  'helpers/fixtures'
  ], ($, EportfolioSection, fixtures) => {
  var $section = null

  QUnit.module("EportfolioSection -> fetchContent", {
    setup() {
      fixtures.setup()
      $section = fixtures.create(
        "<div id='eportfolio_section'>"     +
        "  <div class='section_content'>"   +
        "    <p>Some Editor Content</p>"    +
        "  </div>"                          +
        "  <textarea class='edit_section'>" +
        "    Some HTML Content"             +
        "  </textarea>"                     +
        "</div>"
      )
    },

    teardown() {
      fixtures.teardown()
    }
  });

  test('grabs section content for rich_text type', ()=>{
    var content = EportfolioSection.fetchContent($section, 'rich_text', 'section1')
    equal(content['section1[section_type]'], 'rich_text')
    equal(content['section1[content]'].trim(), '<p>Some Editor Content</p>')
  })

  test("uses edit field value for html type", ()=>{
    var content = EportfolioSection.fetchContent($section, 'html', 'section1')
    equal(content['section1[section_type]'], 'html')
    equal(content['section1[content]'].trim(), 'Some HTML Content')
  })

});
