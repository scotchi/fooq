# Copyright (C) 2009 Scott Wheeler <wheeler@kde.org> | MIT License

require 'rubygems'
require 'fileutils'
require 'stemp'

def read
  file = ARGV.shift
  (file && File.read(file) || STDIN.read).sub(/^#!.+?\n/, '')
end

def split(content)
  split_point = 0
  brace_level = 0
  (0..content.size).each do |i|
    if content[i, 1] == '{'
      if brace_level > 0 || content[split_point, i - split_point] =~ /\w+\s+[\w:\(\),\s]+$/
        brace_level += 1
      end
    elsif brace_level > 0 && content[i, 1] == '}'
      brace_level -= 1
      split_point = i + 1 if brace_level == 0
    end
  end
  return {
    :head => content[0, split_point],
    :body => content[split_point, content.size - split_point]
  }
end

def build_and_run(dir)
  (system('qmake -project CONFIG-=app_bundle') and
   system('qmake') and
   system('make > /dev/null') and
   system("./#{dir.sub(/.*\//, '')}")) or puts File.read('main.cpp')
end

def write_source(content)
  File.open("main.cpp", 'w') do |f|
    f.write <<END
#include <QtCore>
#{content[:head]}
int main(int argc, char *argv[])
{
Q_UNUSED(argc);
Q_UNUSED(argv);
#{content[:body]}
return 0;
}
END
  end
end

def run
  dir = STemp.mkdtemp("/tmp/fooq-XXX")
  content = split(read)
  FileUtils.cd(dir)
  write_source(content)
  build_and_run(dir)
  FileUtils.rm_r(dir)
end
