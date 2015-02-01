# encoding: UTF-8
require "prawn/measurement_extensions"

class Pdf
  def self.generate(filename)
    label_height = 300
    label_width = 180
    col_count = 3
    row_count = 2
    margin = 10
    box_width = label_width - 2 * margin
    box_height = 12
    wine = Vin.new(
      :nom => 'Redwood Creek Frei Brothers',
      :millesime => "2015",
      :cepage => "Cabernet-sauvignon",
      :region => "États-Unis",
      :pastille => "Aromatique et souple",
      :degustation => "Vin arborant une couleur rouge cerise de bonne intensité. Nez assez puissant dégageant des effluves de cassonade, de pâtisserie, de confiture de fraises et de framboise. Ce rouge laisse percevoir une agréable fraîcheur et est pourvu de tannins enrobés. Il révèle une texture souple qui précède une finale assez persistante.",
      :boire => "maintenant",
      :temperature => "14 - 16°C",
      :prix => "16,20 $",
      :accords => "Panini au poulet grillé et pancetta croustillante avec mayonnaise aux tomates séchées. Rouleaux de printemps au canard confit. Côtes levées de dos à la bière noire et au miel. Steaks d'entrecôte à la sauce bordelaise",
      :achat => "12,95 $ (-20%)",
      :date_achat => "2015-01")
    Prawn::Document.generate(filename) {
      dash(3, :space => 2)
      stroke_color "aaaaaa"
      self.line_width = 0.5
      (0.upto(row_count - 1)).each { |row|
        (0.upto(col_count - 1)).each { |col|
          bounding_box([label_width * col, (row_count * label_height) - row * label_height], :width => label_width, :height => label_height) {
            stroke_bounds
            stroke {
              r = 27.mm / 2
              circle [label_width / 2, label_height - r - 60], r
            }
            font("Helvetica", :size => 10) {
              bounding_box([margin, label_height - margin], :width => box_width, :height => label_height - 2 * margin) {
                font("Helvetica", :style => :bold, :size => 12) {
                  text_box wine.nom, :at => [0, label_height - margin * 2], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                }
                line_no = 0
                text_box wine.cepage, :at => [0, label_height - margin * 2 - box_height * line_no += 1], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                text_box wine.region, :at => [0, label_height - margin * 2 - box_height * line_no += 1], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                text_box wine.millesime, :at => [0, label_height - margin * 2 - box_height * line_no += 1], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit
                text_box wine.achat, :at => [box_width / 2 + margin / 2, label_height - margin * 2 - box_height * line_no], :width => box_width / 2, :height => box_height, :overflow => :shrink_to_fit, :align => :right
                text_box wine.boire, :at => [0, label_height - margin * 2 - box_height * line_no += 1], :width => box_width, :height => box_height, :overflow => :shrink_to_fit
                font("Helvetica", :size => 9) {
                  text_box wine.accords, :at => [0, 120], :width => box_width + margin / 2, :height => 200, :overflow => :shrink_to_fit
                }
              }
            }
            rotate(90, :origin => [0, 0]) {
              float {
                text_box "V2.0  © Nicolas Marchildon 2015,  © Société des alcools du Québec, Montréal, 2007, 2010",
                  :at => [5, -2], :width => label_height, :height => 6, :overflow => :shrink_to_fit
              }
            }
          }
        }
      }
      start_new_page
      (0.upto(row_count - 1)).each { |row|
        (0.upto(col_count - 1)).each { |col|
          bounding_box([label_width * col, (row_count * label_height) - row * label_height], :width => label_width, :height => label_height) {
            stroke_bounds
            font("Helvetica", :size => 10) {
              bounding_box([margin, label_height - margin], :width => box_width, :height => label_height - 2 * margin) {
                font("Helvetica", :size => 9) {
                  text_box wine.degustation, :at => [0, 120], :width => box_width + margin / 2, :height => 200, :overflow => :shrink_to_fit
                }
              }
            }
          }
        }
      }
    }
  end
end