# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Factories
  def wiki_page_model(opts = {})
    context = opts.delete(:course) || opts.delete(:context) || @course || (course_with_student(active_all: true) && @course)
    opts = opts.slice(:title, :body, :url, :user_id, :user, :editing_roles, :notify_of_update, :todo_date)
    @page = context.wiki_pages.create!(valid_wiki_page_attributes.merge(opts))
  end

  def block_editor_page_with_media
    @block_editor_page = @copy_from.wiki_pages.create!(title: "title", body: "<address><ul></ul></address>")
    @block_editor_media_attachment_1 = Attachment.create!(context: @copy_from, folder: Folder.root_folders(@copy_from).first, media_entry_id: "m-frommediaobject", display_name: "media-that-goes-into-an-actual-media-block.mp4", filename: "media-that-goes-into-an-actual-media-block.mp4", uploaded_data: StringIO.new("media"))
    @block_editor_media_attachment_2 = Attachment.create!(context: @copy_from, folder: Folder.root_folders(@copy_from).first, media_entry_id: "m-frommediaobject-2", display_name: "media-that-goes-into-the-rce-block.mp4", filename: "media-that-goes-into-the-rce-block.mp4", uploaded_data: StringIO.new("media"))
    MediaObject.create! media_id: "m-frommediaobject", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: @block_editor_media_attachment_1.id, media_type: "video/webm"
    MediaObject.create! media_id: "m-frommediaobject-2", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: @block_editor_media_attachment_2.id, media_type: "video/webm"
    @block_editor_image_1 = Attachment.create!(context: @copy_from, folder: Folder.root_folders(@copy_from).first, display_name: "image-that-goes-into-an-image-block.jpg", filename: "image-that-goes-into-an-image-block.jpg", uploaded_data: StringIO.new("image"))
    @block_editor_image_2 = Attachment.create!(context: @copy_from, folder: Folder.root_folders(@copy_from).first, display_name: "image-that-goes-into-the-rce-block.jpg", filename: "image-that-goes-into-the-rce-block.jpg", uploaded_data: StringIO.new("image"))
    BlockEditor.create! context: @block_editor_page, editor_version: "0.2", blocks: fixture_blocks
    @block_editor_page
  end

  def block_editor_page_with_global_images
    @block_editor_page = @copy_from.wiki_pages.create!(title: "title", body: "<address><ul></ul></address>")
    BlockEditor.create! context: @block_editor_page, editor_version: "0.2", blocks: fixture_template_blocks
    @block_editor_page
  end

  def block_editor_page_with_empty_images
    @block_editor_page = @copy_from.wiki_pages.create!(title: "title", body: "<address><ul></ul></address>")
    BlockEditor.create! context: @block_editor_page, editor_version: "0.2", blocks: fixture_minimal_empty_image_blocks
    @block_editor_page
  end

  def fixture_blocks
    rce_block_txt = <<~HTML
      <p>
        <iframe
          style="width: 400px; height: 225px; display: inline-block;"
          title="Video player for 1718848236_Sample_1.mp4"
          data-media-type="video"
          src="/media_attachments_iframe/#{@block_editor_media_attachment_2.id}?type=video&amp;embedded=true"
          data-media-id="#{@block_editor_media_attachment_2.reload.media_entry_id}"
        ></iframe>
        <img
          src="/courses/#{@copy_from.id}/files/#{@block_editor_image_2.id}/preview"
          width="400" height="225"
        />
      </p>
    HTML
    {
      "ROOT" => {
        "type" => {
          "resolvedName" => "PageBlock"
        },
        "nodes" => ["yue4mpUChN"],
        "props" => {},
        "custom" => {
          "displayName" => "Blank Page"
        },
        "hidden" => false,
        "isCanvas" => true,
        "displayName" => "Page",
        "linkedNodes" => {}
      },
      "13kQFSc-L3" => {
        "type" => {
          "resolvedName" => "GroupBlock"
        },
        "nodes" => [],
        "props" => {
          "id" => "columns-pEdeFvz6_0-1",
          "layout" => "row",
          "isColumn" => true,
          "alignment" => "start",
          "resizable" => false,
          "roundedCorners" => false,
          "verticalAlignment" => "start"
        },
        "custom" => {
          "isBlock" => true, "displayName" => "Column", "isResizable" => false
        },
        "hidden" => false,
        "parent" => "_LWmxgLGU8",
        "isCanvas" => true,
        "displayName" => "Group",
        "linkedNodes" => {
          "group__inner" => "Ef7hf8YVK5"
        }
      },
      "Ef7hf8YVK5" => {
        "type" => {
          "resolvedName" => "NoSections"
        },
        "nodes" => %w[wlatZhI-P8 rq_jYNdueq _8byC2eDxh],
        "props" => {
          "className" => "group-block__inner",
          "placeholderText" => "Drop a block to add it here"
        },
        "custom" => {
          "noToolbar" => true
        },
        "hidden" => false,
        "parent" => "13kQFSc-L3",
        "isCanvas" => true,
        "displayName" => "NoSections",
        "linkedNodes" => {}
      },
      "_8byC2eDxh" => {
        "type" => {
          "resolvedName" => "RCETextBlock"
        },
        "nodes" => [],
        "props" => {
          "text" => rce_block_txt,
          "sizeVariant" => "auto"
        },
        "custom" => {
          "isBlock" => true, "isResizable" => true
        },
        "hidden" => false,
        "parent" => "Ef7hf8YVK5",
        "isCanvas" => false,
        "displayName" => "Text",
        "linkedNodes" => {}
      },
      "_LWmxgLGU8" => {
        "type" => {
          "resolvedName" => "ColumnsSectionInner"
        },
        "nodes" => ["13kQFSc-L3"],
        "props" => {},
        "custom" => {
          "noToolbar" => true
        },
        "hidden" => false,
        "parent" => "yue4mpUChN",
        "isCanvas" => true,
        "displayName" => "Columns Inner",
        "linkedNodes" => {}
      },
      "rq_jYNdueq" => {
        "type" => {
          "resolvedName" => "ImageBlock"
        },
        "nodes" => [],
        "props" => {
          "alt" => "",
          "src" => "http://#{HostUrl.default_host}/courses/#{@copy_from.id}/files/#{@block_editor_image_1.id}/preview",
          "variant" => "default",
          "constraint" => "cover",
          "sizeVariant" => "auto",
          "maintainAspectRatio" => false
        },
        "custom" => {
          "isBlock" => true, "isResizable" => false
        },
        "hidden" => false,
        "parent" => "Ef7hf8YVK5",
        "isCanvas" => false,
        "displayName" => "Image",
        "linkedNodes" => {}
      },
      "wlatZhI-P8" => {
        "type" => {
          "resolvedName" => "MediaBlock"
        },
        "nodes" => [],
        "props" => {
          "src" => "http://#{HostUrl.default_host}/media_attachments_iframe/#{@block_editor_media_attachment_1.id}",
          "title" => "",
          "width" => 417,
          "height" => 314,
          "attachmentId" => "83",
          "maintainAspectRatio" => true
        },
        "custom" => {
          "isBlock" => true, "isResizable" => true
        },
        "hidden" => false,
        "parent" => "Ef7hf8YVK5",
        "isCanvas" => false,
        "displayName" => "Media",
        "linkedNodes" => {}
      },
      "yue4mpUChN" => {
        "type" => {
          "resolvedName" => "ColumnsSection"
        },
        "nodes" => [],
        "props" => {
          "columns" => 1
        },
        "custom" => {
          "isSection" => true
        },
        "hidden" => false,
        "parent" => "ROOT",
        "isCanvas" => false,
        "displayName" => "Columns",
        "linkedNodes" => {
          "columns__inner" => "_LWmxgLGU8"
        }
      }
    }
  end

  def fixture_template_blocks
    { "ROOT" =>
       { "type" => { "resolvedName" => "PageBlock" },
         "nodes" => ["Rztq3QJmgX"],
         "props" => {},
         "custom" => { "displayName" => "Course Home - Elementary" },
         "hidden" => false,
         "isCanvas" => true,
         "displayName" => "Page",
         "linkedNodes" => {} },
      "2dG8NCQo6D" =>
       { "type" => { "resolvedName" => "ImageBlock" },
         "nodes" => [],
         "props" => { "alt" => "", "src" => "/images/block_editor/templates/teacherNote.svg", "variant" => "default", "constraint" => "cover", "sizeVariant" => "auto", "maintainAspectRatio" => false },
         "custom" => { "isBlock" => true, "isResizable" => false },
         "hidden" => false,
         "parent" => "Yr5XzlwVH2",
         "isCanvas" => false,
         "displayName" => "Image",
         "linkedNodes" => {} },
      "E2-qOwLGHV" =>
       { "type" => { "resolvedName" => "GroupBlock" },
         "nodes" => [],
         "props" => { "id" => "columns-pEdeFvz6_0-1", "layout" => "column", "isColumn" => true, "alignment" => "center", "resizable" => false, "roundedCorners" => false, "verticalAlignment" => "center" },
         "custom" => { "isBlock" => true, "displayName" => "Column", "isResizable" => false },
         "hidden" => false,
         "parent" => "g-rO-j_SaM",
         "isCanvas" => true,
         "displayName" => "Group",
         "linkedNodes" => { "group__inner" => "Yr5XzlwVH2" } },
      "Rztq3QJmgX" =>
       { "type" => { "resolvedName" => "ColumnsSection" },
         "nodes" => [],
         "props" => { "columns" => 1, "background" => "#F9FAFFFF" },
         "custom" => { "isSection" => true },
         "hidden" => false,
         "parent" => "ROOT",
         "isCanvas" => false,
         "displayName" => "Columns",
         "linkedNodes" => { "columns__inner" => "g-rO-j_SaM" } },
      "Yr5XzlwVH2" =>
       { "type" => { "resolvedName" => "NoSections" },
         "nodes" => ["2dG8NCQo6D", "tUF84HE2cn"],
         "props" => { "className" => "group-block__inner", "placeholderText" => "Drop a block to add it here" },
         "custom" => { "noToolbar" => true },
         "hidden" => false,
         "parent" => "E2-qOwLGHV",
         "isCanvas" => true,
         "displayName" => "NoSections",
         "linkedNodes" => {} },
      "g-rO-j_SaM" =>
       { "type" => { "resolvedName" => "ColumnsSectionInner" },
         "nodes" => ["E2-qOwLGHV"],
         "props" => {},
         "custom" => { "noToolbar" => true },
         "hidden" => false,
         "parent" => "Rztq3QJmgX",
         "isCanvas" => true,
         "displayName" => "Columns Inner",
         "linkedNodes" => {} },
      "tUF84HE2cn" =>
       { "type" => { "resolvedName" => "ImageBlock" },
         "nodes" => [],
         "props" =>
          { "alt" => "",
            "src" => "/images/block_editor/templates/global-1.svg",
            "width" => 96.875,
            "height" => 100,
            "variant" => "default",
            "constraint" => "contain",
            "sizeVariant" => "percent",
            "maintainAspectRatio" => false },
         "custom" => { "isBlock" => true, "isResizable" => true },
         "hidden" => false,
         "parent" => "Yr5XzlwVH2",
         "isCanvas" => false,
         "displayName" => "Image",
         "linkedNodes" => {} } }
  end

  def fixture_minimal_empty_image_blocks
    { "ROOT" =>
       { "type" => { "resolvedName" => "PageBlock" },
         "nodes" => ["yue4mpUChN"],
         "props" => {},
         "custom" => { "displayName" => "Blank Page" },
         "hidden" => false,
         "isCanvas" => true,
         "displayName" => "Page",
         "linkedNodes" => {} },
      "13kQFSc-L3" =>
       { "type" => { "resolvedName" => "GroupBlock" },
         "nodes" => [],
         "props" =>
          { "id" => "columns-pEdeFvz6_0-1",
            "layout" => "row",
            "isColumn" => true,
            "alignment" => "start",
            "resizable" => false,
            "roundedCorners" => false,
            "verticalAlignment" => "start" },
         "custom" => { "isBlock" => true, "displayName" => "Column", "isResizable" => false },
         "hidden" => false,
         "parent" => "_LWmxgLGU8",
         "isCanvas" => true,
         "displayName" => "Group",
         "linkedNodes" => { "group__inner" => "Ef7hf8YVK5" } },
      "Ef7hf8YVK5" =>
       { "type" => { "resolvedName" => "NoSections" },
         "nodes" => ["FUN8kk-ph7"],
         "props" => { "className" => "group-block__inner", "placeholderText" => "Drop a block to add it here" },
         "custom" => { "noToolbar" => true },
         "hidden" => false,
         "parent" => "13kQFSc-L3",
         "isCanvas" => true,
         "displayName" => "NoSections",
         "linkedNodes" => {} },
      "FUN8kk-ph7" =>
       { "type" => { "resolvedName" => "ImageBlock" },
         "nodes" => [],
         "props" => { "alt" => "", "src" => "", "variant" => "default", "constraint" => "cover", "sizeVariant" => "auto", "maintainAspectRatio" => false },
         "custom" => { "isBlock" => true, "isResizable" => false },
         "hidden" => false,
         "parent" => "Ef7hf8YVK5",
         "isCanvas" => false,
         "displayName" => "Image",
         "linkedNodes" => {} },
      "_LWmxgLGU8" =>
       { "type" => { "resolvedName" => "ColumnsSectionInner" },
         "nodes" => ["13kQFSc-L3"],
         "props" => {},
         "custom" => { "noToolbar" => true },
         "hidden" => false,
         "parent" => "yue4mpUChN",
         "isCanvas" => true,
         "displayName" => "Columns Inner",
         "linkedNodes" => {} },
      "yue4mpUChN" =>
       { "type" => { "resolvedName" => "ColumnsSection" },
         "nodes" => [],
         "props" => { "columns" => 1 },
         "custom" => { "isSection" => true },
         "hidden" => false,
         "parent" => "ROOT",
         "isCanvas" => false,
         "displayName" => "Columns",
         "linkedNodes" => { "columns__inner" => "_LWmxgLGU8" } } }
  end

  def wiki_page_assignment_model(opts = {})
    @page = opts.delete(:wiki_page) || wiki_page_model(opts)
    assignment_model({
      course: @page.course,
      wiki_page: @page,
      submission_types: "wiki_page",
      title: "Content Page Assignment",
      due_at: nil
    }.merge(opts))
  end

  def valid_wiki_page_attributes
    {
      title: "some page"
    }
  end
end
