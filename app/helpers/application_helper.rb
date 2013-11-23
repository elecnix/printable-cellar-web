module ApplicationHelper
  def number_to_currency_qc_fr(n)
    number_with_precision(n, :separator => ',', :precision => 2) + " $"
  end
end

