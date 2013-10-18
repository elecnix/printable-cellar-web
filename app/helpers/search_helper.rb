# encoding: UTF-8
module SearchHelper
  def taste_tag(id)
    tag = TasteTag::MAPPINGS[id]
    tag('img', src: "images/tags/dark/#{tag[0]}_s.png", title: tag[1], class: 'taste-tag-s') if tag
  end
end
