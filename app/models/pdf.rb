# encoding: UTF-8
require "prawn/measurement_extensions"

class Pdf
  def self.generate(filename, wines)
    label_height = 275
    label_width = 180
    col_count = 3
    row_count = 2
    labels_per_page = col_count * row_count
    margin = 10
    box_width = label_width - 2 * margin
    box_height = 12
    Prawn::Document.generate(filename) {
      dash(3, :space => 2)
      stroke_color "aaaaaa"
      self.line_width = 0.5
      sheet_index = 0
      sheet_count = (wines.length.to_f / labels_per_page).ceil
      Rails.logger.info("Wines: #{wines.length}, pages: #{sheet_count}")
      1.upto(sheet_count).each {
        start_new_page if sheet_index > 0
        stroke_rectangle [0, label_height * row_count], label_width * col_count, label_height * row_count
        1.upto(col_count - 1).each { |col| stroke_line [label_width * col, 0], [label_width * col, label_height * row_count] }
        1.upto(row_count - 1).each { |row| stroke_line [0, label_height * row], [label_width * col_count, label_height * row] }
        0.upto(row_count - 1).each { |row|
          0.upto(col_count - 1).each { |col|
            wine = wines[labels_per_page * sheet_index + ((row) * col_count) + col]
            if wine
              bounding_box([label_width * col, (row_count * label_height) - row * label_height], :width => label_width, :height => label_height) {
                #stroke_bounds
                stroke {
                  r = 30.mm / 2
                  circle [label_width / 2, label_height - r - 60], r
                }
                font("Helvetica", :size => 9) {
                  bounding_box([margin, label_height - margin], :width => box_width, :height => label_height - 2 * margin) {
                    font("Helvetica", :style => :bold, :size => 12) {
                      text_box wine.nom, :at => [0, label_height - margin * 2], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                    }
                    line_no = 1.0
                    text_box wine.cepage, :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                    line_no += 1
                    text_box wine.pays || '', :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                    line_no += 1
                    text_box "Millesime:", :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height * 0.4, :overflow => :shrink_to_fit
                    line_no += 0.4
                    font("Helvetica", :style => :bold, :size => 10) {
                      text_box wine.millesime, :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit
                    }
                    line_no += 1
                    text_box "Achat:", :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height * 0.4, :overflow => :shrink_to_fit
                    line_no += 0.4
                    text_box wine.date_achat, :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit
                    font("Helvetica", :size => 10) {
                      text_box wine.prix, :at => [box_width / 2 + margin / 2, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit, :align => :right
                    } 
                    line_no += 1
                    text_box "Boire:", :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height * 0.4, :overflow => :shrink_to_fit
                    line_no += 0.4
                    boire = (wine.millesime && wine.boire.to_i > 0 ? (wine.millesime.to_i + wine.boire.to_i).to_s + (wine.millesime.to_i > 0 ? '' : ' ans') : (wine.millesime.nil? ? '' : 'maintenant'))
                    text_box boire, :at => [0, label_height - margin * 2 - box_height * line_no], :width => box_width / 4, :height => box_height, :overflow => :shrink_to_fit
                    line_no += 1
                    font("Helvetica", :size => 9) {
                      text_box wine.accords, :at => [0, 90], :width => box_width + margin / 2, :height => 200, :overflow => :shrink_to_fit
                    }
                  }
                }
                rotate(90, :origin => [0, 0]) {
                  float {
                    text_box "V2.0.1  © Nicolas Marchildon 2015,  © Société des alcools du Québec, Montréal, 2007, 2010",
                      :at => [5, -2], :width => label_height, :height => 6, :overflow => :shrink_to_fit
                  }
                }
                # Code QR
                if wine.cup
                  qr_file = "#{wine.cup}.png"
                  qr = RQRCode::QRCode.new(wine.cup, :size => 4, :level => :h)
                  qr.to_img.resize(200, 200).save(qr_file)
                  image qr_file, :at => [margin, 150], :width => 15.mm
                end
                # Pastille
                if wine.pastille
                  tag_width = 15.mm
                  tag = TasteTag::MAPPINGS[wine.pastille]
                  image "public/images/pastilles/#{tag[0]}.png", :at => [box_width - tag_width + margin, 150], :width => tag_width if tag
                end
              }
            end
          }
        }
        start_new_page
        stroke_rectangle [0, label_height * row_count], label_width * col_count, label_height * row_count
        1.upto(col_count - 1).each { |col| stroke_line [label_width * col, 0], [label_width * col, label_height * row_count] }
        1.upto(row_count - 1).each { |row| stroke_line [0, label_height * row], [label_width * col_count, label_height * row] }
        (0.upto(row_count - 1)).each { |row|
          (0.upto(col_count - 1)).each { |col|
            wine = wines[labels_per_page * sheet_index + ((row) * col_count) + col]
            if wine
              col = col_count - col - 1
              bounding_box([label_width * col, (row_count * label_height) - row * label_height], :width => label_width, :height => label_height) {
                font("Helvetica", :size => 10) {
                  bounding_box([margin, label_height - margin], :width => box_width, :height => label_height - 2 * margin) {
                    line_no = 0
                    text_box wine.achat, :at => [box_width / 2 + margin / 2, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit, :align => :right
                    font("Helvetica", :size => 9) {
                      text_box wine.degustation, :at => [0, 120], :width => box_width + margin / 2, :height => 200, :overflow => :shrink_to_fit
                    }
                  }
                }
            }
            end
          }
        }
        sheet_index += 1
      }
    }
  end
end