# encoding: UTF-8
require 'rubygems'
require 'mechanize'

class SearchController < ApplicationController

  def index
    if params[:q]
      @wines = params[:q].gsub(/\r\n?/, " ").gsub(/\s+/, ' ').split(' ').map { |code| get_wine(code) }
#      @wines.each do |wine|
#        qr = RQRCode::QRCode.new(wine.cup, :size => 4, :level => :l)
#        qr.to_img.resize(30, 30).save("public/qr/30/#{wine.cup}.png")
#      end
      @wine_batch = WineBatch.new
      @wine_batch.wines = @wines
      render :action => "prepare"
    end
  end

  private

  def get_page(cup)
    cached_page = CachedPage.where(key: cup).order("created_at DESC").limit(1).first
    if (cached_page.nil?)
      logger.info "GET SAQ: #{cup}"
      @agent = Mechanize.new
      @agent.default_encoding = 'utf-8'
      @agent.force_default_encoding = true
      page = @agent.get('http://www.saq.com/webapp/wcs/stores/servlet/SearchDisplay?storeId=20002&catalogId=50000&langId=-2&pageSize=20&beginIndex=0&searchTerm=' + cup)
      cached_page = CachedPage.new(:key => cup, :value => page.parser.to_s.encode('utf-8'))
      cached_page.save!
      sleep 1
      page.parser
    else
      logger.info "CACHE SAQ: #{cup}"
      page_body = cached_page.value.force_encoding('utf-8')
      Nokogiri::HTML::Document.parse(page_body)
    end
  end

  def get_wine(cup)
    cup = cup.rjust(14, '0')
    page = get_page(cup)
    unless page.css('.product-description-title').first
      logger.error("No product description found for " + cup)
      return Vin.new
    end
    details = Hash[page.css("#details/ul/li/div").map { |node| node.content.gsub(/\r\n?/, " ").gsub(/\s+/, ' ').strip }.each_slice(2).to_a]
    # {"Pays"=>"France", "Région"=>"Sud-Ouest", "Appellation d'origine"=>"Cahors", "Désignation réglementée"=>"AOC", "Producteur"=>"...", "Cépage(s)"=>"Malbec 100 %", "couleur"=>"Rouge", "Format"=>"750 ml  ", "Degré d'alcool"=>"13 %", "Type de bouchon"=>"Liège", "Type de contenant"=>"Verre"}
    temp_spacer = page.css('#tasting/div/p/span').first
    garde = page.css('#tasting/div/table').first
    return Vin.new(:cup => cup,
      :nom => page.css('.product-description-title').first.content.strip,
      :saq => page.css('.product-description-code-saq').first.next_sibling.content.strip,
      :pays => page.css('.product-page-subtitle').first.content.strip,
      :cepage => details["Cépage(s)"].to_s.sub(/ 100.?%/, ''),
      :alcool => details["Degré d'alcool"],
      :region => details["Région"],
      :millesime => '',
      :pastille => '', #page.css('.prod-pastille/img').first['alt'].sub(/.*: /, '').strip,
      :degustation => page.css('#tasting/div/p').map { |node| node.content.strip }.join(' ').strip,
      :garde => (garde.content.strip if garde),
      :boire => (garde.content.strip.sub(/.*garder (.+) ans.*/, '\1').to_i if garde),
      :temperature => ((temp_spacer.previous_sibling.content.strip + " " + " " + temp_spacer.next_sibling.content.strip).gsub(/\r\n?/, " ").gsub(/\s+/, ' ').sub(/De :/, '').sub(/°C À :/, ' -').strip if temp_spacer),
      :prix => page.css('.price').first.content.strip,
      :accords => page.css("span[class='recipes-name']").map { |node| node.content.strip }.join('. ').strip,
      :achat => '',
      :quantite => 1)
  end

end
