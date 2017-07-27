const rce = require('canvas-rce')
const canvasTheme = require('instructure-ui/lib/themes/canvas').default
require('./plugin')
require('tinymce/plugins/image')

canvasTheme.use()

function renderEditor(editorEl, textareaId) {
  rce.renderIntoDiv(editorEl, {
    defaultContent: document.getElementById('textarea1').value,
    editorOptions: () => {
      return {
        height: '600px',
        plugins: "link, image, textcolor, table, a11y_checker",
        menubar: true,
        toolbar: [
          "bold,italic,underline,|,link,image,|,forecolor,backcolor,|,alignleft,aligncenter,alignright,|,outdent,indent,|,bullist,numlist,|,fontsizeselect,formatselect,|,check_a11y",
        ]
      }
    },
    textareaId
  })
}

renderEditor(document.getElementById('editor1'), 'textarea1')