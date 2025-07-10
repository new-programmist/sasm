require "ruby2d"
class DUMMYPEN
  def initialize
  end
  def color=(color)
    print "COLOR #{color}\n"
  end
  def clear
    print "CLEAR\n"
  end
  def width=(width)
    print "WIDTH #{width}\n"
  end
  def goto(x, y)
    print "PENGOTO #{x},#{y}\n"
  end
  def down
    print "DOWN\n"
  end
  def up
    print "UP\n"
  end
end
$main = self
def self.key_down?(key)
  Window.key_down?(key)
end
def self.draw_line(x1, y1, x2, y2, color, thickness)
  Line.new(x1: x1, y1: y1, x2: x2, y2: y2, width: thickness, color: color)
  Circle.new(x: x1, y: y1, radius: thickness / 2, color: color)
  Circle.new(x: x2, y: y2, radius: thickness / 2, color: color)
end

$pressed_keys = {}

on :key_down do |event|
  $pressed_keys[event.key] = true
end

on :key_up do |event|
  $pressed_keys[event.key] = false
end

class PEN
  def initialize
    Window.set title: "Assembly Scratch", width: 500, height: 500
    @x = 0
    @y = 0
    @color = "#FFFFFF"
    @down = false
    @thickness = 1
    @show_thread = Thread.new do
      $main.show
    end
  end
  def color=(color)
    @color = parse_argb(color)
    if @down
      $main.draw_line(@x, @y, @x, @y, @color, @thickness)
    end
  end
  def clear
    Window.clear
  end
  def width=(width)
    @thickness = width * Window.height
    if @down
      $main.draw_line(@x, @y, @x, @y, @color, @thickness)
    end
  end
  def goto(x, y)
    @x = x * Window.width + Window.width / 2
    @y = Window.height / 2 - y * Window.height
    if @down
      $main.draw_line(@x, @y, @x, @y, @color, @thickness)
    end
  end
  def down
    @down = true
    $main.draw_line(@x, @y, @x, @y, @color, @thickness)
  end
  def up
    @down = false
  end
  def parse_argb(argb)
    argb += 255 * 256 * 256 * 256
    Color.new [(argb & 0xFF0000) >> 16, (argb & 0xFF00) >> 8, argb & 0xFF, (argb & 0xFF000000) >> 24]
  end
end
$DUMMY_PEN = PEN.new
class COMPILER
  @TYPEHASH = Hash.new{|h, k| h[k] = k.to_s }
  @TYPEHASH.merge!({
    "INT" => "0",
    "int" => "0",
    "FORMAT_INT" => "0",
    "UINT" => "1",
    "uint" => "1",
    "FORMAT_UINT" => "1",
    "FLOAT" => "2",
    "float" => "2",
    "FORMAT_FLOAT" => "2",
    "UFLOAT" => "3",
    "ufloat" => "3",
    "FORMAT_UFLOAT" => "3",
  })
  def self.TYPEHASH
    @TYPEHASH
  end
  def self.KEYHASH
    @KEYHASH
  end
  @KEYHASH = Hash.new{|h, k| h[k] = k.to_s }
  [
    "`",
"1",
"2",
"3",
"4",
"5",
"6",
"7",
"8",
"9",
"0",
"-",
"=",
"backspace",
"q",
"w",
"e",
"r",
"t",
"y",
"u",
"i",
"o",
"p",
"a",
"s",
"d",
"f",
"g",
"h",
"j",
"k",
"l",
"z",
"x",
"c",
"v",
"b",
"n",
"m",
"[",
"]",
"\\",
";",
"'",
",",
".",
"/",
"tab",
"capslock",
"left shift",
"backspace",
"return",
"right shift",
"left ctrl",
"left alt",
"space",
"right alt",
"right gui",
"right ctrl",
"up",
"down",
"left",
"right",
"home",
"end",
"insert",
"delete",
"pageup",
"pagedown",
"f1",
"f2",
"f3",
"f4",
"f5",
"f6",
"f7",
"f8",
"f9",
"f10",
"f11",
"f12",
"scrolllock",
"pause",
"escape",
  ].each_with_index do |k, i|
    @KEYHASH[k] = i.to_s(16).rjust(4, "0")
  end
  def initialize(program, memory = "000000000"*65536)
    @program = program
    @variables = {}
    @tags = {}
    @memory = memory.gsub(" ", "")
  end
  def varid(name)
    if name.start_with?("@")
      name[1..4].to_i(16).to_s(16).rjust(4, "0")
    else
      (@variables[name] ||= @variables.size).to_s(16).rjust(4, "0")
    end
  end
  def tagplace(name)
    if name.start_with?("@")
      name[1..4].to_i(16)
    else
      (@tags[name] ||= @tags.size)
    end
  end
  def convval(val)
    val = (val + 0x8000) % 0x10000 - 0x8000
    if val > 0
      val.to_s(16).rjust(4, "0")
    else
      (val + 0x10000).to_s(16).rjust(4, "0")
    end
  end
  def compile
    program = @program.gsub(";", "\n").lines
    i = 0
    program.each { |line|
      line = line.chomp
      if line.empty?
        next
      end
      #args = line.split(/\s+/)
      args = line.split
      if ["SET", "CP", "ADD", "SUB", "MUL", "DIV", "JMP1IF", "JMP", "PRINT", "PACK", "JMP1IF==", "JMP1IF<", "JMP1IF>", "JMP1IF<=", "JMP1IF>=", "JMPBY", "FORMAT", "CPCFROM", "CPCTO", "PENGOTO", "PENCOLOR", "PENWIDTH", "PENUP", "PENDOWN", "PENCLEAR", "SAVELINK", "GOTOLINK", "ADDVAL", "SUBVAL", "MULVAL", "KEY"].include?(args[0]) # all commands except TAG
        i += 1
      elsif args[0] == "TAG"
        @tags[args[1]] = i + 1
      end
    }
    i = 0
    compiled = program.map { |line|
      line = line.chomp
      if line.empty?
        next ""
      end
      #args = line.split(/\s+/)
      args = line.split
      case args[0]
      when "SET"
        i += 1
        varid = varid(args[1])
        next "03#{varid}#{args[2]}".ljust(16, "*")
      when "CP"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "04#{varid}#{varid2}".ljust(16, "*")
      when "ADD"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "05#{varid}#{varid2}".ljust(16, "*")
      when "SUB"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "06#{varid}#{varid2}".ljust(16, "*")
      when "MUL"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "08#{varid}#{varid2}".ljust(16, "*")
      when "DIV"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        #next "08#{varid}#{varid2}".ljust(16, "*")
        next "*" * 16
      when "JMP"
        i += 1
        val = tagplace(args[1]) - i
        next "07#{convval(val)}".ljust(16, "*")
      when "TAG"
        #@tags[args[1]] = i + 1
        next ""
      when "PACK"
        i += 1
        varid = varid(args[1])
        val = COMPILER.TYPEHASH[args[2]].to_s
        next "09#{varid}#{val}".ljust(16, "*")
      when "JMP1IF"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "0A#{varid}#{varid2}".ljust(16, "*")
      when "PRINT"
        i += 1
        varid = varid(args[1])
        next "0F#{varid}".ljust(16, "*")
      when "JMP1IF=="
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "0A#{varid}#{varid2}".ljust(16, "*")
      when "JMP1IF>"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "0B#{varid}#{varid2}".ljust(16, "*")
      when "JMP1IF>="
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "0C#{varid}#{varid2}".ljust(16, "*")
      when "JMP1IF<"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])# varid2 > varid
        next "0B#{varid2}#{varid}".ljust(16, "*")
      when "JMP1IF<="
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "0C#{varid2}#{varid}".ljust(16, "*")
      when "JMPBY"
        i += 1
        varid = varid(args[1])
        next "0D#{varid}#{args[2]}".ljust(16, "*")
      when "FORMAT"
        i += 1
        varid = varid(args[1])
        val = COMPILER.TYPEHASH[args[2]].to_s
        next "0E#{varid}#{val}".ljust(16, "*")
      when "CPCFROM"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "10#{varid}#{varid2}".ljust(16, "*")
      when "CPCTO"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "11#{varid}#{varid2}".ljust(16, "*")
      when "PENGOTO"
        i += 1
        varid = varid(args[1])
        varid2 = varid(args[2])
        next "12#{varid}#{varid2}".ljust(16, "*")
      when "PENCOLOR"
        i += 1
        varid = varid(args[1])
        next "13#{varid}".ljust(16, "*")
      when "PENWIDTH"
        i += 1
        varid = varid(args[1])
        next "16#{varid}".ljust(16, "*")
      when "PENDOWN"
        i += 1
        next "14".ljust(16, "*")
      when "PENUP"
        i += 1
        next "15".ljust(16, "*")
      when "PENCLEAR"
        i += 1
        next "17".ljust(16, "*")
      when "SAVELINK"
        i += 1
        varid = varid(args[1])
        next "18#{varid}".ljust(16, "*")
      when "GOTOLINK"
        i += 1
        varid = varid(args[1])
        next "19#{varid}".ljust(16, "*")
      when "ADDVAL"
        i += 1
        varid = varid(args[1])
        val = args[2]
        next "1A#{varid}#{val}".ljust(16, "*")
      when "SUBVAL"
        i += 1
        varid = varid(args[1])
        val = args[2]
        next "1B#{varid}#{val}".ljust(16, "*")
      when "MULVAL"
        i += 1
        varid = varid(args[1])
        val = args[2]
        next "1C#{varid}#{val}".ljust(16, "*")
      when "KEY"
        i += 1
        varid = varid(args[1])
        keytype = COMPILER.KEYHASH[args[2]]
        next "1D#{varid}#{keytype}".ljust(16, "*")
      end
    }
    VM.new(compiled.join.gsub("*", "0"), @memory)
  end
end

class VM
  @REVERSEKEYHASH = {}
  COMPILER.KEYHASH.each do |k, v|
    @REVERSEKEYHASH[v] = k
  end
  def self.REVERSEKEYHASH
    @REVERSEKEYHASH
  end
  FORMAT_INT = 0
  FORMAT_UINT = 1
  FORMAT_FLOAT = 2
  FORMAT_UFLOAT = 3
  attr_accessor :memory, :program
  attr_reader :pc

  def initialize(program_str, memory_str = "000000000"*65536)
    @memory = memory_str   # 9文字単位でセル
    @program = program_str # 16文字単位で命令
    @pc = 0
  end

  def memory_easy(x = 20)
    @memory[0..(x*9)].scan(/.{9}/).join("\n")
  end
  def program_easy(x = program.size/16)
    @program[0..(x*16)].scan(/.{16}/).join("\n")
  end

  def run
    while @pc * 16 < @program.size
      inst = @program[@pc * 16, 16]
      #sleep 0.1
      id = inst[0..1].to_i(16)
      args = inst[2..-1]
      case id
      when 0x03 # SET x, yval (Format+8HEX)
        x = args[0..3].to_i(16)
        yval = args[4..12]
        set_cell(x, yval)
      when 0x04 # CP x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        set_cell(y, get_cell(x))
      when 0x05 # ADD x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        val = value(x) + value(y)
        set_cell(x, encode(mem_format(x), val))
      when 0x06 # SUB x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        val = value(x) - value(y)
        set_cell(x, encode(mem_format(x), val))
      when 0x08 # MUL x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        val = value(x) * value(y)
        set_cell(x, encode(mem_format(x), val))
      when 0x09 # PACK x, fmt
        x = args[0..3].to_i(16)
        fmt = args[4].to_i(16)
        val = value(x)
        set_cell(x, encode(fmt, val))
      when 0x0A # JMP1IF== x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        @pc += (value(x) == value(y)) ? 1 : 0
      when 0x07 # JMP val
        v = args[0..3].to_i(16)
        v -= 0x10000 if v >= 0x8000
        @pc += v - 1
      when 0x0F # PR1NT x (PRINT)
        x = args[0..3].to_i(16)
        print (value_as(x, FORMAT_INT) % 0x100).chr
      when 0x0B #JMP1IF> x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        @pc += (value(x) > value(y)) ? 1 : 0
      when 0x0C #JMP1IF>= x, y
        x = args[0..3].to_i(16)
        y = args[4..7].to_i(16)
        @pc += (value(x) >= value(y)) ? 1 : 0
      when 0x0D #JMPBY x
        x = value_as(args[0..3].to_i(16), FORMAT_INT)
        @pc += x - 1
      when 0x0E #FORMAT x fmt
        x = args[0..3].to_i(16)
        fmt = args[4].to_i(16)
        set_cell(x, fmt.to_s(16) + get_cell(x)[1..8])
      when 0x10 #CPCFROM x, y
        x = args[0..3].to_i(16)
        y = value_as(args[4..7].to_i(16), FORMAT_INT) & 0xFFFF
        set_cell(x, get_cell(y))
      when 0x11 #CPCTO x, y
        x = args[0..3].to_i(16)
        y = value_as(args[4..7].to_i(16), FORMAT_INT) & 0xFFFF
        set_cell(get_cell(y), get_cell(x))
      when 0x12 #PENGOTO x,y
        x = value(args[0..3].to_i(16)) / 2.0 ** 30
        y = value(args[4..7].to_i(16)) / 2.0 ** 30

        $DUMMY_PEN.goto(x, y)
      when 0x13 #PENCOLOR x
        x = get_cell(args[0..3].to_i(16))
        a = x[1..2].to_i(16)
        r = x[3..4].to_i(16)
        g = x[5..6].to_i(16)
        b = x[7..8].to_i(16)
        $DUMMY_PEN.color = ((255 - a) * a << 24) + (r << 16) + (g << 8) + b
      when 0x14 #PENUP
        $DUMMY_PEN.up
      when 0x15 #PENDOWN
        $DUMMY_PEN.down
      when 0x16 #PENWIDTH x
        $DUMMY_PEN.width = value(args[0..3].to_i(16)) / 2.0 ** 30
      when 0x17 #PENCLEAR
        $DUMMY_PEN.clear
      when 0x18 #SAVELINK x
        x = args[0..3].to_i(16)
        set_cell(x, "1" + @pc.to_s(16).rjust(8, "0"))
      when 0x19 #LOADLINK x
        x = args[0..3].to_i(16)
        @pc = value(x).to_i
      when 0x1A #ADDVAL x V
        x = args[0..3].to_i(16)
        yval = args[4..12]
        set_cell(x, encode(mem_format(x), value(x) + value_text(yval)))
      when 0x1B #SUBVAL x V
        x = args[0..3].to_i(16)
        yval = args[4..12]
        set_cell(x, encode(mem_format(x), value(x) - value_text(yval)))
      when 0x1C #MULVAL x V
        x = args[0..3].to_i(16)
        yval = args[4..12]
        set_cell(x, encode(mem_format(x), value(x) * value_text(yval)))
      when 0x1D #KEY x key
        x = args[0..3].to_i(16)
        key = VM.REVERSEKEYHASH[args[4..7]]
        set_cell(x, $pressed_keys[key] ? "100000001" : "100000000")
      else
        raise "Unknown opcode #{id.to_s(16)}"
      end
      @pc += 1
    end
  end

  def value_as(i, fmt)
    cell = get_cell(i)
    fmt = fmt
    hex = cell[1..8]
    case fmt
    when FORMAT_INT
      v = hex.to_i(16)
      v - 0x80000000
    when FORMAT_UINT
      hex.to_i(16)  # 0x80000000 を除く
    when FORMAT_FLOAT
      [hex].pack("H*").unpack1("g")
    when FORMAT_UFLOAT
      [hex].pack("H*").unpack1("g") # 仮にfloatと同様
    else
      raise "Invalid format #{fmt}"
    end
  end
  # メモリ：9文字単位
  def value_text(cell)
    fmt = cell[0].to_i(16)
    hex = cell[1..8]
    case fmt
    when FORMAT_INT
      v = hex.to_i(16)
      v - 0x80000000
    when FORMAT_UINT
      hex.to_i(16)
    when FORMAT_FLOAT
      [hex].pack("H*").unpack1("g")
    when FORMAT_UFLOAT
      [hex].pack("H*").unpack1("g") # 仮にfloatと同様
    else
      raise "Invalid format #{fmt}"
    end
  end

  def get_cell(i)
    @memory[i * 9, 9]
  end

  def set_cell(i, val)
    @memory[i * 9, 9] = val.ljust(9, "0")
  end

  def mem_format(i)
    get_cell(i)[0].to_i(16)
  end

  def value(i)
    cell = get_cell(i)
    fmt = cell[0].to_i(16)
    hex = cell[1..8]
    case fmt
    when FORMAT_INT
      v = hex.to_i(16)
      v - 0x80000000
    when FORMAT_UINT
      hex.to_i(16)
    when FORMAT_FLOAT
      [hex].pack("H*").unpack1("g")
    when FORMAT_UFLOAT
      [hex].pack("H*").unpack1("g") # 仮にfloatと同様
    else
      raise "Invalid format #{fmt}"
    end
  end

  def encode(fmt, val)
    body =
      case fmt
      when FORMAT_INT
        val = (val.to_i + 0x80000000)
        "%08X" % (val & 0xFFFFFFFF)
      when FORMAT_UINT
        "%08X" % (val.to_i & 0xFFFFFFFF)
      when FORMAT_FLOAT
        [val.to_f].pack("g").unpack1("H*").upcase
      when FORMAT_UFLOAT
        [val.to_f].pack("g").unpack1("H*").upcase
      else
        raise "Invalid format #{fmt}"
      end
    fmt.to_s(16).upcase + body
  end

  def memory
    @memory
  end
end
#memory = "08000000A 080000001 080000000 23E200000".chars.reject { |c| c == " " }.join # addr0=10, addr1=1, addr2=0
#
#program = [
#  "0500000001******", # ADD addr0 += addr1 → 11
##  "0800000000******", # MUL addr0 *= addr0 → 121
##  "0600000001******", # SUB addr0 -= addr1 → 120
#  "030002080000064*", # SET addr2 = 100
#  "0F0000**********", # PR1NT addr0
#  "0500030001******", # ADD addr3 += addr1
#  "0A00020000******", # JMP1IF addr2 == addr0
#  "07FFFB**********",  # JMP -4 (ループ)
#]
#
## ダミーの'*'はFなどで埋めておく
#program.map! { |s| s.gsub("*", "0") }
#
#vm = VM.new(program.join, memory)
#vm.run
##puts vm.memory.scan(/.{9}/).inspect
#puts
# all commands:["SET", "CP", "ADD", "SUB", "MUL", "DIV", "JMP1IF", "JMP", "PRINT", "PACK", "JMP1IF==", "JMP1IF<", "JMP1IF>", "JMP1IF<=", "JMP1IF>=", "JMPBY", "FORMAT", "CPCFROM", "CPCTO", "PENGOTO", "PENCOLOR", "PENWIDTH", "PENUP", "PENDOWN", "PENCLEAR", "TAG"]
example = <<EOF
SET a 08000000A
SET b 080000001
SET c 080000000
SET d 23E200000
TAG tag
ADD a b
SET c 080000064
PRINT a
ADD d b
JMP1IF a c
JMP tag
CPCFROM e b
PENDOWN
PENGOTO a b
PENCOLOR= c
PENUP
EOF

# New instructions:
# ADD x N
# SAVELINK x
# GOTOLINK x

program = <<EOF
  SET a 08000000A
  JMP skip
  TAG func1
    ADD a a
    GOTOLINK back
  TAG skip
  SAVELINK back
  ADDVAL back 080000002
  JMP func1
  PRINT a
EOF
vm = nil
program = File.read(ARGV[0]) if ARGV[0]
if program[0] == "#"
  if program[1,8] == "!DOCTYPE"
    case program[10,4].downcase
    when "sasm"
      vm = COMPILER.new(program[15..-1]).compile
    when "sexe"
      vm = VM.new(program[15..-1])
    else
      raise "Invalid document type"
    end
  else
    vm = COMPILER.new(program).compile
  end
else
  vm = COMPILER.new(program).compile
end
#puts vm.program.chars.each_slice(16).map(&:join).join("\n")

vm.run
sleep 1
#puts vm.memory[0..255].scan(/.{9}/).inspect
