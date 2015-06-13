define ['compiled/util/processMigrationItemSelections'], (processMigrationItemSelections)->
  module "processMigrationItemSelections"
  data = {
            "authenticity_token": "QL/bXYKYG65JrbPhnzd5XXwNMmRw2kbsl+j02gY3Quc=",
            "copy[content_migration_id]": "219",
            "copy[everything]": "0",
            "copy[all_assignments]": "0",
            "copy[assignments][id]": "1",
            "copy[all_quizzes]": "0",
            "copy[quizzes][id]": "1",
            "copy[quizzes][res00026]": "1",
            "copy[quizzes][res00027]": "1",
            "copy[quizzes][res00028]": "0",
            "copy[assessment_questions]": "1",
            "copy[all_files]": "1",
            "copy[folders][id]": "0",
            "copy[files][id]": "0",
            "copy[all_modules]": "1",
            "copy[modules][id]": "1",
            "copy[all_outline_folders]": "0",
            "copy[outline_folders][id]": "1",
            "copy[outline_folders][toc00001]": "0",
            "copy[outline_folders][res00006]": "1",
            "copy[outline_folders][res00008]": "1",
            "copy[all_topics]": "1",
            "copy[topics][id]": "1",
            "copy[all_announcements]": "1",
            "copy[all_calendar_events]": "1",
            "copy[all_rubrics]": "1",
            "copy[all_groups]": "1",
            "copy[groups][id]": "1",
            "copy[all_assignment_groups]": "0",
            "copy[assignment_groups][id]": "1",
            "copy[all_wikis]": "0",
            "copy[wikis][id]": "1",
            "copy[all_external_tools]": "0",
            "copy[external_tools][id]": "1",
            "copy[shift_dates]": "1",
            "copy[old_start_date]": "Nov 6, 2009",
            "copy[old_end_date]": "Nov 6, 2009",
            "copy[new_start_date]": "",
            "copy[new_end_date]": "",
            "copy[day_substitutions][0]" : "1",
            "copy[day_substitutions][3]" : "4"
    }

  test 'change hash of hashes to hash of lists', ->
    newData = processMigrationItemSelections(data)
    deepEqual newData, {
                        "items_to_copy":{
                          "assignments": ["id"],
                          "quizzes": ["id","res00026","res00027"],
                          "outline_folders": ["id","res00006","res00008"],
                          "assignment_groups": ["id"],
                          "wikis": ["id"],
                          "external_tools": ["id"]
                          },
                        "authenticity_token": "QL/bXYKYG65JrbPhnzd5XXwNMmRw2kbsl+j02gY3Quc=",
                        "copy[content_migration_id]": "219",
                        "copy[everything]": "0",
                        "copy[all_assignments]": "0",
                        "copy[all_quizzes]": "0",
                        "copy[assessment_questions]": "1",
                        "copy[all_files]": "1",
                        "copy[all_modules]": "1",
                        "copy[all_outline_folders]": "0",
                        "copy[all_topics]": "1",
                        "copy[all_announcements]": "1",
                        "copy[all_calendar_events]": "1",
                        "copy[all_rubrics]": "1",
                        "copy[all_groups]": "1",
                        "copy[all_assignment_groups]": "0",
                        "copy[all_wikis]": "0",
                        "copy[all_external_tools]": "0",
                        "copy[shift_dates]": "1",
                        "copy[old_start_date]": "Nov 6, 2009",
                        "copy[old_end_date]": "Nov 6, 2009",
                        "copy[new_start_date]": "",
                        "copy[new_end_date]": "",
                        "copy[day_substitutions][0]" : "1",
                        "copy[day_substitutions][3]" : "4"
    }

  test 'remove individual selections if copy everything is selected', ->
    data['copy[everything]'] = "1"
    newData = processMigrationItemSelections(data)
    deepEqual newData, {
                        "items_to_copy": {},
                        "authenticity_token": "QL/bXYKYG65JrbPhnzd5XXwNMmRw2kbsl+j02gY3Quc=",
                        "copy[content_migration_id]": "219",
                        "copy[everything]": "1",
                        "copy[assessment_questions]": "1",
                        "copy[shift_dates]": "1",
                        "copy[old_start_date]": "Nov 6, 2009",
                        "copy[old_end_date]": "Nov 6, 2009",
                        "copy[new_start_date]": "",
                        "copy[new_end_date]": "",
                        "copy[day_substitutions][0]" : "1",
                        "copy[day_substitutions][3]" : "4"
    }


