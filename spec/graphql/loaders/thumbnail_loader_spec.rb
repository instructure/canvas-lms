# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Loaders::ThumbnailLoader do
  before :once do
    course_with_teacher(active_all: true)
  end

  it "preloads thumbnails for multiple attachments" do
    # Create multiple attachments
    attachments = Array.new(3) do |i|
      attachment_with_context(@course, uploaded_data: stub_png_data, content_type: "image/png", filename: "test#{i}.png")
    end

    # Load all attachments through the loader
    GraphQL::Batch.batch do
      loader = Loaders::ThumbnailLoader.for
      attachments.each do |attachment|
        loader.load(attachment).then do |preloaded_attachment|
          # Verify the thumbnails association is loaded
          expect(preloaded_attachment.association(:thumbnails)).to be_loaded
        end
      end
    end
  end

  it "preloads parent attachments for thumbnails to prevent N+1" do
    # Create attachments with thumbnails
    attachments = Array.new(2) do |i|
      attachment_with_context(@course, uploaded_data: stub_png_data, content_type: "image/png", filename: "test#{i}.png")
    end

    # Create thumbnails for each attachment (avoid duplicates)
    attachments.map do |attachment|
      attachment.thumbnails.find_or_create_by!(thumbnail: "thumb") do |thumb|
        thumb.uploaded_data = stub_png_data
      end
    end

    GraphQL::Batch.batch do
      loader = Loaders::ThumbnailLoader.for
      attachments.each do |attachment|
        loader.load(attachment).then do |preloaded_attachment|
          # Verify thumbnails are preloaded
          expect(preloaded_attachment.association(:thumbnails)).to be_loaded

          # Verify each thumbnail has its parent attachment preloaded
          preloaded_attachment.thumbnails.each do |thumbnail|
            expect(thumbnail.association(:attachment)).to be_loaded
          end
        end
      end
    end
  end

  it "prevents N+1 queries when accessing thumbnails" do
    # Create multiple attachments
    attachments = Array.new(3) do |i|
      attachment_with_context(@course, uploaded_data: stub_png_data, content_type: "image/png", filename: "test#{i}.png")
    end

    # Count thumbnail-related queries
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      query_count += 1 if /SELECT.*thumbnails.*parent_id/.match?(payload[:sql])
    end

    # Access thumbnails through the loader
    GraphQL::Batch.batch do
      attachments.each do |attachment|
        Loaders::ThumbnailLoader.for.load(attachment).then(&:thumbnail)
      end
    end

    # Should have at most one bulk preload query
    expect(query_count).to be <= 1
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it "prevents N+1 queries when thumbnails access parent attachments" do
    # Create attachments with thumbnails
    attachments = Array.new(2) do |i|
      attachment_with_context(@course, uploaded_data: stub_png_data, content_type: "image/png", filename: "test#{i}.png")
    end

    # Create thumbnails for each attachment (avoid duplicates)
    attachments.each do |attachment|
      attachment.thumbnails.find_or_create_by!(thumbnail: "thumb") do |thumb|
        thumb.uploaded_data = stub_png_data
      end
    end

    # Count attachment lookup queries (the specific N+1 we're fixing)
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      # Match pattern: SELECT "attachments".* FROM ... WHERE "attachments"."id" = $1 LIMIT 1
      query_count += 1 if /SELECT.*attachments.*FROM.*attachments.*WHERE.*attachments.*id.*= \$1 LIMIT 1/.match?(payload[:sql])
    end

    GraphQL::Batch.batch do
      attachments.each do |attachment|
        Loaders::ThumbnailLoader.for.load(attachment).then do |preloaded_attachment|
          # Access thumbnail.cached_s3_url which calls attachment.context (triggers N+1 without fix)
          preloaded_attachment.thumbnails.each(&:cached_s3_url)
        end
      end
    end

    # Should have zero individual attachment lookup queries
    expect(query_count).to eq(0)
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  it "handles attachments with no thumbnails gracefully" do
    # Create attachment without thumbnails
    attachment = attachment_with_context(@course, uploaded_data: stub_file_data("test.txt", "plain text content", "text/plain"), content_type: "text/plain", filename: "test.txt")

    GraphQL::Batch.batch do
      Loaders::ThumbnailLoader.for.load(attachment).then do |preloaded_attachment|
        expect(preloaded_attachment.association(:thumbnails)).to be_loaded
        expect(preloaded_attachment.thumbnails).to be_empty
        expect(preloaded_attachment.thumbnail).to be_nil
      end
    end
  end
end
