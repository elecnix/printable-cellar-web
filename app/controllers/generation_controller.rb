# encoding: utf-8

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
    tmp = SecureRandom.urlsafe_base64
    tmp_dir = Rails.root.join('tmp', tmp)
    puts "Writing to #{tmp_dir}"
    puts `mkdir -p "#{tmp_dir}"`
    puts "Unzip..."
    puts `unzip "#{src_odg}" content.xml -d "#{tmp_dir}"`
    puts "Replace..."
    content = File.read("#{tmp_dir}/content.xml")
    puts "content.xml has #{content.size}"
    params['wine'].values.each_slice(3) do |row|
      row_wines = row.map { |wine_attributes| Vin.new(wine_attributes) }
      row_wines.each { |wine| replace_recto(wine, content) }
      row_wines.reverse_each { |wine| replace_verso(wine, content) }
    end
    
    # Fill the rest of the page, if any
    empty = Vin.new
    (1..9).each { replace_recto(empty, content) ; replace_verso(empty, content) }
    
    File.open("#{tmp_dir}/content.xml", "w") { |file| file.puts content }
    puts "Copy..."
    puts `cp "#{src_odg}" "#{tmp_dir}/fiche.odg"`
    puts "chmod..."
    puts `chmod u+w "#{tmp_dir}/fiche.odg"`
    puts "Zip..."
    puts `zip -j -r "#{tmp_dir}/fiche.odg" "#{tmp_dir}/content.xml"`
    puts "Send..."
    send_file "#{tmp_dir}/fiche.odg"
  end
end
