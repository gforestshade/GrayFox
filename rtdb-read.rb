require 'open-uri'
require 'json'

def rtdb_read(hash)
  base_uri = 'https://grayfox-6701c.firebaseio.com/'
  uri = URI.parse("#{base_uri}/writes/#{hash}.json")
  body = uri.read
  JSON.parse(uri.read)
end

