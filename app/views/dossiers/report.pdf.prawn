prawn_document(:page_size => 'A4') do |pdf|

  items = @dossiers.map do |item|
    @report[:columns].inject([]) do |output, attr|
      output.push(show_column_for_report(item, attr, true))
    end
  end

  header_column = @report[:columns].inject([]) do |output, attr|
    output << show_header_for_report(attr)
  end

  pdf.text @report[:title] if @report[:title]

  pdf.move_down(20)

  pdf.table items, :headers => header_column,
                   :row_colors => ["FFFFFF","DDDDDD"],
                   :column_widths => {0 => 70, 1 => pdf.margin_box.width - 70 - 150, 2 => 150},
                   :width => pdf.margin_box.width,
                   :position => :center,
                   :align => {0 => :left, 1 => :left, 2 => :right},
                   :align_headers => :left


  pdf.repeat :all do
    pdf.stroke_line [pdf.bounds.right - 50, 0], [pdf.bounds.right, 0]
  end

  pdf.number_pages "<page>", :at => [pdf.bounds.right - 150, -5],
                             :width => 150,
                             :align => :right,
                             :page_filter => :all,
                             :start_count_at => 1,
                             :total_pages => pdf.page_count

end