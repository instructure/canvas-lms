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
  "all_4321c3a1": { "message": "همه" },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "برای یک  درخواست شبکه خطا رخ داده است"
  },
  "announcement_list_da155734": { "message": "فهرست اطلاعیه" },
  "announcements_a4b8ed4a": { "message": "اطلاعیه ها" },
  "apps_54d24a47": { "message": "برنامه ها" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "نسبت ابعاد حفظ خواهد شد"
  },
  "assignments_1e02582c": { "message": "تکلیف ها" },
  "cancel_caeb1e68": { "message": "لغو" },
  "canvas_plugins_705a5016": { "message": "افزونه های کانواس" },
  "click_any_page_to_insert_a_link_to_that_page_ac920c02": {
    "message": "برای درج پیوند به یک صفحه، روی آن صفحه کلیک کنید."
  },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Click to embed { imageName }"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Click to insert a link into the editor."
  },
  "close_d634289d": { "message": "بستن" },
  "collaborations_5c56c15f": { "message": "همکاری ها" },
  "content_type_2cf90d95": { "message": "نوع محتوا" },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n  other {}\n}"
  },
  "course_files_62deb8f8": { "message": "فایل های درس" },
  "course_files_a31f97fc": { "message": "فایل های درس" },
  "course_navigation_dd035109": { "message": "پیمایش درس" },
  "custom_6979cd81": { "message": "سفارشی" },
  "decrease_indent_de6343ab": { "message": "کاهش تورفتگی" },
  "details_98a31b68": { "message": "اطلاعات" },
  "dimensions_45ddb7b7": { "message": "ابعاد" },
  "discussions_a5f96392": { "message": "بحث ها" },
  "discussions_index_6c36ced": { "message": "فهرست بحث ها" },
  "done_54e3d4b6": { "message": "انجام شد" },
  "due_multiple_dates_cc0ee3f5": { "message": "مهلت: چند تاریخ" },
  "embed_image_1080badc": { "message": "درج تصویر" },
  "files_c300e900": { "message": "فایل ها" },
  "files_index_af7c662b": { "message": "فهرست فایل ها" },
  "generating_preview_45b53be0": { "message": "در حال ایجاد پیش نمایش..." },
  "grades_a61eba0a": { "message": "نمره ها" },
  "group_files_82e5dcdb": { "message": "فایل های گروه" },
  "group_navigation_99f191a": { "message": "پیمایش گروه" },
  "image_8ad06": { "message": "تصویر" },
  "images_7ce26570": { "message": "تصاویر" },
  "increase_indent_6d550a4a": { "message": "افزایش تورفتگی" },
  "insert_593145ef": { "message": "درج" },
  "insert_equella_links_49a8dacd": { "message": "Insert Equella Links" },
  "insert_link_6dc23cae": { "message": "درج پیوند" },
  "insert_math_equation_57c6e767": { "message": "درج معادله ریاضی" },
  "invalid_file_type_881cc9b2": { "message": "نوع فایل معتبر نیست" },
  "keyboard_shortcuts_ed1844bd": { "message": "میانبرهای صفحه کلید" },
  "link_7262adec": { "message": "پیوند" },
  "link_to_other_content_in_the_course_879163b5": {
    "message": "به محتوای دیگر موجود در درس پیوند دهید."
  },
  "link_to_other_content_in_the_group_3fe25379": {
    "message": "به محتوای دیگر در گروه پیوند دهید."
  },
  "links_14b70841": { "message": "پیوندها" },
  "load_more_results_460f49a9": { "message": "Load more results" },
  "loading_25990131": { "message": "در حال بارگذاری..." },
  "loading_bde52856": { "message": "در حال بارگذاری" },
  "loading_failed_b3524381": { "message": "Loading failed..." },
  "locked_762f138b": { "message": "قفل شده" },
  "media_af190855": { "message": "رسانه" },
  "modules_c4325335": { "message": "ماژول ها" },
  "my_files_2f621040": { "message": "فایل های من" },
  "next_page_d2a39853": { "message": "صفحه بعد" },
  "no_e16d9132": { "message": "خیر" },
  "no_results_940393cf": { "message": "No results." },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "باز کردن این کادر گفتکوی میانبرهای صفحه کلید"
  },
  "options_3ab0ea65": { "message": "گزینه ها" },
  "pages_e5414c2c": { "message": "صفحه ها" },
  "people_b4ebb13c": { "message": "افراد" },
  "preview_53003fd2": { "message": "پیش‌نمایش" },
  "previous_page_928fc112": { "message": "صفحه قبل" },
  "published_c944a23d": { "message": "منتشر شده" },
  "quizzes_7e598f57": { "message": "آزمون ها" },
  "record_7c9448b": { "message": "ضبط کردن" },
  "recording_98da6bda": { "message": "در حال ضبط" },
  "rich_content_editor_2708ef21": { "message": "ویرایشگر محتوای غنی" },
  "save_11a80ec3": { "message": "ذخیره سازی" },
  "search_280d00bd": { "message": "جستجو" },
  "selected_274ce24f": { "message": "انتخاب شده" },
  "size_b30e1077": { "message": "اندازه" },
  "something_went_wrong_89195131": { "message": "اشکالی رخ داده است." },
  "sort_by_e75f9e3e": { "message": "مرتب کردن بر اساس" },
  "start_over_f7552aa9": { "message": "شروع دوباره" },
  "submit_a3cc6859": { "message": "ارسال" },
  "syllabus_f191f65b": { "message": "سرفصل" },
  "title_ee03d132": { "message": "عنوان" },
  "unpublished_dfd8801": { "message": "منتشر نشده" },
  "upload_file_fd2361b8": { "message": "بارگذاری فایل" },
  "upload_media_ce31135a": { "message": "بارگذاری رسانه" },
  "url_22a5f3b8": { "message": "نشانی اینترنتی" },
  "video_player_b371005": { "message": "پخش کننده فیلم" },
  "wiki_home_9cd54d0": { "message": "صفحه اصلی ویکی" },
  "yes_dde87d5": { "message": "بله" }
}


formatMessage.addLocale({fa_IR: locale})
