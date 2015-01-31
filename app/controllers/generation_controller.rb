# encoding: utf-8
require 'rqrcode_png'
require 'zip/zip'

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
    # Create an array with 9 wines (full sheet)
    wine_sheet = params['wine'].values.inject([]) { |sheet, wine_attributes| sheet + Vin.new(wine_attributes).flatten }
    # Fill the rest of the page with empty wine info
    wine_sheet.fill(wine_sheet.length, 9) { |i| Vin.new }

    # Load LibreOffice document (un-zip)
    src_odg = "app/printable-cellar-legal-fr.odg"
    date = DateTime.now.strftime('%F')
    random = SecureRandom.urlsafe_base64[0..7]
    tmp_file = Rails.root.join('tmp', "printable-cellar-" + date + "-" + random + ".odg")
    puts "Copying to #{tmp_file}"
    puts `cp "#{src_odg}" "#{tmp_file}"`
    content = ""
    manifest = ""
    Zip::ZipFile.open(src_odg, false) { |zipfile|
      puts "Replacing..."
      content = zipfile.read("content.xml").force_encoding('utf-8')
      manifest = zipfile.read("META-INF/manifest.xml").force_encoding('utf-8')
    }
    puts "content.xml has #{content.size}"

    # Perform replacement in the document
    wine_sheet.each_slice(3) do |row_wines|
      row_wines.each { |wine| replace_recto(wine, content) }
      row_wines.reverse_each { |wine| replace_verso(wine, content) }
    end
    replace_tags(wine_sheet, content)

    def append_manifest(manifest_xml, picture)
      manifest_xml.sub!(/(<\/manifest:manifest>)/, "<manifest:file-entry manifest:full-path=\"Pictures/#{picture}\" manifest:media-type=\"\"/>\\1")
    end
    
    # Add QR codes files to Jar manifest
    wine_sheet.each do |wine|
      if wine.cup
        append_manifest(manifest, "#{wine.cup}.png")
      end
    end
    append_manifest(manifest, "qr-empty.png")

    # Re-zip document and send it
    Zip::ZipFile.open(tmp_file, false) { |zipfile|
      zipfile.get_output_stream("content.xml") { |f| f.puts content }
      zipfile.get_output_stream("META-INF/manifest.xml") { |f| f.puts manifest }
      zipfile.add("Pictures/qr-empty.png", "app/qr-empty.png") 
      wine_sheet.each do |wine|
        if wine.cup
          zipfile.get_output_stream("Pictures/#{wine.cup}.png") { |f|
            qr = RQRCode::QRCode.new(wine.cup, :size => 4, :level => :h)
            qr.to_img.resize(200, 200).save(f)
          }
        end
      end
    }
    puts "Send..."
    send_file(tmp_file)
    # TODO remove temporary file
  end
end
