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
import '../tinymce/cy'

const locale = {
  "access_the_pretty_html_editor_37168efe": {
    "message": "Cael mynediad at y golygydd HTML hardd"
  },
  "accessibility_checker_b3af1f6c": { "message": "Gwiriwr Hygyrchedd" },
  "action_to_take_b626a99a": { "message": "Cam gweithredu i''w gymryd:" },
  "add_8523c19b": { "message": "Ychwanegu" },
  "add_a_caption_2a915239": { "message": "Ychwanegu capsiwn" },
  "add_alt_text_for_the_image_48cd88aa": {
    "message": "Ychwanegu testun amgen ar gyfer y ddelwedd"
  },
  "add_another_f4e50d57": { "message": "Ychwanegu un arall" },
  "add_cc_subtitles_55f0394e": { "message": "Ychwanegu CC/Is-deitlau" },
  "add_image_60b2de07": { "message": "Ychwanegu Delwedd" },
  "add_one_9e34a6f8": { "message": "Ychwanegu un!" },
  "additional_considerations_f3801683": {
    "message": "Ystyriaethau ychwanegol"
  },
  "adjacent_links_with_the_same_url_should_be_a_singl_7a1f7f6c": {
    "message": "Dylai dolenni cyfagos â’r un URL fod yn un ddolen."
  },
  "aleph_f4ffd155": { "message": "Aleph" },
  "align_11050992": { "message": "Alinio" },
  "alignment_and_lists_5cebcb69": { "message": "Aliniad a Rhestrau" },
  "all_4321c3a1": { "message": "Y cyfan" },
  "all_apps_a50dea49": { "message": "Pob Ap" },
  "alpha_15d59033": { "message": "Alpha" },
  "alphabetical_55b5b4e0": { "message": "Yn nhrefn yr wyddor" },
  "alt_attribute_text_should_not_contain_more_than_12_e21d4040": {
    "message": "Ni ddylai testun priodoli gynnwys mwy na 120 nod."
  },
  "alt_text_611fb322": { "message": "Testun Amgen" },
  "amalg_coproduct_c589fb12": { "message": "Amalg (Cyd-gynnyrch)" },
  "an_error_occured_reading_the_file_ff48558b": {
    "message": "Gwall wrth ddarllen y ffeil"
  },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "Gwall wrth wneud cais ar gyfer y rhwydwaith"
  },
  "an_error_occurred_uploading_your_media_71f1444d": {
    "message": "Gwall wrth lwytho eich cyfryngau i fyny."
  },
  "and_7fcc2911": { "message": "A" },
  "angle_c5b4ec50": { "message": "Ongl" },
  "announcement_fb4cb645": { "message": "Cyhoeddiad" },
  "announcement_list_da155734": { "message": "Rhestr Cyhoeddiadau" },
  "announcements_a4b8ed4a": { "message": "Cyhoeddiadau" },
  "apply_781a2546": { "message": "Rhoi ar waith" },
  "apply_changes_to_all_instances_of_this_icon_maker__2642f466": {
    "message": "Defnyddio''r newidiadau ar bob enghraifft o’r Eicon Gwneuthurwr Eiconau hwn yn y Cwrs."
  },
  "approaches_the_limit_893aeec9": { "message": "Yn cyrraedd y terfyn" },
  "approximately_e7965800": { "message": "Tua" },
  "apps_54d24a47": { "message": "Apiau" },
  "are_you_sure_you_want_to_cancel_changes_you_made_m_c5210496": {
    "message": "Ydych chi’n siŵr eich bod am ganslo? Mae’n bosib na fydd y newidiadau rydych wedi’u gwneud yn cael eu cadw."
  },
  "arrows_464a3e54": { "message": "Saethau" },
  "art_icon_8e1daad": { "message": "Eicon Celf" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Bydd y gymhareb agwedd yn cael ei chadw"
  },
  "assignment_976578a8": { "message": "Aseiniad" },
  "assignments_1e02582c": { "message": "Aseiniadau" },
  "asterisk_82255584": { "message": "Seren" },
  "attributes_963ba262": { "message": "Priodoleddau" },
  "audio_and_video_recording_not_supported_please_use_5ce3f0d7": {
    "message": "Does dim modd delio â recordio fideo a sain; defnyddiwch borwr gwahanol."
  },
  "audio_options_feb58e2c": { "message": "Opsiynau Sain" },
  "audio_options_tray_33a90711": { "message": "Ardal Opsiynau Sain" },
  "audio_player_for_title_20cc70d": {
    "message": "Chwaraewr sain ar gyfer { title }"
  },
  "auto_saved_content_exists_would_you_like_to_load_t_fee528f2": {
    "message": "Mae cynnwys sydd wedi’i gadw’n awtomatig yn bodoli. Hoffech chi lwytho’r cynnwys sydd wedi’i gadw’n awtomatig?"
  },
  "available_folders_694d0436": { "message": "Ffolderi sydd ar gael" },
  "backslash_b2d5442d": { "message": "Ôl-slaes" },
  "bar_ec63ed6": { "message": "Bar" },
  "basic_554cdc0a": { "message": "Sylfaenol" },
  "because_501841b": { "message": "Oherwydd" },
  "below_81d4dceb": { "message": "O dan" },
  "beta_cb5f307e": { "message": "Beta" },
  "big_circle_16b2e604": { "message": "Cylch Mawr" },
  "binomial_coefficient_ea5b9bb7": { "message": "Cyfernod Binomaidd" },
  "black_4cb01371": { "message": "Black" },
  "blue_daf8fea9": { "message": "Glas" },
  "bottom_15a2a9be": { "message": "Gwaelod" },
  "bottom_third_5f5fec1d": { "message": "Traean Isaf" },
  "bowtie_5f9629e4": { "message": "Tei bo" },
  "brick_f2656265": { "message": "Bric" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "Canslo" },
  "cap_product_3a5265a6": { "message": "Cynnyrch Cap" },
  "center_align_e68d9997": { "message": "Alinio i’r Canol" },
  "centered_dot_64d5e378": { "message": "Dot Canolog" },
  "centered_horizontal_dots_451c5815": {
    "message": "Dotiau Llorweddol Canolog"
  },
  "change_alt_text_92654906": { "message": "Newid testun amgen" },
  "change_heading_tag_to_paragraph_a61e3113": {
    "message": "Newid tag y pennawd yn baragraff"
  },
  "change_only_this_heading_s_level_903cc956": {
    "message": "Newid lefel y pennawd hwn yn unig"
  },
  "change_text_color_1aecb912": { "message": "Newid lliw''r testun" },
  "changes_you_made_may_not_be_saved_4e8db973": {
    "message": "Mae’n bosib na fydd y newidiadau rydych wedi’u gwneud yn cael eu cadw."
  },
  "characters_9d897d1c": { "message": "Nodau" },
  "characters_no_spaces_485e5367": { "message": "Nodau (dim bylchau)" },
  "check_accessibility_3c78211c": { "message": "Gwirio Hygyrchedd" },
  "checking_for_accessibility_issues_fac18c6d": {
    "message": "Wrthi’n chwilio am broblemau o ran hygyrchedd"
  },
  "chi_54a32644": { "message": "Chi" },
  "choose_caption_file_9c45bc4e": { "message": "Dewiswch ffeil gapsiwn" },
  "choose_usage_rights_33683854": {
    "message": "Dewiswch hawliau defnyddio..."
  },
  "circle_484abe63": { "message": "Cylch" },
  "circle_unordered_list_9e3a0763": {
    "message": "rhestr cylchoedd sydd ddim mewn trefn"
  },
  "clear_2084585f": { "message": "Clirio" },
  "clear_image_3213fe62": { "message": "Clirio’r ddelwedd" },
  "clear_selected_file_82388e50": { "message": "Clirio''r ffeil dan sylw" },
  "clear_selected_file_filename_2fe8a58e": {
    "message": "Clirio''r ffeil dan sylw: { filename }"
  },
  "click_or_shift_click_for_the_html_editor_25d70bb4": {
    "message": "Cliciwch neu pwyswch shifft a chlicio ar gyfer y golygydd html."
  },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Cliciwch i blannu { imageName }"
  },
  "click_to_hide_preview_3c707763": { "message": "Cliciwch i guddio rhagolwg" },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Cliciwch i fewnosod dolen i’r nodwedd golygu."
  },
  "click_to_show_preview_faa27051": {
    "message": "Cliciwch i ddangos rhagolwg"
  },
  "close_a_menu_or_dialog_also_returns_you_to_the_edi_739079e6": {
    "message": "Cau dewislen neu ddeialog. Hefyd yn mynd a chi''n ôl i''r ardal olygu"
  },
  "close_accessibility_checker_29d1c51e": {
    "message": "Cau''r Gwiriwr Hygyrchedd"
  },
  "close_d634289d": { "message": "Cau" },
  "closed_caption_file_must_be_less_than_maxkb_kb_5880f752": {
    "message": "Rhaid i ffeiliau capsiynau caeedig fod yn llai na { maxKb } kb"
  },
  "closed_captions_subtitles_e6aaa016": {
    "message": "Capsiynau Caeedig/Isdeitlau"
  },
  "clubs_suit_c1ffedff": { "message": "Clubs (Suit)" },
  "collaborations_5c56c15f": { "message": "Cydweithrediadau" },
  "collapse_to_hide_types_1ab46d2e": {
    "message": "Crebachu i guddio { types }"
  },
  "color_picker_6b359edf": { "message": "Dewisydd Lliw" },
  "color_picker_colorname_selected_ad4cf400": {
    "message": "Dewisydd Lliw ({ colorName } wedi’i ddewis)"
  },
  "column_e1ae5c64": { "message": "Colofn" },
  "column_group_1c062368": { "message": "Grŵp y golofn" },
  "complex_numbers_a543d004": { "message": "Rhifau Cymhleth" },
  "computer_1d7dfa6f": { "message": "Cyfrifiadur" },
  "congruent_5a244acd": { "message": "Cyfath" },
  "contains_311f37b7": { "message": "Yn cynnwys" },
  "content_1440204b": { "message": "Cynnwys" },
  "content_is_still_being_uploaded_if_you_continue_it_8f06d0cb": {
    "message": "Mae cynnwys wrthi''n cael ei llwytho i fyny, os byddwch chi''n parhau ni fydd yn cael ei blannu''n gywir."
  },
  "content_subtype_5ce35e88": { "message": "Is-fath o Gynnwys" },
  "content_type_2cf90d95": { "message": "Math o Gynnwys" },
  "coproduct_e7838082": { "message": "Cyd-gynnyrch" },
  "copyright_holder_66ee111": { "message": "Perchennog yr Hawlfraint:" },
  "could_not_insert_content_itemtype_items_are_not_cu_638dfecd": {
    "message": "Doedd dim modd mewnosod y cynnwys: Nid yw Canvas yn gallu delio â \"{ itemType }\" eitem ar hyn o bryd."
  },
  "count_40eced3b": { "message": "Nifer" },
  "count_plural_0_0_words_one_1_word_other_words_acf32eca": {
    "message": "{ count, plural,\n     =0 {0 gair}\n    one {1 gair}\n  other {# gair}\n}"
  },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {# eitem wedi''i lwytho}\n  other {# eitem wedi''i lwytho}\n}"
  },
  "course_documents_104d76e0": { "message": "Dogfennau Cwrs" },
  "course_files_62deb8f8": { "message": "Ffeiliau Cwrs" },
  "course_files_a31f97fc": { "message": "Ffeiliau cwrs" },
  "course_images_f8511d04": { "message": "Delweddau Cwrs" },
  "course_link_b369426": { "message": "Dolen Cwrs" },
  "course_links_b56959b9": { "message": "Dolenni Cwrs" },
  "course_media_ec759ad": { "message": "Cyfryngau Cwrs" },
  "course_navigation_dd035109": { "message": "Dewislen Crwydro’r Cwrs" },
  "create_icon_110d6463": { "message": "Creu Eicon" },
  "create_icon_maker_icon_c716bffe": {
    "message": "Creu Eicon Gwneuthurwr Eiconau"
  },
  "creative_commons_license_725584ae": {
    "message": "Trwydded Creative Commons:"
  },
  "crop_image_41bf940c": { "message": "Tocio’r ddelwedd" },
  "crop_image_807ebb08": { "message": "Tocio Delwedd" },
  "cup_product_14174434": { "message": "Cynnyrch Cwpan" },
  "current_image_f16c249c": { "message": "Delwedd Bresennol" },
  "current_link_945a47ee": { "message": "Dolen Gyfredol" },
  "current_volume_level_c55ab825": { "message": "Lefel Sain Bresennol" },
  "custom_6979cd81": { "message": "Personol" },
  "custom_width_and_height_pixels_946eea7c": {
    "message": "Lled ac uchder personol (Picseli)"
  },
  "cyan_c1d5f68a": { "message": "Cyan" },
  "dagger_57e0f4e5": { "message": "Cyllell" },
  "date_added_ed5ad465": { "message": "Dyddiad Ychwanegu" },
  "decorative_icon_9a7f3fc3": { "message": "Eicon Addurniadol" },
  "decorative_image_fde98579": { "message": "Delwedd addurniadol" },
  "decorative_type_upper_f2c95e3": { "message": "Addurniadol { TYPE_UPPER }" },
  "decrease_indent_d9cf469d": { "message": "Lleihau Mewnoliad" },
  "deep_purple_bb3e2907": { "message": "Porffor Tywyll" },
  "default_bulleted_unordered_list_47079da8": {
    "message": "rhestr ddiofyn o bwyntiau bwled sydd ddim mewn trefn"
  },
  "default_numerical_ordered_list_48dd3548": {
    "message": "rhestr ddiofyn o rifau sydd mewn trefn"
  },
  "definite_integral_fe7ffed1": { "message": "Integryn Pendant" },
  "degree_symbol_4a823d5f": { "message": "Symbol Gradd" },
  "delimiters_4db4840d": { "message": "Amffinyddion" },
  "delta_53765780": { "message": "Delta" },
  "describe_the_icon_f6a18823": { "message": "(Disgrifiwch yr eicon)" },
  "describe_the_type_ff448da5": { "message": "(Disgrifiwch y { TYPE })" },
  "describe_the_video_2fe8f46a": { "message": "(Disgrifiwch y fideo)" },
  "description_436c48d7": { "message": "Disgrifiad" },
  "details_98a31b68": { "message": "Manylion" },
  "diagonal_dots_7d71b57e": { "message": "Dotiau Croeslinol" },
  "diamond_b8dfe7ae": { "message": "Diemwnt" },
  "diamonds_suit_526abaaf": { "message": "Diamonds (Suit)" },
  "digamma_258ade94": { "message": "Digamma" },
  "dimension_type_f5fa9170": { "message": "Math o Ddimensiwn" },
  "dimensions_45ddb7b7": { "message": "Dimensiynau" },
  "directionality_26ae9e08": { "message": "Cyfeirioldeb" },
  "directly_edit_latex_b7e9235b": { "message": "Golygu LaTeX yn Uniongyrchol" },
  "disable_preview_222bdf72": { "message": "Analluogi Rhagolwg" },
  "discussion_6719c51d": { "message": "Trafodaeth" },
  "discussions_a5f96392": { "message": "Trafodaethau" },
  "discussions_index_6c36ced": { "message": "Mynegai Trafodaethau" },
  "disjoint_union_e74351a8": { "message": "Uniad Arwahan" },
  "display_options_315aba85": { "message": "Dangos Opsiynau" },
  "display_text_link_opens_in_a_new_tab_75e9afc9": {
    "message": "Dangos Dolen Testun (Yn agor mewn tab newydd)"
  },
  "division_sign_72190870": { "message": "Arwydd Rhannu" },
  "document_678cd7bf": { "message": "Dogfen" },
  "documents_81393201": { "message": "Dogfennau" },
  "done_54e3d4b6": { "message": "Wedi gorffen" },
  "double_dagger_faf78681": { "message": "Cyllell Ddwbl" },
  "down_5831a426": { "message": "I Lawr" },
  "down_and_left_diagonal_arrow_40ef602c": {
    "message": "Saeth Croeslinol i lawr ac i’r chwith"
  },
  "down_and_right_diagonal_arrow_6ea0f460": {
    "message": "Saeth Croeslinol i lawr ac i’r dde"
  },
  "download_filename_2baae924": { "message": "Llwytho { filename } i Lawr" },
  "downward_arrow_cca52012": { "message": "Saeth i lawr" },
  "downward_pointing_triangle_2a12a601": {
    "message": "Triongl yn pwyntio i lawr"
  },
  "drag_a_file_here_1bf656d5": { "message": "Llusgwch ffeil yma" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "Gallwch lusgo a gollwng, neu glicio i bori drwy’ch cyfrifiadur"
  },
  "drag_handle_use_up_and_down_arrows_to_resize_e29eae5c": {
    "message": "Dolen lusgo. Defnyddiwch y saethau i fyny ac i lawr i newid maint"
  },
  "due_multiple_dates_cc0ee3f5": { "message": "Erbyn: Mwy nag un dyddiad" },
  "due_when_7eed10c6": { "message": "Erbyn: { when }" },
  "edit_alt_text_for_this_icon_instance_9c6fc5fd": {
    "message": "Golygu’r testun amgen ar gyfer y fersiwn hwn o’r eicon"
  },
  "edit_c5fbea07": { "message": "Golygu" },
  "edit_course_link_5a5c3c59": { "message": "Golygu Dolen Cwrs" },
  "edit_equation_f5279959": { "message": "Golygu Hafaliad" },
  "edit_existing_icon_maker_icon_5d0ebb3f": {
    "message": "Golygu’r Eicon Gwneuthurwr Eiconau Presennol"
  },
  "edit_icon_2c6b0e91": { "message": "Golygu Eicon" },
  "edit_link_7f53bebb": { "message": "Golygu Dolen" },
  "editor_statusbar_26ac81fc": { "message": "Bar Statws Golygydd" },
  "element_starting_with_start_91bf4c3b": {
    "message": "Elfen yn dechrau gyda { start }"
  },
  "embed_828fac4a": { "message": "Plannu" },
  "embed_code_314f1bd5": { "message": "Plannu Cod" },
  "embed_content_from_external_tool_3397ad2d": {
    "message": "Plannu cynnwys o Adnodd Allanol"
  },
  "embed_image_1080badc": { "message": "Plannu Delwedd" },
  "embed_video_a97a64af": { "message": "Plannu Fideo" },
  "embedded_content_aaeb4d3d": { "message": "cynnwys wedi''i blannu" },
  "empty_set_91a92df4": { "message": "Set Gwag" },
  "encircled_dot_8f5e51c": { "message": "Dot mewn cylch" },
  "encircled_minus_72745096": { "message": "Minws mewn cylch" },
  "encircled_plus_36d8d104": { "message": "Plws mewn cylch" },
  "encircled_times_5700096d": { "message": "Amser mewn cylch" },
  "engineering_icon_f8f3cf43": { "message": "Eicon Peirianeg" },
  "english_icon_25bfe845": { "message": "Eicon Saesneg" },
  "enter_at_least_3_characters_to_search_4f037ee0": {
    "message": "Rhowch o leiaf 3 nod i chwilio"
  },
  "enter_replacement_text_17631bbc": { "message": "rhowch destun newydd" },
  "enter_search_text_26cb4459": { "message": "rhowch destun chwilio" },
  "epsilon_54bb8afa": { "message": "Epsilon" },
  "epsilon_variant_d31f1e77": { "message": "Epsilon (Amrywiad)" },
  "equals_sign_c51bdc58": { "message": "Hafalnod" },
  "equation_1c5ac93c": { "message": "Hafaliad" },
  "equation_editor_39fbc3f1": { "message": "Golygydd Hafaliadau" },
  "equilibrium_6ff3040b": { "message": "Cydbwysedd" },
  "equivalence_class_7b0f11c0": { "message": "Dosbarth Cydwerthedd" },
  "equivalent_identity_654b3ce5": { "message": "Cywerth (Hunaniaeth)" },
  "eta_b8828f99": { "message": "Eta" },
  "exists_2e62bdaa": { "message": "Yn bodoli" },
  "exit_fullscreen_b7eb0aa4": { "message": "Gadael y Sgrin Lawn" },
  "expand_preview_by_default_2abbf9f8": {
    "message": "Ehangu rhagolwg yn ddiofyn"
  },
  "expand_to_see_types_f5d29352": { "message": "Ehangu i weld { types }" },
  "external_link_d3f9e62a": { "message": "Dolen Allanol" },
  "external_tool_frame_70b32473": { "message": "Ffrâm adnodd allanol" },
  "external_tools_6e77821": { "message": "Adnoddau Allanol" },
  "extra_large_b6cdf1ff": { "message": "Mawr Iawn" },
  "extra_small_9ae33252": { "message": "Bach Iawn" },
  "extracurricular_icon_67c8ca42": { "message": "Eicon Allgwricwlar" },
  "f_function_fe422d65": { "message": "F (nodwedd)" },
  "failed_getting_file_contents_e9ea19f4": {
    "message": "Wedi methu cael cynnwys ffeil"
  },
  "failed_to_retrieve_content_from_external_tool_5899c213": {
    "message": "Wedi methu nôl cynnwys o adnodd allanol"
  },
  "file_name_8fd421ff": { "message": "Enw’r Ffeil" },
  "file_storage_quota_exceeded_b7846cd1": {
    "message": "Wedi cyrraedd cwota storio ffeil"
  },
  "file_url_c12b64be": { "message": "URL Ffeil" },
  "filename_file_icon_602eb5de": { "message": "{ filename } eicon ffeil" },
  "filename_image_preview_6cef8f26": {
    "message": "{ filename } rhagolwg o ddelwedd"
  },
  "filename_text_preview_e41ca2d8": {
    "message": "{ filename } rhagolwg o destun"
  },
  "files_c300e900": { "message": "Ffeiliau" },
  "files_index_af7c662b": { "message": "Mynegai Ffeiliau" },
  "find_8d605019": { "message": "Canfod" },
  "find_and_replace_6e345933": { "message": "Canfod a Chyfnewid" },
  "finish_bc343002": { "message": "Gorffen" },
  "fix_heading_hierarchy_f60884c4": {
    "message": "Pennu hierarchaeth penawdau"
  },
  "flat_music_76d5a5c3": { "message": "Fflat (Cerddoriaeth)" },
  "focus_element_options_toolbar_18d993e": {
    "message": "Canolbwyntio bar offer opsiynau elfen"
  },
  "folder_tree_fbab0726": { "message": "Coeden ffolderi" },
  "for_all_b919f972": { "message": "I Bawb" },
  "format_4247a9c5": { "message": "Fformat" },
  "format_as_a_list_142210c3": { "message": "Fformatio ar ffurf rhestr" },
  "formatting_5b143aa8": { "message": "Fformatio" },
  "forward_slash_3f90f35e": { "message": "Blaen Slaes" },
  "found_auto_saved_content_3f6e4ca5": {
    "message": "Wedi dod o hyd i gynnwys sydd wedi’i gadw’n awtomatig"
  },
  "found_count_plural_0_results_one_result_other_resu_46aeaa01": {
    "message": "Wedi canfod { count, plural,\n     =0 {# canlyniad}\n    one {# canlyniad}\n  other {# canlyniad}\n}"
  },
  "fraction_41bac7af": { "message": "Ffracsiwn" },
  "fullscreen_873bf53f": { "message": "Sgrin Lawn" },
  "gamma_1767928": { "message": "Gamma" },
  "generating_preview_45b53be0": { "message": "Wrthi’n creu rhagolwg..." },
  "gif_png_format_images_larger_than_size_kb_are_not__7af3bdbd": {
    "message": "Ar hyn o bryd, does dim modd delio â delweddau ar fformat GIF/PNG sy’n fwy na { size } KB."
  },
  "go_to_the_editor_s_menubar_e6674c81": {
    "message": "Ewch i far dewislen y golygydd"
  },
  "go_to_the_editor_s_toolbar_a5cb875f": {
    "message": "Ewch i far offer y golygydd"
  },
  "grades_a61eba0a": { "message": "Graddau" },
  "greater_than_e98af662": { "message": "Yn fwy na" },
  "greater_than_or_equal_b911949a": { "message": "Yn fwy na neu’n hafal i" },
  "greek_65c5b3f7": { "message": "Groeg" },
  "green_15af4778": { "message": "Gwyrdd" },
  "grey_a55dceff": { "message": "Llwyd" },
  "group_documents_8bfd6ae6": { "message": "Dogfennau Grŵp" },
  "group_files_4324f3df": { "message": "Ffeiliau Grŵp" },
  "group_files_82e5dcdb": { "message": "Ffeiliau grŵp" },
  "group_images_98e0ac17": { "message": "Delweddau Grŵp" },
  "group_isomorphism_45b1458c": { "message": "Isomorthffedd Grŵp" },
  "group_link_63e626b3": { "message": "Dolen Grŵp" },
  "group_links_9493129e": { "message": "Dolenni Grwpiau" },
  "group_media_2f3d128a": { "message": "Cyfryngau Grŵp" },
  "group_navigation_99f191a": { "message": "Dewislen Crwydro Grwpiau" },
  "h_bar_bb94deae": { "message": "Bar H" },
  "hat_ea321e35": { "message": "Het" },
  "header_column_f27433cb": { "message": "Colofn y pennawd" },
  "header_row_and_column_ec5b9ec": { "message": "Colofn a rhes y pennawd" },
  "header_row_f33eb169": { "message": "Rhes y pennawd" },
  "heading_2_5b84eed2": { "message": "Pennawd 2" },
  "heading_3_2c83de44": { "message": "Pennawd 3" },
  "heading_4_b2e74be7": { "message": "Pennawd 4" },
  "heading_levels_should_not_be_skipped_3947c0e0": {
    "message": "Ni ddylid anwybyddu lefelau penawdau."
  },
  "heading_starting_with_start_42a3e7f9": {
    "message": "Pennawd yn dechrau gyda { start }"
  },
  "headings_should_not_contain_more_than_120_characte_3c0e0cb3": {
    "message": "Ni ddylai penawdau gynnwys mwy na 120 nod."
  },
  "health_icon_8d292eb5": { "message": "Eicon Iechyd" },
  "hearts_suit_e50e04ca": { "message": "Hearts (Suit)" },
  "height_69b03e15": { "message": "Uchder" },
  "hexagon_d8468e0d": { "message": "Hecsagon" },
  "hide_description_bfb5502e": { "message": "Cuddio disgrifiad" },
  "hide_title_description_caf092ef": {
    "message": "Cuddio disgrifiad { title }"
  },
  "highlight_an_element_to_activate_the_element_optio_60e1e56b": {
    "message": "Amlygwch elfen i roi’r bar offer opsiynau elfen ar waith"
  },
  "home_351838cd": { "message": "Hafan" },
  "html_code_editor_fd967a44": { "message": "golygydd cod html" },
  "html_editor_fb2ab713": { "message": "Golygydd HTML" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Rydw i wedi cael caniatâd i ddefnyddio’r ffeil hon."
  },
  "i_hold_the_copyright_71ee91b1": { "message": "Fi sydd biau’r hawlfraint" },
  "icon_215a1dc6": { "message": "Eicon" },
  "icon_8168b2f8": { "message": "eicon" },
  "icon_color_b86dd6d6": { "message": "Lliw Eicon" },
  "icon_maker_icons_cc560f7e": { "message": "Eiconau’r Gwneuthurwr Eiconau" },
  "icon_options_7e32746e": { "message": "Opsiynau Eicon" },
  "icon_options_tray_2b407977": { "message": "Ardal Opsiynau Eicon" },
  "icon_preview_1782a1d9": { "message": "Rhagolwg o’r Eicon" },
  "icon_shape_30b61e7": { "message": "Siâp yr Eicon" },
  "icon_size_9353edea": { "message": "Maint yr Eicon" },
  "if_left_empty_link_text_will_display_as_course_lin_2a34eedb": {
    "message": "Os bydd yn wag, bydd testun dolen yn ymddangos fel enw dolen cwrs"
  },
  "if_usage_rights_are_required_the_file_will_not_pub_841e276e": {
    "message": "Os oes angen Hawliau Defnyddio ni fydd y ffeil yn cael ei chyhoeddi nes ei bod wedi’i galluogi ar y dudalen Ffeiliau."
  },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "Os na fyddwch chi’n dewis hawliau defnyddio yn awr, bydd y ffeil hon yn cael ei dad-gyhoeddi ar ôl iddi gael ei llwytho i fyny."
  },
  "image_8ad06": { "message": "Delwedd" },
  "image_c1c98202": { "message": "delwedd" },
  "image_filenames_should_not_be_used_as_the_alt_attr_bcfd7780": {
    "message": "Ni ddylid defnyddio enwau ffeiliau delweddau fel y nodwedd amgen wrth ddisgrifio cynnwys delweddau."
  },
  "image_options_5412d02c": { "message": "Opsiynau Delwedd" },
  "image_options_tray_90a46006": { "message": "Ardal Opsiynau Delwedd" },
  "image_to_crop_3a34487d": { "message": "Delwedd i''w thocio" },
  "image_with_filename_file_aacd7180": {
    "message": "Delwedd â’r enw ffeil { file }"
  },
  "images_7ce26570": { "message": "Delweddau" },
  "images_should_include_an_alt_attribute_describing__b86d6a86": {
    "message": "Dylai delweddau gynnwys nodwedd amgen sy’n disgrifio cynnwys y ddelwedd."
  },
  "imaginary_portion_of_complex_number_2c733ffa": {
    "message": "Cyfran Ddychmygol (o Rif Cymhleth)"
  },
  "in_element_of_19ca2f33": { "message": "Yn (Elfen O)" },
  "increase_indent_6af90f7c": { "message": "Cynyddu Mewnoliad" },
  "indefinite_integral_6623307e": { "message": "Integryn Amhendant" },
  "index_of_max_80dcf7a5": { "message": "{ index } o { max }" },
  "indigo_2035fc55": { "message": "Indigo" },
  "inference_fed5c960": { "message": "Casgliad" },
  "infinity_7a10f206": { "message": "Anfeidredd" },
  "insert_593145ef": { "message": "Mewnosod" },
  "insert_link_6dc23cae": { "message": "Mewnosod Dolen" },
  "insert_math_equation_57c6e767": {
    "message": "Mewnosod hafaliad mathemategol"
  },
  "integers_336344e1": { "message": "Cyfanrif" },
  "intersection_cd4590e4": { "message": "Croestoriad" },
  "invalid_entry_f7d2a0f5": { "message": "Cofnod annilys." },
  "invalid_file_c11ba11": { "message": "Ffeil Annilys" },
  "invalid_file_type_881cc9b2": { "message": "Math o ffeil annilys" },
  "invalid_url_cbde79f": { "message": "URL annilys" },
  "iota_11c932a9": { "message": "Iota" },
  "issue_num_total_f94536cf": { "message": "Problem { num }/{ total }" },
  "kappa_2f14c816": { "message": "Kappa" },
  "kappa_variant_eb64574b": { "message": "Kappa (Amrywiad)" },
  "keyboard_shortcuts_ed1844bd": { "message": "Bysellau Hwylus" },
  "keyboards_navigate_to_links_using_the_tab_key_two__5fab8c82": {
    "message": "Mae bysellfyrddau’n symud i ddolenni drwy ddefnyddio’r fysell ‘Tab’. Gall dwy ddolen gyfagos â''r un gyrchfan fod yn ddryslyd i ddefnyddwyr bysellfyrddau."
  },
  "lambda_4f602498": { "message": "Lambda" },
  "language_arts_icon_a798b0f8": { "message": "Eicon Celfyddydau Iaith" },
  "languages_icon_9d20539": { "message": "Eicon Ieithoedd" },
  "large_9c5e80e7": { "message": "Mawr" },
  "learn_more_about_adjacent_links_2cb9762c": {
    "message": "Dysgu mwy am ddolenni cyfagos"
  },
  "learn_more_about_color_contrast_c019dfb9": {
    "message": "Dysgu mwy am gyferbynnedd lliw"
  },
  "learn_more_about_organizing_page_headings_8a7caa2e": {
    "message": "Dysgu mwy am drefnu penawdau tudalennau"
  },
  "learn_more_about_proper_page_heading_structure_d2959f2d": {
    "message": "Dysgu mwy am strwythur penawdau tudalennau cywir"
  },
  "learn_more_about_table_headers_5f5ee13": {
    "message": "Dysgu mwy am benawdau tablau"
  },
  "learn_more_about_using_alt_text_for_images_5698df9a": {
    "message": "Dysgu mwy am ddefnyddio testun amgen ar gyfer delweddau"
  },
  "learn_more_about_using_captions_with_tables_36fe496f": {
    "message": "Dysgu mwy am ddefnyddio capsiynau gyda thablau"
  },
  "learn_more_about_using_filenames_as_alt_text_264286af": {
    "message": "Dysgu mwy am ddefnyddio enwau ffeiliau fel testun amgen"
  },
  "learn_more_about_using_lists_4e6eb860": {
    "message": "Dysgu mwy am ddefnyddio rhestrau"
  },
  "learn_more_about_using_scope_attributes_with_table_20df49aa": {
    "message": "Dysgu mwy am ddefnyddio priodoleddau cwmpas gyda thablau"
  },
  "leave_as_is_4facfe55": { "message": "Gadael fel y mae" },
  "left_3ea9d375": { "message": "Chwith" },
  "left_align_43d95491": { "message": "Alinio i’r Chwith" },
  "left_angle_bracket_c87a6d07": { "message": "Braced Ongl Chwith" },
  "left_arrow_4fde1a64": { "message": "Saeth i’r Chwith" },
  "left_arrow_with_hook_5bfcad93": {
    "message": "Saeth i’r Chwith gyda Bachyn"
  },
  "left_ceiling_ee9dd88a": { "message": "Nenfwd Chwith" },
  "left_curly_brace_1726fb4": { "message": "Cyplysydd Cyrliog Chwith" },
  "left_downard_harpoon_arrow_1d7b3d2e": {
    "message": "Saeth Tryfer i Lawr i’r Chwith"
  },
  "left_floor_29ac2274": { "message": "Llawr Chwith" },
  "left_to_right_e9b4fd06": { "message": "Chwith i’r Dde" },
  "left_upward_harpoon_arrow_3a562a96": {
    "message": "Saeth Tryfer i Fyny i’r Chwith"
  },
  "leftward_arrow_1e4765de": { "message": "Saeth i’r Chwith" },
  "leftward_pointing_triangle_d14532ce": {
    "message": "Triongl yn pwyntio i’r chwith"
  },
  "less_than_a26c0641": { "message": "Yn llai na" },
  "less_than_or_equal_be5216cb": { "message": "Yn llai na neu’n hafal i" },
  "library_icon_ae1e54cf": { "message": "Eicon Llyfrgell" },
  "light_blue_5374f600": { "message": "Glas golau" },
  "link_7262adec": { "message": "Dolen" },
  "link_options_a16b758b": { "message": "Opsiynau Dolen" },
  "link_type_linktypemessage_c6d26815": {
    "message": "math o ddolen: { linkTypeMessage }"
  },
  "link_with_text_starting_with_start_b3fcbe71": {
    "message": "Dolen â thestun yn dechrau gyda { start }"
  },
  "links_14b70841": { "message": "Dolenni" },
  "links_to_an_external_site_de74145d": {
    "message": "Dolenni at safle allanol."
  },
  "lists_should_be_formatted_as_lists_f862de8d": {
    "message": "Dylai rhestrau gael eu fformatio fel rhestrau."
  },
  "load_more_35d33c7": { "message": "Llwytho Mwy" },
  "loading_25990131": { "message": "Wrthi’n llwytho..." },
  "loading_bde52856": { "message": "Wrthi’n llwytho" },
  "loading_closed_captions_subtitles_failed_95ceef47": {
    "message": "Wedi methu llwytho capsiynau caeedig/isdeitlau."
  },
  "loading_external_tool_d839042c": {
    "message": "Wrthi’n Llwytho Adnodd Allanol"
  },
  "loading_failed_b3524381": { "message": "Wedi methu llwytho..." },
  "loading_failed_e6a9d8ef": { "message": "Wedi methu llwytho." },
  "loading_folders_d8b5869e": { "message": "Wrthi’n llwytho ffolderi" },
  "loading_placeholder_for_filename_792ef5e8": {
    "message": "Wrthi’n llwytho dalfan ar gyfer { fileName }"
  },
  "loading_please_wait_d276220a": {
    "message": "Wrthi’n llwytho, arhoswch funud"
  },
  "loading_preview_9f077aa1": { "message": "Wrthi’n llwytho rhagolwg" },
  "locked_762f138b": { "message": "Wedi Cloi" },
  "logical_equivalence_76fca396": { "message": "Cydwerthedd Rhesymegol" },
  "logical_equivalence_short_8efd7b4f": {
    "message": "Cydwerthedd Rhesymegol (Byr)"
  },
  "logical_equivalence_short_and_thick_1e1f654d": {
    "message": "Cydwerthedd Rhesymegol (Byr a Thrwchus)"
  },
  "logical_equivalence_thick_662dd3f2": {
    "message": "Cydwerthedd Rhesymegol (Trwchus)"
  },
  "low_horizontal_dots_cc08498e": { "message": "Dotiau Llorweddol Isel" },
  "magenta_4a65993c": { "message": "Magenta" },
  "maps_to_e5ef7382": { "message": "Mapiau I" },
  "math_icon_ad4e9d03": { "message": "Eicon Mathemateg" },
  "media_af190855": { "message": "Cyfryngau" },
  "media_file_is_processing_please_try_again_later_58a6d49": {
    "message": "Ffeil cyfryngau’n cael ei phrosesu Rhowch gynnig arall arni rywbryd eto."
  },
  "media_title_2112243b": { "message": "Teitl Cyfryngau" },
  "medium_5a8e9ead": { "message": "Cyfrwng" },
  "merge_links_2478df96": { "message": "Cyfuno dolenni" },
  "mic_a7f3d311": { "message": "Meicroffon" },
  "microphone_disabled_15c83130": { "message": "Microffon wedi’i Analluogi" },
  "middle_27dc1d5": { "message": "Canol" },
  "minimize_file_preview_da911944": {
    "message": "Lleihau’r Rhagolwg o’r Ffeil"
  },
  "minimize_video_20aa554b": { "message": "Lleihau Fideo" },
  "minus_fd961e2e": { "message": "Minws" },
  "minus_plus_3461f637": { "message": "Minws/Plws" },
  "misc_3b692ea7": { "message": "Amrywiol" },
  "miscellaneous_e9818229": { "message": "Amrywiol" },
  "module_90d9fd32": { "message": "Modiwl" },
  "modules_c4325335": { "message": "Modiwlau" },
  "moving_image_to_crop_directionword_6f66cde2": {
    "message": "Wrthi’n symud delwedd i docio { directionWord }"
  },
  "mu_37223b8b": { "message": "Mu" },
  "multi_color_image_63d7372f": { "message": "Delwedd mwy nag un lliw" },
  "multiplication_sign_15f95c22": { "message": "Arwydd Lluosi" },
  "music_icon_4db5c972": { "message": "Eicon Cerddoriaeth" },
  "must_be_at_least_percentage_22e373b6": {
    "message": "Yn gorfod bod yn { percentage }% o leiaf"
  },
  "must_be_at_least_width_x_height_px_41dc825e": {
    "message": "Yn gorfod bod o leiaf { width } x { height }px"
  },
  "my_files_2f621040": { "message": "Fy ffeiliau" },
  "n_th_root_9991a6e4": { "message": "N-th Root" },
  "nabla_1e216d25": { "message": "Nabla" },
  "name_1aed4a1b": { "message": "Enw" },
  "name_color_ceec76ff": { "message": "{ name } ({ color })" },
  "natural_music_54a70258": { "message": "Naturiol (Cerddoriaeth)" },
  "natural_numbers_3da07060": { "message": "Rhifau Naturiol" },
  "navigate_through_the_menu_or_toolbar_415a4e50": {
    "message": "Llywiwch trwy''r ddewislen neu''r bar offer"
  },
  "navigation_ee9af92d": { "message": "Crwydro" },
  "nested_greater_than_d852e60d": { "message": "Nythu’n Fwy Na" },
  "nested_less_than_27d17e58": { "message": "Nythu’n Llai Na" },
  "new_quiz_34aacba6": { "message": "Cwis Newydd" },
  "next_40e12421": { "message": "Nesaf" },
  "no_accessibility_issues_were_detected_f8d3c875": {
    "message": "Heb ganfod problemau o ran hygyrchedd."
  },
  "no_announcements_created_yet_c44a94f4": {
    "message": "Does dim cyhoeddiadau wedi’u creu eto."
  },
  "no_announcements_found_20185afc": {
    "message": "Heb ddod o hyd i gyhoeddiadau."
  },
  "no_assignments_created_yet_1b236d87": {
    "message": "Does dim aseiniadau wedi’u creu eto."
  },
  "no_assignments_found_79e46d7f": {
    "message": "Heb ddod o hyd i aseiniadau."
  },
  "no_changes_to_save_d29f6e91": { "message": "Dim newidiadau i’w cadw." },
  "no_discussions_created_yet_ff99abe3": {
    "message": "Does dim trafodaethau wedi’u creu eto."
  },
  "no_discussions_found_9284063b": {
    "message": "Heb ddod o hyd i drafodaethau."
  },
  "no_e16d9132": { "message": "Na" },
  "no_file_chosen_9a880793": { "message": "Dim ffeil wedi’i dewis" },
  "no_headers_9bc7dc7f": { "message": "Dim pennawd" },
  "no_modules_created_yet_c71b6d4d": {
    "message": "Does dim modiwlau wedi’u creu eto."
  },
  "no_modules_found_2df43a40": { "message": "Heb ddod o hyd i fodiwlau." },
  "no_pages_created_yet_c379fa6e": {
    "message": "Does dim tudalennau wedi’u creu eto."
  },
  "no_pages_found_6799350": { "message": "Heb ddod o hyd i dudalennau." },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Does dim rhagolwg ar gael ar gyfer y ffeil hon."
  },
  "no_quizzes_created_yet_1a2370b9": {
    "message": "Does dim cwisiau wedi’u creu eto."
  },
  "no_quizzes_found_c80c537a": { "message": "Heb ddod o hyd i gwisiau." },
  "no_results_940393cf": { "message": "Dim canlyniadau." },
  "no_results_found_58717065": { "message": "Heb ddod o hyd i ganlyniadau" },
  "no_results_found_for_filterterm_ad1b04c8": {
    "message": "Heb ddod o hyd i ganlyniadau ar gyfer { filterTerm }"
  },
  "no_video_1ed00b26": { "message": "Dim Fideo" },
  "none_3b5e34d2": { "message": "Dim" },
  "none_selected_b93d56d2": { "message": "Dim un wedi’i ddewis" },
  "not_equal_6e2980e6": { "message": "Ddim yn Hafal" },
  "not_in_not_an_element_of_fb1ffb54": {
    "message": "Ddim yn (Ddim yn Elfen o)"
  },
  "not_negation_1418ebb8": { "message": "Ddim (Negyddu)" },
  "not_subset_dc2b5e84": { "message": "Ddim yn Is-set" },
  "not_subset_strict_23d282bf": { "message": "Ddim yn Is-set (Strict)" },
  "not_superset_5556b913": { "message": "Ddim yn Uwch-set" },
  "not_superset_strict_24e06f36": { "message": "Ddim yn Uwch-set (Strict)" },
  "nu_1c0f6848": { "message": "Nu" },
  "octagon_e48be9f": { "message": "Octagon" },
  "olive_6a3e4d6b": { "message": "Olive" },
  "omega_8f2c3463": { "message": "Omega" },
  "one_of_the_following_styles_must_be_added_to_save__1de769aa": {
    "message": "Rhaid ychwanegu un o’r arddulliau canlynol i gadw eicon: Lliw Eicon, Maint Amlinell, Testun Eicon, neu Ddelwedd"
  },
  "one_or_more_files_failed_to_paste_please_try_uploa_7fa39dd3": {
    "message": "Wedi methu gludo un neu ragor o ffeiliau i fyny. Rhowch gynnig ar lwytho i fyny neu lusgo a gollwng ffeiliau."
  },
  "open_circle_e9bd069": { "message": "Cylch Agored" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "Agor y ddeialog bysellau hwylus"
  },
  "open_title_application_fd624fc5": { "message": "Agor rhaglen { title }" },
  "operators_a2ef9a93": { "message": "Gweithredyddion" },
  "or_9b70ccaa": { "message": "Neu" },
  "orange_81386a62": { "message": "Oren" },
  "ordered_and_unordered_lists_cfadfc38": {
    "message": "Rhestrau Mewn Trefn a Rhestrau Ddim Mewn Trefn"
  },
  "other_editor_shortcuts_may_be_found_at_404aba4a": {
    "message": "Mae bysellau hwylus golygu eraill i''w cael yn"
  },
  "outline_color_3ef2cea7": { "message": "Lliw Amlinell" },
  "outline_size_a6059a21": { "message": "Maint Amlinell" },
  "p_is_not_a_valid_protocol_which_must_be_ftp_http_h_adf13fc2": {
    "message": "Dydy { p } ddim yn brotocol dilys, rhaid iddo fod yn ftp, http, https, mailto, skype, tel neu gellir ei hepgor"
  },
  "page_50c4823d": { "message": "Tudalen" },
  "pages_e5414c2c": { "message": "Tudalennau" },
  "paragraph_5e5ad8eb": { "message": "Paragraff" },
  "paragraph_starting_with_start_a59923f8": {
    "message": "Paragraff yn dechrau gyda { start }"
  },
  "parallel_d55d6e38": { "message": "Paralel" },
  "partial_derivative_4a9159df": { "message": "Rhannol (Deilliadol)" },
  "paste_5963d1c1": { "message": "Gludo" },
  "pause_12af3bb4": { "message": "Rhewi" },
  "pentagon_17d82ea3": { "message": "Pentagon" },
  "people_b4ebb13c": { "message": "Pobl" },
  "percentage_34ab7c2c": { "message": "Canran" },
  "percentage_must_be_a_number_8033c341": {
    "message": "Mae canran yn gorfod bod yn rhif"
  },
  "performing_arts_icon_f3497486": {
    "message": "Eicon Celfyddydau Perfformio"
  },
  "perpendicular_7c48ede4": { "message": "Perpendicwlar" },
  "phi_4ac33b6d": { "message": "Phi" },
  "phi_variant_c9bb3ac5": { "message": "Phi (Amrywiad)" },
  "physical_education_icon_d7dffd3e": { "message": "Eicon Addysg Gorfforol" },
  "pi_dc4f0bd8": { "message": "Pi" },
  "pi_variant_10f5f520": { "message": "Pi (Amrywiad)" },
  "pink_68ad45cb": { "message": "Pinc" },
  "pixels_52ece7d1": { "message": "Picseli" },
  "play_1a47eaa7": { "message": "Chwarae" },
  "play_media_comment_35257210": { "message": "Chwarae sylw ar gyfryngau." },
  "play_media_comment_by_name_from_createdat_c230123d": {
    "message": "Chwarae sylw ar gyfryngau gan { name } o { createdAt }."
  },
  "please_allow_canvas_to_access_your_microphone_and__dc2c3079": {
    "message": "Gadewch i Canvas gael mynediad at eich microffon a gwe-gamera."
  },
  "plus_d43cd4ec": { "message": "Plws" },
  "plus_minus_f8be2e83": { "message": "Plws/Minws" },
  "posted_when_a578f5ab": { "message": "Wedi postio: { when }" },
  "power_set_4f26f316": { "message": "Set Pŵer" },
  "precedes_196b9aef": { "message": "Cyn" },
  "precedes_equal_20701e84": { "message": "Cyn Hafalnod" },
  "preformatted_d0670862": { "message": "Wedi''i fformatio’n barod" },
  "prev_f82cbc48": { "message": "Blaenorol" },
  "preview_53003fd2": { "message": "Rhagolwg" },
  "preview_a3f8f854": { "message": "RHAGOLWG" },
  "preview_in_overlay_ed772c46": { "message": "Rhagolwg mewn troshaen" },
  "preview_inline_9787330": { "message": "Rhagolwg mewn llinell" },
  "previous_bd2ac015": { "message": "Blaenorol" },
  "prime_917ea60e": { "message": "Cysefin" },
  "prime_numbers_13464f61": { "message": "Rhifau Cysefin" },
  "product_39cf144f": { "message": "Cynnyrch" },
  "proportional_f02800cc": { "message": "Cyfraneddol" },
  "protocol_must_be_ftp_http_https_mailto_skype_tel_o_73beb4f8": {
    "message": "Rhaid i’r protocol fod yn ftp, http, https, mailto, skype, tel neu gellir ei hepgor"
  },
  "psi_e3f5f0f7": { "message": "Psi" },
  "published_c944a23d": { "message": "wedi cyhoeddi" },
  "published_when_302d8e23": { "message": "Wedi cyhoeddi: { when }" },
  "pumpkin_904428d5": { "message": "Pumpkin" },
  "purple_7678a9fc": { "message": "Porffor" },
  "quaternions_877024e0": { "message": "Cwaternion" },
  "quiz_e0dcce8f": { "message": "Cwis" },
  "quizzes_7e598f57": { "message": "Cwisiau" },
  "rational_numbers_80ddaa4a": { "message": "Rhifau Rhesymegol" },
  "real_numbers_7c99df94": { "message": "Rhifau Go Iawn" },
  "real_portion_of_complex_number_7dad33b5": {
    "message": "Cyfran Go Iawn (o Rif Cymhleth)"
  },
  "record_7c9448b": { "message": "Recordio" },
  "record_upload_media_5fdce166": {
    "message": "Recordio Cyfryngau/Llwytho Cyfryngau i Fyny"
  },
  "recording_98da6bda": { "message": "Recordiad" },
  "red_8258edf3": { "message": "Coch" },
  "relationships_6602af70": { "message": "Perthynas" },
  "religion_icon_246e0be1": { "message": "Eicon Crefydd" },
  "remove_heading_style_5fdc8855": { "message": "Tynnu arddull y pennawd" },
  "remove_link_d1f2f4d0": { "message": "Tynnu Dolen" },
  "replace_all_d3d68b3": { "message": "Cyfnewid pob un" },
  "replace_e61834a7": { "message": "Disodli" },
  "replace_with_eeff01ad": { "message": "Cyfnewid am" },
  "reset_95a81614": { "message": "Ailosod" },
  "resize_ec83d538": { "message": "Ailfeintio" },
  "restore_auto_save_deccd84b": { "message": "Adfer cadw’n awtomatig?" },
  "reverse_turnstile_does_not_yield_7558be06": {
    "message": "Giât Dro yn ôl (Ddim yn rhoi)"
  },
  "rho_a0244a36": { "message": "Rho" },
  "rho_variant_415245cd": { "message": "Rho (Amrywiad)" },
  "rich_content_editor_2708ef21": { "message": "Golygydd Cynnwys Cyfoethog" },
  "rich_text_area_press_oskey_f8_for_rich_content_edi_c2f651d": {
    "message": "Ardal Testun Cyfoethog. Pwyswch { OSKey }+F8 ar gyfer bysellau cyflym y Golygydd Cynnwys Cyfoethog."
  },
  "right_71ffdc4d": { "message": "De" },
  "right_align_39e7a32a": { "message": "Alinio i’r Dde" },
  "right_angle_bracket_d704e2d6": { "message": "Braced Ongl Dde" },
  "right_arrow_35e0eddf": { "message": "Saeth i’r Dde" },
  "right_arrow_with_hook_29d92d31": { "message": "Saeth i’r Dde gyda Bachyn" },
  "right_ceiling_839dc744": { "message": "Nenfwd De" },
  "right_curly_brace_5159d5cd": { "message": "Cyplysydd Cyrliog De" },
  "right_downward_harpoon_arrow_d71b114f": {
    "message": "Saeth Tryfer i Lawr i’r Dde"
  },
  "right_floor_5392d5cf": { "message": "Llawr De" },
  "right_to_left_9cfb092a": { "message": "De i’r Chwith" },
  "right_upward_harpoon_arrow_f5a34c73": {
    "message": "Saeth Tryfer i Fyny i’r Dde"
  },
  "rightward_arrow_32932107": { "message": "Saeth i''r Dde" },
  "rightward_pointing_triangle_60330f5c": {
    "message": "Triongl yn pwyntio i’r dde"
  },
  "rotate_image_90_degrees_2ab77c05": { "message": "Troi delwedd - 90 gradd" },
  "rotate_image_90_degrees_6c92cd42": { "message": "Troi delwedd - 90 gradd" },
  "rotation_9699c538": { "message": "Troi" },
  "row_fc0944a7": { "message": "Rhes" },
  "row_group_979f5528": { "message": "Grŵp y rhes" },
  "sadly_the_pretty_html_editor_is_not_keyboard_acces_50da7665": {
    "message": "Yn anffodus, dydy’r golygydd HTML hardd ddim ar gael drwy fysellfwrdd.  Cael mynediad at y golygydd HTML crai yma."
  },
  "save_11a80ec3": { "message": "Cadw" },
  "save_copy_ca63944e": { "message": "Cadw Copi" },
  "save_media_cb9e786e": { "message": "Cadw Cyfryngau" },
  "saved_icon_maker_icons_df86e2a1": {
    "message": "Eiconau’r Gwneuthurwr Eiconau a Gadwyd"
  },
  "screen_readers_cannot_determine_what_is_displayed__6a5842ab": {
    "message": "Does dim modd defnyddio darllenwyr sgrin i bennu beth sy’n cael ei ddangos mewn delwedd heb destun amgen, dim ond rhesi o rifau a llythrennau diystyr yw enwau ffeiliau yn aml, ac nid ydynt yn disgrifio''r cyd-destun na’r ystyr."
  },
  "screen_readers_cannot_determine_what_is_displayed__6f1ea667": {
    "message": "Does dim modd i ddarllenwyr sgrin bennu beth sy’n cael ei ddangos mewn delwedd heb destun amgen, sy’n disgrifio cynnwys ac ystyr y ddelwedd. Dylai’r testun amgen fod ym syml ac yn gryno."
  },
  "screen_readers_cannot_determine_what_is_displayed__a57e6723": {
    "message": "Does dim modd i ddarllenwyr sgrin bennu beth sy’n cael ei ddangos mewn delwedd heb destun amgen, sy’n disgrifio cynnwys ac ystyr y ddelwedd."
  },
  "screen_readers_cannot_interpret_tables_without_the_bd861652": {
    "message": "Ni all darllenwyr sgrin ddehongli tablau heb y strwythur priodol. Mae penawdau tablau yn nodi cyfeiriad ac ystod y cynnwys."
  },
  "screen_readers_cannot_interpret_tables_without_the_e62912d5": {
    "message": "Ni all darllenwyr sgrin ddehongli tablau heb y strwythur priodol. Mae capsiynau tablau’n disgrifio cyd-destun y tabl ac yn rhoi dealltwriaeth gyffredinol ohono."
  },
  "screen_readers_cannot_interpret_tables_without_the_f0bdec0f": {
    "message": "Ni all darllenwyr sgrin ddehongli tablau heb y strwythur priodol. Mae penawdau tablau yn rhoi trosolwg o’r cynnwys a’i gyfeiriad."
  },
  "script_l_42a7b254": { "message": "Sgript L" },
  "search_280d00bd": { "message": "Chwilio" },
  "select_audio_source_21043cd5": { "message": "Dewiswch ffynonellau sain" },
  "select_crop_shape_d441feeb": { "message": "Dewis siâp tocio" },
  "select_language_7c93a900": { "message": "Dewis Iaith" },
  "select_video_source_1b5c9dbe": { "message": "Dewiswch ffynonellau fideo" },
  "selected_274ce24f": { "message": "Wedi dewis" },
  "selected_linkfilename_c093b1f2": {
    "message": "Wedi dewis { linkFileName }"
  },
  "selection_b52c4c5e": { "message": "Dewis" },
  "set_header_scope_8c548f40": { "message": "Pennu ystod y pennawd" },
  "set_minus_b46e9b88": { "message": "Gosod Minws" },
  "set_table_header_cfab13a0": { "message": "Pennu pennawd y tabl" },
  "sharp_music_ab956814": { "message": "Sharp (Cerddoriaeth)" },
  "shift_arrows_4d5785fe": { "message": "SHIFT+Saethau" },
  "shift_o_to_open_the_pretty_html_editor_55ff5a31": {
    "message": "Shift-O i agor y golygydd html hardd."
  },
  "shortcut_911d6255": { "message": "Llwybr byr" },
  "show_audio_options_b489926b": { "message": "Dangos opsiynau sain" },
  "show_image_options_1e2ecc6b": { "message": "Dangos opsiynau delwedd" },
  "show_link_options_545338fd": { "message": "Dangos opsiynau dolen" },
  "show_studio_media_options_a0c748c6": {
    "message": "Dangos opsiynau cyfryngau Studio"
  },
  "show_video_options_6ed3721a": { "message": "Dangos opsiynau fideo" },
  "sighted_users_browse_web_pages_quickly_looking_for_1d4db0c1": {
    "message": "Mae defnyddwyr sy''n gweld yn dda yn pori drwy dudalennau gwe yn gyflym, gan chwilio am benawdau mawr neu drwm. Mae defnyddwyr darllenydd sgrin yn dibynnu ar benawdau i ddeall y cyd-destun. Dylai penawdau ddefnyddio''r strwythur priodol."
  },
  "sighted_users_browse_web_pages_quickly_looking_for_ade806f5": {
    "message": "Mae defnyddwyr sy''n gweld yn dda yn pori drwy dudalennau gwe yn gyflym, gan chwilio am benawdau mawr neu drwm. Mae defnyddwyr darllenydd sgrin yn dibynnu ar benawdau i ddeall y cyd-destun. Dylai penawdau fod yn gryno yn unol â''r strwythur priodol."
  },
  "sigma_5c35e553": { "message": "Sigma" },
  "sigma_variant_8155625": { "message": "Sigma (Amrywiad)" },
  "single_color_image_4e5d4dbc": { "message": "Delwedd un lliw" },
  "single_color_image_color_95fa9a87": { "message": "Lliw Delwedd Un Lliw" },
  "size_b30e1077": { "message": "Maint" },
  "size_of_caption_file_is_greater_than_the_maximum_m_bff5f86e": {
    "message": "Mae maint y ffeil capsiynau’n fwy na’r { max } kb a ganiateir ar gyfer maint y ffeil."
  },
  "small_b070434a": { "message": "Bach" },
  "solid_circle_9f061dfc": { "message": "Cylch Solid" },
  "something_went_wrong_89195131": { "message": "Aeth rhywbeth o’i le." },
  "something_went_wrong_accessing_your_webcam_6643b87e": {
    "message": "Aeth rhywbeth o’i le wrth gael mynediad at eich gwe-gamera."
  },
  "something_went_wrong_and_i_don_t_know_what_to_show_e0c54ec8": {
    "message": "Aeth rhywbeth o''i le a dydw i ddim yn gwybod beth i''w ddangos i chi."
  },
  "something_went_wrong_check_your_connection_reload__c7868286": {
    "message": "Aeth rhywbeth o’i le. Gwiriwch eich cysylltiad, ail-lwythwch y dudalen a rhoi cynnig arall arni."
  },
  "something_went_wrong_d238c551": { "message": "Aeth rhywbeth o’i le" },
  "something_went_wrong_while_sharing_your_screen_8de579e5": {
    "message": "Aeth rhywbeth o’i le wrth rannu eich sgrin."
  },
  "sort_by_e75f9e3e": { "message": "Trefnu yn ôl" },
  "spades_suit_b37020c2": { "message": "Spades (Suit)" },
  "square_511eb3b3": { "message": "Sgwâr" },
  "square_cap_9ec88646": { "message": "Cap Sgwâr" },
  "square_cup_b0665113": { "message": "Cwpan Sgwâr" },
  "square_root_e8bcbc60": { "message": "Ail Isradd" },
  "square_root_symbol_d0898a53": { "message": "Symbol Ail Isradd" },
  "square_subset_17be67cb": { "message": "Is-set Sgwâr" },
  "square_subset_strict_7044e84f": { "message": "Is-set Sgwâr (Strict)" },
  "square_superset_3be8dae1": { "message": "Uwch-set Sgwâr" },
  "square_superset_strict_fa4262e4": { "message": "Uwch-set Sgwâr (Strict)" },
  "square_unordered_list_b15ce93b": {
    "message": "rhestr sgwariau sydd ddim mewn trefn"
  },
  "star_8d156e09": { "message": "Seren" },
  "start_over_f7552aa9": { "message": "Dechrau eto" },
  "start_recording_9a65141a": { "message": "Dechrau’r Recordiad" },
  "steel_blue_14296f08": { "message": "Durlas" },
  "studio_media_options_ee504361": { "message": "Opsiynau Cyfryngau Studio" },
  "studio_media_options_tray_cfb94654": {
    "message": "Ardal Opsiynau Cyfryngau Studio"
  },
  "styles_2aa721ef": { "message": "Arddulliau" },
  "submit_a3cc6859": { "message": "Cyflwyno" },
  "subscript_59744f96": { "message": "Isysgrif" },
  "subset_19c1a92f": { "message": "Is-set" },
  "subset_strict_8d8948d6": { "message": "Is-set (Strict)" },
  "succeeds_9cc31be9": { "message": "Ar ôl" },
  "succeeds_equal_158e8c3a": { "message": "Ar ôl Hafalnod" },
  "sum_b0842d31": { "message": "Swm" },
  "superscript_8cb349a2": { "message": "Uwchysgrif" },
  "superscript_and_subscript_37f94a50": {
    "message": "Uwch-ysgrif ac Is-ysgrif"
  },
  "superset_c4db8a7a": { "message": "Uwch-set" },
  "superset_strict_c77dd6d2": { "message": "Uwch-set (Strict)" },
  "supported_file_types_srt_or_webvtt_7d827ed": {
    "message": "Mathau o ffeiliau y mae modd delio â nhw: SRT neu WebVTT"
  },
  "switch_to_pretty_html_editor_a3cee15f": {
    "message": "Newid i’r golygydd HTML hardd"
  },
  "switch_to_raw_html_editor_f970ae1a": {
    "message": "Newid i’r golygydd HTML crai"
  },
  "switch_to_the_html_editor_146dfffd": {
    "message": "Newid i’r golygydd html "
  },
  "switch_to_the_rich_text_editor_63c1ecf6": {
    "message": "Newid i’r golygydd testun cyfoethog"
  },
  "syllabus_f191f65b": { "message": "Maes Llafur" },
  "system_audio_allowed_b2508f8c": { "message": "Sain System wedi’i Ganiatáu" },
  "system_audio_disabled_c177bd13": {
    "message": "Sain System wedi’i Analluogi"
  },
  "tab_arrows_4cf5abfc": { "message": "TAB/Saethau" },
  "table_header_starting_with_start_ffcabba6": {
    "message": "Pennawd tabl yn dechrau gyda { start }"
  },
  "table_starting_with_start_e7232848": {
    "message": "Tabl yn dechrau gyda { start }"
  },
  "tables_headers_should_specify_scope_5abf3a8e": {
    "message": "Dylai penawdau tablau bennu’r ystod."
  },
  "tables_should_include_a_caption_describing_the_con_e91e78fc": {
    "message": "Dylai tablau gynnwys capsiwn sy’n disgrifio cynnwys y tabl."
  },
  "tables_should_include_at_least_one_header_48779eac": {
    "message": "Dylai tablau gynnwys o leiaf un pennawd."
  },
  "tau_880974b7": { "message": "Tau" },
  "teal_f729a294": { "message": "Glaswyrdd" },
  "text_7f4593da": { "message": "Testun" },
  "text_background_color_16e61c3f": { "message": "Lliw Cefndir yTestun" },
  "text_color_acf75eb6": { "message": "Lliw''r Testun" },
  "text_is_difficult_to_read_without_sufficient_contr_69e62bd6": {
    "message": "Mae’r testun yn anodd ei ddarllen heb gyferbynnedd digonol rhwng y testun a’r cefndir, yn enwedig i bobl sydd â golwg sâl."
  },
  "text_larger_than_18pt_or_bold_14pt_should_display__5c364db6": {
    "message": "Dylai testun mwy na 18pt (neu 14pt trwm) fod â chyferbyniad 3:1 o leiaf."
  },
  "text_optional_384f94f7": { "message": "Testun (dewisol)" },
  "text_position_8df8c162": { "message": "Lleoliad y Testun" },
  "text_size_887c2f6": { "message": "Maint y Testun" },
  "text_smaller_than_18pt_or_bold_14pt_should_display_aaffb22b": {
    "message": "Dylai testun llai na 18pt (neu 14pt trwm) fod â chyferbyniad 4.5:1 o leiaf."
  },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "Mae’r rhagolwg o’r ddogfen wrthi’n cael ei brosesu ar hyn o bryd. Rhowch gynnig arall arni rywbryd eto."
  },
  "the_first_heading_on_a_page_should_be_an_h2_859089f2": {
    "message": "Dylai’r pennawd cyntaf ar dudalen fod yn H2."
  },
  "the_following_content_is_partner_provided_ed1da756": {
    "message": "Mae’r cynnwys canlynol yn cael ei ddarparu gan bartner"
  },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Mae’r deunydd yn y parth cyhoeddus"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Mae’r deunydd wedi''i drwyddedu o dan Creative Commons"
  },
  "the_material_is_subject_to_an_exception_e_g_fair_u_a39c8ca2": {
    "message": "Mae eithriad yn berthnasol i’r deunydd - e.e. defnydd teg, yr hawl i ddyfynnu, neu eraill o dan gyfreithiau hawlfraint perthnasol"
  },
  "the_preceding_content_is_partner_provided_d753928c": {
    "message": "Mae’r cynnwys blaenorol yn cael ei ddarparu gan bartner"
  },
  "the_pretty_html_editor_is_not_keyboard_accessible__d6d5d2b": {
    "message": "Dydy’r golygydd html hardd ddim ar gael drwy fysellfwrdd. Pwyswch Shift-O i agor y golygydd html crai."
  },
  "therefore_d860e024": { "message": "Felly" },
  "theta_ce2d2350": { "message": "Theta" },
  "theta_variant_fff6da6f": { "message": "Theta (Amrywiad)" },
  "thick_downward_arrow_b85add4c": { "message": "Saeth Trwchus i Lawr" },
  "thick_left_arrow_d5f3e925": { "message": "Saeth Trwchus i’r Chwith" },
  "thick_leftward_arrow_6ab89880": { "message": "Saeth Trwchus i’r Chwith" },
  "thick_right_arrow_3ed5e8f7": { "message": "Saeth Trwchus i’r Dde" },
  "thick_rightward_arrow_a2e1839e": { "message": "Saeth Trwchus i’r Dde" },
  "thick_upward_arrow_acd20328": { "message": "Saeth Trwchus i Fyny" },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "Does dim modd dangos y ddogfen hon yn Canvas."
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "Does dim modd rendro’r hafaliad hwn yn y Wedd Syml."
  },
  "this_image_is_currently_unavailable_25c68857": {
    "message": "Dydy''r ddelwedd hon ddim ar gael ar hyn o bryd."
  },
  "though_your_video_will_have_the_correct_title_in_t_90e427f3": {
    "message": "Er y bydd gan eich fideo y teitl cywir yn y porwr, nid ydym ni wedi gallu ei ddiweddaru yn y gronfa ddata."
  },
  "timebar_a4d18443": { "message": "Bar amser" },
  "title_ee03d132": { "message": "Teitl" },
  "to_be_posted_when_d24bf7dc": { "message": "I''w Bostio: { when }" },
  "to_do_when_2783d78f": { "message": "Tasgau i’w Gwneud: { when }" },
  "toggle_summary_group_413df9ac": { "message": "Toglo grŵp { summary } " },
  "toggle_tooltip_d3b7cb86": { "message": "Toglo tooltip" },
  "tools_2fcf772e": { "message": "Adnoddau" },
  "top_66e0adb6": { "message": "Y Brig" },
  "tray_839df38a": { "message": "Ardal" },
  "triangle_6072304e": { "message": "Triongl" },
  "turnstile_yields_f9e76df1": { "message": "Giât Dro (Yn Rhoi)" },
  "type_control_f9_to_access_image_options_text_a47e319f": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau delwedd. { text }"
  },
  "type_control_f9_to_access_link_options_text_4ead9682": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau dolen. { text }"
  },
  "type_control_f9_to_access_table_options_text_92141329": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau tabl. { text }"
  },
  "unable_to_determine_resource_selection_url_7867e060": {
    "message": "Does dim modd pennu url dewis adnodd"
  },
  "union_e6b57a53": { "message": "Uniad" },
  "unpublished_dfd8801": { "message": "heb gyhoeddi" },
  "untitled_16aa4f2b": { "message": "Dideitl" },
  "untitled_efdc2d7d": { "message": "dideitl" },
  "up_and_left_diagonal_arrow_e4a74a23": {
    "message": "Saeth Croeslinol i fyny ac i’r chwith"
  },
  "up_and_right_diagonal_arrow_935b902e": {
    "message": "Saeth Croeslinol i fyny ac i’r dde"
  },
  "up_c553575d": { "message": "I Fyny" },
  "updated_link_a827e441": { "message": "Dolen wedi’i diweddaru" },
  "upload_document_253f0478": { "message": "Llwytho Dogfen i fyny" },
  "upload_file_fd2361b8": { "message": "Llwytho Ffeil i Fyny" },
  "upload_image_6120b609": { "message": "Llwytho Delwedd i Fyny" },
  "upload_media_ce31135a": { "message": "Llwytho Cyfryngau i fyny" },
  "upload_record_media_e4207d72": {
    "message": "Llwytho i Fyny/Recordio Cyfryngau"
  },
  "uploading_19e8a4e7": { "message": "Llwytho i fyny" },
  "uppercase_alphabetic_ordered_list_3f5aa6b2": {
    "message": "rhestr mewn trefn, mewn priflythrennau, yn nhrefn yr wyddor"
  },
  "uppercase_delta_d4f4bc41": { "message": "Delta Fawr" },
  "uppercase_gamma_86f492e9": { "message": "Gamma Fawr" },
  "uppercase_lambda_c78d8ed4": { "message": "Lambda Fawr" },
  "uppercase_omega_8aedfa2": { "message": "Omega Fawr" },
  "uppercase_phi_caa36724": { "message": "Phi Fawr" },
  "uppercase_pi_fcc70f5e": { "message": "Pi Fawr" },
  "uppercase_psi_6395acbe": { "message": "Psi Fawr" },
  "uppercase_roman_numeral_ordered_list_853f292b": {
    "message": "rhestr mewn trefn o rifolion Rhufeinig mewn priflythrennau"
  },
  "uppercase_sigma_dbb70e92": { "message": "Sigma Fawr" },
  "uppercase_theta_49afc891": { "message": "Theta Fawr" },
  "uppercase_upsilon_8c1e623e": { "message": "Upsilon Fawr" },
  "uppercase_xi_341e8556": { "message": "Xi Fawr" },
  "upsilon_33651634": { "message": "Upsilon" },
  "upward_and_downward_pointing_arrow_fa90a918": {
    "message": "Saeth yn pwyntio i fyny ac i lawr"
  },
  "upward_and_downward_pointing_arrow_thick_d420fdef": {
    "message": "Saeth yn pwyntio i fyny ac i lawr (trwchus)"
  },
  "upward_arrow_9992cb2d": { "message": "Saeth i Fyny" },
  "upward_pointing_triangle_d078d7cb": {
    "message": "Triongl yn pwyntio i fyny"
  },
  "url_22a5f3b8": { "message": "URL" },
  "usage_right_ff96f3e2": { "message": "Hawl Defnyddio:" },
  "usage_rights_required_5fe4dd68": {
    "message": "Hawliau Defnyddio (gofynnol)"
  },
  "use_arrow_keys_to_navigate_options_2021cc50": {
    "message": "Defnyddiwch fysellau saeth i symud drwy''r opsiynau."
  },
  "use_arrow_keys_to_select_a_shape_c8eb57ed": {
    "message": "Defnyddiwch y saethau i ddewis siâp."
  },
  "use_arrow_keys_to_select_a_size_699a19f4": {
    "message": "Defnyddiwch y saethau i ddewis maint."
  },
  "use_arrow_keys_to_select_a_text_position_72f9137c": {
    "message": "Defnyddiwch y saethau i ddewis lleoliad y testun."
  },
  "use_arrow_keys_to_select_a_text_size_65e89336": {
    "message": "Defnyddiwch y saethau i ddewis maint y testun."
  },
  "use_arrow_keys_to_select_an_outline_size_e009d6b0": {
    "message": "Defnyddiwch y saethau i ddewis maint amlinelliad."
  },
  "used_by_screen_readers_to_describe_the_content_of__4f14b4e4": {
    "message": "{ TYPE } yn cael ei ddefnyddio gan ddarllenwyr sgrin i ddisgrifio cynnwys delwedd"
  },
  "used_by_screen_readers_to_describe_the_content_of__b1e76d9e": {
    "message": "Yn cael ei ddefnyddio gan ddarllenwyr sgrin i ddisgrifio cynnwys delwedd"
  },
  "used_by_screen_readers_to_describe_the_video_37ebad25": {
    "message": "Yn cael ei ddefnyddio gan ddarllenwyr sgrin i ddisgrifio’r fideo"
  },
  "user_documents_c206e61f": { "message": "Dogfennau Defnyddiwr" },
  "user_files_78e21703": { "message": "Ffeiliau Defnyddwyr" },
  "user_images_b6490852": { "message": "Delweddau Defnyddiwr" },
  "user_media_14fbf656": { "message": "Cyfryngau Defnyddiwr" },
  "vector_notation_cf6086ab": { "message": "Fector (nodiant)" },
  "vertical_bar_set_builder_notation_4300495f": {
    "message": "Bar Fertigol (Gosod Nodiant Adeiladwr)"
  },
  "vertical_dots_bfb21f14": { "message": "Dotiau Fertigol" },
  "video_options_24ef6e5d": { "message": "Opsiynau Fideo" },
  "video_options_tray_3b9809a5": { "message": "Ardal Opsiynau Fideo" },
  "video_player_b371005": { "message": "Chwaraewr Fideo" },
  "video_player_for_9e7d373b": { "message": "Chwaraewr fideo ar gyfer " },
  "video_player_for_title_ffd9fbc4": {
    "message": "Chwaraewr fideo ar gyfer { title }"
  },
  "view_all_e13bf0a6": { "message": "Gweld Pob Un" },
  "view_ba339f93": { "message": "Gweld" },
  "view_description_30446afc": { "message": "Gweld disgrifiad" },
  "view_keyboard_shortcuts_34d1be0b": { "message": "Gweld bysellau hwylus" },
  "view_title_description_67940918": {
    "message": "Gweld disgrifiad { title }"
  },
  "view_word_and_character_counts_a743dd0c": {
    "message": "Gweld y cyfrif geiriau a’r cyfrif nodau"
  },
  "we_couldn_t_detect_a_working_microphone_connected__ceb71c40": {
    "message": "Does dim microffon sy’n gweithio’n gysylltiedig â’ch dyfais."
  },
  "we_couldn_t_detect_a_working_webcam_connected_to_y_6715cc4": {
    "message": "Does dim gwe-gamera sy’n gweithio’n gysylltiedig â’ch dyfais."
  },
  "we_couldn_t_detect_a_working_webcam_or_microphone__263b6674": {
    "message": "Does dim microffon na gwe-gamera sy’n gweithio’n gysylltiedig â’ch dyfais."
  },
  "webcam_disabled_30c66986": { "message": "Gwe-gamera wedi’i Analluogi" },
  "webcam_fe91b20f": { "message": "Gwe-gamera" },
  "webpages_should_only_have_a_single_h1_which_is_aut_dc99189e": {
    "message": "Dim ond un H1 ddylai tudalennau gwe eu cael, sy’n cael ei ddefnyddion awtomatig gan Deitl y dudalen. Dylai’r pennawd cyntaf yn eich cynnwys fod yn H2."
  },
  "when_markup_is_used_that_visually_formats_items_as_f941fc1b": {
    "message": "Pan fydd marcio’n cael ei ddefnyddio, sy’n fformatio eitemau’n weledol ar ffurf rhestr ond sydd ddim yn nodi perthynas y rhestr, mae’n bosib y bydd defnyddwyr yn cael trafferth i ddod o hyd i’r wybodaeth."
  },
  "white_87fa64fd": { "message": "Gwyn" },
  "why_523b3d8c": { "message": "Pam" },
  "width_492fec76": { "message": "Lled" },
  "width_and_height_must_be_numbers_110ab2e3": {
    "message": "Rhaid i''r lled a''r uchder fod yn rhifau"
  },
  "width_x_height_px_ff3ccb93": { "message": "{ width } x { height }px" },
  "wiki_home_9cd54d0": { "message": "Hafan Wici" },
  "word_count_c77fe3a6": { "message": "Cyfrif Geiriau" },
  "words_b448b7d5": { "message": "Geiriau" },
  "wreath_product_200b38ef": { "message": "Lluoswm Torch" },
  "xi_149681d0": { "message": "Xi" },
  "yes_dde87d5": { "message": "Iawn" },
  "you_have_unsaved_changes_in_the_icon_maker_tray_do_e8cf5f1b": {
    "message": "Mae gennych chi newidiadau heb eu cadw yn yr ardal Gwneuthurwr Eiconau. Ydych chi am fwrw ymlaen heb gadw’r newidiadau hyn?"
  },
  "you_may_need_to_adjust_additional_headings_to_main_975f0eee": {
    "message": "Efallai y bydd angen i chi addasu penawdau ychwanegol i gynnal hierarchaeth y dudalen."
  },
  "you_may_not_upload_an_empty_file_11c31eb2": {
    "message": "Chewch chi ddim llwytho ffeil wag i fyny."
  },
  "your_image_has_been_compressed_for_icon_maker_imag_2e45cd91": {
    "message": "Mae eich delwedd wedi''i chywasgu ar gyfer Gwneuthurwr Eiconau. Fydd delweddau sy’n llai na { size } ddim yn cael eu cywasgu."
  },
  "your_microphone_is_blocked_in_the_browser_settings_42af0ddc": {
    "message": "Mae eich microffon wedi’i flocio yng ngosodiadau’r porwr."
  },
  "your_webcam_and_microphone_are_blocked_in_the_brow_73357dc6": {
    "message": "Mae eich microffon a’ch gwe-gamera wedi’u blocio yng ngosodiadau’r porwr."
  },
  "your_webcam_is_blocked_in_the_browser_settings_7f638128": {
    "message": "Mae eich gwe-gamera wedi’i flocio yng ngosodiadau’r porwr."
  },
  "your_webcam_may_already_be_in_use_6cd64c25": {
    "message": "Efallai bod eich gwe-gamera yn cael ei ddefnyddio’n barod."
  },
  "zeta_5ef24f0e": { "message": "Zeta" },
  "zoom_f3e54d69": { "message": "Zoom" },
  "zoom_in_image_bb97d4f": { "message": "Nesáu at y ddelwedd" },
  "zoom_out_image_d0a0a2ec": { "message": "Pellhau o’r ddelwedd" }
}


formatMessage.addLocale({cy: locale})
