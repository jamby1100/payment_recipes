def load_keys(filename)
  output = {}

  File.read(filename).split("\n").each do |pair|
    key, value = pair.split("=")
    output[key] = value.gsub("\"", "")
  end

  output
end

KEYS = load_keys(".keys")