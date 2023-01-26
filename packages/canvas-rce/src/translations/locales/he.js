/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import formatMessage from '../../format-message'
import '../tinymce/he_IL'

const locale = {
  "add_8523c19b": { "message": "הוספה" },
  "all_4321c3a1": { "message": "כל" },
  "alpha_15d59033": { "message": "אלפא" },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "אירעה שגיאה ביצירת בקשת רשת"
  },
  "announcement_list_da155734": { "message": "רשימת הכרזות" },
  "announcements_a4b8ed4a": { "message": "הכרזות" },
  "apply_781a2546": { "message": "החל" },
  "apps_54d24a47": { "message": "אפליקציות" },
  "arrows_464a3e54": { "message": "חצים" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": { "message": "יחס הממדים יישמר" },
  "assignments_1e02582c": { "message": "משימות" },
  "attributes_963ba262": { "message": "מאפיינים" },
  "basic_554cdc0a": { "message": "בסיסי" },
  "blue_daf8fea9": { "message": "כחול" },
  "bottom_15a2a9be": { "message": "תחתית" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "ביטול" },
  "choose_usage_rights_33683854": { "message": "בחירה של זכויות שימוש..." },
  "clear_2084585f": { "message": "ניקוי" },
  "click_to_embed_imagename_c41ea8df": {
    "message": "הקש/י כדי לשלב { imageName }"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "הקלקה להוספת קישור לתוך עורך התוכן"
  },
  "close_d634289d": { "message": "סגירה" },
  "collaborations_5c56c15f": { "message": "שיתופי פעולה" },
  "content_1440204b": { "message": "תוכן" },
  "content_type_2cf90d95": { "message": "סוג תוכן" },
  "copyright_holder_66ee111": { "message": "בעלים של זכויות יוצרים:" },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n    two {}\n   many {}\n  other {}\n}"
  },
  "course_files_62deb8f8": { "message": "קובצי קורס" },
  "course_files_a31f97fc": { "message": "קבצי קורס" },
  "course_navigation_dd035109": { "message": "ניווט בקורס" },
  "creative_commons_license_725584ae": {
    "message": "זכויות במסגרת Creative Commons"
  },
  "custom_6979cd81": { "message": "ידני" },
  "cyan_c1d5f68a": { "message": "ירקרק-כחול" },
  "deep_purple_bb3e2907": { "message": "סגול כהה" },
  "delimiters_4db4840d": { "message": "מפסקים" },
  "details_98a31b68": { "message": "פרטים" },
  "dimensions_45ddb7b7": { "message": "ממדים" },
  "discussions_a5f96392": { "message": "דיונים " },
  "discussions_index_6c36ced": { "message": "אינדקס דיונים" },
  "done_54e3d4b6": { "message": "בוצע" },
  "due_multiple_dates_cc0ee3f5": { "message": "יעד: תאריכים מרובים" },
  "edit_c5fbea07": { "message": "עריכה" },
  "embed_image_1080badc": { "message": "הטמעת תמונה" },
  "external_tools_6e77821": { "message": "כלים חיצוניים" },
  "files_c300e900": { "message": "קבצים " },
  "files_index_af7c662b": { "message": "אינדקס קבצים" },
  "format_4247a9c5": { "message": "פורמט" },
  "generating_preview_45b53be0": { "message": "מכין תצוגה מקדימה..." },
  "grades_a61eba0a": { "message": "הערכות" },
  "greek_65c5b3f7": { "message": "יוונית" },
  "green_15af4778": { "message": "ירוק" },
  "group_files_82e5dcdb": { "message": "קבצי קבוצה" },
  "group_navigation_99f191a": { "message": "ניווט בקבוצה" },
  "home_351838cd": { "message": "דף הבית" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "קיבלתי הרשאות להשתמש בקובץ זה"
  },
  "i_hold_the_copyright_71ee91b1": { "message": "זכויות היוצרים הן שלי" },
  "icon_215a1dc6": { "message": "צלמית" },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "אם לא תבחר/י את סוג זכויות השימוש כעת, קובץ זה לא יפורסם בתום העלאתו"
  },
  "image_8ad06": { "message": "תמונה" },
  "images_7ce26570": { "message": "תמונות" },
  "indigo_2035fc55": { "message": "אינדיגו" },
  "insert_593145ef": { "message": "הוספה" },
  "insert_link_6dc23cae": { "message": "הוספת קישור" },
  "invalid_file_type_881cc9b2": { "message": "סוג קובץ לא חוקי" },
  "invalid_url_cbde79f": { "message": "כתובת דף אינטרנט לא תקינה" },
  "keyboard_shortcuts_ed1844bd": { "message": "קיצורי מקלדת" },
  "light_blue_5374f600": { "message": "כחול בהיר" },
  "link_7262adec": { "message": "קישור" },
  "links_14b70841": { "message": "קישורים" },
  "links_to_an_external_site_de74145d": { "message": "קישורים לאתר חיצוני" },
  "loading_25990131": { "message": "בטעינה... " },
  "loading_bde52856": { "message": "טוען" },
  "loading_failed_b3524381": { "message": "טעינה נכשלה..." },
  "locked_762f138b": { "message": "נעול" },
  "media_af190855": { "message": "מדיה" },
  "minimize_file_preview_da911944": {
    "message": "מיזעור חלון תצוגה מקדימה של קובץ"
  },
  "minimize_video_20aa554b": { "message": "מיזעור וידאו" },
  "misc_3b692ea7": { "message": "אחר" },
  "modules_c4325335": { "message": "מודולים" },
  "my_files_2f621040": { "message": "הקבצים שלי" },
  "name_1aed4a1b": { "message": "שם" },
  "no_e16d9132": { "message": "לא" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "אין תצוגה מקדימה לקובץ זה"
  },
  "no_results_940393cf": { "message": "אין תוצאות" },
  "none_3b5e34d2": { "message": "אף אחד" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "פתיחת חלון דיאלוג של מקשי קיצור"
  },
  "operators_a2ef9a93": { "message": "מפעילים" },
  "orange_81386a62": { "message": "כתום" },
  "pages_e5414c2c": { "message": "דפים" },
  "people_b4ebb13c": { "message": "אנשים " },
  "percentage_34ab7c2c": { "message": "אחוז" },
  "pink_68ad45cb": { "message": "ורוד" },
  "preview_53003fd2": { "message": "תצוגה מקדימה" },
  "published_c944a23d": { "message": "פורסם" },
  "purple_7678a9fc": { "message": "סגול" },
  "quizzes_7e598f57": { "message": "בחנים" },
  "record_7c9448b": { "message": "הקלטה" },
  "red_8258edf3": { "message": "אדום" },
  "relationships_6602af70": { "message": "יחסים" },
  "replace_e61834a7": { "message": "החלפה" },
  "reset_95a81614": { "message": "חזרה למצב ברירת מחדל" },
  "rich_content_editor_2708ef21": { "message": "עורך תוכן עשיר" },
  "save_11a80ec3": { "message": "שמירה " },
  "search_280d00bd": { "message": "חיפוש" },
  "size_b30e1077": { "message": "גודל" },
  "star_8d156e09": { "message": "הוספת כוכבית" },
  "submit_a3cc6859": { "message": "הגשה" },
  "syllabus_f191f65b": { "message": "תכנית לימודים" },
  "teal_f729a294": { "message": "ירוק-כחלחל" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "התצוגה המוקדמת של מסמך זה מעובדת כעת. יש לנסות מאוחר יותר"
  },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "החומר הנו ברשות הציבור"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "זכויות היוצרים של החומר במסגרת כללי נחלת הכלל - Creative Commons"
  },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "מסמך זה לא ניתן להצגה בתוך קנבס."
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "נוסחה זו לא ניתנת להצגה בתצוגה בסיסית"
  },
  "title_ee03d132": { "message": "כותרת" },
  "unpublished_dfd8801": { "message": "לא פורסם" },
  "upload_file_fd2361b8": { "message": "העלאת קובץ" },
  "upload_media_ce31135a": { "message": "העלאת מדיה" },
  "uploading_19e8a4e7": { "message": "מעלה" },
  "url_22a5f3b8": { "message": "כתובת דף אינטרנט" },
  "usage_right_ff96f3e2": { "message": "זכויות שימוש" },
  "view_ba339f93": { "message": "תצוגה" },
  "white_87fa64fd": { "message": "לבן" },
  "wiki_home_9cd54d0": { "message": "דף הבית של וויקי" },
  "yes_dde87d5": { "message": "כן" },
  "zoom_f3e54d69": { "message": "תקריב" }
}


formatMessage.addLocale({he: locale})
