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
import '../tinymce/fa_IR'

const locale = {
  "add_8523c19b": { "message": "افزودن" },
  "add_one_9e34a6f8": { "message": "افزودن یک مورد!" },
  "additional_considerations_f3801683": { "message": "ملاحظات اضافی" },
  "all_4321c3a1": { "message": "همه" },
  "alpha_15d59033": { "message": "آلفا" },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "برای یک  درخواست شبکه خطا رخ داده است"
  },
  "and_7fcc2911": { "message": "و " },
  "announcement_fb4cb645": { "message": "اطلاعیه" },
  "announcement_list_da155734": { "message": "فهرست اطلاعیه" },
  "announcements_a4b8ed4a": { "message": "اطلاعیه ها" },
  "apply_781a2546": { "message": "اعمال" },
  "apps_54d24a47": { "message": "برنامه ها" },
  "are_you_sure_you_want_to_cancel_changes_you_made_m_c5210496": {
    "message": "آیا مطمئن هستید که می خواهید لغو شود؟ تغییرات انجام شده ممکن است ذخیره نشوند."
  },
  "arrows_464a3e54": { "message": "پیکان ها" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "نسبت ابعاد حفظ خواهد شد"
  },
  "assignment_976578a8": { "message": "تکلیف" },
  "assignments_1e02582c": { "message": "تکلیف ها" },
  "attributes_963ba262": { "message": "ویژگی ها" },
  "available_folders_694d0436": { "message": "پوشه های موجود" },
  "basic_554cdc0a": { "message": "اصلی" },
  "beta_cb5f307e": { "message": "بتا" },
  "blue_daf8fea9": { "message": "آبی" },
  "bottom_15a2a9be": { "message": "پایین" },
  "brick_f2656265": { "message": "آجر" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "لغو" },
  "changes_you_made_may_not_be_saved_4e8db973": {
    "message": "تغییرات انجام شده ممکن است ذخیره نشوند."
  },
  "characters_9d897d1c": { "message": "نویسه ها" },
  "choose_usage_rights_33683854": { "message": "انتخاب حقوق استفاده..." },
  "clear_2084585f": { "message": "پاک کردن" },
  "clear_selected_file_82388e50": { "message": "پاک کردن فایل انتخاب شده" },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Click to embed { imageName }"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Click to insert a link into the editor."
  },
  "close_d634289d": { "message": "بستن" },
  "collaborations_5c56c15f": { "message": "همکاری ها" },
  "computer_1d7dfa6f": { "message": "کامپیوتر" },
  "content_1440204b": { "message": "محتوا" },
  "content_type_2cf90d95": { "message": "نوع محتوا" },
  "copyright_holder_66ee111": { "message": "دارنده حق نشر:" },
  "count_40eced3b": { "message": "تعداد" },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n  other {}\n}"
  },
  "course_files_62deb8f8": { "message": "فایل های درس" },
  "course_files_a31f97fc": { "message": "فایل های درس" },
  "course_navigation_dd035109": { "message": "پیمایش درس" },
  "creative_commons_license_725584ae": { "message": "مجوز کریتیو کامنز:" },
  "current_volume_level_c55ab825": { "message": "سطح حجم فعلی" },
  "custom_6979cd81": { "message": "سفارشی" },
  "cyan_c1d5f68a": { "message": "آبی تیره" },
  "decrease_indent_d9cf469d": { "message": "کاهش تورفتگی" },
  "deep_purple_bb3e2907": { "message": "ارغوانی پر رنگ" },
  "delimiters_4db4840d": { "message": "جداکننده ها" },
  "description_436c48d7": { "message": "شرح" },
  "details_98a31b68": { "message": "اطلاعات" },
  "dimensions_45ddb7b7": { "message": "ابعاد" },
  "discussion_6719c51d": { "message": "بحث" },
  "discussions_a5f96392": { "message": "بحث ها" },
  "discussions_index_6c36ced": { "message": "فهرست بحث ها" },
  "done_54e3d4b6": { "message": "انجام شد" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "بکشید و رها کنید، یا برای مرور رایانه کلیک کنید"
  },
  "due_multiple_dates_cc0ee3f5": { "message": "مهلت: چند تاریخ" },
  "edit_c5fbea07": { "message": "ویرایش" },
  "embed_828fac4a": { "message": "قراردادن" },
  "embed_content_from_external_tool_3397ad2d": {
    "message": "درج محتوا از ابزار بیرونی"
  },
  "embed_image_1080badc": { "message": "درج تصویر" },
  "external_tools_6e77821": { "message": "ابزارهای بیرونی" },
  "file_name_8fd421ff": { "message": "نام فایل" },
  "files_c300e900": { "message": "فایل ها" },
  "files_index_af7c662b": { "message": "فهرست فایل ها" },
  "find_8d605019": { "message": "یافتن" },
  "finish_bc343002": { "message": "پایان" },
  "folder_tree_fbab0726": { "message": "درخت پوشه" },
  "format_4247a9c5": { "message": "قالب" },
  "generating_preview_45b53be0": { "message": "در حال ایجاد پیش نمایش..." },
  "grades_a61eba0a": { "message": "نمره ها" },
  "greek_65c5b3f7": { "message": "یونانی" },
  "green_15af4778": { "message": "سبز" },
  "group_files_4324f3df": { "message": "فایل های گروهی" },
  "group_files_82e5dcdb": { "message": "فایل های گروه" },
  "group_navigation_99f191a": { "message": "پیمایش گروه" },
  "home_351838cd": { "message": "صفحه اصلی" },
  "html_editor_fb2ab713": { "message": "ویرایشگر HTML" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "مجوز استفاده از این فایل را به دست آورده ام."
  },
  "i_hold_the_copyright_71ee91b1": { "message": "حق نشر دارم" },
  "icon_215a1dc6": { "message": "نماد" },
  "icon_maker_icons_cc560f7e": { "message": "نمادهای سازنده آیکون" },
  "image_8ad06": { "message": "تصویر" },
  "image_c1c98202": { "message": "تصویر" },
  "images_7ce26570": { "message": "تصاویر" },
  "increase_indent_6af90f7c": { "message": "افزایش تورفتگی" },
  "indigo_2035fc55": { "message": "Indigo" },
  "insert_593145ef": { "message": "درج" },
  "insert_link_6dc23cae": { "message": "درج پیوند" },
  "insert_math_equation_57c6e767": { "message": "درج معادله ریاضی" },
  "invalid_file_type_881cc9b2": { "message": "نوع فایل معتبر نیست" },
  "invalid_url_cbde79f": { "message": "نشانی اینترنتی معتبر نیست" },
  "keyboard_shortcuts_ed1844bd": { "message": "میانبرهای صفحه کلید" },
  "light_blue_5374f600": { "message": "آبی روشن" },
  "link_7262adec": { "message": "پیوند" },
  "links_14b70841": { "message": "پیوندها" },
  "links_to_an_external_site_de74145d": {
    "message": "به یک تارنمای بیرونی پیوند می شود."
  },
  "loading_25990131": { "message": "در حال بارگذاری..." },
  "loading_bde52856": { "message": "در حال بارگذاری" },
  "loading_external_tool_d839042c": { "message": "بارگذاری ابزار خارجی" },
  "loading_failed_b3524381": { "message": "Loading failed..." },
  "loading_folders_d8b5869e": { "message": "بارگیری پوشه ها" },
  "locked_762f138b": { "message": "قفل شده" },
  "magenta_4a65993c": { "message": "ارغوانی" },
  "media_af190855": { "message": "رسانه" },
  "mic_a7f3d311": { "message": "میکروفون" },
  "minimize_file_preview_da911944": { "message": "کمینه کردن پیش نمایش فایل" },
  "minimize_video_20aa554b": { "message": "کمینه کردن تصویر" },
  "misc_3b692ea7": { "message": "متفرقه" },
  "module_90d9fd32": { "message": "ماژول" },
  "modules_c4325335": { "message": "ماژول ها" },
  "my_files_2f621040": { "message": "فایل های من" },
  "name_1aed4a1b": { "message": "نام" },
  "navigation_ee9af92d": { "message": "پیمایش" },
  "new_quiz_34aacba6": { "message": "آزمون جدید" },
  "next_40e12421": { "message": "بعدی" },
  "no_e16d9132": { "message": "خیر" },
  "no_pages_created_yet_c379fa6e": {
    "message": "هنوز هیچ صفحه ای ایجاد نشده است"
  },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "هیچ پیش نمایشی برای این فایل موجود نیست."
  },
  "no_results_940393cf": { "message": "No results." },
  "no_results_found_58717065": { "message": "نتیجه ای یافت نشد" },
  "no_video_1ed00b26": { "message": "بدون تصویر" },
  "none_3b5e34d2": { "message": "هیچ کدام" },
  "olive_6a3e4d6b": { "message": "زیتون" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "باز کردن این کادر گفتکوی میانبرهای صفحه کلید"
  },
  "operators_a2ef9a93": { "message": "عملگرها" },
  "or_9b70ccaa": { "message": "یا" },
  "orange_81386a62": { "message": "نارنجی" },
  "page_50c4823d": { "message": "صفحه" },
  "pages_e5414c2c": { "message": "صفحه ها" },
  "pause_12af3bb4": { "message": "مکث" },
  "people_b4ebb13c": { "message": "افراد" },
  "percentage_34ab7c2c": { "message": "درصد" },
  "pink_68ad45cb": { "message": "صورتی" },
  "play_1a47eaa7": { "message": "نمایش" },
  "play_media_comment_35257210": { "message": "پخش نظر رسانه ای" },
  "please_allow_canvas_to_access_your_microphone_and__dc2c3079": {
    "message": "لطفاً به Canvas اجازه دهید تا به میکروفون و وب کم شما دسترسی پیدا کند."
  },
  "prev_f82cbc48": { "message": "قبلی" },
  "preview_53003fd2": { "message": "پیش‌نمایش" },
  "preview_a3f8f854": { "message": "پیش نمایش" },
  "previous_bd2ac015": { "message": "Previous" },
  "published_c944a23d": { "message": "منتشر شده" },
  "pumpkin_904428d5": { "message": "کدوتنبل" },
  "purple_7678a9fc": { "message": "ارغوانی" },
  "quiz_e0dcce8f": { "message": "آزمون" },
  "quizzes_7e598f57": { "message": "آزمون ها" },
  "record_7c9448b": { "message": "ضبط کردن" },
  "recording_98da6bda": { "message": "در حال ضبط" },
  "red_8258edf3": { "message": "قرمز" },
  "relationships_6602af70": { "message": "روابط" },
  "replace_e61834a7": { "message": "جایگزین کردن" },
  "reset_95a81614": { "message": "بازنشانی" },
  "rich_content_editor_2708ef21": { "message": "ویرایشگر محتوای غنی" },
  "save_11a80ec3": { "message": "ذخیره سازی" },
  "search_280d00bd": { "message": "جستجو" },
  "select_language_7c93a900": { "message": "انتخاب زبان" },
  "selected_274ce24f": { "message": "انتخاب شده" },
  "size_b30e1077": { "message": "اندازه" },
  "something_went_wrong_89195131": { "message": "اشکالی رخ داده است." },
  "something_went_wrong_d238c551": { "message": "مشکلی پیش آمد" },
  "sort_by_e75f9e3e": { "message": "مرتب کردن بر اساس" },
  "star_8d156e09": { "message": "ستاره دار کردن" },
  "start_over_f7552aa9": { "message": "شروع دوباره" },
  "start_recording_9a65141a": { "message": "شروع ضبط" },
  "submit_a3cc6859": { "message": "ارسال" },
  "syllabus_f191f65b": { "message": "سرفصل" },
  "teal_f729a294": { "message": "سبز مایل به آبی" },
  "text_7f4593da": { "message": "متن" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "پیش نمایش سند در حال پردازش است. لطفا بعدا دوباره تلاش کنید."
  },
  "the_following_content_is_partner_provided_ed1da756": {
    "message": "محتوای زیر توسط شریک فراهم شده است"
  },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "مطلب در دامنه عمومی است"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "مطلب تحت مجوز کریتیو کامنز است"
  },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "این سند نمی تواند در کانواس نمایش داده شود."
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "این معادله را نمی توان در نمای اصلی ارائه داد."
  },
  "this_image_is_currently_unavailable_25c68857": {
    "message": "این تصویر در حال حاضر در دسترس نیست"
  },
  "title_ee03d132": { "message": "عنوان" },
  "toggle_tooltip_d3b7cb86": { "message": "تغییر ابزار راهنما" },
  "top_66e0adb6": { "message": "بالا" },
  "unpublished_dfd8801": { "message": "منتشر نشده" },
  "untitled_16aa4f2b": { "message": "بدون عنوان" },
  "upload_file_fd2361b8": { "message": "بارگذاری فایل" },
  "upload_image_6120b609": { "message": "بارگذاری عکس" },
  "upload_media_ce31135a": { "message": "بارگذاری رسانه" },
  "uploading_19e8a4e7": { "message": "در حال بارگذاری" },
  "url_22a5f3b8": { "message": "نشانی اینترنتی" },
  "usage_right_ff96f3e2": { "message": "حق استفاده:" },
  "use_arrow_keys_to_navigate_options_2021cc50": {
    "message": "برای حرکت به گزینه ها از کلیدهای جهت دار استفاده کنید."
  },
  "user_files_78e21703": { "message": "فایل های کاربر" },
  "video_player_b371005": { "message": "پخش کننده فیلم" },
  "view_all_e13bf0a6": { "message": "مشاهده همه" },
  "view_ba339f93": { "message": "مشاهده" },
  "webcam_fe91b20f": { "message": "دوربین" },
  "wiki_home_9cd54d0": { "message": "صفحه اصلی ویکی" },
  "word_count_c77fe3a6": { "message": "تعداد کلمه" },
  "yes_dde87d5": { "message": "بله" },
  "your_webcam_may_already_be_in_use_6cd64c25": {
    "message": "وب کم شما ممکن است در حال استفاده باشد."
  },
  "zoom_f3e54d69": { "message": "بزرگنمایی" }
}


formatMessage.addLocale({'fa-IR': locale})
