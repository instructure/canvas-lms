# read: http://msdn.microsoft.com/en-us/library/ie/dn455106.aspx to learn more about browserconfig.xml
xml.instruct!
xml.browserconfig do
  xml.msapplication do
    xml.tile do
      xml.square70x70logo   src: brand_variable('ic-brand-msapplication-tile-square')
      xml.square150x150logo src: brand_variable('ic-brand-msapplication-tile-square')
      xml.wide310x150logo   src: brand_variable('ic-brand-msapplication-tile-wide')
      xml.square310x310logo src: brand_variable('ic-brand-msapplication-tile-square')
      xml.TileColor brand_variable('ic-brand-msapplication-tile-color')
    end
  end
end