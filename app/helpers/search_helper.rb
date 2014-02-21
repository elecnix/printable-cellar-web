# encoding: UTF-8
module SearchHelper
  def taste_tag(id, size = 's')
    tag = TasteTag::MAPPINGS[id]
    tag('img', src: "images/tags/dark/#{tag[0]}_s.png", title: tag[1], class: 'taste-tag-' + size) if tag
  end
end
