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
import '../tinymce/it'

const locale = {
  "access_the_pretty_html_editor_37168efe": {
    "message": "Accedi a Editor HTML sicuro"
  },
  "accessibility_checker_b3af1f6c": { "message": "Verifica accessibilità" },
  "add_8523c19b": { "message": "Aggiungi" },
  "add_another_f4e50d57": { "message": "Aggiungi un altro" },
  "add_cc_subtitles_55f0394e": { "message": "Aggiungi CC/Sottotitoli" },
  "add_image_60b2de07": { "message": "Aggiungi Immagine" },
  "align_11050992": { "message": "Allinea" },
  "align_center_ca078feb": { "message": "Allinea al centro" },
  "align_left_e9f1f93b": { "message": "Allinea a sinistra" },
  "align_right_9bad3ac1": { "message": "Allinea a destra" },
  "alignment_and_lists_5cebcb69": { "message": "Allineamento ed elenchi" },
  "all_4321c3a1": { "message": "Tutto" },
  "all_apps_a50dea49": { "message": "Tutte le app" },
  "alphabetical_55b5b4e0": { "message": "Alfabetico" },
  "alt_text_611fb322": { "message": "Testo alternativo" },
  "an_error_occured_reading_the_file_ff48558b": {
    "message": "Si è verificato un errore durante la lettura del file"
  },
  "an_error_occurred_making_a_network_request_d1bda348": {
    "message": "Si è verificato un errore durante la creazione di una richiesta di rete"
  },
  "an_error_occurred_uploading_your_media_71f1444d": {
    "message": "Si è verificato un errore durante il caricamento dei file multimediali."
  },
  "announcement_list_da155734": { "message": "Elenco annuncio" },
  "announcements_a4b8ed4a": { "message": "Annunci" },
  "apply_781a2546": { "message": "Applica" },
  "apply_changes_to_all_instances_of_this_icon_maker__2642f466": {
    "message": "Applica modifiche a tutte le istanze di questo produttore icone nel corso"
  },
  "apps_54d24a47": { "message": "App" },
  "arrows_464a3e54": { "message": "Frecce" },
  "art_icon_8e1daad": { "message": "Icona art" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": {
    "message": "Le proporzioni verranno mantenute"
  },
  "assignments_1e02582c": { "message": "Compiti" },
  "attributes_963ba262": { "message": "Attributi" },
  "audio_and_video_recording_not_supported_please_use_5ce3f0d7": {
    "message": "Registrazione audio e video non supportata; usa un altro browser."
  },
  "audio_options_feb58e2c": { "message": "Opzioni audio" },
  "audio_options_tray_33a90711": {
    "message": "Area di notifica opzioni audio"
  },
  "audio_player_for_title_20cc70d": {
    "message": "Riproduttore audio di { title }"
  },
  "auto_saved_content_exists_would_you_like_to_load_t_fee528f2": {
    "message": "Contenuto salvataggio automatico esistente. Caricare al suo posto il contenuto salvato automaticamente?"
  },
  "available_folders_694d0436": { "message": "Cartelle disponibili" },
  "basic_554cdc0a": { "message": "Base" },
  "below_81d4dceb": { "message": "Sotto" },
  "black_4cb01371": { "message": "Nero" },
  "blue_daf8fea9": { "message": "Blu" },
  "bottom_third_5f5fec1d": { "message": "Terzo inferiore" },
  "brick_f2656265": { "message": "Mattone" },
  "c_2001_acme_inc_283f7f80": { "message": "(c) 2001 Acme Inc." },
  "cancel_caeb1e68": { "message": "Annulla" },
  "choose_caption_file_9c45bc4e": {
    "message": "Scegli un file di sottotitoli"
  },
  "choose_usage_rights_33683854": {
    "message": "Scegli diritti di utilizzo..."
  },
  "circle_484abe63": { "message": "Cerchio" },
  "circle_unordered_list_9e3a0763": {
    "message": "cerchia elenco non ordinato"
  },
  "clear_2084585f": { "message": "Cancella" },
  "clear_image_3213fe62": { "message": "Cancella immagine" },
  "clear_selected_file_82388e50": { "message": "Cancella file selezionato" },
  "clear_selected_file_filename_2fe8a58e": {
    "message": "Cancella file selezionato: { filename }"
  },
  "click_or_shift_click_for_the_html_editor_25d70bb4": {
    "message": "Fai clic o Maiusc+clic per l’editor html."
  },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Clicca  per incorporare { imageName }"
  },
  "click_to_hide_preview_3c707763": {
    "message": "Fai clic per nascondere anteprima"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Fai clic per inserire un link nell''editor."
  },
  "click_to_show_preview_faa27051": {
    "message": "Fai clic per mostrare anteprima"
  },
  "close_a_menu_or_dialog_also_returns_you_to_the_edi_739079e6": {
    "message": "Chiudere un menu o una finestra di dialogo. Consente anche di tornare all’area dell’editor"
  },
  "close_d634289d": { "message": "Chiudi" },
  "closed_caption_file_must_be_less_than_maxkb_kb_5880f752": {
    "message": "Il file dei sottotitoli chiusi deve essere inferiore a { maxKb } kb"
  },
  "closed_captions_subtitles_e6aaa016": {
    "message": "Didascalie/Sottotitoli chiusi"
  },
  "collaborations_5c56c15f": { "message": "Collaborazioni" },
  "collapse_to_hide_types_1ab46d2e": {
    "message": "Riduci per nascondere { types }"
  },
  "color_picker_6b359edf": { "message": "Selettore colori" },
  "color_picker_colorname_selected_ad4cf400": {
    "message": "Selettore colori ({ colorName } selezionato/i)"
  },
  "computer_1d7dfa6f": { "message": "Computer" },
  "content_1440204b": { "message": "Contenuto" },
  "content_is_still_being_uploaded_if_you_continue_it_8f06d0cb": {
    "message": "Il contenuto è ancora in fase di caricamento, se continui non sarà incorporato correttamente."
  },
  "content_subtype_5ce35e88": { "message": "Sottocategoria di contenuto" },
  "content_type_2cf90d95": { "message": "Tipo di contenuto" },
  "copyright_holder_66ee111": { "message": "Titolare del copyright:" },
  "count_plural_0_0_words_one_1_word_other_words_acf32eca": {
    "message": "{ count, plural,\n     =0 {0 parole}\n    one {1 parola}\n  other {# parole}\n}"
  },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n    one {# elemento caricato}\n  other {# elementi caricati}\n}"
  },
  "course_documents_104d76e0": { "message": "Documenti del corso" },
  "course_files_62deb8f8": { "message": "File del corso" },
  "course_files_a31f97fc": { "message": "File corso" },
  "course_images_f8511d04": { "message": "Immagini del corso" },
  "course_links_b56959b9": { "message": "Link al corso" },
  "course_media_ec759ad": { "message": "File multimediali del corso" },
  "course_navigation_dd035109": { "message": "Esplorazione corso" },
  "create_icon_110d6463": { "message": "Crea icona" },
  "create_icon_maker_icon_c716bffe": {
    "message": "Crea icona produttore icone"
  },
  "creative_commons_license_725584ae": {
    "message": "Licenza Creative Commons:"
  },
  "crop_image_41bf940c": { "message": "Ritaglia immagine" },
  "crop_image_807ebb08": { "message": "Ritaglia immagine" },
  "current_image_f16c249c": { "message": "Immagine attuale" },
  "custom_6979cd81": { "message": "Personalizzato" },
  "cyan_c1d5f68a": { "message": "Ciano" },
  "date_added_ed5ad465": { "message": "Data aggiunta" },
  "decorative_image_3c28aa7d": { "message": "Immagine decorativa" },
  "decrease_indent_de6343ab": { "message": "Riduci rientro" },
  "deep_purple_bb3e2907": { "message": "Viola scuro" },
  "default_bulleted_unordered_list_47079da8": {
    "message": "elenco non ordinato puntato predefinito"
  },
  "default_numerical_ordered_list_48dd3548": {
    "message": "elenco ordinato numericamente predefinito"
  },
  "delimiters_4db4840d": { "message": "Delimitatori" },
  "describe_the_image_e65d2e32": { "message": "(Descrivi l’immagine)" },
  "describe_the_video_2fe8f46a": { "message": "(Descrivi il video)" },
  "details_98a31b68": { "message": "Dettagli" },
  "diamond_b8dfe7ae": { "message": "Rombo" },
  "dimensions_45ddb7b7": { "message": "Dimensioni" },
  "directionality_26ae9e08": { "message": "Direzionalità" },
  "directly_edit_latex_b7e9235b": { "message": "Modifica direttamente LaTeX" },
  "discussions_a5f96392": { "message": "Discussioni" },
  "discussions_index_6c36ced": { "message": "Indice discussioni" },
  "display_options_315aba85": { "message": "Visualizza opzioni" },
  "display_text_link_opens_in_a_new_tab_75e9afc9": {
    "message": "Visualizza collegamento testuale (Si apre in una nuova scheda)"
  },
  "document_678cd7bf": { "message": "Documento" },
  "documents_81393201": { "message": "Documenti" },
  "done_54e3d4b6": { "message": "Fatto" },
  "drag_a_file_here_1bf656d5": { "message": "Trascina qui un file" },
  "drag_and_drop_or_click_to_browse_your_computer_60772d6d": {
    "message": "Trascina la selezione o fai clic per cercare nel tuo computer"
  },
  "drag_handle_use_up_and_down_arrows_to_resize_e29eae5c": {
    "message": "Trascinare la maniglia. Usa frecce su e giù per ridimensionare"
  },
  "due_multiple_dates_cc0ee3f5": { "message": "Scadenza: Più date" },
  "due_when_7eed10c6": { "message": "Scadenza: { when }" },
  "edit_c5fbea07": { "message": "Modifica" },
  "edit_equation_f5279959": { "message": "Modifica equazione" },
  "edit_existing_button_icon_3d0277bd": {
    "message": "Modifica pulsante/icona esistente"
  },
  "edit_icon_2c6b0e91": { "message": "Icona di modifica" },
  "edit_link_7f53bebb": { "message": "Modifica collegamento" },
  "editor_statusbar_26ac81fc": { "message": "Barra di stato dell’editor" },
  "embed_828fac4a": { "message": "Incorpora" },
  "embed_code_314f1bd5": { "message": "Incorpora codice" },
  "embed_image_1080badc": { "message": "Incorpora immagine" },
  "embed_video_a97a64af": { "message": "Incorpora il video" },
  "embedded_content_aaeb4d3d": { "message": "contenuto incorporato" },
  "engineering_icon_f8f3cf43": { "message": "Icona Progettazione" },
  "english_icon_25bfe845": { "message": "Icona Inglese" },
  "enter_at_least_3_characters_to_search_4f037ee0": {
    "message": "Inserisci almeno 3 caratteri per la ricerca"
  },
  "equation_1c5ac93c": { "message": "Equazione" },
  "equation_editor_39fbc3f1": { "message": "Editor equazione" },
  "expand_preview_by_default_2abbf9f8": {
    "message": "Espandi anteprima per impostazione predefinita"
  },
  "expand_to_see_types_f5d29352": { "message": "Espandi per vedere { types }" },
  "external_links_3d9f074e": { "message": "Link esterni" },
  "external_tools_6e77821": { "message": "Strumenti esterni" },
  "extra_large_b6cdf1ff": { "message": "Extra Large" },
  "extra_small_9ae33252": { "message": "Extra piccola" },
  "extracurricular_icon_67c8ca42": { "message": "Icona Extracurricolare" },
  "file_url_c12b64be": { "message": "URL file" },
  "filename_file_icon_602eb5de": { "message": "Icona file { filename }" },
  "filename_image_preview_6cef8f26": {
    "message": "Anteprima immagine { filename }"
  },
  "filename_text_preview_e41ca2d8": {
    "message": "Anteprima testo { filename }"
  },
  "files_c300e900": { "message": "File" },
  "files_index_af7c662b": { "message": "Indice file" },
  "focus_element_options_toolbar_18d993e": {
    "message": "Barra degli strumenti delle opzioni degli elementi di messa a fuoco"
  },
  "folder_tree_fbab0726": { "message": "Struttura ad albero delle cartelle" },
  "format_4247a9c5": { "message": "Formato" },
  "formatting_5b143aa8": { "message": "Formattazione in corso" },
  "found_auto_saved_content_3f6e4ca5": {
    "message": "Trovato contenuto salvato automaticamente"
  },
  "found_count_plural_0_results_one_result_other_resu_46aeaa01": {
    "message": "Trovati { count, plural,\n     =0 {# risultati}\n    one {# risultato}\n  other {# risultati}\n}"
  },
  "fullscreen_873bf53f": { "message": "Tutto schermo" },
  "generating_preview_45b53be0": {
    "message": "Generazione anteprima in corso..."
  },
  "go_to_the_editor_s_menubar_e6674c81": {
    "message": "Vai alla barra dei menu dell''editor"
  },
  "go_to_the_editor_s_toolbar_a5cb875f": {
    "message": "Vai alla barra degli strumenti dell''editor"
  },
  "grades_a61eba0a": { "message": "Voti" },
  "greek_65c5b3f7": { "message": "Greco" },
  "green_15af4778": { "message": "Verde" },
  "grey_a55dceff": { "message": "Grigio" },
  "group_documents_8bfd6ae6": { "message": "Documenti di gruppo" },
  "group_files_4324f3df": { "message": "File di gruppo" },
  "group_files_82e5dcdb": { "message": "File gruppo" },
  "group_images_98e0ac17": { "message": "Immagini di gruppo" },
  "group_links_9493129e": { "message": "Gruppo link" },
  "group_media_2f3d128a": { "message": "Supporto multimediale di gruppo" },
  "group_navigation_99f191a": { "message": "Esplorazione gruppo" },
  "heading_2_5b84eed2": { "message": "Intestazione 2" },
  "heading_3_2c83de44": { "message": "Intestazione 3" },
  "heading_4_b2e74be7": { "message": "Intestazione 4" },
  "health_icon_8d292eb5": { "message": "Icona Salute" },
  "height_69b03e15": { "message": "Altezza" },
  "hexagon_d8468e0d": { "message": "Esagono" },
  "hide_description_bfb5502e": { "message": "Nascondi descrizione" },
  "hide_title_description_caf092ef": {
    "message": "Nascondi descrizione { title }"
  },
  "home_351838cd": { "message": "Home" },
  "html_code_editor_fd967a44": { "message": "editor codice html" },
  "html_editor_fb2ab713": { "message": "Editor HTML" },
  "i_have_obtained_permission_to_use_this_file_6386f087": {
    "message": "Ho ottenuto l''autorizzazione a utilizzare questo file."
  },
  "i_hold_the_copyright_71ee91b1": {
    "message": "Sono il proprietario del copyright"
  },
  "icon_color_b86dd6d6": { "message": "Icona Colore" },
  "icon_maker_icons_cc560f7e": { "message": "Icone produttore icone" },
  "icon_outline_e978dc0c": { "message": "Struttura icona" },
  "icon_outline_size_33f39b86": { "message": "Dimensione struttura icona" },
  "icon_shape_30b61e7": { "message": "Forma icona" },
  "icon_size_9353edea": { "message": "Dimensione icona" },
  "if_you_do_not_select_usage_rights_now_this_file_wi_14e07ab5": {
    "message": "Se non selezioni i diritti di utilizzo ora, questo file sarà in stato \"non pubblicato\" dopo il caricamento."
  },
  "image_8ad06": { "message": "Immagine" },
  "image_options_5412d02c": { "message": "Opzioni immagine" },
  "image_options_tray_90a46006": { "message": "Barra opzioni immagine" },
  "image_to_crop_3a34487d": { "message": "Immagine da ritagliare" },
  "images_7ce26570": { "message": "Immagini" },
  "increase_indent_6d550a4a": { "message": "Aumenta rientro" },
  "indigo_2035fc55": { "message": "Indaco" },
  "insert_593145ef": { "message": "Inserisci" },
  "insert_equella_links_49a8dacd": { "message": "Inserisci link Equella" },
  "insert_link_6dc23cae": { "message": "Inserisci link" },
  "insert_math_equation_57c6e767": {
    "message": "Inserisci equazione matematica"
  },
  "invalid_file_c11ba11": { "message": "File non valido" },
  "invalid_file_type_881cc9b2": { "message": "Tipo file non valido" },
  "invalid_url_cbde79f": { "message": "URL non valido" },
  "keyboard_shortcuts_ed1844bd": { "message": "Scelte rapide da tastiera" },
  "language_arts_icon_a798b0f8": { "message": "Icona Studio della lingua" },
  "languages_icon_9d20539": { "message": "Icona Lingue" },
  "large_9c5e80e7": { "message": "Grande" },
  "left_to_right_e9b4fd06": { "message": "Da sinistra a destra" },
  "library_icon_ae1e54cf": { "message": "Icona Libreria" },
  "light_blue_5374f600": { "message": "Blu chiaro" },
  "link_7262adec": { "message": "Link" },
  "link_options_a16b758b": { "message": "Opzioni link" },
  "links_14b70841": { "message": "Link" },
  "load_more_35d33c7": { "message": "Carica altro" },
  "load_more_results_460f49a9": { "message": "Carica altri risultati" },
  "loading_25990131": { "message": "Caricamento in corso..." },
  "loading_bde52856": { "message": "Caricamento" },
  "loading_failed_b3524381": { "message": "Caricamento non riuscito..." },
  "loading_failed_e6a9d8ef": { "message": "Caricamento non riuscito." },
  "loading_folders_d8b5869e": { "message": "Caricamento cartelle" },
  "loading_please_wait_d276220a": {
    "message": "Caricamento in corso, attendere"
  },
  "loading_preview_9f077aa1": { "message": "Caricamento dell’anteprima" },
  "locked_762f138b": { "message": "Bloccato" },
  "magenta_4a65993c": { "message": "Magenta" },
  "math_icon_ad4e9d03": { "message": "Icona Matematica" },
  "media_af190855": { "message": "Elementi multimediali" },
  "media_file_is_processing_please_try_again_later_58a6d49": {
    "message": "File multimediale in elaborazione. Riprova in seguito."
  },
  "medium_5a8e9ead": { "message": "Medio" },
  "middle_27dc1d5": { "message": "Centro" },
  "misc_3b692ea7": { "message": "Varie" },
  "miscellaneous_e9818229": { "message": "Varie" },
  "modules_c4325335": { "message": "Moduli" },
  "multi_color_image_63d7372f": { "message": "Immagine multicolore" },
  "music_icon_4db5c972": { "message": "Icona Musica" },
  "must_be_at_least_percentage_22e373b6": {
    "message": "Deve essere almeno { percentage }%"
  },
  "must_be_at_least_width_x_height_px_41dc825e": {
    "message": "Deve essere almeno { width } x { height }px"
  },
  "my_files_2f621040": { "message": "I miei file" },
  "name_1aed4a1b": { "message": "Nome" },
  "name_color_ceec76ff": { "message": "{ name } ({ color })" },
  "navigate_through_the_menu_or_toolbar_415a4e50": {
    "message": "Naviga attraverso il menu o la barra degli strumenti"
  },
  "next_page_d2a39853": { "message": "Pagina successiva" },
  "no_e16d9132": { "message": "No" },
  "no_file_chosen_9a880793": { "message": "Nessun file scelto" },
  "no_preview_is_available_for_this_file_f940114a": {
    "message": "Nessuna anteprima disponibile per questo file."
  },
  "no_results_940393cf": { "message": "Nessun risultato." },
  "no_results_found_for_filterterm_ad1b04c8": {
    "message": "Nessun risultato trovato per { filterTerm }"
  },
  "no_results_found_for_term_1564c08e": {
    "message": "Nessun risultato trovato per { term }."
  },
  "none_3b5e34d2": { "message": "Nessuno" },
  "none_selected_b93d56d2": { "message": "Nessuna selezionata" },
  "octagon_e48be9f": { "message": "Ottagono" },
  "olive_6a3e4d6b": { "message": "Oliva" },
  "open_this_keyboard_shortcuts_dialog_9658b83a": {
    "message": "Apri questa finestra di dialogo delle scelte rapide da tastiera"
  },
  "open_title_application_fd624fc5": {
    "message": "Apri applicazione { title }"
  },
  "operators_a2ef9a93": { "message": "Operatori" },
  "orange_81386a62": { "message": "Arancione" },
  "ordered_and_unordered_lists_cfadfc38": {
    "message": "Elenchi ordinati e non ordinati"
  },
  "other_editor_shortcuts_may_be_found_at_404aba4a": {
    "message": "Altre scorciatoie dell’editor possono essere trovate in"
  },
  "p_is_not_a_valid_protocol_which_must_be_ftp_http_h_adf13fc2": {
    "message": "{ p } Non è un protocollo valido che deve essere ftp, http, https, mailto, skype, tel oppure può essere omesso"
  },
  "pages_e5414c2c": { "message": "Pagine" },
  "paragraph_5e5ad8eb": { "message": "Paragrafo" },
  "pentagon_17d82ea3": { "message": "Pentagono" },
  "people_b4ebb13c": { "message": "Persone" },
  "percentage_34ab7c2c": { "message": "Percentuale" },
  "percentage_must_be_a_number_8033c341": {
    "message": "La percentuale dev’essere un numero"
  },
  "performing_arts_icon_f3497486": { "message": "Icona Arti dello spettacolo" },
  "physical_education_icon_d7dffd3e": { "message": "Icona Educazione fisica" },
  "pink_68ad45cb": { "message": "Rosa" },
  "pixels_52ece7d1": { "message": "Pixel" },
  "posted_when_a578f5ab": { "message": "Postato: { when }" },
  "preformatted_d0670862": { "message": "Preformattato" },
  "pretty_html_editor_28748756": { "message": "Editor HTML sicuro" },
  "preview_53003fd2": { "message": "Anteprima" },
  "preview_in_overlay_ed772c46": { "message": "Anteprima in sovrapposizione" },
  "preview_inline_9787330": { "message": "Anteprima inline" },
  "previous_page_928fc112": { "message": "Pagina precedente" },
  "protocol_must_be_ftp_http_https_mailto_skype_tel_o_73beb4f8": {
    "message": "Il protocollo deve essere ftp, http, https, mailto, skype, tel oppure può essere omesso"
  },
  "published_c944a23d": { "message": "pubblicato" },
  "published_when_302d8e23": { "message": "Pubblicato: { when }" },
  "pumpkin_904428d5": { "message": "Zucca" },
  "purple_7678a9fc": { "message": "Viola" },
  "quizzes_7e598f57": { "message": "Quiz" },
  "raw_html_editor_e3993e41": { "message": "Editor HTML non elaborato" },
  "record_7c9448b": { "message": "Registra" },
  "record_upload_media_5fdce166": {
    "message": "Registra/Carica file multimediali"
  },
  "red_8258edf3": { "message": "Rosso" },
  "relationships_6602af70": { "message": "Relazioni" },
  "religion_icon_246e0be1": { "message": "Icona Religione" },
  "remove_link_d1f2f4d0": { "message": "Rimuovi link" },
  "resize_ec83d538": { "message": "Ridimensiona" },
  "restore_auto_save_deccd84b": {
    "message": "Ripristinare salvataggio automatico?"
  },
  "rich_content_editor_2708ef21": { "message": "Editor di contenuti avanzati" },
  "rich_text_area_press_alt_0_for_rich_content_editor_9d23437f": {
    "message": "Area di testo RTF. Premere ALT+0 per scorciatoie di Editor di contenuti avanzati."
  },
  "right_to_left_9cfb092a": { "message": "Da destra a sinistra" },
  "sadly_the_pretty_html_editor_is_not_keyboard_acces_50da7665": {
    "message": "Purtroppo l’editor HTML sicuro non è accessibile dalla tastiera. Accedi qui a editor HTML non elaborato."
  },
  "save_11a80ec3": { "message": "Salva" },
  "saved_icon_maker_icons_df86e2a1": {
    "message": "Icone produttore icone salvate"
  },
  "search_280d00bd": { "message": "Cerca" },
  "search_term_b2d2235": { "message": "Cerca termine" },
  "select_crop_shape_d441feeb": { "message": "Seleziona forma di ritaglio" },
  "select_language_7c93a900": { "message": "Selezionare la lingua" },
  "selected_274ce24f": { "message": "Selezionato" },
  "shift_o_to_open_the_pretty_html_editor_55ff5a31": {
    "message": "Maiusc+O per aprire l’editor html sicuro."
  },
  "show_audio_options_b489926b": { "message": "Mostra opzioni audio" },
  "show_image_options_1e2ecc6b": { "message": "Mostra opzioni immagine" },
  "show_link_options_545338fd": { "message": "Mostra opzioni link" },
  "show_video_options_6ed3721a": { "message": "Mostra opzioni video" },
  "single_color_image_4e5d4dbc": { "message": "Immagine monocolore" },
  "single_color_image_color_95fa9a87": {
    "message": "Colore immagine monocolore"
  },
  "size_b30e1077": { "message": "Dimensioni" },
  "size_of_caption_file_is_greater_than_the_maximum_m_bff5f86e": {
    "message": "La dimensione del file dei sottotitoli è superiore alla dimensione massima consentita di { max } kb."
  },
  "small_b070434a": { "message": "Piccolo" },
  "something_went_wrong_89195131": { "message": "Si è verificato un errore." },
  "something_went_wrong_and_i_don_t_know_what_to_show_e0c54ec8": {
    "message": "Qualcosa è andato storto e non so cosa mostrarti."
  },
  "something_went_wrong_d238c551": { "message": "Si è verificato un problema" },
  "sort_by_e75f9e3e": { "message": "Ordina per" },
  "square_511eb3b3": { "message": "Quadrato" },
  "square_unordered_list_b15ce93b": {
    "message": "incornicia elenco non ordinato"
  },
  "star_8d156e09": { "message": "Aggiungi a Speciali" },
  "steel_blue_14296f08": { "message": "Blu acciaio" },
  "styles_2aa721ef": { "message": "Stili" },
  "submit_a3cc6859": { "message": "Invia" },
  "subscript_59744f96": { "message": "Pedice" },
  "superscript_8cb349a2": { "message": "Apice" },
  "supported_file_types_srt_or_webvtt_7d827ed": {
    "message": "Tipi di file supportati: SRT o WebVTT"
  },
  "switch_to_the_html_editor_146dfffd": { "message": "Passa a editor html" },
  "switch_to_the_rich_text_editor_63c1ecf6": {
    "message": "Passa a editor di testo RTF"
  },
  "syllabus_f191f65b": { "message": "Piano di studio" },
  "tab_arrows_4cf5abfc": { "message": "TAB/Frecce" },
  "teal_f729a294": { "message": "Verde acqua" },
  "text_7f4593da": { "message": "Testo" },
  "text_background_color_16e61c3f": { "message": "Colore sfondo testo" },
  "text_color_acf75eb6": { "message": "Colore testo" },
  "text_position_8df8c162": { "message": "Posizione testo" },
  "text_size_887c2f6": { "message": "Dimensione testo" },
  "the_material_is_in_the_public_domain_279c39a3": {
    "message": "Il materiale è nel dominio pubblico"
  },
  "the_material_is_licensed_under_creative_commons_3242cb5e": {
    "message": "Il materiale è concesso in licenza da Creative Commons"
  },
  "the_material_is_subject_to_an_exception_e_g_fair_u_a39c8ca2": {
    "message": "Il materiale è soggetto a eccezioni, per es. l’uso equo, il diritto di citare o altre in base alle leggi applicabili sul diritto d’autore"
  },
  "the_pretty_html_editor_is_not_keyboard_accessible__d6d5d2b": {
    "message": "L’editor html sicuro non è accessibile dalla tastiera. Premere Maiusc+O per aprire l’editor html non elaborato."
  },
  "though_your_video_will_have_the_correct_title_in_t_90e427f3": {
    "message": "Anche se il tuo video avrà il titolo corretto nel browser, non siamo riusciti ad aggiornarlo nel database."
  },
  "title_ee03d132": { "message": "Titolo" },
  "to_be_posted_when_d24bf7dc": { "message": "Da postare: { when }" },
  "to_do_when_2783d78f": { "message": "Elenco attività: { when }" },
  "toggle_summary_group_413df9ac": {
    "message": "Attiva/Disattiva gruppo { summary }"
  },
  "tools_2fcf772e": { "message": "Strumenti" },
  "totalresults_results_found_numdisplayed_results_cu_a0a44975": {
    "message": "{ totalResults } risultati trovati, { numDisplayed } risultati attualmente visualizzati"
  },
  "tray_839df38a": { "message": "Barra delle applicazioni" },
  "triangle_6072304e": { "message": "Triangolo" },
  "type_control_f9_to_access_image_options_text_a47e319f": {
    "message": "digita Control F9 per accedere alle opzioni immagine. { text }"
  },
  "type_control_f9_to_access_link_options_text_4ead9682": {
    "message": "digita Control F9 per accedere alle opzioni di collegamento. { text }"
  },
  "type_control_f9_to_access_table_options_text_92141329": {
    "message": "digita Control F9 per accedere alle opzioni di tabella. { text }"
  },
  "unpublished_dfd8801": { "message": "non pubblicato" },
  "untitled_efdc2d7d": { "message": "senza titolo" },
  "upload_document_253f0478": { "message": "Carica documento" },
  "upload_file_fd2361b8": { "message": "Carica File" },
  "upload_image_6120b609": { "message": "Carica immagine" },
  "upload_media_ce31135a": { "message": "Carica file multimediali" },
  "upload_record_media_e4207d72": {
    "message": "Carica/Registra file multimediali"
  },
  "uploading_19e8a4e7": { "message": "Caricamento" },
  "uppercase_alphabetic_ordered_list_3f5aa6b2": {
    "message": "elenco ordinato per lettera maiuscola"
  },
  "uppercase_roman_numeral_ordered_list_853f292b": {
    "message": "elenco ordinato per cifra romana maiuscola"
  },
  "url_22a5f3b8": { "message": "URL" },
  "usage_right_ff96f3e2": { "message": "Diritto di utilizzo:" },
  "usage_rights_required_5fe4dd68": {
    "message": "Diritti di utilizzo (obbligatori)"
  },
  "use_arrow_keys_to_navigate_options_2021cc50": {
    "message": "Utilizza i tasti freccia per spostarti tra le opzioni."
  },
  "use_arrow_keys_to_select_a_shape_c8eb57ed": {
    "message": "Usa i tasti freccia per selezionare una forma."
  },
  "use_arrow_keys_to_select_a_size_699a19f4": {
    "message": "Usa i tasti freccia per selezionare una dimensione."
  },
  "use_arrow_keys_to_select_a_text_position_72f9137c": {
    "message": "Usa i tasti freccia per selezionare una posizione testo."
  },
  "use_arrow_keys_to_select_a_text_size_65e89336": {
    "message": "Usa i tasti freccia per selezionare una dimensione testo."
  },
  "use_arrow_keys_to_select_an_outline_size_e009d6b0": {
    "message": "Usa i tasti freccia per selezionare una dimensione struttura."
  },
  "used_by_screen_readers_to_describe_the_content_of__b1e76d9e": {
    "message": "Usato da screen reader per descrivere il contenuto di un’immagine"
  },
  "used_by_screen_readers_to_describe_the_video_37ebad25": {
    "message": "Usato dagli screen reader per descrivere il video"
  },
  "user_documents_c206e61f": { "message": "Documenti utente" },
  "user_files_78e21703": { "message": "File utente" },
  "user_images_b6490852": { "message": "Immagini utente" },
  "user_media_14fbf656": { "message": "Elementi multimediali utente" },
  "video_options_24ef6e5d": { "message": "Opzioni video" },
  "video_options_tray_3b9809a5": { "message": "Barra delle opzioni video" },
  "video_player_for_9e7d373b": { "message": "Riproduttore video per " },
  "video_player_for_title_ffd9fbc4": {
    "message": "Riproduttore video per { title }"
  },
  "view_ba339f93": { "message": "Visualizza" },
  "view_description_30446afc": { "message": "Visualizza descrizione" },
  "view_keyboard_shortcuts_34d1be0b": {
    "message": "Visualizza scelte rapide da tastiera"
  },
  "view_predefined_colors_92f5db39": {
    "message": "Visualizza colori predefiniti"
  },
  "view_title_description_67940918": {
    "message": "Visualizza descrizione { title }"
  },
  "white_87fa64fd": { "message": "Bianco" },
  "width_492fec76": { "message": "Larghezza" },
  "width_and_height_must_be_numbers_110ab2e3": {
    "message": "La larghezza e l''altezza devono essere numerici"
  },
  "width_x_height_px_ff3ccb93": { "message": "{ width } x { height }px" },
  "wiki_home_9cd54d0": { "message": "Home page wiki" },
  "yes_dde87d5": { "message": "Sì" },
  "you_may_not_upload_an_empty_file_11c31eb2": {
    "message": "Non si possono caricare file vuoti"
  },
  "zoom_in_image_bb97d4f": { "message": "Ingrandisci immagine" },
  "zoom_out_image_d0a0a2ec": { "message": "Riduci immagine" }
}


formatMessage.addLocale({it: locale})
