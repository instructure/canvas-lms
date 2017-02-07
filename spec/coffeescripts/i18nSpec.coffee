# note: most of these tests are now redundant w/ i18nliner-js, leaving them
# for a little bit though

define [
  "jquery"
  "i18nObj"
  "helpers/I18nStubber"
  "jquery.instructure_misc_helpers" # for $.raw
], ($, I18n, I18nStubber) ->

  scope = I18n.scoped('foo')
  t = (args...) -> scope.t(args...)

  module "I18n",
    setup: ->
      I18nStubber.pushFrame()

    teardown: ->
      I18nStubber.popFrame()

  test "missing placeholders", ->
    equal t("k", "ohai %{name}"),
      "ohai [missing %{name} value]"
    equal t("k", "ohai %{name}", name: null),
      "ohai [missing %{name} value]"
    equal t("k", "ohai %{name}", name: undefined),
      "ohai [missing %{name} value]"

  test "default locale fallback on lookup", ->
    I18nStubber.stub 'en', {foo: {fallback_message: 'this is in the en locale'}}, ->
      I18n.locale = 'bad-locale'
      equal scope.lookup('foo.fallback_message'),
        'this is in the en locale'

  test "fallbacks should only include valid ancestors", ->
    I18nStubber.stub {en: {}, fr: {}, "fr-CA": {}, "fr-FR": {}, "fr-FR-oh-la-la": {}, "zh-Hant": {}}, null, ->
      deepEqual I18n.getLocaleAndFallbacks("fr-FR-oh-la-la"),
                ["fr-FR-oh-la-la", "fr-FR", "fr", "en"]

  test "fallbacks should not include the default twice", ->
    I18nStubber.stub {en: {}, "en-GB": {}, "en-GB-x-custom": {}}, null, ->
      deepEqual I18n.getLocaleAndFallbacks("en-GB-x-custom"),
                ["en-GB-x-custom", "en-GB", "en"]

  test "html safety: should not html-escape translations or interpolations by default", ->
    equal t('bar', 'these are some tags: <input> and %{another}', {another: '<img>'}),
      'these are some tags: <input> and <img>'

  test "html safety: should html-escape translations and interpolations if any interpolated values are htmlSafe", ->
    equal t('bar', "only one of these won't get escaped: <input>, %{a}, %{b} & %{c}", {a: '<img>', b: $.raw('<br>'), c: '<hr>'}),
      'only one of these won&#39;t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'

  test "html safety: should html-escape translations and interpolations if any placeholders are flagged as safe", ->
    equal t('bar', "only one of these won't get escaped: <input>, %{a}, %h{b} & %{c}", {a: '<img>', b: '<br>', c: '<hr>'}),
      'only one of these won&#39;t get escaped: &lt;input&gt;, &lt;img&gt;, <br> &amp; &lt;hr&gt;'

  test "wrappers: should auto-html-escape", ->
    equal t('bar', '*2* > 1', {wrapper: '<b>$1</b>'}),
      '<b>2</b> &gt; 1'

  test "wrappers: should not escape already-escaped text", ->
    equal t('bar', '*%{input}* > 1', {input: $.raw('<input>'), wrapper: '<b>$1</b>'}),
      '<b><input></b> &gt; 1'

  test "wrappers: should support multiple wrappers", ->
    equal t('bar', '*1 + 1* == **2**', {wrapper: {'*': '<i>$1</i>', '**': '<b>$1</b>'}}),
      '<i>1 + 1</i> == <b>2</b>'

  test "wrappers: should replace globally", ->
    equal t('bar', '*1 + 1* == *2*', {wrapper: '<i>$1</i>'}),
      '<i>1 + 1</i> == <i>2</i>'

  test "wrappers: should interpolate placeholders in wrappers", ->
    # this functionality is primarily useful in handlebars templates where
    # wrappers are auto-generated ... in normal js you'd probably just
    # manually concatenate it into your wrapper
    equal t('bar', 'you need to *log in*', {wrapper: '<a href="%{url}">$1</a>', url: 'http://foo.bar'}),
      'you need to <a href="http://foo.bar">log in</a>'

  test "pluralize: should format the number", ->
    equal t({one: "1 thing", other: "%{count} things"}, {count: 1500}), '1,500 things'

  module 'I18n localize number',
    setup: ->
      @delimiter = ' '
      @separator = ','
      I18nStubber.pushFrame()
      I18nStubber.stub 'foo',
        number:
          format:
            delimiter: @delimiter
            separator: @separator
            precision: 3
            strip_insignificant_zeros: false
      I18nStubber.setLocale('foo')

    teardown: ->
      I18nStubber.popFrame()

  test 'uses delimiter from local', ->
    equal I18n.localizeNumber(1000), "1#{@delimiter}000"

  test 'uses separator from local', ->
    equal I18n.localizeNumber(1.2), "1#{@separator}2"

  test 'uses precision from number if not specified', ->
    equal I18n.localizeNumber(1.2345), "1#{@separator}2345"

  test 'uses precision specified', ->
    equal I18n.localizeNumber(1.2, precision: 3), "1#{@separator}200"
    equal I18n.localizeNumber(1.2345, precision: 3), "1#{@separator}234"

  test 'formats as a percentage if set to true', ->
    equal I18n.localizeNumber(1.2, percentage: true), "1#{@separator}2%"
