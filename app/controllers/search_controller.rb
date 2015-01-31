# encoding: UTF-8
require 'rubygems'
require 'mechanize'

class SearchController < ApplicationController

  def index
    if params[:q]
      @wines = params[:q].gsub(/\r\n?/, " ").gsub(/\s+/, ' ').split(' ').map { |code| get_wine(normalize_code(code)) }
      @wine_batch = @wines.inject(WineBatch.new) { |batch, wine| batch << wine }
      @rebate = params[:rebate].to_i
      @wine_batch.apply_rebate(@rebate) if @rebate > 0
      if params[:export]
        render :action => "export"
      else
        render :action => "prepare"
      end
    end
  end

  private

  def normalize_code(code)
    # A UPC barcode is also an EAN-13 barcode with the first digit set to zero.
    # EAN-13: "LLLLLLRRRRRRX"
    # Some UPC codes have a leading zero that is not scanned, so: 99988071096 => 00099988071096
    # Le code SAQ comporte 8 chiffres?
    if code.length > 8
      code.rjust(13, '0')
    else
      code
    end
  end

  def get_page(cup)
    cached_page = CachedPage.where(['key = ? and created_at > ?', cup, 1.day.ago]).order("created_at DESC").limit(1).first
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
    page = get_page(cup)
    unless page.css('.product-description-title').first
      logger.error("No product description found for " + cup)
      return Vin.new(:cup => cup)
    end
    details = Hash[page.css("#details/ul/li/div").map { |node| node.content.gsub(/\r\n?/, " ").gsub(/\s+/, ' ').strip }.each_slice(2).to_a]
    # {"Pays"=>"France", "Région"=>"Sud-Ouest", "Appellation d'origine"=>"Cahors", "Désignation réglementée"=>"AOC", "Producteur"=>"...", "Cépage(s)"=>"Malbec 100 %", "couleur"=>"Rouge", "Format"=>"750 ml  ", "Degré d'alcool"=>"13 %", "Type de bouchon"=>"Liège", "Type de contenant"=>"Verre"}
    temp_spacer = page.css('#tasting/div/p/span').first
    garde = page.css('#tasting/div/table').first
    cup_result = page.at_css('.product-description-code-cpu').next_sibling.content.strip
    cup_result = cup if cup_result.empty?
    attributes = {
      :cup => cup_result,
      :nom => page.at_css('.product-description-title').content.strip,
      :saq => page.at_css('.product-description-code-saq').next_sibling.content.strip,
      :pays => page.at_css('.product-page-subtitle').content.strip,
      :cepage => details["Cépage(s)"].to_s.sub(/ 100.?%/, ''),
      :alcool => details["Degré d'alcool"],
      :region => details["Région"],
      :millesime => '',
      :pastille => page.xpath("//table[@class='product-description-table']/tr/td/a/img").map { |node| node['src'].sub(/.*\/(..)-g_fr.png/, '\1') }.first,
      :degustation => page.css('.tasting-title').select { |node| node.content == "Note de dégustation" }.map { |node| node.next_element.content.strip }.join(' ').strip,
      :garde => (garde.content.strip if garde),
      :boire => (garde.content.strip.sub(/.*garder (.+) ans.*/, '\1').to_i if garde),
      :temperature => (clean_string(temp_spacer.previous_sibling.content.strip + " " + " " + temp_spacer.next_sibling.content.strip).gsub(/\s+/, ' ').sub(/De : /, '').sub(/°C À : /, ' - ') if temp_spacer),
      :accords => page.css("span[class='recipes-name']").map { |node| node.content.strip }.join('. ').strip,
      :quantite => 1
    }
    cart = page.at_css('.product-add-to-cart-meta')
    cart.css('.hors-ecran, .rabais-etoile').map { |node| node.remove() }
    if (cart.at_css('.price-rebate'))
      attributes[:prix] = cart.at_css('.initialprice').content.strip.gsub(/,/, '.').gsub(/[$\s]/, '').to_f
      attributes[:achat] = cart.at_css('.price-rebate').content.strip.gsub(/,/, '.').gsub(/[$\s]/, '').to_f
    else
      attributes[:prix] = cart.at_css('.price').text().strip.gsub(/,/, '.').gsub(/[$\s]/, '').to_f
      attributes[:achat] = attributes[:prix]
    end
    return Vin.new(attributes)
  end

  def clean_string(input)
    input.gsub(/\r\n?/, " ").gsub(/[[:space:]]/, ' ').gsub(/\s+/, ' ') if input
  end
end
