import { renderIntoDiv } from "canvas-rce"
import canvasTheme from "instructure-ui/lib/themes/canvas"

import { getInstance, setLocale } from "./plugin"
import "tinymce/plugins/image"

getInstance(instance => instance.setConfig({ disableContrastCheck: false }))
const lang = (/lang=([^&]+)/.exec(window.location.search) || {})[1]
setLocale(lang || "en")

canvasTheme.use()

function renderEditor(editorEl, textareaId) {
  renderIntoDiv(editorEl, {
    defaultContent: document.getElementById("textarea1").value,
    editorOptions: () => {
      return {
        height: "600px",
        plugins: "link, image, textcolor, table, a11y_checker",
        menubar: true,
        toolbar: [
          "bold,italic,underline,|,link,image,|,forecolor,backcolor,|,alignleft,aligncenter,alignright,|,outdent,indent,|,bullist,numlist,|,fontsizeselect,formatselect,|,check_a11y"
        ]
      }
    },
    textareaId
  })
}

renderEditor(document.getElementById("editor1"), "textarea1")
