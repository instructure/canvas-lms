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
import '../tinymce/hu_HU'

const locale = {
  "accessibility_checker_b3af1f6c": { "message": "Akadálymentesség ellenőrző" },
  "add_8523c19b": { "message": "Hozzáadás" },
  "add_another_f4e50d57": { "message": "Másik hozzáadása" },
  "add_cc_subtitles_55f0394e": { "message": "Felirat hozzáadása" },
  "align_11050992": { "message": "Igazítás" },
  "align_center_ca078feb": { "message": "Középre igazítás" },
  "align_left_e9f1f93b": { "message": "Balra igazítás" },
  "align_right_9bad3ac1": { "message": "Jobbra igazítás" },
  "alignment_and_lists_5cebcb69": { "message": "Igazítások és listák" },
  "all_4321c3a1": { "message": "Összes" },
  "alphabetical_55b5b4e0": { "message": "Betűrendben" },
  "alt_text_611fb322": { "message": "Alternatív szöveg" },
  "an_error_occured_reading_the_file_ff48558b": {
    "message": "Hiba történt a fájl olvasásakor"
  },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "Hiba történt egy hálózati kérelem létrehozásakor"
  },
  "an_error_occurred_uploading_your_media_71f1444d": {
    "message": "Hiba történt a médiád feltöltése során."
  },
  "announcement_list_da155734": { "message": "Hirdetménylista" },
  "announcements_a4b8ed4a": { "message": "Hirdetmények" },
  "apply_781a2546": { "message": "Alkalmazás" },
  "apps_54d24a47": { "message": "Alkalmazások" },
  "arrows_464a3e54": { "message": "Nyilak" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Képarány megtartása"
  },
  "assignments_1e02582c": { "message": "Feladatok" },
  "attributes_963ba262": { "message": "Attribútumok" },
  "audio_player_for_title_20cc70d": {
    "message": "Audio lejátszó ehhez: { title }"
  },
  "auto_saved_content_exists_would_you_like_to_load_t_fee528f2": {
    "message": "Van automatikusan mentett tartalom. Szeretné inkább azt betölteni?"
  },
  "available_folders_694d0436": { "message": "Elérhető mappák" },
  "basic_554cdc0a": { "message": "Alap" },
  "blue_daf8fea9": { "message": "Kék" },
  "brick_f2656265": { "message": "Tégla" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "Mégse" },
  "choose_caption_file_9c45bc4e": { "message": "Feliratfájl választása" },
  "choose_usage_rights_33683854": {
    "message": "Válasszon a felhasználói jogokból..."
  },
  "circle_unordered_list_9e3a0763": { "message": "rendezetlen lista körökkel" },
  "clear_2084585f": { "message": "Törlés" },
  "clear_selected_file_82388e50": { "message": "Kiválasztott fájl törlése" },
  "clear_selected_file_filename_2fe8a58e": {
    "message": "Kiválasztott fájl törlése: { filename }"
  },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Kattintson a { imageName } kép beágyazásához."
  },
  "click_to_hide_preview_3c707763": {
    "message": "Kattintson az előnézet elrejtéséhez!"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Link beszúrásához kattintson ide."
  },
  "click_to_show_preview_faa27051": { "message": "Kattintson az előnézethez!" },
  "close_a_menu_or_dialog_also_returns_you_to_the_edi_739079e6": {
    "message": "Menü vagy párbeszéd bezárása. Ez visszavisz a szerkesztő területre."
  },
  "close_d634289d": { "message": "Bezár" },
  "closed_captions_subtitles_e6aaa016": { "message": "Zárt feliratok" },
  "collaborations_5c56c15f": { "message": "Együttműködés" },
  "collapse_to_hide_types_1ab46d2e": {
    "message": "Összecsukás az elrejtéshez { types }"
  },
  "computer_1d7dfa6f": { "message": "Számítógép" },
  "content_1440204b": { "message": "Tartalom" },
  "content_is_still_being_uploaded_if_you_continue_it_8f06d0cb": {
    "message": "A tartalom feltöltése még folyamatban van. Ha folytatja, akkor nem lesz rendesen beágyazva."
  },
  "content_subtype_5ce35e88": { "message": "Tartalom altípusa" },
  "content_type_2cf90d95": { "message": "Tartalom típusa " },
  "copyright_holder_66ee111": { "message": "Jog tulajdonosa:" },
  "count_plural_0_0_words_one_1_word_other_words_acf32eca": {
    "message": "{ count, plural,\n     =0 {0 szó}\n    one {1 szó}\n  other {# szó}\n}"
  },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {# elem betöltve}\n  other {# elem betöltve}\n}"
  },
  "course_documents_104d76e0": { "message": "Kurzus dokumentumai" },
  "course_files_62deb8f8": { "message": "Kurzusfájlok" },
  "course_files_a31f97fc": { "message": "Tanfolyam fájlok" },
  "course_images_f8511d04": { "message": "Kurzus képei" },
  "course_links_b56959b9": { "message": "Kurzus linkjei" },
  "course_media_ec759ad": { "message": "Kurzus média" },
  "course_navigation_dd035109": { "message": "Kurzusnavigáció" },
  "creative_commons_license_725584ae": {
    "message": "Creative Commons licenc:"
  },
  "custom_6979cd81": { "message": "Egyéni" },
  "cyan_c1d5f68a": { "message": "Cián" },
  "date_added_ed5ad465": { "message": "Dátum hozzáadva" },
  "decorative_image_3c28aa7d": { "message": "Dekoratív kép" },
  "decrease_indent_de6343ab": { "message": "Behúzás csökkentése" },
  "deep_purple_bb3e2907": { "message": "Sötétlila" },
  "default_bulleted_unordered_list_47079da8": {
    "message": "alapértelmezett nem rendezett lista"
  },
  "default_numerical_ordered_list_48dd3548": {
    "message": "alapértelmezett sorszámozott lista"
  },
  "delimiters_4db4840d": { "message": "Elválasztó jelek" },
  "describe_the_image_e65d2e32": { "message": "(A kép leírása)" },
  "describe_the_video_2fe8f46a": { "message": "(A videó leírása)" },
  "details_98a31b68": { "message": "Részletek" },
  "dimensions_45ddb7b7": { "message": "Méretek" },
  "directionality_26ae9e08": { "message": "Irányítottság" },
  "discussions_a5f96392": { "message": "Fórumok" },
  "discussions_index_6c36ced": { "message": "Fórumok indexe" },
  "display_options_315aba85": { "message": "Megjelenítési beállítások" },
  "display_text_link_opens_in_a_new_tab_75e9afc9": {
    "message": "Szöveges link megjelenítése (új lapfülön jelenik meg)"
  },
  "document_678cd7bf": { "message": "Dokumentum" },
  "documents_81393201": { "message": "Dokumentumok" },
  "done_54e3d4b6": { "message": "Kész" },
  "drag_a_file_here_1bf656d5": { "message": "Húzzon ide egy fájlt" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "Húzza ide a fájlt vagy tallózza ki a számítógépen"
  },
  "drag_handle_use_up_and_down_arrows_to_resize_e29eae5c": {
    "message": "Húzza a fogantyút. Átméretezéshez használja a fel és le nyilakat."
  },
  "due_multiple_dates_cc0ee3f5": {
    "message": "Határidő: Több határidő van érvényben"
  },
  "due_when_7eed10c6": { "message": "Határidő: { when }" },
  "edit_c5fbea07": { "message": "Szerkesztés" },
  "edit_equation_f5279959": { "message": "Egyenlet szerkesztése" },
  "edit_link_7f53bebb": { "message": "Link szerkesztése" },
  "editor_statusbar_26ac81fc": { "message": "Szerkesztő állapotsor" },
  "embed_828fac4a": { "message": "Beágyaz" },
  "embed_code_314f1bd5": { "message": "Kód beágyazása" },
  "embed_image_1080badc": { "message": "Beágyazott kép" },
  "embed_video_a97a64af": { "message": "Videó beágyazása" },
  "embedded_content_aaeb4d3d": { "message": "beágyazott tartalom" },
  "enter_at_least_3_characters_to_search_4f037ee0": {
    "message": "Legalább 3 karaktert be kell írni a kereséshez"
  },
  "equation_1c5ac93c": { "message": "Egyenlet" },
  "expand_to_see_types_f5d29352": {
    "message": "Kiterjesztés a(z) { types } megtekintéséhez"
  },
  "external_links_3d9f074e": { "message": "Külső linkek" },
  "external_tools_6e77821": { "message": "Külső eszközök" },
  "extra_large_b6cdf1ff": { "message": "Extra nagy" },
  "file_url_c12b64be": { "message": "Fájl URL" },
  "filename_file_icon_602eb5de": { "message": "{ filename } fájl ikon" },
  "filename_image_preview_6cef8f26": { "message": "{ filename } kép előnézet" },
  "filename_text_preview_e41ca2d8": {
    "message": "{ filename } szöveg előnézet"
  },
  "files_c300e900": { "message": "Fájlok" },
  "files_index_af7c662b": { "message": "Fájlok indexe" },
  "focus_element_options_toolbar_18d993e": {
    "message": "Az elem opciók eszköztár fókuszba helyezése"
  },
  "folder_tree_fbab0726": { "message": "Könyvtárfa" },
  "format_4247a9c5": { "message": "Formátum" },
  "formatting_5b143aa8": { "message": "Formázás" },
  "found_auto_saved_content_3f6e4ca5": {
    "message": "Automatikusan mentett tartalmat találtunk"
  },
  "found_count_plural_0_results_one_result_other_resu_46aeaa01": {
    "message": "{ count, plural,\n     =0 {# eredmény}\n    one {# eredmény}\n  other {# eredmény}\n} található"
  },
  "fullscreen_873bf53f": { "message": "Teljes képernyő" },
  "generating_preview_45b53be0": { "message": "Előnézet generálása... " },
  "go_to_the_editor_s_menubar_e6674c81": {
    "message": "Ugrás a szerkesztő menüsorhoz"
  },
  "go_to_the_editor_s_toolbar_a5cb875f": {
    "message": "Ugrás a szerkesztő eszköztárhoz"
  },
  "grades_a61eba0a": { "message": "Értékelések" },
  "greek_65c5b3f7": { "message": "Görög" },
  "green_15af4778": { "message": "Zöld" },
  "group_documents_8bfd6ae6": { "message": "Csoport dokumentumok" },
  "group_files_4324f3df": { "message": "Csoportfájlok" },
  "group_files_82e5dcdb": { "message": "Csoportfájlok" },
  "group_images_98e0ac17": { "message": "Csoport képek" },
  "group_links_9493129e": { "message": "Csoport hivatkozások" },
  "group_media_2f3d128a": { "message": "Csoport média" },
  "group_navigation_99f191a": { "message": "Csoportnavigáció" },
  "heading_2_5b84eed2": { "message": "Címsor 2" },
  "heading_3_2c83de44": { "message": "Címsor 3" },
  "heading_4_b2e74be7": { "message": "Címsor 4" },
  "height_69b03e15": { "message": "Magasság" },
  "home_351838cd": { "message": "Kezdőlap" },
  "html_editor_fb2ab713": { "message": "HTML szerkesztő" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Szereztem jogosultságot ennek a fájlnak a használatához."
  },
  "i_hold_the_copyright_71ee91b1": { "message": "Megtartom a szerzői jogot" },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "Ha nem választja ki most a felhasználási jogokat, a fájl nem lesz publikálva a feltöltés után."
  },
  "image_8ad06": { "message": "Kép" },
  "image_options_5412d02c": { "message": "Képbeállítások" },
  "image_options_tray_90a46006": { "message": "Képbeállítások tálca" },
  "images_7ce26570": { "message": "Képek" },
  "increase_indent_6d550a4a": { "message": "Behúzás növelése" },
  "indigo_2035fc55": { "message": "Indigókék" },
  "insert_593145ef": { "message": "Beszúrás" },
  "insert_equella_links_49a8dacd": { "message": "Equella linkek beszúrása" },
  "insert_link_6dc23cae": { "message": "Link beszúrása" },
  "insert_math_equation_57c6e767": {
    "message": "Matematikai képlet beszúrása"
  },
  "invalid_file_c11ba11": { "message": "Érvénytelen fájl." },
  "invalid_file_type_881cc9b2": { "message": "Érvénytelen fájltípus" },
  "invalid_url_cbde79f": { "message": "Helytelen webcím" },
  "keyboard_shortcuts_ed1844bd": { "message": "Billentyűparancsok" },
  "large_9c5e80e7": { "message": "Nagy" },
  "left_to_right_e9b4fd06": { "message": "Balról jobbra" },
  "light_blue_5374f600": { "message": "Világoskék" },
  "link_7262adec": { "message": "Hivatkozás" },
  "link_options_a16b758b": { "message": "Link beállításai" },
  "links_14b70841": { "message": "Linkek" },
  "load_more_35d33c7": { "message": "Továbbiak betöltése" },
  "load_more_results_460f49a9": { "message": "További eredmények betöltése" },
  "loading_25990131": { "message": "Betöltés..." },
  "loading_bde52856": { "message": "Töltődik" },
  "loading_failed_b3524381": { "message": "Sikertelen betöltés..." },
  "loading_failed_e6a9d8ef": { "message": "Sikertelen betöltés." },
  "loading_folders_d8b5869e": { "message": "Mappák betöltése" },
  "loading_please_wait_d276220a": { "message": "Betöltés, kérjük, várjon" },
  "locked_762f138b": { "message": "Zárolva" },
  "magenta_4a65993c": { "message": "Magenta" },
  "media_af190855": { "message": "Média" },
  "medium_5a8e9ead": { "message": "Közepes" },
  "misc_3b692ea7": { "message": "Egyéb" },
  "miscellaneous_e9818229": { "message": "Egyéb" },
  "modules_c4325335": { "message": "Modulok" },
  "must_be_at_least_width_x_height_px_41dc825e": {
    "message": "Legalább { width } x { height } pixel szükséges"
  },
  "my_files_2f621040": { "message": "Fájljaim" },
  "name_1aed4a1b": { "message": "Név" },
  "navigate_through_the_menu_or_toolbar_415a4e50": {
    "message": "Navigáljon a menün vagy eszköztáron át"
  },
  "next_page_d2a39853": { "message": "Következő oldal" },
  "no_e16d9132": { "message": "Nem" },
  "no_file_chosen_9a880793": { "message": "Nincs fájl kiválasztva" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Ehhez a fájlhoz nincs előnézet."
  },
  "no_results_940393cf": { "message": "Nincs eredmény." },
  "no_results_found_for_filterterm_ad1b04c8": {
    "message": "Nincs találat a követezőre: { filterTerm }"
  },
  "no_results_found_for_term_1564c08e": {
    "message": "Nincs találat a követezőre: { term }."
  },
  "none_3b5e34d2": { "message": "Nincs" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "Nyissa meg a billentyűkombinációk párbeszédablakot"
  },
  "operators_a2ef9a93": { "message": "Műveletek" },
  "orange_81386a62": { "message": "Narancs" },
  "ordered_and_unordered_lists_cfadfc38": {
    "message": "Rendezett és Rendezetlen Listák"
  },
  "other_editor_shortcuts_may_be_found_at_404aba4a": {
    "message": "További szerkesztési billentyűparancsokat találhat a következő helyen"
  },
  "p_is_not_a_valid_protocol_which_must_be_ftp_http_h_adf13fc2": {
    "message": "{ p } nem egy érvényes protokoll; lehet ftp, http, https, mailto, skype, tel, vagy esetleg elhagyható"
  },
  "pages_e5414c2c": { "message": "Oldalak" },
  "paragraph_5e5ad8eb": { "message": "Bekezdés" },
  "people_b4ebb13c": { "message": "Résztvevők" },
  "percentage_34ab7c2c": { "message": "Százalék" },
  "pink_68ad45cb": { "message": "Rózsaszín" },
  "posted_when_a578f5ab": { "message": "Közzétéve: { when }" },
  "preformatted_d0670862": { "message": "Előre formázott" },
  "preview_53003fd2": { "message": "Előnézet" },
  "previous_page_928fc112": { "message": "Előző oldal" },
  "protocol_must_be_ftp_http_https_mailto_skype_tel_o_73beb4f8": {
    "message": "A protokoll lehet ftp, http, https, mailto, skype, tel, vagy esetleg elhagyható "
  },
  "published_c944a23d": { "message": "publikált" },
  "published_when_302d8e23": { "message": "Publikálva: { when }" },
  "pumpkin_904428d5": { "message": "Sütőtök" },
  "purple_7678a9fc": { "message": "Lila" },
  "quizzes_7e598f57": { "message": "Kvízek" },
  "raw_html_editor_e3993e41": { "message": "Egyszerű HTML szerkesztő" },
  "record_7c9448b": { "message": "Felvétel" },
  "record_upload_media_5fdce166": {
    "message": "Médiafájl rögzítése/feltöltése"
  },
  "red_8258edf3": { "message": "Vörös" },
  "relationships_6602af70": { "message": "Kapcsolatok" },
  "remove_link_d1f2f4d0": { "message": "Link eltávolítása" },
  "restore_auto_save_deccd84b": {
    "message": "Visszaállítás automatikus mentésből?"
  },
  "rich_content_editor_2708ef21": { "message": "Vizuális szövegszerkesztő" },
  "right_to_left_9cfb092a": { "message": "Jobbról balra" },
  "save_11a80ec3": { "message": "Mentés" },
  "search_280d00bd": { "message": "Keresés" },
  "search_term_b2d2235": { "message": "Kifejezés keresése" },
  "select_language_7c93a900": { "message": "Válasszon nyelvet" },
  "selected_274ce24f": { "message": "Kiválasztva" },
  "show_image_options_1e2ecc6b": { "message": "Képbeállítások mutatása" },
  "show_link_options_545338fd": { "message": "Linkbeállítások mutatása" },
  "show_video_options_6ed3721a": { "message": "Videóbeállítások mutatása" },
  "size_b30e1077": { "message": "Méret" },
  "small_b070434a": { "message": "Kicsi" },
  "something_went_wrong_89195131": { "message": "Hiba történt!" },
  "something_went_wrong_and_i_don_t_know_what_to_show_e0c54ec8": {
    "message": "Hiba történt! Nem tudom, mit mutassak."
  },
  "something_went_wrong_d238c551": { "message": "Hiba történt!" },
  "sort_by_e75f9e3e": { "message": "Rendezés alapja" },
  "square_unordered_list_b15ce93b": {
    "message": "rendezetlen lista négyzetekkel"
  },
  "star_8d156e09": { "message": "Csillagozás" },
  "styles_2aa721ef": { "message": "Stílusok" },
  "submit_a3cc6859": { "message": "Beküldés" },
  "subscript_59744f96": { "message": "alsó index" },
  "superscript_8cb349a2": { "message": "felső index" },
  "supported_file_types_srt_or_webvtt_7d827ed": {
    "message": "Támogatott fájltípusok: SRT vagy WebVTT"
  },
  "syllabus_f191f65b": { "message": "Tematika" },
  "tab_arrows_4cf5abfc": { "message": "Tab/Nyilak" },
  "teal_f729a294": { "message": "Kékeszöld" },
  "text_7f4593da": { "message": "Szöveg" },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Az anyag a közkincs kategóriába tartozik"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Ezt az anyagot Creative Commons licenc alatt tették közzé."
  },
  "the_material_is_subject_to_an_exception_e_g_fair_u_a39c8ca2": {
    "message": "Az anyag kivételt képez- pl. tisztességes felhasználás, árajánlási jog vagy mások a vonatkozó szerzői jogi törvények alapján"
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "Ezt az egyenletet nem lehet megjeleníteni alapnézetben."
  },
  "though_your_video_will_have_the_correct_title_in_t_90e427f3": {
    "message": "Bár a videója a megfelelő címmel jelenik majd meg a böngészőben, az adatbázisban nem sikerült frissíteni."
  },
  "title_ee03d132": { "message": "Cím" },
  "to_be_posted_when_d24bf7dc": { "message": "Időzített közzététel: { when }" },
  "to_do_when_2783d78f": { "message": "Teendő : { when }" },
  "tools_2fcf772e": { "message": "Eszközök" },
  "totalresults_results_found_numdisplayed_results_cu_a0a44975": {
    "message": "{ totalResults } találat, ebből { numDisplayed } megjelenítve"
  },
  "tray_839df38a": { "message": "Tálca" },
  "type_control_f9_to_access_image_options_text_a47e319f": {
    "message": "Nyomjon Control F9-et a kép opciók eléréséhez { text }"
  },
  "type_control_f9_to_access_link_options_text_4ead9682": {
    "message": "Nyomjon Control F9-et a link opciók eléréséhez { text }"
  },
  "type_control_f9_to_access_table_options_text_92141329": {
    "message": "Nyomjon Control F9-et a táblázat opciók eléréséhez { text }"
  },
  "unpublished_dfd8801": { "message": "nem publikált" },
  "upload_document_253f0478": { "message": "Dokumentum feltöltése" },
  "upload_file_fd2361b8": { "message": "Fájl feltöltése" },
  "upload_image_6120b609": { "message": "Kép feltöltése" },
  "upload_media_ce31135a": { "message": "Médiafájl feltöltése" },
  "upload_record_media_e4207d72": { "message": "Média feltöltés/rögzítés" },
  "uploading_19e8a4e7": { "message": "Feltöltés" },
  "uppercase_alphabetic_ordered_list_3f5aa6b2": {
    "message": "nagybetűs lista abc sorrendbe rendezve"
  },
  "uppercase_roman_numeral_ordered_list_853f292b": {
    "message": "nagybetűs lista római számok szerint rendezve"
  },
  "url_22a5f3b8": { "message": "URL" },
  "usage_right_ff96f3e2": { "message": "Felhasználási jog:" },
  "usage_rights_required_5fe4dd68": {
    "message": "Felhasználási jogok (kötelező)"
  },
  "use_arrow_keys_to_navigate_options_2021cc50": {
    "message": "Használja a nyíl billentyűket az opció kiválasztására!"
  },
  "used_by_screen_readers_to_describe_the_content_of__b1e76d9e": {
    "message": "Képernyőolvasók által egy kép tartalmának leírásához használt szöveg"
  },
  "used_by_screen_readers_to_describe_the_video_37ebad25": {
    "message": "Képernyőolvasók által a videó leírásához használt szöveg"
  },
  "user_documents_c206e61f": { "message": "A felhasználó dokumentumai" },
  "user_files_78e21703": { "message": "A felhasználó fájlai" },
  "user_images_b6490852": { "message": "A felhsználó képei" },
  "user_media_14fbf656": { "message": "A felhasználó médiafájljai" },
  "video_options_24ef6e5d": { "message": "Videóbeállítások" },
  "video_options_tray_3b9809a5": { "message": "Videóbeállítások tálca" },
  "video_player_for_9e7d373b": { "message": "Audio lejátszó ehhez" },
  "video_player_for_title_ffd9fbc4": {
    "message": "Videólejátszó ehhez: { title }"
  },
  "view_ba339f93": { "message": "Megtekintés" },
  "view_keyboard_shortcuts_34d1be0b": {
    "message": "A gyors elérés billentyűkombinációk megtekintése"
  },
  "width_492fec76": { "message": "Szélesség" },
  "width_and_height_must_be_numbers_110ab2e3": {
    "message": "A szélességnek és a magasságnak számnak kell lenni"
  },
  "width_x_height_px_ff3ccb93": { "message": "{ width } x { height } pixel" },
  "wiki_home_9cd54d0": { "message": "Wiki kezdőlap" },
  "yes_dde87d5": { "message": "Igen" },
  "you_may_not_upload_an_empty_file_11c31eb2": {
    "message": "Nem tölthet fel egy üres fájlt."
  }
}


formatMessage.addLocale({hu: locale})
