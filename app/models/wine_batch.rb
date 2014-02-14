class WineBatch
  include ActiveRecord::Validations
  attr_accessor :wines
  def apply_rebate(rebate)
    wines.each do |wine|
      unless wine.prix.nil?
        initial_rebate = wine.prix - wine.achat
        wine.achat = wine.prix - initial_rebate - wine.achat * (rebate / 100.0)
      end
    end
  end
end
