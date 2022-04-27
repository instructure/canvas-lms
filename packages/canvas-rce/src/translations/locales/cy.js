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
  "add_8523c19b": { "message": "Ychwanegu" },
  "add_another_f4e50d57": { "message": "Ychwanegu un arall" },
  "add_cc_subtitles_55f0394e": { "message": "Ychwanegu CC/Is-deitlau" },
  "add_image_60b2de07": { "message": "Ychwanegu Delwedd" },
  "align_11050992": { "message": "Alinio" },
  "align_center_ca078feb": { "message": "Alinio i’r canol" },
  "align_left_e9f1f93b": { "message": "Alinio i’r chwith" },
  "align_right_9bad3ac1": { "message": "Alinio i’r dde" },
  "alignment_and_lists_5cebcb69": { "message": "Aliniad a Rhestrau" },
  "all_4321c3a1": { "message": "Y cyfan" },
  "all_apps_a50dea49": { "message": "Pob Ap" },
  "alphabetical_55b5b4e0": { "message": "Yn nhrefn yr wyddor" },
  "alt_text_611fb322": { "message": "Testun Amgen" },
  "an_error_occured_reading_the_file_ff48558b": {
    "message": "Gwall wrth ddarllen y ffeil"
  },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "Gwall wrth wneud cais ar gyfer y rhwydwaith"
  },
  "an_error_occurred_uploading_your_media_71f1444d": {
    "message": "Gwall wrth lwytho eich cyfryngau i fyny."
  },
  "announcement_list_da155734": { "message": "Rhestr Cyhoeddiadau" },
  "announcements_a4b8ed4a": { "message": "Cyhoeddiadau" },
  "apply_781a2546": { "message": "Rhoi ar waith" },
  "apply_changes_to_all_instances_of_this_icon_maker__2642f466": {
    "message": "Defnyddio''r newidiadau ar bob enghraifft o’r Eicon Gwneuthurwr Eiconau hwn yn y Cwrs."
  },
  "apps_54d24a47": { "message": "Apiau" },
  "arrows_464a3e54": { "message": "Saethau" },
  "art_icon_8e1daad": { "message": "Eicon Celf" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Bydd y gymhareb agwedd yn cael ei chadw"
  },
  "assignments_1e02582c": { "message": "Aseiniadau" },
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
  "basic_554cdc0a": { "message": "Sylfaenol" },
  "below_81d4dceb": { "message": "O dan" },
  "black_4cb01371": { "message": "Black" },
  "blue_daf8fea9": { "message": "Glas" },
  "bottom_third_5f5fec1d": { "message": "Traean Isaf" },
  "brick_f2656265": { "message": "Bric" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "Canslo" },
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
  "close_d634289d": { "message": "Cau" },
  "closed_caption_file_must_be_less_than_maxkb_kb_5880f752": {
    "message": "Rhaid i ffeiliau capsiynau caeedig fod yn llai na { maxKb } kb"
  },
  "closed_captions_subtitles_e6aaa016": {
    "message": "Capsiynau Caeedig/Isdeitlau"
  },
  "collaborations_5c56c15f": { "message": "Cydweithrediadau" },
  "collapse_to_hide_types_1ab46d2e": {
    "message": "Crebachu i guddio { types }"
  },
  "color_picker_6b359edf": { "message": "Dewisydd Lliw" },
  "color_picker_colorname_selected_ad4cf400": {
    "message": "Dewisydd Lliw ({ colorName } wedi’i ddewis)"
  },
  "computer_1d7dfa6f": { "message": "Cyfrifiadur" },
  "content_1440204b": { "message": "Cynnwys" },
  "content_is_still_being_uploaded_if_you_continue_it_8f06d0cb": {
    "message": "Mae cynnwys wrthi''n cael ei llwytho i fyny, os byddwch chi''n parhau ni fydd yn cael ei blannu''n gywir."
  },
  "content_subtype_5ce35e88": { "message": "Is-fath o Gynnwys" },
  "content_type_2cf90d95": { "message": "Math o Gynnwys" },
  "copyright_holder_66ee111": { "message": "Perchennog yr Hawlfraint:" },
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
  "current_image_f16c249c": { "message": "Delwedd Bresennol" },
  "custom_6979cd81": { "message": "Personol" },
  "cyan_c1d5f68a": { "message": "Cyan" },
  "date_added_ed5ad465": { "message": "Dyddiad Ychwanegu" },
  "decorative_image_3c28aa7d": { "message": "Delwedd addurniadol" },
  "decrease_indent_de6343ab": { "message": "Lleihau mewnoliad" },
  "deep_purple_bb3e2907": { "message": "Porffor Tywyll" },
  "default_bulleted_unordered_list_47079da8": {
    "message": "rhestr ddiofyn o bwyntiau bwled sydd ddim mewn trefn"
  },
  "default_numerical_ordered_list_48dd3548": {
    "message": "rhestr ddiofyn o rifau sydd mewn trefn"
  },
  "delimiters_4db4840d": { "message": "Amffinyddion" },
  "describe_the_image_e65d2e32": { "message": "(Disgrifio''r ddelwedd)" },
  "describe_the_video_2fe8f46a": { "message": "(Disgrifiwch y fideo)" },
  "details_98a31b68": { "message": "Manylion" },
  "diamond_b8dfe7ae": { "message": "Diemwnt" },
  "dimensions_45ddb7b7": { "message": "Dimensiynau" },
  "directionality_26ae9e08": { "message": "Cyfeirioldeb" },
  "directly_edit_latex_b7e9235b": { "message": "Golygu LaTeX yn Uniongyrchol" },
  "discussions_a5f96392": { "message": "Trafodaethau" },
  "discussions_index_6c36ced": { "message": "Mynegai Trafodaethau" },
  "display_options_315aba85": { "message": "Dangos Opsiynau" },
  "display_text_link_opens_in_a_new_tab_75e9afc9": {
    "message": "Dangos Dolen Testun (Yn agor mewn tab newydd)"
  },
  "document_678cd7bf": { "message": "Dogfen" },
  "documents_81393201": { "message": "Dogfennau" },
  "done_54e3d4b6": { "message": "Wedi gorffen" },
  "drag_a_file_here_1bf656d5": { "message": "Llusgwch ffeil yma" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "Gallwch lusgo a gollwng, neu glicio i bori drwy’ch cyfrifiadur"
  },
  "drag_handle_use_up_and_down_arrows_to_resize_e29eae5c": {
    "message": "Dolen lusgo. Defnyddiwch y saethau i fyny ac i lawr i newid maint"
  },
  "due_multiple_dates_cc0ee3f5": { "message": "Erbyn: Mwy nag un dyddiad" },
  "due_when_7eed10c6": { "message": "Erbyn: { when }" },
  "edit_c5fbea07": { "message": "Golygu" },
  "edit_equation_f5279959": { "message": "Golygu Hafaliad" },
  "edit_existing_button_icon_3d0277bd": {
    "message": "Golygu Botwm / Eicon Cyfredol"
  },
  "edit_icon_2c6b0e91": { "message": "Golygu Eicon" },
  "edit_link_7f53bebb": { "message": "Golygu Dolen" },
  "editor_statusbar_26ac81fc": { "message": "Bar Statws Golygydd" },
  "embed_828fac4a": { "message": "Plannu" },
  "embed_code_314f1bd5": { "message": "Plannu Cod" },
  "embed_image_1080badc": { "message": "Plannu Delwedd" },
  "embed_video_a97a64af": { "message": "Plannu Fideo" },
  "embedded_content_aaeb4d3d": { "message": "cynnwys wedi''i blannu" },
  "engineering_icon_f8f3cf43": { "message": "Eicon Peirianeg" },
  "english_icon_25bfe845": { "message": "Eicon Saesneg" },
  "enter_at_least_3_characters_to_search_4f037ee0": {
    "message": "Rhowch o leiaf 3 nod i chwilio"
  },
  "equation_1c5ac93c": { "message": "Hafaliad" },
  "equation_editor_39fbc3f1": { "message": "Golygydd Hafaliadau" },
  "expand_preview_by_default_2abbf9f8": {
    "message": "Ehangu rhagolwg yn ddiofyn"
  },
  "expand_to_see_types_f5d29352": { "message": "Ehangu i weld { types }" },
  "external_links_3d9f074e": { "message": "Dolenni Allanol" },
  "external_tools_6e77821": { "message": "Adnoddau Allanol" },
  "extra_large_b6cdf1ff": { "message": "Mawr Iawn" },
  "extra_small_9ae33252": { "message": "Bach Iawn" },
  "extracurricular_icon_67c8ca42": { "message": "Eicon Allgwricwlar" },
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
  "focus_element_options_toolbar_18d993e": {
    "message": "Canolbwyntio bar offer opsiynau elfen"
  },
  "folder_tree_fbab0726": { "message": "Coeden ffolderi" },
  "format_4247a9c5": { "message": "Fformat" },
  "formatting_5b143aa8": { "message": "Fformatio" },
  "found_auto_saved_content_3f6e4ca5": {
    "message": "Wedi dod o hyd i gynnwys sydd wedi’i gadw’n awtomatig"
  },
  "found_count_plural_0_results_one_result_other_resu_46aeaa01": {
    "message": "Wedi canfod { count, plural,\n     =0 {# canlyniad}\n    one {# canlyniad}\n  other {# canlyniad}\n}"
  },
  "fullscreen_873bf53f": { "message": "Sgrin Lawn" },
  "generating_preview_45b53be0": { "message": "Wrthi’n creu rhagolwg..." },
  "go_to_the_editor_s_menubar_e6674c81": {
    "message": "Ewch i far dewislen y golygydd"
  },
  "go_to_the_editor_s_toolbar_a5cb875f": {
    "message": "Ewch i far offer y golygydd"
  },
  "grades_a61eba0a": { "message": "Graddau" },
  "greek_65c5b3f7": { "message": "Groeg" },
  "green_15af4778": { "message": "Gwyrdd" },
  "grey_a55dceff": { "message": "Llwyd" },
  "group_documents_8bfd6ae6": { "message": "Dogfennau Grŵp" },
  "group_files_4324f3df": { "message": "Ffeiliau Grŵp" },
  "group_files_82e5dcdb": { "message": "Ffeiliau grŵp" },
  "group_images_98e0ac17": { "message": "Delweddau Grŵp" },
  "group_links_9493129e": { "message": "Dolenni Grwpiau" },
  "group_media_2f3d128a": { "message": "Cyfryngau Grŵp" },
  "group_navigation_99f191a": { "message": "Dewislen Crwydro Grwpiau" },
  "heading_2_5b84eed2": { "message": "Pennawd 2" },
  "heading_3_2c83de44": { "message": "Pennawd 3" },
  "heading_4_b2e74be7": { "message": "Pennawd 4" },
  "health_icon_8d292eb5": { "message": "Eicon Iechyd" },
  "height_69b03e15": { "message": "Uchder" },
  "hexagon_d8468e0d": { "message": "Hecsagon" },
  "hide_description_bfb5502e": { "message": "Cuddio disgrifiad" },
  "hide_title_description_caf092ef": {
    "message": "Cuddio disgrifiad { title }"
  },
  "home_351838cd": { "message": "Hafan" },
  "html_code_editor_fd967a44": { "message": "golygydd cod html" },
  "html_editor_fb2ab713": { "message": "Golygydd HTML" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Rydw i wedi cael caniatâd i ddefnyddio’r ffeil hon."
  },
  "i_hold_the_copyright_71ee91b1": { "message": "Fi sydd biau’r hawlfraint" },
  "icon_color_b86dd6d6": { "message": "Lliw Eicon" },
  "icon_maker_icons_cc560f7e": { "message": "Eiconau’r Gwneuthurwr Eiconau" },
  "icon_outline_e978dc0c": { "message": "Amlinell yr Eicon" },
  "icon_outline_size_33f39b86": { "message": "Maint Amlinell yr Eicon" },
  "icon_shape_30b61e7": { "message": "Siâp yr Eicon" },
  "icon_size_9353edea": { "message": "Maint yr Eicon" },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "Os na fyddwch chi’n dewis hawliau defnyddio yn awr, bydd y ffeil hon yn cael ei dad-gyhoeddi ar ôl iddi gael ei llwytho i fyny."
  },
  "image_8ad06": { "message": "Delwedd" },
  "image_options_5412d02c": { "message": "Opsiynau Delwedd" },
  "image_options_tray_90a46006": { "message": "Ardal Opsiynau Delwedd" },
  "image_to_crop_3a34487d": { "message": "Delwedd i''w thocio" },
  "images_7ce26570": { "message": "Delweddau" },
  "increase_indent_6d550a4a": { "message": "Cynyddu mewnoliad" },
  "indigo_2035fc55": { "message": "Indigo" },
  "insert_593145ef": { "message": "Mewnosod" },
  "insert_equella_links_49a8dacd": { "message": "Mewnosod Dolenni Equella" },
  "insert_link_6dc23cae": { "message": "Mewnosod Dolen" },
  "insert_math_equation_57c6e767": {
    "message": "Mewnosod hafaliad mathemategol"
  },
  "invalid_file_c11ba11": { "message": "Ffeil Annilys" },
  "invalid_file_type_881cc9b2": { "message": "Math o ffeil annilys" },
  "invalid_url_cbde79f": { "message": "URL annilys" },
  "keyboard_shortcuts_ed1844bd": { "message": "Bysellau Hwylus" },
  "language_arts_icon_a798b0f8": { "message": "Eicon Celfyddydau Iaith" },
  "languages_icon_9d20539": { "message": "Eicon Ieithoedd" },
  "large_9c5e80e7": { "message": "Mawr" },
  "left_to_right_e9b4fd06": { "message": "Chwith i’r Dde" },
  "library_icon_ae1e54cf": { "message": "Eicon Llyfrgell" },
  "light_blue_5374f600": { "message": "Glas golau" },
  "link_7262adec": { "message": "Dolen" },
  "link_options_a16b758b": { "message": "Opsiynau Dolen" },
  "links_14b70841": { "message": "Dolenni" },
  "load_more_35d33c7": { "message": "Llwytho Mwy" },
  "load_more_results_460f49a9": { "message": "Llwytho mwy o ganlyniadau" },
  "loading_25990131": { "message": "Wrthi’n llwytho..." },
  "loading_bde52856": { "message": "Wrthi’n llwytho" },
  "loading_failed_b3524381": { "message": "Wedi methu llwytho..." },
  "loading_failed_e6a9d8ef": { "message": "Wedi methu llwytho." },
  "loading_folders_d8b5869e": { "message": "Wrthi’n llwytho ffolderi" },
  "loading_please_wait_d276220a": {
    "message": "Wrthi’n llwytho, arhoswch funud"
  },
  "loading_preview_9f077aa1": { "message": "Wrthi’n llwytho rhagolwg" },
  "locked_762f138b": { "message": "Wedi Cloi" },
  "magenta_4a65993c": { "message": "Magenta" },
  "math_icon_ad4e9d03": { "message": "Eicon Mathemateg" },
  "media_af190855": { "message": "Cyfryngau" },
  "media_file_is_processing_please_try_again_later_58a6d49": {
    "message": "Ffeil cyfryngau’n cael ei phrosesu Rhowch gynnig arall arni rywbryd eto."
  },
  "medium_5a8e9ead": { "message": "Cyfrwng" },
  "middle_27dc1d5": { "message": "Canol" },
  "misc_3b692ea7": { "message": "Amrywiol" },
  "miscellaneous_e9818229": { "message": "Amrywiol" },
  "modules_c4325335": { "message": "Modiwlau" },
  "multi_color_image_63d7372f": { "message": "Delwedd mwy nag un lliw" },
  "music_icon_4db5c972": { "message": "Eicon Cerddoriaeth" },
  "must_be_at_least_percentage_22e373b6": {
    "message": "Yn gorfod bod yn { percentage }% o leiaf"
  },
  "must_be_at_least_width_x_height_px_41dc825e": {
    "message": "Yn gorfod bod o leiaf { width } x { height }px"
  },
  "my_files_2f621040": { "message": "Fy ffeiliau" },
  "name_1aed4a1b": { "message": "Enw" },
  "name_color_ceec76ff": { "message": "{ name } ({ color })" },
  "navigate_through_the_menu_or_toolbar_415a4e50": {
    "message": "Llywiwch trwy''r ddewislen neu''r bar offer"
  },
  "next_page_d2a39853": { "message": "Tudalen Nesaf" },
  "no_e16d9132": { "message": "Na" },
  "no_file_chosen_9a880793": { "message": "Dim ffeil wedi’i dewis" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Does dim rhagolwg ar gael ar gyfer y ffeil hon."
  },
  "no_results_940393cf": { "message": "Dim canlyniadau." },
  "no_results_found_for_filterterm_ad1b04c8": {
    "message": "Heb ddod o hyd i ganlyniadau ar gyfer { filterTerm }"
  },
  "no_results_found_for_term_1564c08e": {
    "message": "Heb ddod o hyd i ganlyniadau ar gyfer { term }."
  },
  "none_3b5e34d2": { "message": "Dim" },
  "none_selected_b93d56d2": { "message": "Dim un wedi’i ddewis" },
  "octagon_e48be9f": { "message": "Octagon" },
  "olive_6a3e4d6b": { "message": "Olive" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "Agor y ddeialog bysellau hwylus"
  },
  "open_title_application_fd624fc5": { "message": "Agor rhaglen { title }" },
  "operators_a2ef9a93": { "message": "Gweithredyddion" },
  "orange_81386a62": { "message": "Oren" },
  "ordered_and_unordered_lists_cfadfc38": {
    "message": "Rhestrau Mewn Trefn a Rhestrau Ddim Mewn Trefn"
  },
  "other_editor_shortcuts_may_be_found_at_404aba4a": {
    "message": "Mae bysellau hwylus golygu eraill i''w cael yn"
  },
  "p_is_not_a_valid_protocol_which_must_be_ftp_http_h_adf13fc2": {
    "message": "Dydy { p } ddim yn brotocol dilys, rhaid iddo fod yn ftp, http, https, mailto, skype, tel neu gellir ei hepgor"
  },
  "pages_e5414c2c": { "message": "Tudalennau" },
  "paragraph_5e5ad8eb": { "message": "Paragraff" },
  "pentagon_17d82ea3": { "message": "Pentagon" },
  "people_b4ebb13c": { "message": "Pobl" },
  "percentage_34ab7c2c": { "message": "Canran" },
  "percentage_must_be_a_number_8033c341": {
    "message": "Mae canran yn gorfod bod yn rhif"
  },
  "performing_arts_icon_f3497486": {
    "message": "Eicon Celfyddydau Perfformio"
  },
  "physical_education_icon_d7dffd3e": { "message": "Eicon Addysg Gorfforol" },
  "pink_68ad45cb": { "message": "Pinc" },
  "pixels_52ece7d1": { "message": "Picseli" },
  "posted_when_a578f5ab": { "message": "Wedi postio: { when }" },
  "preformatted_d0670862": { "message": "Wedi''i fformatio’n barod" },
  "pretty_html_editor_28748756": { "message": "Golygydd HTML Hardd" },
  "preview_53003fd2": { "message": "Rhagolwg" },
  "preview_in_overlay_ed772c46": { "message": "Rhagolwg mewn troshaen" },
  "preview_inline_9787330": { "message": "Rhagolwg mewn llinell" },
  "previous_page_928fc112": { "message": "Tudalen Flaenorol" },
  "protocol_must_be_ftp_http_https_mailto_skype_tel_o_73beb4f8": {
    "message": "Rhaid i’r protocol fod yn ftp, http, https, mailto, skype, tel neu gellir ei hepgor"
  },
  "published_c944a23d": { "message": "wedi cyhoeddi" },
  "published_when_302d8e23": { "message": "Wedi cyhoeddi: { when }" },
  "pumpkin_904428d5": { "message": "Pumpkin" },
  "purple_7678a9fc": { "message": "Porffor" },
  "quizzes_7e598f57": { "message": "Cwisiau" },
  "raw_html_editor_e3993e41": { "message": "Golygydd HTML Crai" },
  "record_7c9448b": { "message": "Recordio" },
  "record_upload_media_5fdce166": {
    "message": "Recordio Cyfryngau/Llwytho Cyfryngau i Fyny"
  },
  "red_8258edf3": { "message": "Coch" },
  "relationships_6602af70": { "message": "Perthynas" },
  "religion_icon_246e0be1": { "message": "Eicon Crefydd" },
  "remove_link_d1f2f4d0": { "message": "Tynnu Dolen" },
  "resize_ec83d538": { "message": "Ailfeintio" },
  "restore_auto_save_deccd84b": { "message": "Adfer cadw’n awtomatig?" },
  "rich_content_editor_2708ef21": { "message": "Golygydd Cynnwys Cyfoethog" },
  "rich_text_area_press_alt_0_for_rich_content_editor_9d23437f": {
    "message": "Ardal Testun Cyfoethog. Pwyswch ALT+0 ar gyfer bysellau cyflym y Golygydd Cynnwys Cyfoethog."
  },
  "right_to_left_9cfb092a": { "message": "De i’r Chwith" },
  "sadly_the_pretty_html_editor_is_not_keyboard_acces_50da7665": {
    "message": "Yn anffodus, dydy’r golygydd HTML hardd ddim ar gael drwy fysellfwrdd.  Cael mynediad at y golygydd HTML crai yma."
  },
  "save_11a80ec3": { "message": "Cadw" },
  "saved_icon_maker_icons_df86e2a1": {
    "message": "Eiconau’r Gwneuthurwr Eiconau a Gadwyd"
  },
  "search_280d00bd": { "message": "Chwilio" },
  "search_term_b2d2235": { "message": "Term Chwilio" },
  "select_crop_shape_d441feeb": { "message": "Dewis siâp tocio" },
  "select_language_7c93a900": { "message": "Dewis Iaith" },
  "selected_274ce24f": { "message": "Wedi dewis" },
  "shift_o_to_open_the_pretty_html_editor_55ff5a31": {
    "message": "Shift-O i agor y golygydd html hardd."
  },
  "show_audio_options_b489926b": { "message": "Dangos opsiynau sain" },
  "show_image_options_1e2ecc6b": { "message": "Dangos opsiynau delwedd" },
  "show_link_options_545338fd": { "message": "Dangos opsiynau dolen" },
  "show_video_options_6ed3721a": { "message": "Dangos opsiynau fideo" },
  "single_color_image_4e5d4dbc": { "message": "Delwedd un lliw" },
  "single_color_image_color_95fa9a87": { "message": "Lliw Delwedd Un Lliw" },
  "size_b30e1077": { "message": "Maint" },
  "size_of_caption_file_is_greater_than_the_maximum_m_bff5f86e": {
    "message": "Mae maint y ffeil capsiynau’n fwy na’r { max } kb a ganiateir ar gyfer maint y ffeil."
  },
  "small_b070434a": { "message": "Bach" },
  "something_went_wrong_89195131": { "message": "Aeth rhywbeth o’i le." },
  "something_went_wrong_and_i_don_t_know_what_to_show_e0c54ec8": {
    "message": "Aeth rhywbeth o''i le a dydw i ddim yn gwybod beth i''w ddangos i chi."
  },
  "something_went_wrong_d238c551": { "message": "Aeth rhywbeth o’i le" },
  "sort_by_e75f9e3e": { "message": "Trefnu yn ôl" },
  "square_511eb3b3": { "message": "Sgwâr" },
  "square_unordered_list_b15ce93b": {
    "message": "rhestr sgwariau sydd ddim mewn trefn"
  },
  "star_8d156e09": { "message": "Seren" },
  "steel_blue_14296f08": { "message": "Durlas" },
  "styles_2aa721ef": { "message": "Arddulliau" },
  "submit_a3cc6859": { "message": "Cyflwyno" },
  "subscript_59744f96": { "message": "Isysgrif" },
  "superscript_8cb349a2": { "message": "Uwchysgrif" },
  "supported_file_types_srt_or_webvtt_7d827ed": {
    "message": "Mathau o ffeiliau y mae modd delio â nhw: SRT neu WebVTT"
  },
  "switch_to_the_html_editor_146dfffd": {
    "message": "Newid i’r golygydd html "
  },
  "switch_to_the_rich_text_editor_63c1ecf6": {
    "message": "Newid i’r golygydd testun cyfoethog"
  },
  "syllabus_f191f65b": { "message": "Maes Llafur" },
  "tab_arrows_4cf5abfc": { "message": "TAB/Saethau" },
  "teal_f729a294": { "message": "Glaswyrdd" },
  "text_7f4593da": { "message": "Testun" },
  "text_background_color_16e61c3f": { "message": "Lliw Cefndir yTestun" },
  "text_color_acf75eb6": { "message": "Lliw''r Testun" },
  "text_position_8df8c162": { "message": "Lleoliad y Testun" },
  "text_size_887c2f6": { "message": "Maint y Testun" },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Mae’r deunydd yn y parth cyhoeddus"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Mae’r deunydd wedi''i drwyddedu o dan Creative Commons"
  },
  "the_material_is_subject_to_an_exception_e_g_fair_u_a39c8ca2": {
    "message": "Mae eithriad yn berthnasol i’r deunydd - e.e. defnydd teg, yr hawl i ddyfynnu, neu eraill o dan gyfreithiau hawlfraint perthnasol"
  },
  "the_pretty_html_editor_is_not_keyboard_accessible__d6d5d2b": {
    "message": "Dydy’r golygydd html hardd ddim ar gael drwy fysellfwrdd. Pwyswch Shift-O i agor y golygydd html crai."
  },
  "though_your_video_will_have_the_correct_title_in_t_90e427f3": {
    "message": "Er y bydd gan eich fideo y teitl cywir yn y porwr, nid ydym ni wedi gallu ei ddiweddaru yn y gronfa ddata."
  },
  "title_ee03d132": { "message": "Teitl" },
  "to_be_posted_when_d24bf7dc": { "message": "I''w Bostio: { when }" },
  "to_do_when_2783d78f": { "message": "Tasgau i’w Gwneud: { when }" },
  "toggle_summary_group_413df9ac": { "message": "Toglo grŵp { summary } " },
  "tools_2fcf772e": { "message": "Adnoddau" },
  "totalresults_results_found_numdisplayed_results_cu_a0a44975": {
    "message": "Wedi dod o hyd i { totalResults } canlyniad, { numDisplayed } canlyniad yn cael ei arddangos ar hyn o bryd"
  },
  "tray_839df38a": { "message": "Ardal" },
  "triangle_6072304e": { "message": "Triongl" },
  "type_control_f9_to_access_image_options_text_a47e319f": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau delwedd. { text }"
  },
  "type_control_f9_to_access_link_options_text_4ead9682": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau dolen. { text }"
  },
  "type_control_f9_to_access_table_options_text_92141329": {
    "message": "teipiwch Control F9 i gael mynediad at yr opsiynau tabl. { text }"
  },
  "unpublished_dfd8801": { "message": "heb gyhoeddi" },
  "untitled_efdc2d7d": { "message": "dideitl" },
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
  "uppercase_roman_numeral_ordered_list_853f292b": {
    "message": "rhestr mewn trefn o rifolion Rhufeinig mewn priflythrennau"
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
  "video_options_24ef6e5d": { "message": "Opsiynau Fideo" },
  "video_options_tray_3b9809a5": { "message": "Ardal Opsiynau Fideo" },
  "video_player_for_9e7d373b": { "message": "Chwaraewr fideo ar gyfer " },
  "video_player_for_title_ffd9fbc4": {
    "message": "Chwaraewr fideo ar gyfer { title }"
  },
  "view_ba339f93": { "message": "Gweld" },
  "view_description_30446afc": { "message": "Gweld disgrifiad" },
  "view_keyboard_shortcuts_34d1be0b": { "message": "Gweld bysellau hwylus" },
  "view_predefined_colors_92f5db39": {
    "message": "Gweld lliwiau wedi’u diffinio ymlaen llaw"
  },
  "view_title_description_67940918": {
    "message": "Gweld disgrifiad { title }"
  },
  "white_87fa64fd": { "message": "Gwyn" },
  "width_492fec76": { "message": "Lled" },
  "width_and_height_must_be_numbers_110ab2e3": {
    "message": "Rhaid i''r lled a''r uchder fod yn rhifau"
  },
  "width_x_height_px_ff3ccb93": { "message": "{ width } x { height }px" },
  "wiki_home_9cd54d0": { "message": "Hafan Wici" },
  "yes_dde87d5": { "message": "Iawn" },
  "you_may_not_upload_an_empty_file_11c31eb2": {
    "message": "Chewch chi ddim llwytho ffeil wag i fyny."
  },
  "zoom_in_image_bb97d4f": { "message": "Nesáu at y ddelwedd" },
  "zoom_out_image_d0a0a2ec": { "message": "Pellhau o’r ddelwedd" }
}


formatMessage.addLocale({cy: locale})
