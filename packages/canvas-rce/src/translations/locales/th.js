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
import '../tinymce/th'

const locale = {
  "accessibility_checker_b3af1f6c": {
    "message": "ระบบตรวจสอบการใช้งาน"
  },
  "action_to_take_b626a99a": {
    "message": "การดำเนินการที่จะมีขึ้น:"
  },
  "add_a_caption_2a915239": {
    "message": "เพิ่มคำบรรยาย"
  },
  "add_alt_text_for_the_image_48cd88aa": {
    "message": "เพิ่มข้อความเผื่อเลือกสำหรับภาพ"
  },
  "adjacent_links_with_the_same_url_should_be_a_singl_7a1f7f6c": {
    "message": "ลิงค์ที่ติดกันกับ URL เหมือน ๆ กันควรเป็นลิงค์แยกเดี่ยว"
  },
  "alt_attribute_text_should_not_contain_more_than_12_e21d4040": {
    "message": "ข้อความคุณลักษณะเผื่อเลือกไม่ควรยาวเกินกว่า 120 ตัวอักษร"
  },
  "apply_781a2546": {
    "message": "ปรับใช้"
  },
  "change_alt_text_92654906": {
    "message": "เปลี่ยนข้อความเผื่อเลือก"
  },
  "change_heading_tag_to_paragraph_a61e3113": {
    "message": "เปลี่ยนหมายเหตุกำกับหัวเรื่องสำหรับย่อหน้า"
  },
  "change_text_color_1aecb912": {
    "message": "เปลี่ยนสีข้อความ"
  },
  "check_accessibility_3c78211c": {
    "message": "ตรวจสอบการใช้งาน"
  },
  "checking_for_accessibility_issues_fac18c6d": {
    "message": "กำลังตรวจสอบปัญหาการใช้งาน"
  },
  "close_accessibility_checker_29d1c51e": {
    "message": "ปิดระบบตรวจสอบการใช้งาน"
  },
  "column_e1ae5c64": {
    "message": "คอลัมน์"
  },
  "column_group_1c062368": {
    "message": "กลุ่มคอลัมน์"
  },
  "decorative_image_fde98579": {
    "message": "ภาพตกแต่ง"
  },
  "element_starting_with_start_91bf4c3b": {
    "message": "องค์ประกอบเริ่มต้นด้วย { start }"
  },
  "fix_heading_hierarchy_f60884c4": {
    "message": "แก้ไขโครงสร้างหัวเรื่อง"
  },
  "header_column_f27433cb": {
    "message": "คอลัมน์หัวเรื่อง"
  },
  "header_row_and_column_ec5b9ec": {
    "message": "แถวและคอลัมน์หัวเรื่อง"
  },
  "header_row_f33eb169": {
    "message": "แถวหัวเรื่อง"
  },
  "heading_levels_should_not_be_skipped_3947c0e0": {
    "message": "ไม่ควรข้ามระดับหัวเรื่อง"
  },
  "heading_starting_with_start_42a3e7f9": {
    "message": "หัวเรื่องเริ่มต้นด้วย { start }"
  },
  "headings_should_not_contain_more_than_120_characte_3c0e0cb3": {
    "message": "หัวเรื่องไม่ควรยาวมากกว่า 120 ตัวอักษร"
  },
  "image_filenames_should_not_be_used_as_the_alt_attr_bcfd7780": {
    "message": "ชื่อไฟล์ภาพไม่ควรใช้เป็นคุณลักษณะเผื่อเลือกเพื่อระบุเนื้อหาในภาพ"
  },
  "image_with_filename_file_aacd7180": {
    "message": "ภาพพร้อมชื่อไฟล์ { file }"
  },
  "images_should_include_an_alt_attribute_describing__b86d6a86": {
    "message": "ภาพควรมีคุณลักษณะเผื่อเลือกระบุเนื้อหาของภาพ"
  },
  "issue_num_total_f94536cf": {
    "message": "ประเด็น { num }/{ total }"
  },
  "keyboards_navigate_to_links_using_the_tab_key_two__5fab8c82": {
    "message": "แป้นพิมพ์สืบค้นลิงค์ต่าง ๆ โดยใช้ปุ่ม Tab ลิงค์สองตัวที่ติดกันที่นำไปยังปลายทางเดียวกันอาจทำให้ผู้ใช้แป้นพิมพ์เกิดความสับสน"
  },
  "learn_more_a79a7918": {
    "message": "เรียนรู้เพิ่มเติม"
  },
  "leave_as_is_4facfe55": {
    "message": "ปล่อยไว้ตามเดิม"
  },
  "link_with_text_starting_with_start_b3fcbe71": {
    "message": "ลิงค์ที่มีข้อความเริ่มต้นด้วย { start }"
  },
  "merge_links_2478df96": {
    "message": "ผสานลิงค์"
  },
  "next_40e12421": {
    "message": "ถัดไป"
  },
  "no_accessibility_issues_were_detected_f8d3c875": {
    "message": "ไม่พบปัญหาในการใช้งาน"
  },
  "no_headers_9bc7dc7f": {
    "message": "ไม่มีหัวเรื่อง"
  },
  "none_3b5e34d2": {
    "message": "ไม่มี"
  },
  "paragraph_starting_with_start_a59923f8": {
    "message": "ย่อหน้าที่เริ่มต้นด้วย { start }"
  },
  "prev_f82cbc48": {
    "message": "ก่อนหน้า"
  },
  "remove_heading_style_5fdc8855": {
    "message": "ลบรูปแบบหัวเรื่อง"
  },
  "row_fc0944a7": {
    "message": "แถว"
  },
  "row_group_979f5528": {
    "message": "กลุ่มแถว"
  },
  "screen_readers_cannot_determine_what_is_displayed__6a5842ab": {
    "message": "ตัวอ่านหน้าจอไม่สามารถพิจารณาได้ว่าอะไรที่ปรากฏอยู่ในภาพหากไม่มีข้อความเผื่อเลือก และชื่อไฟล์มักเป็นชุกอักขระที่ไม่มีความหมายเฉพาะประกอบไปด้วยตัวเลขและตัวอักษรที่ไม่เกี่ยวข้องกับบริบทหรือความหมายแฝง"
  },
  "screen_readers_cannot_determine_what_is_displayed__6f1ea667": {
    "message": "ตัวอ่านหน้าจอไม่สามารถระบุเนื้อหาที่จัดแสดงในภาพหากไม่ีข้อความเผื่อเลือกเพื่อระบุบริบทและความหมายของภาพ ข้อความเผื่อเลือกควรกระชับและเข้าใจได้ง่าย"
  },
  "screen_readers_cannot_determine_what_is_displayed__a57e6723": {
    "message": "ตัวอ่านหน้าจอไม่สามารถระบุเนื้อหาที่จัดแสดงในภาพหากไม่ีข้อความเผื่อเลือกเพื่อระบุบริบทและความหมายของภาพ"
  },
  "screen_readers_cannot_interpret_tables_without_the_bd861652": {
    "message": "ตัวอ่านหน้าจอไม่สามารถแปลความหมายตารางโดยไม่มีโครงสร้างที่ถูกต้อง หัวเรื่องตารางระบุทิศทางและขอบเขตของเนื้อหา"
  },
  "screen_readers_cannot_interpret_tables_without_the_e62912d5": {
    "message": "ตัวอ่านหน้าจอไม่สามารถแปลความหมายตารางโดยไม่มีโครงสร้างที่ถูกต้อง คำบรรยายตารางระบุบริบทและรายละเอียดทั่วไปเกี่ยวกับตารางดังกล่าว"
  },
  "screen_readers_cannot_interpret_tables_without_the_f0bdec0f": {
    "message": "ตัวอ่านหน้าจอไม่สามารถแปลความหมายตารางโดยไม่มีโครงสร้างที่ถูกต้อง หัวตารางกำหนดทิศทางและภาพรวมของเนื้อหา"
  },
  "set_header_scope_8c548f40": {
    "message": "กำหนดขอบเขตหัวเรื่อง"
  },
  "set_table_header_cfab13a0": {
    "message": "กำหนดหัวเรื่องตาราง"
  },
  "sighted_users_browse_web_pages_quickly_looking_for_1d4db0c1": {
    "message": "ผู้ใช้ที่อ่านได้เองจะเรียกดูหน้าเว็บได้อย่างรวดเร็ว ทั้งหัวเรื่องตัวใหญ่และตัวหนา ผู้ใช้ตัวอ่านหน้าจอจะต้องอาศัยหัวเรื่องเพื่อทำความเข้าใจบริบทแวดล้อม หัวเรื่องควรใช้โครงสร้างที่เหมาะสม"
  },
  "sighted_users_browse_web_pages_quickly_looking_for_ade806f5": {
    "message": "ผู้ใช้ที่อ่านได้เองจะเรียกดูหน้าเว็บได้อย่างรวดเร็ว ทั้งหัวเรื่องตัวใหญ่และตัวหนา ผู้ใช้ตัวอ่านหน้าจอจะต้องอาศัยหัวเรื่องเพื่อทำความเข้าใจบริบทแวดล้อม หัวเรื่องควรกระชับและอยู่ภายในโครงสร้างที่เหมาะสม"
  },
  "table_header_starting_with_start_ffcabba6": {
    "message": "หัวเรื่องตารางเริ่มต้นด้วย { start }"
  },
  "table_starting_with_start_e7232848": {
    "message": "ตารางเริ่มต้นด้วย { start }"
  },
  "tables_headers_should_specify_scope_5abf3a8e": {
    "message": "หัวเรื่องตารางควรระบุขอบเขต"
  },
  "tables_should_include_a_caption_describing_the_con_e91e78fc": {
    "message": "ตารางควรครอบคลุมคำบรรยายระบุเนื้อหาของตาราง"
  },
  "tables_should_include_at_least_one_header_48779eac": {
    "message": "ตารางควรมีหัวเรื่องอย่างน้อยหนึ่งรายการ"
  },
  "text_is_difficult_to_read_without_suffcient_contra_27b82183": {
    "message": "ข้อความยากในการอ่านหากไม่มีความเปรียบต่างที่ชัดเจนระหว่างข้อความและพื้นหลัง โดยเฉพาะสำหรับผู้ที่สายตาไม่ดี"
  },
  "text_larger_than_18pt_or_bold_14pt_should_display__5c364db6": {
    "message": "ข้อความที่ใหญ่กว่า 18pt (หรือตัวหนา 14pt) ควรมีระดับความเปรียบต่างขั้นต่ำที่ 3:1"
  },
  "text_smaller_than_18pt_or_bold_14pt_should_display_aaffb22b": {
    "message": "ข้อความที่เล็กกว่า 18pt (หรือตัวหนา 14pt) ควรมีระดับความเปรียบต่างขั้นต่ำที่ 4.5:1"
  },
  "why_523b3d8c": {
    "message": "สาเหตุ"
  }
}


formatMessage.addLocale({th: locale})
