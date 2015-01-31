# encoding: UTF-8
class Pdf
  def self.generate
    Prawn::Document.generate("generate.pdf") do
      text "Hello World"
    end
  end
end