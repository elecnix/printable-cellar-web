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

end
