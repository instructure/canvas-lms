# hey
require [
  'tinymce.editor_box'
], () ->
  a = document.querySelectorAll(".dynamic-syllabus-parts-editor textarea.rich-text-editor, #bz-course-intro-text-editor");
  i = 0
  while i < a.length
    $(a[i]).editorBox();
    i++
