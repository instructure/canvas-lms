define [
  'jquery'
  'underscore'
  'compiled/jquery/serializeForm'
], ($, _) ->
  $sampleForm = $('<form></form>')
                .append('<input type="radio" value="val1" name=radio[1] />')
                .append('<input type="radio" value="val2" name=radio[2] />')
                .append('<input type="radio" value="val3" name=radio[3] />')
                .append('<input type="radio" value="group_val_1" name="radio_group" id="rg1" />')
                .append('<input type="radio" value="group_val_2" name="radio_group" id="rg2" />')
                .append('<input type="radio" value="group_val_3" name="radio_group" id="rg3" />')
                .append('<input type="checkbox" value="checkbox1" name="checkbox[1]" />')
                .append('<input type="checkbox" value="checkbox2" name="checkbox[2]" />')
                .append('<input type="button" value="button" />')

  module "SerializeForm: without serialize-radio-value",
    setup: ->
      $sampleForm.find('[name="radio[1]"]').prop('checked', true)
    teardown: ->
      $sampleForm.find('[name="radio[1]"]').prop('checked', false)

  test "Radio button values should be booleans", ->
    serialized = $sampleForm.serializeForm()
    radio1 = _.find serialized, (input) -> input.name == "radio[1]"
    ok radio1.value, "Selected radio value should be true"

  test "Serializes all input items", ->
    serialized = $sampleForm.serializeForm()
    ok serialized.length == 8, "There are 8 input elements serialized"

  module "SerializeForm: with serialize-radio-value",
    setup: ->
      $sampleForm.attr('serialize-radio-value', '')
    teardown: ->
      $sampleForm.removeAttr('serialize-radio-value')

  test "Doesnt serialize radio buttons that arent selected", ->
    serialized = $sampleForm.serializeForm()

    radios = _.filter serialized, (input) -> 
      input.name == "radio[1]" ||
      input.name == "radio[2]" ||
      input.name == "radio[3]"

    ok radios.length == 0, "No radio selected"

  test "Sends the true value of radio buttons that are selected", ->
    $sampleForm.find('[name="radio[1]"]').prop('checked', true)
    serialized = $sampleForm.serializeForm()
    radio1 = _.find serialized, (input) -> input.name == "radio[1]"
    equal radio1.value, "val1", "Serializes the true value of radio buttons"
    $sampleForm.find('[name="radio[1]"]').prop('checked', false)

  test "Serializes true radio button values of a selected group", ->
    $sampleForm.find('#rg2').prop('checked', true)

    serialized = $sampleForm.serializeForm()
    radio2 = _.find serialized, (input) -> input.name == "radio_group"
    equal radio2.value, "group_val_2", "Serializes the true value of radio buttons"

    $sampleForm.find('#rg2').prop('checked', false)

