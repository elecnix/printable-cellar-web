# encoding: utf-8
require 'rqrcode_png'
require 'zip/zip'
require 'prawn'

class GenerationController < ApplicationController

  def escape(string)
    CGI.escapeHTML(string.to_s)
  end
  def replace_recto(wine, content)
    content.sub!(/\$nom/, escape(wine.nom))
    content.sub!(/\$cepage/, escape(wine.cepage))
    content.sub!(/\$pays/, escape(wine.pays))
    content.sub!(/\$millesime/, escape(wine.millesime))
    content.sub!(/\$boire/, escape(wine.millesime && wine.boire.to_i > 0 ? (wine.millesime.to_i + wine.boire.to_i).to_s + (wine.millesime.to_i > 0 ? '' : ' ans') : (wine.millesime.nil? ? '' : 'maintenant')))
    content.sub!(/\$prix/, escape(wine.achat == wine.prix ? '' : wine.prix))
    content.sub!(/\$achat/, escape([wine.prix, wine.achat].min))
    content.sub!(/\$accords/, escape(wine.accords))
    content.sub!(/10000000000000CB000000CB4F4C2532.png/, "#{wine.cup || 'qr-empty'}.png")
  end
  def replace_verso(wine, content)
    content.sub!(/\$alcool/, escape(wine.alcool))
    content.sub!(/\$degustation/, escape(wine.degustation))
    content.sub!(/\$temperature/, escape(wine.temperature))
    content.sub!(/\$date/, escape(wine.date_achat))
  end
  def replace_tags(wines, content)
    # Remove taste tags that do not match the current wine
    # A taste tag looks like this in the ODF document: 
    #   <draw:frame draw:name="blanc-aromatique-rond" draw:style-name="gr1" draw:text-style-name="P1" draw:layer="layout" svg:width="2.767cm" svg:height="2.767cm" svg:x="12.495cm" svg:y="7.563cm">
    #     <draw:image xlink:href="Pictures/100002010000028E0000028EFE59EE7F.png" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad">
    #       <text:p/>
    #     </draw:image>
    #   </draw:frame>
    wine_tags = wines.map { |wine|
      tag = TasteTag::MAPPINGS[wine.pastille]
      tag[0] if tag
    }
    i = -1
    tag_counts = Hash.new(0)
    content.gsub!(/(<draw:frame draw:name="(.*?)" .*?<\/draw:frame>)/) { |p|
      i = i + 1
      tag_counts[$2] += 1
      $1 if $2 == wine_tags[tag_counts[$2] - 1] || $2 == "qr"
    }
  end

  def new
#    wine_sheet = params['wine'].values.inject([]) { |sheet, wine_attributes| sheet + Vin.new(wine_attributes).flatten }
    date = DateTime.now.strftime('%F')
    random = SecureRandom.urlsafe_base64[0..7]
    tmp_file = Rails.root.join('tmp', "printable-cellar-" + date + "-" + random + ".pdf")
    puts "Generating to #{tmp_file}"
    Pdf.generate(tmp_file)
    send_file(tmp_file)
    # TODO remove temporary file
  end
end
