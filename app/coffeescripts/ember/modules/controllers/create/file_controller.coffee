define [
  './base_controller'
  'i18n!create_module_item_quiz'
  '../../models/item'
  'ic-ajax'
], (Base, I18n, Item, {request}) ->

  CreateFileController = Base.extend

    text:
      file: I18n.t('file_to_upload', 'File to upload')

    createItem: ->
      file = @get('files')[0]
      item = Item.createRecord(title: file.name, type: 'File')
      fileData = name: file.name, size: file.size, content_type: file.type
      request(
        url: "/api/v1/courses/#{ENV.course_id}/files"
        type: 'post'
        data: fileData
      ).then((({upload_params, upload_url}) =>
        formData = new FormData
        xhr = new XMLHttpRequest
        formData.append(key, val) for key, val of upload_params
        formData.append('file', file)
        xhr.open 'POST', upload_url, true
        xhr.onload = (event) =>
          # TODO: ember run stuff in here for testing
          if event.target.status isnt 200
            return @handleContentError(item)
          response = $.parseJSON(event.target.response)
          item.set('content_id', response.id)
          item.save()
        xhr.send formData
      ), (=>
        @handleContentError(item)
      ))
      item

