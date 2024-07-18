class Xode < ApplicationRecord
  belongs_to :node_value, class_name: 'XodeValue'
  belongs_to :parent, optional: true, class_name: 'Xode'
  def to_client_hash
    h = {}
    meta = h['meta'] = {}
    meta['name'] = name
    meta['id'] = iid
    meta['nid'] = id
    h['value'] = value
    h
  end
  def value
    @value ||= get_value
  end

  # private

  def get_value
    if node_value_id == 0
      { value: nil }
    elsif node_value.source_id
      { source_id: node_value.source_id }
    elsif node_value.text
      {
        docid: node_value.docid,
        beg: node_value.begi,
        end: node_value.endi,
        text: node_value.text
      }
    elsif node_value.begi and node_value.endi
      {
        beg: node_value.begi,
        end: node_value.endi
      }
    elsif node_value.begr and node_value.endr.nil?
      {
        docid: node_value.docid,
        beg: node_value.begr.to_f
      }
    elsif node_value.begr
      h = {
        docid: node_value.docid,
        beg: node_value.begr.to_f,
        end: node_value.endr.to_f
      }
      h[:value] = node_value.value if node_value.value
      # h[:timestamps] = node_value.timestamps if node_value.timestamps
      h
    else
      { value: node_value.value }
    end
  end
end
