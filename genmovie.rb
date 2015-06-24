require 'open3'
require 'RMagick'
include Magick

DEBUG = false
FPS = 1

VOICES = "voices"
VOICE_FMT = "m4a"
FRAMES = "frames"

FW = 1280
FH = 720
FW_2 = FW/2
FH_2 = FH/2

@frames = []

def sh(command)
  ret = Open3.capture3(command)
  if DEBUG
    $stderr.puts ret[1]
  end
  return ret[0]
end

def sec2time(sec)
  date = Time.new(0)
  d = date + sec
  return d.strftime("%H:%M:%S.%L")
end

def get_text(id)
  if @jimaku != nil
    txt = @jimaku[id-1]
    return txt
  else
    raise "jimaku is not initialized"
  end
end

def voicefile(id)
  return "#{VOICES}/#{id}.#{VOICE_FMT}"
end

def get_sec(path)
  file = path
  # ret = sh "ffprobe -i #{file} 2>&1 | grep Duration"

  # s = Open3.capture3("ffprobe -i #{file}")[1]

  # ret = ""
  # s.each_line do |line|
  #   line.strip!
  #   if line.include? "Duration"
  #     ret = line
  #     break
  #   end
  # end

  ret = sh "soxi -D #{file}"
  # p ret
  return sec2time(Float(ret)*0.50)

  # return ret.split(/[:,] /)[1]
end

def gen_frame(id,max)
  c = id*3
  w_id = c-2
  m_id = c-1
  n_id = c
  wv = voicefile(w_id)
  mv = voicefile(m_id)
  nv = voicefile(n_id)

  # get audio length
  # if id == 1
  #   @none_sec = voice_sec(n_id)
  # end
  # word_sec = voice_sec(w_id)
  # mean_sec = voice_sec(m_id)

  # movie_len = sec2time(word_sec + mean_sec + @none_sec)

  print " #{id}/#{max} "
  print "."

  # join audio files
  joinList = [wv,mv,nv].map{|f| "file '#{f}'"}.join("\n")
  File.write('concat-voices.txt',joinList)

  soundFile = "#{FRAMES}/a#{id}.wav" # aac
  sh "ffmpeg -f concat -i concat-voices.txt #{soundFile}"

  # get movie length
  movie_len = get_sec(soundFile)
  # p movie_len

  print "."

  # generate frame
  canvas = Image.new(FW,FH) do |c|
    c.background_color = "white"
  end
  dr = Draw.new
  dr.font = '/Library/Fonts/Hiragino Sans GB W6.otf'
  dr.stroke('transparent')
  dr.fill('black')
  dr.pointsize = 50 # 文字サイズ
  dr.text(100, FH_2-50, get_text(id))
  dr.draw(canvas)

  dr.font = '/Library/Fonts/Hiragino Sans GB W6.otf'
  dr.stroke('transparent')
  dr.fill('gray')
  dr.pointsize = 50 # 文字サイズ
  dr.text(100, FH_2-200, id.to_s)
  dr.draw(canvas)

  imageFile = "#{FRAMES}/im#{id.to_s.rjust(6,'0')}.png"
  canvas.write(imageFile)
  canvas.destroy!

  print "."

  # generate movie
  movieOnlyFile = "#{FRAMES}/__#{id.to_s.rjust(6,'0')}.avi"
  movieFile = "#{FRAMES}/#{id.to_s.rjust(6,'0')}.avi"
  sh "ffmpeg -f image2 -r #{FPS} -loop 1 -t #{movie_len} -i #{imageFile} #{movieOnlyFile}"
  sh "ffmpeg -i #{movieOnlyFile} -i #{soundFile} #{movieFile}"

  sh "rm -rf #{soundFile} #{movieOnlyFile} #{imageFile}"

  @frames.push(movieFile)

  puts "ok"
end


# ==============================

if ARGV[0] != 'skip_voices'
  `ruby parse.rb voices`
end

@jimaku = []
jf = File.read('jimaku-words.txt')
jf.each_line do |line|
  line.strip!
  @jimaku.push line
end

`mkdir -p #{FRAMES}`
`rm -rf #{FRAMES}/*`

max = Dir.glob("#{VOICES}/**").size/3
# max = 8 # test

max.times do |i|
  id = i+1
  gen_frame(id,max)
end

# concat frames
concat_file = ""
@frames.each do |path|
  concat_file += "file '#{path}'\n"
end
File.write("frame-concat.txt",concat_file)
puts

`ffmpeg -f concat -i "frame-concat.txt" -vcodec libx264 english-words.mp4`
`rm -rf #{FRAMES} concat-voices.txt`

