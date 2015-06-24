require 'spreadsheet'

LOAD_FILE = "english-words.xls"
EXPORT = "voices"
CONCAT_DEF = "concat-def.txt"
MARGIN_VOICE = "none.m4a"
en_voice = "Samantha"
ja_voice = "Kyoko"
voice_fmt = "m4a"

csv = []
book = Spreadsheet.open(LOAD_FILE)
sheet = book.worksheet('words')  
sheet.each do |row|
  word = row[0]
  means = row[1]
  csv.push({:word => word, :means => means})
end

`mkdir -p #{EXPORT}`
`rm -rf #{EXPORT}/*`

# csv = csv[1..3] # test

total = csv.size
voiceFiles = (1..total*3).map {|id|
  "file '#{EXPORT}/#{id}.#{voice_fmt}'"
}.join("\n")
File.write(CONCAT_DEF,voiceFiles)

csv.each_with_index do |a, i|
  c = i*3 + 3
  size_count = " #{i+1}/#{total}"
  w_id = c-2
  m_id = c-1
  none_id = c
  # export voice of word
  puts "[Export:#{size_count}]  #{a[:word]}: #{a[:means]}"
  `say -v #{en_voice} "#{a[:word]}" -o #{EXPORT}/#{w_id}.#{voice_fmt}`
  `say -v #{ja_voice} "#{a[:means]}。" -o #{EXPORT}/#{m_id}.#{voice_fmt}`
  if i == total - 1
    `say -v Tom "finish" -r 200 -o #{EXPORT}/#{none_id}.#{voice_fmt}`
  else
    `say -v Tom "next" -r 200 -o #{EXPORT}/#{none_id}.#{voice_fmt}`
  end
end

if ARGV[0] != 'voices'
  `ffmpeg -f concat -i #{CONCAT_DEF} learning-voice.mp3`
end



