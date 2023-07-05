# CanvasLinkMigration

CanvasLinkMigration handles importing links to other course content (ie Assignments, Quizzes, Content Pages etc, that are created by the RichContentService using Canvas APIs) exported from Canvas.

## Usage

Create a CanvasLinkMigrator::ImportedHtmlConvert using an asset_id_mapping (Get the asset_id_mapping from Canvas API after a migration) and then pass in the html_string data to be imported.

```ruby
converter = CanvasLinkMigrator::ImportedHtmlConvert.new(ResourceMapService.new(asset_id_mapping))
converter.convert_and_replace(html_string)
```

Use convert and resolve_content_links! separately if desired
