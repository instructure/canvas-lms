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
import '../tinymce/ko_KR'

const locale = {
  "add_8523c19b": { "message": "추가" },
  "all_4321c3a1": { "message": "전부" },
  "alpha_15d59033": { "message": "알파" },
  "announcement_list_da155734": { "message": "공지 목록" },
  "announcements_a4b8ed4a": { "message": "공지" },
  "apply_781a2546": { "message": "적용" },
  "apps_54d24a47": { "message": "앱" },
  "arrows_464a3e54": { "message": "화살표" },
  "aspect_ratio_will_be_preserved_cb5fdfb8": { "message": "비율을 유지" },
  "assignments_1e02582c": { "message": "과제" },
  "attributes_963ba262": { "message": "속성" },
  "basic_554cdc0a": { "message": "기본" },
  "cancel_caeb1e68": { "message": "취소" },
  "click_to_embed_imagename_c41ea8df": {
    "message": "Click to embed { imageName }"
  },
  "click_to_insert_a_link_into_the_editor_c19613aa": {
    "message": "Click to insert a link into the editor."
  },
  "close_d634289d": { "message": "닫기" },
  "collaborations_5c56c15f": { "message": "협업" },
  "content_1440204b": { "message": "내용" },
  "content_type_2cf90d95": { "message": "내용 유형" },
  "count_plural_one_item_loaded_other_items_loaded_857023b7": {
    "message": "{ count, plural,\n  other {}\n}"
  },
  "course_files_a31f97fc": { "message": "과목 파일" },
  "course_navigation_dd035109": { "message": "과목 탐색" },
  "delimiters_4db4840d": { "message": "구분자" },
  "details_98a31b68": { "message": "세부 정보" },
  "dimensions_45ddb7b7": { "message": "치수" },
  "discussions_a5f96392": { "message": "토론" },
  "discussions_index_6c36ced": { "message": "토론 색인" },
  "done_54e3d4b6": { "message": "마침" },
  "edit_c5fbea07": { "message": "편집" },
  "embed_image_1080badc": { "message": "이미지 포함" },
  "external_tools_6e77821": { "message": "외부도구" },
  "files_c300e900": { "message": "파일" },
  "files_index_af7c662b": { "message": "파일 색인" },
  "format_4247a9c5": { "message": "형식" },
  "grades_a61eba0a": { "message": "평점" },
  "greek_65c5b3f7": { "message": "그리스 문자" },
  "group_files_82e5dcdb": { "message": "그룹 파일" },
  "group_navigation_99f191a": { "message": "그룹 탐색" },
  "home_351838cd": { "message": "홈" },
  "icon_215a1dc6": { "message": "아이콘" },
  "image_8ad06": { "message": "이미지" },
  "images_7ce26570": { "message": "이미지" },
  "insert_593145ef": { "message": "삽입" },
  "insert_link_6dc23cae": { "message": "링크 삽입" },
  "invalid_file_type_881cc9b2": { "message": "유효하지 않은 파일 유형" },
  "invalid_url_cbde79f": { "message": "잘못된 URL" },
  "keyboard_shortcuts_ed1844bd": { "message": "키보드 단축키" },
  "link_7262adec": { "message": "Link" },
  "links_14b70841": { "message": "링크" },
  "links_to_an_external_site_de74145d": {
    "message": "외부 사이트로 연결합니다."
  },
  "loading_25990131": { "message": "로드하는 중..." },
  "loading_bde52856": { "message": "로드 중" },
  "loading_failed_b3524381": { "message": "Loading failed..." },
  "locked_762f138b": { "message": "잠김" },
  "media_af190855": { "message": "미디어" },
  "minimize_file_preview_da911944": { "message": "파일 미리 보기 최소화" },
  "minimize_video_20aa554b": { "message": "비디오 최소화" },
  "misc_3b692ea7": { "message": "기타" },
  "modules_c4325335": { "message": "모듈" },
  "my_files_2f621040": { "message": "내 파일" },
  "name_1aed4a1b": { "message": "이름" },
  "no_e16d9132": { "message": "아니요" },
  "no_results_940393cf": { "message": "No results." },
  "none_3b5e34d2": { "message": "없음" },
  "operators_a2ef9a93": { "message": "연산자" },
  "pages_e5414c2c": { "message": "페이지" },
  "people_b4ebb13c": { "message": "사용자" },
  "percentage_34ab7c2c": { "message": "퍼센트" },
  "preview_53003fd2": { "message": "미리 보기" },
  "quizzes_7e598f57": { "message": "퀴즈" },
  "record_7c9448b": { "message": "녹음/녹화" },
  "relationships_6602af70": { "message": "관계" },
  "reset_95a81614": { "message": "원래대로" },
  "save_11a80ec3": { "message": "저장" },
  "search_280d00bd": { "message": "검색" },
  "size_b30e1077": { "message": "크기" },
  "sort_by_e75f9e3e": { "message": "정렬 조건" },
  "star_8d156e09": { "message": "별표 표시" },
  "submit_a3cc6859": { "message": "제출" },
  "syllabus_f191f65b": { "message": "요강" },
  "the_document_preview_is_currently_being_processed__7d9ea135": {
    "message": "문서 미리 보기를 처리 중입니다. 나중에 다시 시도하시기 바랍니다."
  },
  "this_equation_cannot_be_rendered_in_basic_view_9b6c07ae": {
    "message": "이 수식은 기본 뷰에 렌더링할 수 없습니다."
  },
  "title_ee03d132": { "message": "제목" },
  "upload_file_fd2361b8": { "message": "파일 업로드" },
  "uploading_19e8a4e7": { "message": "업로드 중" },
  "url_22a5f3b8": { "message": "URL" },
  "view_ba339f93": { "message": "보기" },
  "wiki_home_9cd54d0": { "message": "위키 홈" },
  "yes_dde87d5": { "message": "예" }
}


formatMessage.addLocale({ko: locale})
