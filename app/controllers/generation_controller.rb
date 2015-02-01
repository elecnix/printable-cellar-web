# encoding: utf-8
require 'rqrcode_png'
require 'prawn'

class GenerationController < ApplicationController
  def new
    wines = params['wine'].values.inject([]) { |sheet, wine_attributes| sheet + Vin.new(wine_attributes).flatten }
    date = DateTime.now.strftime('%F')
    random = SecureRandom.urlsafe_base64[0..7]
    tmp_file = Rails.root.join('tmp', "printable-cellar-" + date + "-" + random + ".pdf")
    puts "Generating to #{tmp_file}"
    Pdf.generate(tmp_file, wines)
    send_file(tmp_file)
    # TODO remove temporary file
  end
end
