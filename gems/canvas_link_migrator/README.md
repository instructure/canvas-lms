# CanvasLinkMigration

CanvasLinkMigration processes html content from a Canvas export package and allows it to be retranslated into html with links to Canvas course content (ie Assignments, Quizzes, Content Pages etc).

## Usage

Create a CanvasLinkMigrator::ImportedHtmlConverter using an asset_id_map (Get the asset_map from the Canvas API after a migration) and then pass in the html_string data to be imported.

First create the ImportedHtmlConverter, and then pass the html string into the converter's convert_exported_html method to get the final html product

If any links cannot be resolved appropriately, a list will be returned to you with the resolved html
```ruby
converter = CanvasLinkMigrator::ImportedHtmlConverter.new(resource_map: asset_id_map)
new_html, missing_links = converter.convert_exported_html(html_string)
```
