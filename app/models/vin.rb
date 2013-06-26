class Vin
  include ActiveModel::Validations
  include ActiveModel::Conversion
  attr_accessor :cup, :nom, :saq, :cup, :pays, :cepage, :alcool, :region, :millesime, :pastille, :degustation, :garde, :boire, :temperature, :prix, :accords, :achat, :quantite
  
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
end
