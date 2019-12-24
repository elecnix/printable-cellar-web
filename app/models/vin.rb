# encoding: UTF-8
class Vin
  include ActiveModel::Validations
  include ActiveModel::Conversion
  attr_accessor :cup, :nom, :saq, :pays, :cepage, :alcool, :region, :millesime, :pastille, :degustation, :garde, :boire, :temperature, :prix, :accords, :achat, :date_achat, :quantite
  
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def url
    'http://www.saq.com/webapp/wcs/stores/servlet/SearchDisplay?storeId=20002&catalogId=50000&langId=-2&pageSize=20&beginIndex=0&searchTerm=' + cup.to_s
  end
  
  def rebate_percent
    return 0 if achat.nil? || prix.nil?
    (1.0 - (achat / prix)) * 100
  end
  
  def flatten
    (1.upto quantite.to_i).map { v = self.clone; v.quantite = 1; v }
  end
end
