# Please read: http://msdn.microsoft.com/en-us/library/ie/dn455106.aspx
xml.instruct!
xml.browserconfig do
  xml.msapplication do
    xml.tile do
      xml.square70x70logo   src: @domain_root_account.settings[:msapplication_tile_square].presence || "/windows-tile.png"
      xml.square150x150logo src: @domain_root_account.settings[:msapplication_tile_square].presence || "/windows-tile.png"
      xml.wide310x150logo   src: @domain_root_account.settings[:msapplication_tile_wide].presence   || "/windows-tile-wide.png"
      xml.square310x310logo src: @domain_root_account.settings[:msapplication_tile_square].presence || "/windows-tile.png"
      xml.TileColor @domain_root_account.settings[:msapplication_tile_color].presence               || '#009900' # This is $canvas-primary from sass. If you change this, make sure to change it in the placeholder in app/views/accounts/settings.html.erb too.
    end
  end
end
