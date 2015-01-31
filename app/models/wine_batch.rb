class WineBatch
  include ActiveRecord::Validations
  attr_accessor :wines
  
  def initialize()
    @wines = []
  end
  
  def cups
    @wines.map { |wine| wine.cup }
  end
  
  def << (wine)
    cups.include?(wine.cup) ? self[wine.cup].quantite += 1 : @wines << wine
    self
  end
  
  def [](cup)
    @wines.find { |wine| wine.cup == cup }
  end
  
  def apply_rebate(rebate)
    wines.each do |wine|
      unless wine.prix.nil?
        initial_rebate = wine.prix - wine.achat
        wine.achat = wine.prix - initial_rebate - wine.achat * (rebate / 100.0)
      end
    end
  end
end
