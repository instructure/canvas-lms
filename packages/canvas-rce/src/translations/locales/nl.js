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
import '../tinymce/nl'

const locale = {
  "access_the_pretty_html_editor_37168efe": {
    "message": "Open de pretty HTML-editor"
  },
  "accessibility_checker_b3af1f6c": { "message": "Toegankelijkheidscontrole" },
  "add_8523c19b": { "message": "Toevoegen" },
  "add_another_f4e50d57": { "message": "Nog een toevoegen" },
  "add_cc_subtitles_55f0394e": { "message": "CC/ondertiteling toevoegen" },
  "add_image_60b2de07": { "message": "Afbeelding toevoegen" },
  "aleph_f4ffd155": { "message": "Alef" },
  "alignment_and_lists_5cebcb69": { "message": "Koppeling en lijsten" },
  "all_4321c3a1": { "message": "Alle" },
  "all_apps_a50dea49": { "message": "Alle apps" },
  "alpha_15d59033": { "message": "Alfa" },
  "alphabetical_55b5b4e0": { "message": "Alfabetische volgorde" },
  "alt_text_611fb322": { "message": "Alt tekst" },
  "amalg_coproduct_c589fb12": { "message": "Amalg (coproduct)" },
  "an_error_occured_reading_the_file_ff48558b": {
    "message": "Er is een fout opgetreden bij het lezen van het bestand"
  },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "Er is een fout opgetreden bij het maken van een netwerkaanvraag"
  },
  "an_error_occurred_uploading_your_media_71f1444d": {
    "message": "Er is een fout opgetreden bij het uploaden van je media."
  },
  "and_7fcc2911": { "message": "En" },
  "angle_c5b4ec50": { "message": "Hoek" },
  "announcement_list_da155734": { "message": "Lijst met aankondiging" },
  "announcements_a4b8ed4a": { "message": "Aankondigingen" },
  "apply_781a2546": { "message": "Toepassen" },
  "apply_changes_to_all_instances_of_this_icon_maker__2642f466": {
    "message": "Wijzigingen toepassen op alle exemplaren van dit pictogrammaker-pictogram in de cursus"
  },
  "approaches_the_limit_893aeec9": { "message": "Benadert de limiet" },
  "approximately_e7965800": { "message": "Ongeveer" },
  "apps_54d24a47": { "message": "Apps" },
  "arrows_464a3e54": { "message": "Pijlen" },
  "art_icon_8e1daad": { "message": "Kunstpictogram" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Beeldverhouding blijft behouden"
  },
  "assignments_1e02582c": { "message": "Opdrachten" },
  "asterisk_82255584": { "message": "Asterisk" },
  "attributes_963ba262": { "message": "Kenmerken" },
  "audio_and_video_recording_not_supported_please_use_5ce3f0d7": {
    "message": "Audio- en video-opname wordt niet ondersteund; gebruik een andere browser."
  },
  "audio_options_feb58e2c": { "message": "Audio-opties" },
  "audio_options_tray_33a90711": { "message": "Gebied met audio-opties" },
  "audio_player_for_title_20cc70d": {
    "message": "Audio-speler voor { title }"
  },
  "auto_saved_content_exists_would_you_like_to_load_t_fee528f2": {
    "message": "Er is automatisch opgeslagen inhoud aanwezig. Wil je liever  de automatisch opgeslagen inhoud laden?"
  },
  "available_folders_694d0436": { "message": "Beschikbare mappen" },
  "backslash_b2d5442d": { "message": "Backslash" },
  "bar_ec63ed6": { "message": "Balk" },
  "basic_554cdc0a": { "message": "Basis" },
  "because_501841b": { "message": "Omdat" },
  "below_81d4dceb": { "message": "Hieronder" },
  "beta_cb5f307e": { "message": "Bèta" },
  "big_circle_16b2e604": { "message": "Grote cirkel" },
  "binomial_coefficient_ea5b9bb7": { "message": "Binomiaal coëfficiënt" },
  "black_4cb01371": { "message": "Zwart" },
  "blue_daf8fea9": { "message": "Blauw" },
  "bottom_15a2a9be": { "message": "Onder" },
  "bottom_third_5f5fec1d": { "message": "Derde van beneden" },
  "bowtie_5f9629e4": { "message": "Bowtie" },
  "brick_f2656265": { "message": "Steenrood" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "Annuleren" },
  "cap_product_3a5265a6": { "message": "Cap-product" },
  "centered_dot_64d5e378": { "message": "Gecentreerde punt" },
  "centered_horizontal_dots_451c5815": {
    "message": "Gecentreerde horizontale punten"
  },
  "chi_54a32644": { "message": "Chi" },
  "choose_caption_file_9c45bc4e": { "message": "Ondertitelingsbestand kiezen" },
  "choose_usage_rights_33683854": { "message": "Gebruiksrechten kiezen..." },
  "circle_484abe63": { "message": "Cirkel" },
  "clear_2084585f": { "message": "Wissen" },
  "clear_image_3213fe62": { "message": "Afbeelding wissen" },
  "clear_selected_file_82388e50": {
    "message": "Verwijder geselecteerd bestand"
  },
  "clear_selected_file_filename_2fe8a58e": {
    "message": "Verwijder geselecteerd bestand: { filename }"
  },
  "click_or_shift_click_for_the_html_editor_25d70bb4": {
    "message": "Klik of schuif-klik voor de HTML-editor."
  },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Klikken om { imageName } in te sluiten"
  },
  "click_to_hide_preview_3c707763": {
    "message": "Klik om voorbeeld te verbergen"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Klik om een koppeling in te voegen in de editor."
  },
  "click_to_show_preview_faa27051": { "message": "Klik om voorbeeld te tonen" },
  "close_a_menu_or_dialog_also_returns_you_to_the_edi_739079e6": {
    "message": "Sluit een menu of dialoogvenster. Hierdoor keert u bovendien terug naar het editorgebied"
  },
  "close_d634289d": { "message": "Sluiten" },
  "closed_caption_file_must_be_less_than_maxkb_kb_5880f752": {
    "message": "Ondertitelingsbestand moet kleiner zijn dan { maxKb } kb"
  },
  "closed_captions_subtitles_e6aaa016": {
    "message": "Bijschriften/ondertiteling"
  },
  "clubs_suit_c1ffedff": { "message": "Klaveren (speelkaart)" },
  "collaborations_5c56c15f": { "message": "Samenwerkingen" },
  "collapse_to_hide_types_1ab46d2e": {
    "message": "Inklappen om te verbergen { types }"
  },
  "color_picker_6b359edf": { "message": "Kleurenkiezer" },
  "color_picker_colorname_selected_ad4cf400": {
    "message": "Kleurenkiezer ({ colorName } geselecteerd)"
  },
  "complex_numbers_a543d004": { "message": "Complexe getallen" },
  "computer_1d7dfa6f": { "message": "Computer" },
  "congruent_5a244acd": { "message": "Congruent" },
  "contains_311f37b7": { "message": "Bevat" },
  "content_1440204b": { "message": "Inhoud" },
  "content_is_still_being_uploaded_if_you_continue_it_8f06d0cb": {
    "message": "Inhoud wordt nog steeds gedownload. Als je doorgaat, wordt deze niet goed ingesloten."
  },
  "content_subtype_5ce35e88": { "message": "Inhoud-subtype" },
  "content_type_2cf90d95": { "message": "Inhoudtype" },
  "coproduct_e7838082": { "message": "Coproduct" },
  "copyright_holder_66ee111": { "message": "Houder van auteursrecht:" },
  "count_plural_0_0_words_one_1_word_other_words_acf32eca": {
    "message": "{ count, plural,\n     =0 {0 woorden}\n    one {1 woord}\n  other {# woorden}\n}"
  },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {# item geladen}\n  other {# items geladen}\n}"
  },
  "course_documents_104d76e0": { "message": "Cursusdocumenten" },
  "course_files_62deb8f8": { "message": "Cursusbestanden" },
  "course_files_a31f97fc": { "message": "Cursusbestanden" },
  "course_images_f8511d04": { "message": "Cursusafbeeldingen" },
  "course_links_b56959b9": { "message": "Cursuslinks" },
  "course_media_ec759ad": { "message": "Cursusmedia" },
  "course_navigation_dd035109": { "message": "Cursusnavigatie" },
  "create_icon_110d6463": { "message": "Pictogram maken" },
  "creative_commons_license_725584ae": {
    "message": "Creative Commons-licentie:"
  },
  "crop_image_41bf940c": { "message": "Afbeelding bijsnijden" },
  "crop_image_807ebb08": { "message": "Afbeelding bijsnijden" },
  "cup_product_14174434": { "message": "Cup-product" },
  "current_image_f16c249c": { "message": "Huidige afbeelding" },
  "custom_6979cd81": { "message": "Aangepast" },
  "cyan_c1d5f68a": { "message": "Cyaan" },
  "dagger_57e0f4e5": { "message": "Dolk" },
  "date_added_ed5ad465": { "message": "Datum toegevoegd" },
  "decorative_icon_9a7f3fc3": { "message": "Decoratief pictogram" },
  "decorative_type_upper_f2c95e3": { "message": "Decoratief { TYPE_UPPER }" },
  "deep_purple_bb3e2907": { "message": "Diep paars" },
  "definite_integral_fe7ffed1": { "message": "Bepaalde integraal" },
  "degree_symbol_4a823d5f": { "message": "Gradensymbool" },
  "delimiters_4db4840d": { "message": "Scheidingstekens" },
  "delta_53765780": { "message": "Delta" },
  "describe_the_icon_f6a18823": { "message": "(Beschrijf het pictogram)" },
  "describe_the_type_ff448da5": { "message": "(Beschrijf het { TYPE })" },
  "describe_the_video_2fe8f46a": { "message": "(beschrijf de video)" },
  "details_98a31b68": { "message": "Details" },
  "diagonal_dots_7d71b57e": { "message": "Diagonale punten" },
  "diamond_b8dfe7ae": { "message": "Diamant" },
  "diamonds_suit_526abaaf": { "message": "Ruiten (speelkaart)" },
  "digamma_258ade94": { "message": "Digamma" },
  "dimension_type_f5fa9170": { "message": "Afmetingstype" },
  "dimensions_45ddb7b7": { "message": "Afmetingen" },
  "directionality_26ae9e08": { "message": "richting" },
  "directly_edit_latex_b7e9235b": { "message": "LaTeX rechtstreeks bewerken" },
  "disable_preview_222bdf72": { "message": "Voorbeeld uitschakelen" },
  "discussions_a5f96392": { "message": "Discussies" },
  "discussions_index_6c36ced": { "message": "Discussieoverzicht" },
  "disjoint_union_e74351a8": { "message": "Disjuncte verbinding" },
  "display_options_315aba85": { "message": "Weergaveopties" },
  "display_text_link_opens_in_a_new_tab_75e9afc9": {
    "message": "Tekstkoppeling weergeven (Opent in een nieuw tabblad)"
  },
  "division_sign_72190870": { "message": "Deelteken" },
  "documents_81393201": { "message": "Documenten" },
  "done_54e3d4b6": { "message": "Gereed" },
  "double_dagger_faf78681": { "message": "Double Dagger" },
  "down_and_left_diagonal_arrow_40ef602c": {
    "message": "Pijl omlaag en links diagonaal"
  },
  "down_and_right_diagonal_arrow_6ea0f460": {
    "message": "Pijl omlaag en rechts diagonaal"
  },
  "download_filename_2baae924": { "message": "{ filename } downloaden" },
  "downward_arrow_cca52012": { "message": "Pijl met punt omlaag" },
  "downward_pointing_triangle_2a12a601": {
    "message": "Driehoek met punt omlaag"
  },
  "drag_a_file_here_1bf656d5": { "message": "Sleep een bestand hierheen" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "Slepen en neerzetten of klikken om je computer te doorzoeken"
  },
  "drag_handle_use_up_and_down_arrows_to_resize_e29eae5c": {
    "message": "Sleep de handgreep. Gebruik de pijltoetsen-omhoog en -omlaag om de grootte te wijzigen"
  },
  "due_multiple_dates_cc0ee3f5": { "message": "Inleverdatum: Meerdere datums" },
  "due_when_7eed10c6": { "message": "Inleverdatum: { when }" },
  "edit_alt_text_for_this_icon_instance_9c6fc5fd": {
    "message": "Bewerk de alt-tekst voor deze pictograminstantie"
  },
  "edit_c5fbea07": { "message": "Bewerken" },
  "edit_course_link_5a5c3c59": { "message": "Cursuslink bewerken" },
  "edit_existing_icon_maker_icon_5d0ebb3f": {
    "message": "Bestaand Icon Maker-pictogram bewerken"
  },
  "edit_icon_2c6b0e91": { "message": "Pictogram Bewerken" },
  "edit_link_7f53bebb": { "message": "Link bewerken" },
  "editor_statusbar_26ac81fc": { "message": "Statusbalk van editor" },
  "embed_828fac4a": { "message": "Insluiten" },
  "embed_code_314f1bd5": { "message": "Code insluiten" },
  "embed_image_1080badc": { "message": "Afbeelding insluiten" },
  "embed_video_a97a64af": { "message": "Video insluiten" },
  "embedded_content_aaeb4d3d": { "message": "ingesloten inhoud" },
  "empty_set_91a92df4": { "message": "Lege set" },
  "encircled_dot_8f5e51c": { "message": "Omcirkelde punt" },
  "encircled_minus_72745096": { "message": "Omcirkeld minteken" },
  "encircled_plus_36d8d104": { "message": "Omcirkeld plusteken" },
  "encircled_times_5700096d": { "message": "Omcirkelde tijden" },
  "engineering_icon_f8f3cf43": { "message": "Engineering-pictogram" },
  "english_icon_25bfe845": { "message": "Engels-pictogram" },
  "enter_at_least_3_characters_to_search_4f037ee0": {
    "message": "Voer minimaal 3 tekens in om te gaan zoeken"
  },
  "epsilon_54bb8afa": { "message": "Epsilon" },
  "epsilon_variant_d31f1e77": { "message": "Epsilon (variant)" },
  "equals_sign_c51bdc58": { "message": "Gelijkteken" },
  "equation_editor_39fbc3f1": { "message": "Vergelijkingseditor" },
  "equivalence_class_7b0f11c0": { "message": "Equivalentieklasse" },
  "equivalent_identity_654b3ce5": { "message": "Equivalent (identiteit)" },
  "eta_b8828f99": { "message": "Eta" },
  "exists_2e62bdaa": { "message": "Bestaat" },
  "exit_fullscreen_b7eb0aa4": { "message": "Volledig scherm sluiten" },
  "expand_preview_by_default_2abbf9f8": {
    "message": "Uitvouwvoorbeeld is standaard"
  },
  "expand_to_see_types_f5d29352": {
    "message": "Uitklappen om te bekijken { types }"
  },
  "external_tools_6e77821": { "message": "Externe tools" },
  "extra_large_b6cdf1ff": { "message": "Extra groot" },
  "extra_small_9ae33252": { "message": "Extra klein" },
  "extracurricular_icon_67c8ca42": { "message": "Extracurriculair-pictogram" },
  "f_function_fe422d65": { "message": "F (functie)" },
  "failed_getting_file_contents_e9ea19f4": {
    "message": "Kan geen bestandsinhoud ophalen"
  },
  "file_storage_quota_exceeded_b7846cd1": {
    "message": "Opslagquota voor bestanden overschreden"
  },
  "file_url_c12b64be": { "message": "Bestands-URL" },
  "filename_file_icon_602eb5de": {
    "message": "{ filename } bestandspictogram"
  },
  "filename_image_preview_6cef8f26": {
    "message": "{ filename } afbeeldingsvoorbeeld"
  },
  "filename_text_preview_e41ca2d8": {
    "message": "{ filename } tekstvoorbeeld"
  },
  "files_c300e900": { "message": "Bestanden" },
  "files_index_af7c662b": { "message": "Bestandsoverzicht" },
  "flat_music_76d5a5c3": { "message": "Mol (muziek)" },
  "focus_element_options_toolbar_18d993e": {
    "message": "Werkbalk met focus-elementopties"
  },
  "folder_tree_fbab0726": { "message": "Mappenstructuur" },
  "for_all_b919f972": { "message": "Voor iedereen" },
  "format_4247a9c5": { "message": "Opmaak" },
  "formatting_5b143aa8": { "message": "Opmaak" },
  "forward_slash_3f90f35e": { "message": "Slash" },
  "found_auto_saved_content_3f6e4ca5": {
    "message": "Automatisch opgeslagen inhoud gevonden"
  },
  "found_count_plural_0_results_one_result_other_resu_46aeaa01": {
    "message": "{ count, plural,\n     =0 {# resultaten}\n    one {# resultaat}\n  other {# resultaten}\n} gevonden"
  },
  "fraction_41bac7af": { "message": "Fractie" },
  "fullscreen_873bf53f": { "message": "Volledig scherm" },
  "gamma_1767928": { "message": "Gamma" },
  "generating_preview_45b53be0": {
    "message": "Bezig met genereren van voorbeeld..."
  },
  "gif_png_format_images_larger_than_size_kb_are_not__7af3bdbd": {
    "message": "GIF/PNG-afbeeldingen groter dan { size } KB worden momenteel niet ondersteund."
  },
  "go_to_the_editor_s_menubar_e6674c81": {
    "message": "Ga naar de werkbalk van de editor"
  },
  "go_to_the_editor_s_toolbar_a5cb875f": {
    "message": "Ga naar de werkbalk van de editor"
  },
  "grades_a61eba0a": { "message": "Cijfers" },
  "greater_than_e98af662": { "message": "Groter dan" },
  "greater_than_or_equal_b911949a": { "message": "Groter dan of gelijk" },
  "greek_65c5b3f7": { "message": "Grieks" },
  "green_15af4778": { "message": "Groen" },
  "grey_a55dceff": { "message": "Grijs" },
  "group_documents_8bfd6ae6": { "message": "Documenten groeperen" },
  "group_files_4324f3df": { "message": "Groepsbestanden" },
  "group_files_82e5dcdb": { "message": "Groepsbestanden" },
  "group_images_98e0ac17": { "message": "Afbeeldingen groeperen" },
  "group_isomorphism_45b1458c": { "message": "Groepsisomorfie" },
  "group_links_9493129e": { "message": "Groeplinks" },
  "group_media_2f3d128a": { "message": "Media groeperen" },
  "group_navigation_99f191a": { "message": "Groepsnavigatie" },
  "h_bar_bb94deae": { "message": "H-balk" },
  "hat_ea321e35": { "message": "Hoed" },
  "heading_2_5b84eed2": { "message": "Koptekst 2" },
  "heading_3_2c83de44": { "message": "Koptekst 3" },
  "heading_4_b2e74be7": { "message": "Koptekst 4" },
  "health_icon_8d292eb5": { "message": "Gezondheidpictogram" },
  "hearts_suit_e50e04ca": { "message": "Harten (speelkaart)" },
  "height_69b03e15": { "message": "Hoogte" },
  "hexagon_d8468e0d": { "message": "Zeshoek" },
  "hide_description_bfb5502e": { "message": "Beschrijving verbergen" },
  "hide_title_description_caf092ef": {
    "message": "Beschrijving van { title } verbergen"
  },
  "home_351838cd": { "message": "Startpagina" },
  "html_code_editor_fd967a44": { "message": "HTML-code-editor" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Ik heb toestemming gekregen om dit bestand te gebruiken."
  },
  "i_hold_the_copyright_71ee91b1": { "message": "Ik heb het auteursrecht" },
  "icon_215a1dc6": { "message": "Pictogram" },
  "icon_8168b2f8": { "message": "pictogram" },
  "icon_color_b86dd6d6": { "message": "Pictogramkleur" },
  "icon_maker_icons_cc560f7e": { "message": "Pictogrammaker-pictogrammen" },
  "icon_options_7e32746e": { "message": "Pictogramopties" },
  "icon_options_tray_2b407977": { "message": "Houder met pictogramopties" },
  "icon_preview_1782a1d9": { "message": "Pictogramvoorbeeld" },
  "icon_shape_30b61e7": { "message": "Pictogramvorm" },
  "icon_size_9353edea": { "message": "Pictogramgrootte" },
  "if_left_empty_link_text_will_display_as_course_lin_61087540": {
    "message": "Als de link leeg wordt gelaten, wordt de naam van de cursuslink als tekst weergegeven"
  },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "Als je nu geen gebruiksrechten selecteert, wordt de publicatie van dit bestand ongedaan gemaakt nadat het is geüpload."
  },
  "image_8ad06": { "message": "Afbeelding" },
  "image_c1c98202": { "message": "afbeelding" },
  "image_options_5412d02c": { "message": "Beeldopties" },
  "image_options_tray_90a46006": { "message": "Beeldoptiescel" },
  "image_to_crop_3a34487d": { "message": "Afbeelding voor bijsnijden" },
  "images_7ce26570": { "message": "Afbeeldingen" },
  "imaginary_portion_of_complex_number_2c733ffa": {
    "message": "Denkbeeldig deel (van complex getal)"
  },
  "in_element_of_19ca2f33": { "message": "In (element van)" },
  "indefinite_integral_6623307e": { "message": "Onbepaalde integraal" },
  "indigo_2035fc55": { "message": "Indigo" },
  "inference_fed5c960": { "message": "gevolgtrekking" },
  "infinity_7a10f206": { "message": "Oneindigheid" },
  "insert_593145ef": { "message": "Invoegen" },
  "insert_link_6dc23cae": { "message": "Koppeling invoegen" },
  "integers_336344e1": { "message": "Gehele getallen" },
  "intersection_cd4590e4": { "message": "Snijpunt" },
  "invalid_entry_f7d2a0f5": { "message": "Ongeldige invoer." },
  "invalid_file_c11ba11": { "message": "Ongeldig bestand" },
  "invalid_file_type_881cc9b2": { "message": "Ongeldig bestandstype" },
  "invalid_url_cbde79f": { "message": "Ongeldige URL" },
  "iota_11c932a9": { "message": "Jota" },
  "kappa_2f14c816": { "message": "Kappa" },
  "kappa_variant_eb64574b": { "message": "Kappa (variant)" },
  "keyboard_shortcuts_ed1844bd": { "message": "Sneltoetsen" },
  "lambda_4f602498": { "message": "Lambda" },
  "language_arts_icon_a798b0f8": { "message": "Linguïstiekpictogram" },
  "languages_icon_9d20539": { "message": "Talenpictogram" },
  "large_9c5e80e7": { "message": "Groot" },
  "left_angle_bracket_c87a6d07": { "message": "Recht haakje links" },
  "left_arrow_4fde1a64": { "message": "Pijl-links" },
  "left_arrow_with_hook_5bfcad93": { "message": "Pijl-links met hoek" },
  "left_ceiling_ee9dd88a": { "message": "Bovengrens links" },
  "left_curly_brace_1726fb4": { "message": "Gekrulde accolade links" },
  "left_downard_harpoon_arrow_1d7b3d2e": {
    "message": "Harpoenpijl links omlaag wijzend"
  },
  "left_floor_29ac2274": { "message": "Linker ondergrens" },
  "left_to_right_e9b4fd06": { "message": "Links-rechts" },
  "left_upward_harpoon_arrow_3a562a96": {
    "message": "Harpoenpijl links omhoog wijzend"
  },
  "leftward_arrow_1e4765de": { "message": "Pijl wijzend naar links" },
  "leftward_pointing_triangle_d14532ce": {
    "message": "Driehoek met punt naar links"
  },
  "less_than_a26c0641": { "message": "Kleiner dan" },
  "less_than_or_equal_be5216cb": { "message": "Kleiner dan of gelijk" },
  "library_icon_ae1e54cf": { "message": "Bibliotheekpictogram" },
  "light_blue_5374f600": { "message": "Lichtblauw" },
  "link_7262adec": { "message": "Link" },
  "link_options_a16b758b": { "message": "Linkopties" },
  "links_14b70841": { "message": "Koppelingen" },
  "links_to_an_external_site_de74145d": {
    "message": "Koppelingen naar een externe site."
  },
  "load_more_35d33c7": { "message": "Meer laden" },
  "loading_25990131": { "message": "Bezig met laden..." },
  "loading_bde52856": { "message": "Bezig met laden" },
  "loading_closed_captions_subtitles_failed_95ceef47": {
    "message": "laden van bijschriften/ondertiteling is mislukt."
  },
  "loading_failed_b3524381": { "message": "Laden mislukt..." },
  "loading_failed_e6a9d8ef": { "message": "Laden mislukt." },
  "loading_folders_d8b5869e": { "message": "Mappen worden geladen" },
  "loading_please_wait_d276220a": {
    "message": "Bezig met laden, even wachten"
  },
  "loading_preview_9f077aa1": { "message": "Voorbeeld laden" },
  "locked_762f138b": { "message": "Vergrendeld" },
  "logical_equivalence_76fca396": { "message": "Logische equivalentie" },
  "logical_equivalence_short_8efd7b4f": {
    "message": "Logische equivalentie (kort)"
  },
  "logical_equivalence_short_and_thick_1e1f654d": {
    "message": "Logische equivalentie (kort en dik)"
  },
  "logical_equivalence_thick_662dd3f2": {
    "message": "Logische equivalentie (dik)"
  },
  "low_horizontal_dots_cc08498e": { "message": "Lage horizontale punten" },
  "magenta_4a65993c": { "message": "Magenta" },
  "maps_to_e5ef7382": { "message": "Wijst toe aan" },
  "math_icon_ad4e9d03": { "message": "Wiskundepictogram" },
  "media_af190855": { "message": "Media" },
  "media_file_is_processing_please_try_again_later_58a6d49": {
    "message": "Verwerken van mediabestand. Probeer het later opnieuw."
  },
  "medium_5a8e9ead": { "message": "Medium" },
  "middle_27dc1d5": { "message": "Midden" },
  "minimize_file_preview_da911944": {
    "message": "Voorbeeld van bestand minimaliseren"
  },
  "minimize_video_20aa554b": { "message": "Video minimaliseren" },
  "minus_fd961e2e": { "message": "Min" },
  "minus_plus_3461f637": { "message": "Min/Plus" },
  "misc_3b692ea7": { "message": "Diversen" },
  "miscellaneous_e9818229": { "message": "Diversen" },
  "modules_c4325335": { "message": "Modules" },
  "mu_37223b8b": { "message": "Mu" },
  "multi_color_image_63d7372f": { "message": "Veelkleurige afbeelding" },
  "multiplication_sign_15f95c22": { "message": "Vermenigvuldigingsteken" },
  "music_icon_4db5c972": { "message": "Muziekpictogram" },
  "must_be_at_least_percentage_22e373b6": {
    "message": "Moet ten minste { percentage }% zijn"
  },
  "must_be_at_least_width_x_height_px_41dc825e": {
    "message": "Moet minstens { width } x { height }px zijn"
  },
  "my_files_2f621040": { "message": "Mijn bestanden" },
  "n_th_root_9991a6e4": { "message": "N-de wortel" },
  "nabla_1e216d25": { "message": "Nabla" },
  "name_1aed4a1b": { "message": "Naam" },
  "name_color_ceec76ff": { "message": "{ name } ({ color })" },
  "natural_music_54a70258": { "message": "Natuurlijk (muziek)" },
  "natural_numbers_3da07060": { "message": "Natuurlijke getallen" },
  "navigate_through_the_menu_or_toolbar_415a4e50": {
    "message": "Navigeer door het menu of de werkbalk"
  },
  "nested_greater_than_d852e60d": { "message": "Genest groter dan" },
  "nested_less_than_27d17e58": { "message": "Genest kleiner dan" },
  "no_changes_to_save_d29f6e91": {
    "message": "Geen wijzigingen om op te slaan."
  },
  "no_e16d9132": { "message": "Nee" },
  "no_file_chosen_9a880793": { "message": "Geen bestand gekozen" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Er is geen voorbeeld voor dit bestand beschikbaar."
  },
  "no_results_940393cf": { "message": "Geen resultaten." },
  "no_results_found_for_filterterm_ad1b04c8": {
    "message": "Geen resultaten gevonden voor { filterTerm }"
  },
  "none_3b5e34d2": { "message": "Geen" },
  "none_selected_b93d56d2": { "message": "Geen geselecteerd" },
  "not_equal_6e2980e6": { "message": "Niet gelijk" },
  "not_in_not_an_element_of_fb1ffb54": {
    "message": "Niet in (geen element van)"
  },
  "not_negation_1418ebb8": { "message": "Niet (ontkenning)" },
  "not_subset_dc2b5e84": { "message": "Geen subset" },
  "not_subset_strict_23d282bf": { "message": "Geen subset (strikt)" },
  "not_superset_5556b913": { "message": "Geen superset" },
  "not_superset_strict_24e06f36": { "message": "Geen superset (strikt)" },
  "nu_1c0f6848": { "message": "Nu" },
  "octagon_e48be9f": { "message": "Achthoek" },
  "olive_6a3e4d6b": { "message": "Olijfkleurig" },
  "omega_8f2c3463": { "message": "Omega" },
  "one_of_the_following_styles_must_be_added_to_save__1de769aa": {
    "message": "Een van de volgende stijlen moet worden toegevoegd om een pictogram op te slaan: Pictogramkleur, omtrekgrootte, pictogramtekst of afbeelding"
  },
  "open_circle_e9bd069": { "message": "Open cirkel" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "Open dit dialoogvenster met sneltoetsen"
  },
  "open_title_application_fd624fc5": {
    "message": "{ title } applicatie openen"
  },
  "operators_a2ef9a93": { "message": "Operators" },
  "or_9b70ccaa": { "message": "Of" },
  "orange_81386a62": { "message": "Oranje" },
  "other_editor_shortcuts_may_be_found_at_404aba4a": {
    "message": "Andere editorsnelkoppelingen zijn te vinden op"
  },
  "outline_color_3ef2cea7": { "message": "Omtrekkleur" },
  "outline_size_a6059a21": { "message": "Omtrtekgrootte" },
  "p_is_not_a_valid_protocol_which_must_be_ftp_http_h_adf13fc2": {
    "message": "{ p } is geen geldig protocol; dat moet ftp, http, https, mailto, skype of tel zijn, of het kan worden weggelaten"
  },
  "pages_e5414c2c": { "message": "Pagina''s" },
  "paragraph_5e5ad8eb": { "message": "Alinea" },
  "parallel_d55d6e38": { "message": "Parallel" },
  "partial_derivative_4a9159df": { "message": "Partiële afgeleide" },
  "paste_5963d1c1": { "message": "Plakken" },
  "pentagon_17d82ea3": { "message": "Vijfhoek" },
  "people_b4ebb13c": { "message": "Personen" },
  "percentage_34ab7c2c": { "message": "Percentage" },
  "percentage_must_be_a_number_8033c341": {
    "message": "Percentage moet een getal zijn"
  },
  "performing_arts_icon_f3497486": {
    "message": "Pictogram voor uitvoerende kunsten"
  },
  "perpendicular_7c48ede4": { "message": "Loodlijn" },
  "phi_4ac33b6d": { "message": "Phi" },
  "phi_variant_c9bb3ac5": { "message": "Phi (variant)" },
  "physical_education_icon_d7dffd3e": {
    "message": "Pictogram voor lichamelijke opvoeding"
  },
  "pi_dc4f0bd8": { "message": "Pi" },
  "pi_variant_10f5f520": { "message": "Pi (variant)" },
  "pink_68ad45cb": { "message": "Roze" },
  "pixels_52ece7d1": { "message": "Pixels" },
  "play_media_comment_35257210": { "message": "Media-opmerking afspelen." },
  "play_media_comment_by_name_from_createdat_c230123d": {
    "message": "Media-opmerking van { name } afspelen die gemaakt is op { createdAt }."
  },
  "plus_d43cd4ec": { "message": "Plus" },
  "plus_minus_f8be2e83": { "message": "Plusminus" },
  "posted_when_a578f5ab": { "message": "Geplaatst: { when }" },
  "power_set_4f26f316": { "message": "Machtsverzameling" },
  "precedes_196b9aef": { "message": "Gaat vooraf aan" },
  "precedes_equal_20701e84": { "message": "Gaat vooraf aan gelijk" },
  "preformatted_d0670862": { "message": "Voorgeformatteerd" },
  "preview_53003fd2": { "message": "Voorbeeld" },
  "preview_in_overlay_ed772c46": { "message": "Voorbeeld in overlay" },
  "preview_inline_9787330": { "message": "Voorbeeld inline" },
  "prime_917ea60e": { "message": "Priem" },
  "prime_numbers_13464f61": { "message": "Priemgetallen" },
  "product_39cf144f": { "message": "Product" },
  "proportional_f02800cc": { "message": "Proportioneel" },
  "protocol_must_be_ftp_http_https_mailto_skype_tel_o_73beb4f8": {
    "message": "Protocol moet ftp, http, https, mailto, skype of tel zijn, of het kan worden weggelaten"
  },
  "psi_e3f5f0f7": { "message": "Psi" },
  "published_c944a23d": { "message": "gepubliceerd" },
  "published_when_302d8e23": { "message": "Gepubliceerd: { when }" },
  "pumpkin_904428d5": { "message": "Pompoen" },
  "purple_7678a9fc": { "message": "Paars" },
  "quaternions_877024e0": { "message": "Quaternionen" },
  "quizzes_7e598f57": { "message": "Toetsen" },
  "rational_numbers_80ddaa4a": { "message": "Rationele getallen" },
  "real_numbers_7c99df94": { "message": "Reële getallen" },
  "real_portion_of_complex_number_7dad33b5": {
    "message": "Reëel deel (van complex getal)"
  },
  "record_7c9448b": { "message": "Opnemen" },
  "red_8258edf3": { "message": "Rood" },
  "relationships_6602af70": { "message": "Relaties" },
  "religion_icon_246e0be1": { "message": "Religiepictogram" },
  "replace_e61834a7": { "message": "Vervangen" },
  "reset_95a81614": { "message": "Opnieuw instellen" },
  "resize_ec83d538": { "message": "Grootte wijzigen" },
  "restore_auto_save_deccd84b": {
    "message": "Automatisch opslaan herstellen?"
  },
  "reverse_turnstile_does_not_yield_7558be06": {
    "message": "Inverse tourniquet (conclusie volgt)"
  },
  "rho_a0244a36": { "message": "Rho" },
  "rho_variant_415245cd": { "message": "Rho (variant)" },
  "rich_content_editor_2708ef21": { "message": "Rich Content Editor" },
  "rich_text_area_press_alt_0_for_rich_content_editor_9d23437f": {
    "message": "Rich Text-gebied. Druk op ALT+0 voor Rich Content Editor-sneltoetsen."
  },
  "right_angle_bracket_d704e2d6": { "message": "Recht haakje rechts" },
  "right_arrow_35e0eddf": { "message": "Pijl-rechts" },
  "right_arrow_with_hook_29d92d31": { "message": "Pijl-rechts met hoek" },
  "right_ceiling_839dc744": { "message": "Bovengrens rechts" },
  "right_curly_brace_5159d5cd": { "message": "Gekrulde accolade rechts" },
  "right_downward_harpoon_arrow_d71b114f": {
    "message": "Harpoenpijl rechts omlaag wijzend"
  },
  "right_floor_5392d5cf": { "message": "Ondergrens rechts" },
  "right_to_left_9cfb092a": { "message": "Rechts-links" },
  "right_upward_harpoon_arrow_f5a34c73": {
    "message": "Harpoenpijl rechts omhoog wijzend"
  },
  "rightward_arrow_32932107": { "message": "Pijl wijzend naar rechts" },
  "rightward_pointing_triangle_60330f5c": {
    "message": "Driehoek met punt naar rechts"
  },
  "rotate_image_90_degrees_2ab77c05": { "message": "Beeld draaien -90 graden" },
  "rotate_image_90_degrees_6c92cd42": { "message": "Beeld draaien 90 graden" },
  "rotation_9699c538": { "message": "Rotatie" },
  "sadly_the_pretty_html_editor_is_not_keyboard_acces_50da7665": {
    "message": "Jammer genoeg is de pretty HTML-editor niet toetsenbordtoegankelijk. Open de raw HTML-editor hier."
  },
  "save_11a80ec3": { "message": "Opslaan" },
  "script_l_42a7b254": { "message": "Script L" },
  "search_280d00bd": { "message": "Zoeken" },
  "select_crop_shape_d441feeb": { "message": "Bijsnijvorm selecteren" },
  "select_language_7c93a900": { "message": "Taal selecteren" },
  "selected_linkfilename_c093b1f2": {
    "message": "Geselecteerd { linkFileName }"
  },
  "set_minus_b46e9b88": { "message": "Setminus" },
  "sharp_music_ab956814": { "message": "Kruis (muziek)" },
  "shift_o_to_open_the_pretty_html_editor_55ff5a31": {
    "message": "Shift-O om de pretty HTML-editor te openen."
  },
  "sigma_5c35e553": { "message": "Sigma" },
  "sigma_variant_8155625": { "message": "Sigma (variant)" },
  "single_color_image_4e5d4dbc": { "message": "Enkelkleurige afbeelding" },
  "single_color_image_color_95fa9a87": {
    "message": "Enkelkleurige afbeeldingskleur"
  },
  "size_b30e1077": { "message": "Grootte" },
  "size_of_caption_file_is_greater_than_the_maximum_m_bff5f86e": {
    "message": "Ondertitelingsbestand is groter dan de maximaal toegestane { max } kb bestandsgrootte."
  },
  "small_b070434a": { "message": "Klein" },
  "solid_circle_9f061dfc": { "message": "Dichte cirkel" },
  "something_went_wrong_89195131": { "message": "Er is iets misgegaan." },
  "something_went_wrong_and_i_don_t_know_what_to_show_e0c54ec8": {
    "message": "Er is iets misgegaan en ik weet niet wat ik je moet laten zien."
  },
  "something_went_wrong_check_your_connection_reload__c7868286": {
    "message": "Er is iets misgegaan. Controleer je verbinding, laad de pagina opnieuw en probeer het nog eens."
  },
  "something_went_wrong_d238c551": { "message": "Er is iets misgegaan" },
  "sort_by_e75f9e3e": { "message": "Sorteren op" },
  "spades_suit_b37020c2": { "message": "Schoppen (speelkaart)" },
  "square_511eb3b3": { "message": "Vierkant" },
  "square_cap_9ec88646": { "message": "Doorsnede" },
  "square_cup_b0665113": { "message": "Vereniging" },
  "square_root_e8bcbc60": { "message": "Vierkantswortel" },
  "square_root_symbol_d0898a53": { "message": "Symbool van vierkantswortel" },
  "square_subset_17be67cb": { "message": "Subset van vierkantswortel" },
  "square_subset_strict_7044e84f": {
    "message": "Subset van vierkantswortel (strikt)"
  },
  "square_superset_3be8dae1": { "message": "Superset van vierkantswortel" },
  "square_superset_strict_fa4262e4": {
    "message": "Superset van vierkantswortel (strikt)"
  },
  "star_8d156e09": { "message": "Ster" },
  "steel_blue_14296f08": { "message": "Staalblauw" },
  "styles_2aa721ef": { "message": "Stijlen" },
  "submit_a3cc6859": { "message": "Inleveren" },
  "subscript_59744f96": { "message": "Subscript" },
  "subset_19c1a92f": { "message": "Subset" },
  "subset_strict_8d8948d6": { "message": "Subset (strikt)" },
  "succeeds_9cc31be9": { "message": "Volgt op" },
  "succeeds_equal_158e8c3a": { "message": "Volgt op gelijk" },
  "sum_b0842d31": { "message": "Som" },
  "superscript_8cb349a2": { "message": "Superscript" },
  "superset_c4db8a7a": { "message": "Superset" },
  "superset_strict_c77dd6d2": { "message": "Superset (strikt)" },
  "supported_file_types_srt_or_webvtt_7d827ed": {
    "message": "Ondersteunde bestandstypen: SRT of WebVTT"
  },
  "switch_to_pretty_html_editor_a3cee15f": {
    "message": "Overschakelen geavanceerde HTML-editor"
  },
  "switch_to_raw_html_editor_f970ae1a": {
    "message": "Overschakelen naar basis HTML-editor"
  },
  "switch_to_the_html_editor_146dfffd": {
    "message": "Overschakelen naar de HTML-editor"
  },
  "switch_to_the_rich_text_editor_63c1ecf6": {
    "message": "Overschakelen naar de Rich Text Editor"
  },
  "syllabus_f191f65b": { "message": "Syllabus" },
  "tab_arrows_4cf5abfc": { "message": "TAB/pijlen" },
  "tau_880974b7": { "message": "Tau" },
  "teal_f729a294": { "message": "Groenblauw" },
  "text_7f4593da": { "message": "Tekst" },
  "text_background_color_16e61c3f": { "message": "Achtergrondkleur van tekst" },
  "text_color_acf75eb6": { "message": "Tekstkleur" },
  "text_optional_384f94f7": { "message": "Tekst (optioneel)" },
  "text_position_8df8c162": { "message": "Tekstpositie" },
  "text_size_887c2f6": { "message": "Tekstgrootte" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "Het voorbeeld van het document wordt momenteel verwerkt. Probeer het later opnieuw."
  },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Het materiaal bevindt zich in het openbaar domein"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Het materiaal is onder Creative Commons gelicentieerd"
  },
  "the_material_is_subject_to_an_exception_e_g_fair_u_a39c8ca2": {
    "message": "Op het materiaal is een uitzondering van toepassing, bijvoorbeeld redelijk gebruik, het recht om te citeren of andere toepasselijke wetgeving op het auteursrecht"
  },
  "the_pretty_html_editor_is_not_keyboard_accessible__d6d5d2b": {
    "message": "De pretty HTML-editor is niet toetsenbordtoegankelijk. Druk op Shift O om de raw HTML-editor te openen."
  },
  "therefore_d860e024": { "message": "Ergo" },
  "theta_ce2d2350": { "message": "Theta" },
  "theta_variant_fff6da6f": { "message": "Theta (variant)" },
  "thick_downward_arrow_b85add4c": { "message": "Dikke pijl met punt omlaag" },
  "thick_left_arrow_d5f3e925": { "message": "Dikke pijl-links" },
  "thick_leftward_arrow_6ab89880": {
    "message": "Dikke pijl wijzend naar links"
  },
  "thick_right_arrow_3ed5e8f7": { "message": "Dikke pijl-rechts" },
  "thick_rightward_arrow_a2e1839e": {
    "message": "Dikke pijl wijzend naar rechts"
  },
  "thick_upward_arrow_acd20328": { "message": "Dikke pijl met punt omhoog" },
  "this_document_cannot_be_displayed_within_canvas_7aba77be": {
    "message": "Dit document kan niet in Canvas weergegeven worden."
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "Deze vergelijking kan niet in basisweergave worden getoond."
  },
  "this_image_is_currently_unavailable_25c68857": {
    "message": "Deze afbeelding is momenteel niet beschikbaar"
  },
  "though_your_video_will_have_the_correct_title_in_t_90e427f3": {
    "message": "Ook al krijgt je video de juiste titel in de browser, de video kon niet worden bijgewerkt in de database."
  },
  "title_ee03d132": { "message": "Titel" },
  "to_be_posted_when_d24bf7dc": { "message": "Nog te plaatsen: { when }" },
  "to_do_when_2783d78f": { "message": "To-do: { when }" },
  "toggle_summary_group_413df9ac": {
    "message": "{ summary } groep omschakelen"
  },
  "toggle_tooltip_d3b7cb86": { "message": "ToolTip wisselen" },
  "tools_2fcf772e": { "message": "Tools" },
  "top_66e0adb6": { "message": "Boven" },
  "tray_839df38a": { "message": "Houder" },
  "triangle_6072304e": { "message": "Driehoek" },
  "turnstile_yields_f9e76df1": { "message": "Tourniquet (conclusie volgt)" },
  "type_control_f9_to_access_image_options_text_a47e319f": {
    "message": "typ Ctrl+F9 om opties voor afbeeldingen te openen. { text }"
  },
  "type_control_f9_to_access_link_options_text_4ead9682": {
    "message": "typ Ctrl+F9 om opties voor koppelen te openen. { text }"
  },
  "type_control_f9_to_access_table_options_text_92141329": {
    "message": "typ Ctrl+F9 om opties voor tabellen te openen. { text }"
  },
  "union_e6b57a53": { "message": "Vereniging" },
  "unpublished_dfd8801": { "message": "niet-gepubliceerd" },
  "untitled_efdc2d7d": { "message": "zonder titel" },
  "up_and_left_diagonal_arrow_e4a74a23": {
    "message": "Pijl omhoog en links diagonaal"
  },
  "up_and_right_diagonal_arrow_935b902e": {
    "message": "Pijl omhoog en rechts diagonaal"
  },
  "upload_file_fd2361b8": { "message": "Bestand uploaden" },
  "upload_image_6120b609": { "message": "Afbeelding uploaden" },
  "upload_media_ce31135a": { "message": "Media uploaden" },
  "uploading_19e8a4e7": { "message": "Bezig met uploaden" },
  "uppercase_delta_d4f4bc41": { "message": "Delta in kapitalen" },
  "uppercase_gamma_86f492e9": { "message": "Gamma in kapitalen" },
  "uppercase_lambda_c78d8ed4": { "message": "Lambda in kapitalen" },
  "uppercase_omega_8aedfa2": { "message": "Omega in kapitalen" },
  "uppercase_phi_caa36724": { "message": "Phi in kapitalen" },
  "uppercase_pi_fcc70f5e": { "message": "Pi in kapitalen" },
  "uppercase_psi_6395acbe": { "message": "Psi in kapitalen" },
  "uppercase_sigma_dbb70e92": { "message": "Sigma in kapitalen" },
  "uppercase_theta_49afc891": { "message": "Theta in kapitalen" },
  "uppercase_upsilon_8c1e623e": { "message": "Ypsilon in kapitalen" },
  "uppercase_xi_341e8556": { "message": "Xi in kapitalen" },
  "upsilon_33651634": { "message": "Ypsilon" },
  "upward_and_downward_pointing_arrow_fa90a918": {
    "message": "Pijl met punt omhoog en omlaag"
  },
  "upward_and_downward_pointing_arrow_thick_d420fdef": {
    "message": "Pijl met punt omhoog en omlaag (dik)"
  },
  "upward_arrow_9992cb2d": { "message": "Omhoog wijzende pijl" },
  "upward_pointing_triangle_d078d7cb": {
    "message": "Driehoek met punt omhoog"
  },
  "url_22a5f3b8": { "message": "URL" },
  "usage_right_ff96f3e2": { "message": "Gebruiksrecht:" },
  "usage_rights_required_5fe4dd68": { "message": "Gebruiksrechten (vereist)" },
  "use_arrow_keys_to_navigate_options_2021cc50": {
    "message": "Gebruik de pijltoetsen om door opties te navigeren."
  },
  "use_arrow_keys_to_select_a_shape_c8eb57ed": {
    "message": "Gebruik pijltoetsen om een vorm te selecteren."
  },
  "use_arrow_keys_to_select_a_size_699a19f4": {
    "message": "Gebruik pijltoetsen om een grootte te selecteren."
  },
  "use_arrow_keys_to_select_a_text_position_72f9137c": {
    "message": "Gebruik pijltoetsen om een tekstpositie te selecteren."
  },
  "use_arrow_keys_to_select_a_text_size_65e89336": {
    "message": "Gebruik pijltoetsen om een tekstgrootte te selecteren."
  },
  "use_arrow_keys_to_select_an_outline_size_e009d6b0": {
    "message": "Gebruik pijltoetsen om een omtrekgrootte te selecteren."
  },
  "used_by_screen_readers_to_describe_the_content_of__4f14b4e4": {
    "message": "Gebruikt door schermlezers om de inhoud van een { TYPE } te beschrijven"
  },
  "used_by_screen_readers_to_describe_the_content_of__b1e76d9e": {
    "message": "Gebruikt door schermlezers om de inhoud van een afbeelding te beschrijven"
  },
  "used_by_screen_readers_to_describe_the_video_37ebad25": {
    "message": "Gebruikt door schermlezers om de video te beschrijven"
  },
  "user_documents_c206e61f": { "message": "Gebruikersdocumenten" },
  "user_files_78e21703": { "message": "Gebruikersbestanden" },
  "user_images_b6490852": { "message": "Gebruikersafbeeldingen" },
  "user_media_14fbf656": { "message": "Gebruikersmedia" },
  "vector_notation_cf6086ab": { "message": "Vector (notatie)" },
  "vertical_bar_set_builder_notation_4300495f": {
    "message": "Verticale streep (kardinaliteit)"
  },
  "vertical_dots_bfb21f14": { "message": "Verticale punten" },
  "video_options_24ef6e5d": { "message": "Video-opties" },
  "video_options_tray_3b9809a5": { "message": "Gebied met video-opties" },
  "video_player_for_9e7d373b": { "message": "Videospeler voor " },
  "video_player_for_title_ffd9fbc4": {
    "message": "Videospeler voor { title }"
  },
  "view_ba339f93": { "message": "Bekijken" },
  "view_description_30446afc": { "message": "Beschrijving bekijken" },
  "view_keyboard_shortcuts_34d1be0b": { "message": "Sneltoetsen bekijken" },
  "view_title_description_67940918": {
    "message": "{ title } beschrijving bekijken"
  },
  "view_word_and_character_counts_a743dd0c": {
    "message": "Aantal woorden en tekens bekijken"
  },
  "white_87fa64fd": { "message": "Wit" },
  "width_492fec76": { "message": "Breedte" },
  "width_and_height_must_be_numbers_110ab2e3": {
    "message": "Breedte en hoogte moeten getallen zijn"
  },
  "width_x_height_px_ff3ccb93": { "message": "{ width } x { height }px" },
  "wiki_home_9cd54d0": { "message": "Wiki Home" },
  "wreath_product_200b38ef": { "message": "Kransproduct" },
  "xi_149681d0": { "message": "Xi" },
  "yes_dde87d5": { "message": "Ja" },
  "you_have_unsaved_changes_in_the_icon_maker_tray_do_e8cf5f1b": {
    "message": "Je hebt niet-opgeslagen wijzigingen in het menu Pictogrammenmaker. Wil je doorgaan zonder deze wijzigingen op te slaan?"
  },
  "you_may_not_upload_an_empty_file_11c31eb2": {
    "message": "Je kunt geen leeg bestand uploaden."
  },
  "your_image_has_been_compressed_for_icon_maker_imag_2e45cd91": {
    "message": "Je afbeelding is gecomprimeerd voor Icon Maker. Afbeeldingen kleiner dan { size } KB worden niet gecomprimeerd."
  },
  "zeta_5ef24f0e": { "message": "Zeta" },
  "zoom_f3e54d69": { "message": "Zoom" },
  "zoom_in_image_bb97d4f": { "message": "Afbeelding inzoomen" },
  "zoom_out_image_d0a0a2ec": { "message": "Afbeelding uitzoomen" }
}


formatMessage.addLocale({nl: locale})
