define ['compiled/util/processItemSelections'], (processItemSelections)->
  module "processItemSelections"
  test 'move hash of selected items to list of selected', ->
    data = {
      authenticity_token: "watup="
      'copy[all_assignments]':"1"
      'copy[all_external_tools]':"1"
      'copy[all_files]':"1"
      'copy[assignment_group_552]':"1"
      'copy[attachment_6949]':"1"
      'copy[context_external_tool_253]':"1"
      'copy[context_external_tool_254]':"0"
      'copy[course_id]':"132"
      'copy[course_settings]':"1"
      'copy[day_substitutions][0]':"0"
      'copy[everything]':"0"
      'copy[folder_1564]':"1"
      'copy[new_end_date]':""
      'copy[new_start_date]':""
      'copy[old_end_date]':"Fri Jan 27, 2012"
      'copy[old_start_date]':"Fri Jan 20, 2012"
      'copy[shift_dates]':"1"
    }

    newData = processItemSelections(data)
    deepEqual newData, {
                          "items_to_copy": [
                            "all_assignments",
                            "all_external_tools",
                            "all_files",
                            "assignment_group_552",
                            "attachment_6949",
                            "context_external_tool_253",
                            "course_settings",
                            "folder_1564",
                            "shift_dates"
                          ],
                          "authenticity_token": "watup=",
                          "copy[course_id]": "132",
                          "copy[day_substitutions][0]": "0",
                          "copy[new_end_date]": "",
                          "copy[new_start_date]": "",
                          "copy[old_end_date]": "Fri Jan 27, 2012",
                          "copy[old_start_date]": "Fri Jan 20, 2012"
                        }


