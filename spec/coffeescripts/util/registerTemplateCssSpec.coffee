define [
  'jquery'
  'compiled/util/registerTemplateCss'
], ($, registerTemplateCss) ->
  
  testColor = 'rgb(255, 0, 0)'
  testRule = "body {color:#{testColor};}"
  testTemplateId = templateId = 'test_template_id'

  module 'registerTemplateCss'
  test 'should render correctly', ->
    registerTemplateCss testTemplateId, testRule
    equal $('body').css('color'), testColor

  test 'should append <style> node to bottom of <head>', ->
    registerTemplateCss testTemplateId, testRule
    equal $('head style:last').text(), "/* From: #{testTemplateId} */\n#{testRule}"

  test 'should remove all styles when you call clear()', ->
    registerTemplateCss testTemplateId, testRule
    registerTemplateCss.clear()
    equal $('head style:last').text(), ''
    ok $('body').css('color') != testColor
