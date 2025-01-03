class MessageSerializer
  include JSONAPI::Serializer
  attributes :id, :contents, :created_at, :updated_at, :true_heading
end
