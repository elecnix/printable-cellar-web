# encoding: UTF-8
require 'rubygems'
require 'mechanize'

class SearchController < ApplicationController

  def index
    if params[:q]
      @wines = params[:q].gsub(/\r\n?/, " ").gsub(/\s+/, ' ').split(' ').map { |code| get_wine(code) }
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
    page = get_page(cup)
    unless page.css('.product-description-title').first
      logger.error("No product description found for " + cup)
      return Vin.new
    end
    details = Hash[page.css("#details/ul/li/div").map { |node| node.content.gsub(/\r\n?/, " ").gsub(/\s+/, ' ').strip }.each_slice(2).to_a]
    # {"Pays"=>"France", "Région"=>"Sud-Ouest", "Appellation d'origine"=>"Cahors", "Désignation réglementée"=>"AOC", "Producteur"=>"...", "Cépage(s)"=>"Malbec 100 %", "couleur"=>"Rouge", "Format"=>"750 ml  ", "Degré d'alcool"=>"13 %", "Type de bouchon"=>"Liège", "Type de contenant"=>"Verre"}
    temp_spacer = page.css('#tasting/div/p/span').first
    garde = page.css('#tasting/div/table').first
    attributes = {
      :cup => cup,
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
      attributes[:prix] = cart.at_css('.initialprice').content.strip
      attributes[:achat] = cart.at_css('.price-rebate').content.strip
    else
      attributes[:prix] = cart.at_css('.price').text().strip
      attributes[:achat] = ''
    end
    return Vin.new(attributes)
  end

  def clean_string(input)
    input.gsub(/\r\n?/, " ").gsub(/[[:space:]]/, ' ').gsub(/\s+/, ' ') if input
  end
end
