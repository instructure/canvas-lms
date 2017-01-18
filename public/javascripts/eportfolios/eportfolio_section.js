define([], function() {

  return {
    fetchContent: function($section, section_type, name){
      var data = {}
      if(section_type == "rich_text") {
        data[name + '[section_type]'] = "rich_text";
        var editorContent = $section.find(".section_content").html()
        if (editorContent){ data[name + '[content]'] = editorContent; }
      } else if(section_type == "html") {
        data[name + '[section_type]'] = "html";
        data[name + '[content]'] = $section.find(".edit_section").val();
      } else if(section_type == "submission") {
        data[name + '[section_type]'] = "submission";
        data[name + '[submission_id]'] = $section.getTemplateData({textValues: ['submission_id']}).submission_id;
      } else if(section_type == "attachment") {
        data[name + '[section_type]'] = "attachment";
        data[name + '[attachment_id]'] = $section.getTemplateData({textValues: ['attachment_id']}).attachment_id;
      }
      return data
    }
  }

})
