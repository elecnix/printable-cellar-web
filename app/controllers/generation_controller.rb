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
    content.sub!(/\$boire/, escape(wine.boire))
    content.sub!(/\$prix/, escape(wine.prix))
    content.sub!(/\$temperature/, escape(wine.temperature))
    content.sub!(/\$accords/, escape(wine.accords))
  end
  def replace_verso(wine, content)
    content.sub!(/\$alcool/, escape(wine.alcool))
    content.sub!(/\$degustation/, escape(wine.degustation))
    content.sub!(/\$achat/, escape(wine.achat))
  end

  def new
    src_odg = "app/printable-cellar-legal-fr.odg"
    date = DateTime.now.strftime('%F')
    random = SecureRandom.urlsafe_base64[0..7]
    tmp_file = Rails.root.join('tmp', "printable-cellar-" + date + "-" + random + ".odg")
    puts "Copying to #{tmp_file}"
    puts `cp "#{src_odg}" "#{tmp_file}"`
    content = ""
    Zip::ZipFile.open(src_odg, false) { |zipfile|
      puts "Replace..."
      content = zipfile.read("content.xml").encode
    }
    puts "content.xml has #{content.size}"
    params['wine'].values.each_slice(3) do |row|
      row_wines = row.map { |wine_attributes| Vin.new(wine_attributes) }
      row_wines.each { |wine| replace_recto(wine, content) }
      row_wines.reverse_each { |wine| replace_verso(wine, content) }
    end
    # Fill the rest of the page, if any
    empty = Vin.new
    (1..9).each { replace_recto(empty, content) ; replace_verso(empty, content) }
    
    Zip::ZipFile.open(tmp_file, false) { |zipfile|
      zipfile.get_output_stream("content.xml") { |f| f.puts content }
    }
    puts "Send..."
    send_file(tmp_file)
  end
end
