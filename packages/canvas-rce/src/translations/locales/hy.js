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
import '../tinymce/hy'

const locale = {
  "add_8523c19b": { "message": "Ավելացնել" },
  "all_4321c3a1": { "message": "Բոլորը" },
  "alpha_15d59033": { "message": "Alpha" },
  "announcement_list_da155734": { "message": "Հայտարարությունների ցուցակ" },
  "announcements_a4b8ed4a": { "message": "Հայտարարություններ" },
  "apply_781a2546": { "message": "Կիրառել" },
  "apps_54d24a47": { "message": "Հավելվածներ" },
  "arrows_464a3e54": { "message": "Սլաքներ" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Կողմերի հարաբերակցությունը պահպանվելու է"
  },
  "assignments_1e02582c": { "message": "Հանձնարարություններ" },
  "attributes_963ba262": { "message": "Հատկանիշեր" },
  "basic_554cdc0a": { "message": "Հիմնական" },
  "blue_daf8fea9": { "message": "Կապույտ" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001թ. Acme Inc." },
  "cancel_caeb1e68": { "message": "Չեղյալ համարել" },
  "choose_usage_rights_33683854": {
    "message": "Ընտրել օգտագործման իրավունքները..."
  },
  "clear_2084585f": { "message": "Մաքրել" },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Click to embed { imageName }"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Click to insert a link into the editor."
  },
  "close_d634289d": { "message": "Փակել" },
  "collaborations_5c56c15f": { "message": "Համատեղ աշխատանքներ" },
  "content_1440204b": { "message": "Բովանդակություն" },
  "content_type_2cf90d95": { "message": "Բովանդակության տեսակ" },
  "copyright_holder_66ee111": {
    "message": "Հեղինակային իրավունք ունեցող անձը՝"
  },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {}\n  other {}\n}"
  },
  "course_files_62deb8f8": { "message": "Դասընթացի ֆայլեր" },
  "course_files_a31f97fc": { "message": "Դասընթացի ֆայլեր" },
  "course_navigation_dd035109": { "message": "Նավարկում դասընթացում" },
  "creative_commons_license_725584ae": {
    "message": "\"Creative Commons\" լիցենզիա"
  },
  "cyan_c1d5f68a": { "message": "Cyan" },
  "deep_purple_bb3e2907": { "message": "Մուգ մանուշակագույն" },
  "delimiters_4db4840d": { "message": "Բաժանիչներ" },
  "details_98a31b68": { "message": "Մանրամասներ" },
  "dimensions_45ddb7b7": { "message": "Չափերը" },
  "discussions_a5f96392": { "message": "Քննարկումներ" },
  "discussions_index_6c36ced": { "message": "Քննարկումների ցուցիչ" },
  "done_54e3d4b6": { "message": "Պատրաստ է" },
  "due_multiple_dates_cc0ee3f5": { "message": "Վերջնաժամկետ՝ մի քանի ամսաթիվ" },
  "edit_c5fbea07": { "message": "Խմբագրել" },
  "embed_image_1080badc": { "message": "Տեղադրել պատկերը" },
  "external_tools_6e77821": { "message": "Արտաքին գործիքներ" },
  "files_c300e900": { "message": "Ֆայլեր" },
  "files_index_af7c662b": { "message": "Ֆայլերի ցուցիչ" },
  "format_4247a9c5": { "message": "Ֆորմատ" },
  "generating_preview_45b53be0": { "message": "Կարծիքը գեներացվում է ..." },
  "grades_a61eba0a": { "message": "Գնահատականներ" },
  "greek_65c5b3f7": { "message": "Հունարեն" },
  "green_15af4778": { "message": "Կանաչ" },
  "group_files_82e5dcdb": { "message": "Խմբի ֆայլեր" },
  "group_navigation_99f191a": { "message": "Խմբի նավարկում" },
  "home_351838cd": { "message": "Սկիզբ" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Ես թույլտվություն եմ ստացել օգտագործելու այս ֆայլը:"
  },
  "i_hold_the_copyright_71ee91b1": {
    "message": "Ես հեղինակային իրավունք ունեմ"
  },
  "icon_215a1dc6": { "message": "Նշան" },
  "image_8ad06": { "message": "Պատկեր" },
  "images_7ce26570": { "message": "Պատկերներ" },
  "indigo_2035fc55": { "message": "Indigo" },
  "insert_593145ef": { "message": "Տեղադրել" },
  "insert_link_6dc23cae": { "message": "Տեղադրել հղումը" },
  "invalid_file_type_881cc9b2": { "message": "Ֆայլի անընդունելի տեսակ" },
  "invalid_url_cbde79f": { "message": "Սխալ URL" },
  "keyboard_shortcuts_ed1844bd": { "message": "Արագ հասանելիության ստեղներ" },
  "light_blue_5374f600": { "message": "Բաց կապույտ" },
  "link_7262adec": { "message": "Հղում" },
  "links_14b70841": { "message": "Հղումներ" },
  "links_to_an_external_site_de74145d": {
    "message": "Արտաքին կայքին հղումներ"
  },
  "loading_25990131": { "message": "Բեռնում է..." },
  "loading_bde52856": { "message": "Բեռնում է" },
  "loading_failed_b3524381": { "message": "Loading failed..." },
  "locked_762f138b": { "message": "Արգելափակված է" },
  "media_af190855": { "message": "Մուլտիմեդիա" },
  "minimize_file_preview_da911944": {
    "message": "Փոքրացնել ֆայլի նախնական դիտումը"
  },
  "minimize_video_20aa554b": { "message": "Փոքրացնել տեսահոլովակը" },
  "misc_3b692ea7": { "message": "Այլ" },
  "modules_c4325335": { "message": "Մոդուլներ" },
  "my_files_2f621040": { "message": "Իմ ֆայլերը" },
  "name_1aed4a1b": { "message": "Անուն" },
  "no_e16d9132": { "message": "Ոչ" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Այս ֆայլի նախնական դիտումը հասանելի չէ:"
  },
  "no_results_940393cf": { "message": "No results." },
  "none_3b5e34d2": { "message": "Ոչինչ չկա" },
  "operators_a2ef9a93": { "message": "Օպերատորներ" },
  "orange_81386a62": { "message": "Նարնջագույն" },
  "pages_e5414c2c": { "message": "Էջեր" },
  "people_b4ebb13c": { "message": "Մարդիկ" },
  "percentage_34ab7c2c": { "message": "Տոկոս" },
  "pink_68ad45cb": { "message": "Վարդագույն" },
  "preview_53003fd2": { "message": "Նախնական դիտում" },
  "published_c944a23d": { "message": "հրապարակված" },
  "purple_7678a9fc": { "message": "Մանուշակագույն" },
  "quizzes_7e598f57": { "message": "Թեստեր" },
  "record_7c9448b": { "message": "Գրառում" },
  "red_8258edf3": { "message": "Կարմիր" },
  "relationships_6602af70": { "message": "Հարաբերություններ" },
  "replace_e61834a7": { "message": "Փոխարինել" },
  "reset_95a81614": { "message": "Սկզբնական Վիճակին Բերել" },
  "rich_content_editor_2708ef21": { "message": "Ֆորմատավորված տեքստի խմբագիր" },
  "save_11a80ec3": { "message": "Պահպանել" },
  "search_280d00bd": { "message": "Որոնել" },
  "size_b30e1077": { "message": "Չափ" },
  "star_8d156e09": { "message": "Նշել աստղիկով" },
  "submit_a3cc6859": { "message": "Ուղարկել" },
  "syllabus_f191f65b": { "message": "Դասընթացի ծրագիր" },
  "teal_f729a294": { "message": "Փիրուզագույն" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "Փաստաթղթի նախնական դիտումը այժմ մշակման փուլում է: Փորձեք կրկին ավելի ուշ:"
  },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Նյութը գտնվում է հանրությանը հասանելի դոմենում"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Նյութը արտոնագրված է  Creative Commons կողմից"
  },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "Այս փաստաթուղթը չի կարող ցուցադրվել Canvas-ի ներսում:"
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "Այս հավասարումը հնարավոր չէ ցուցադրել Հիմնական տեսքով:"
  },
  "title_ee03d132": { "message": "Վերնագիր" },
  "unpublished_dfd8801": { "message": "չհրապարակված" },
  "upload_file_fd2361b8": { "message": "Բեռնել ֆայլը " },
  "uploading_19e8a4e7": { "message": "Բեռնում" },
  "url_22a5f3b8": { "message": "URL" },
  "usage_right_ff96f3e2": { "message": "Օգտագործման իրավունք՝" },
  "view_ba339f93": { "message": "Դիտել" },
  "wiki_home_9cd54d0": { "message": "Վիկիի տնային էջ" },
  "yes_dde87d5": { "message": "Այո" }
}


formatMessage.addLocale({hy: locale})
