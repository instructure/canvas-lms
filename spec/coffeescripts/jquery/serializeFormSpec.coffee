define [
  'jquery'
  'compiled/jquery/serializeForm'
], ($) ->
  $sampleForm = $('''
    <form>
      Radio
      <input type="radio" value="group_val_1" name="radio_group" checked />
      <input type="radio" value="group_val_2" name="radio_group" />

      Checked checkbox
      <input type="checkbox" value="checkbox1" name="checkbox[1]" checked />

      Unchecked checkbox
      <input type="checkbox" value="checkbox2" name="checkbox[2]" />

      Unchecked checkbox with hidden field (a la rails and handlebars helper)
      <input type="hidden" value="0" name="checkbox[3]" />
      <input type="checkbox" value="1" name="checkbox[3]" />

      Text field
      <input type="text" value="asdf" name="text" />

      Disabled field
      <input type="text" value="qwerty" name="text2" disabled />

      Textarea
      <textarea name="textarea">hello\nworld</textarea>

      Select
      <select name="select"><option>1</option><option selected>2</option></select>

      Multi-select
      <select name="multiselect" multiple>
        <option>1</option>
        <option selected>2</option>
        <option selected>3</option>
      </select>
    </form>
  ''')

  QUnit.module "SerializeForm"

  test "Serializes valid input items correctly", ->
    serialized = $sampleForm.serializeForm()
    deepEqual serialized, [
      {name: "radio_group", value: "group_val_1"}
      {name: "checkbox[1]", value: "checkbox1"}
      {name: "checkbox[3]", value: "0"}
      {name: "text", value: "asdf"}
      {name: "textarea", value: "hello\r\nworld"}
      {name: "select", value: "2"}
      {name: "multiselect", value: "2"}
      {name: "multiselect", value: "3"}
    ]

