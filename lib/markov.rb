# -*- encoding: utf-8 -*- #

require 'strscan'

class Array
  def sum
    inject(0, &:+)
  end unless [].respond_to? :sum
end

class Markov
  class DB
    def initialize(fname)
      @fname = fname
    end

    def <<(sentence)
      File.open(@fname, 'a:UTF-8') { |f| f.puts sentence }
    end

    def load
      lines = File.readlines(@fname, :encoding => 'UTF-8').each(&:chomp!)
      depth = Integer(lines.shift)
      Markov.train!(depth, lines)
    end
  end

  class Histogram < Hash
    def initialize(*)
      super
      @total = values.sum
    end

    def <<(word)
      @total += 1
      self[word] ||= 0
      self[word] += 1
    end

    def sample
      idx = rand(@total)
      counter = 0
      each do |k, v|
        counter += v
        return k if counter > idx
      end
    end
  end

  def self.train!(depth, sentences)
    empty(depth).train_all!(sentences).reset!
  end

  def self.from_file(fname)
    DB.new(fname).load
  end

  def persist(db)
    db << sentences
    reset!
  end

  attr_reader :links, :inits, :sentences, :depth
  def initialize(links, inits, sentences, depth)
    @sentences = sentences
    @links = links
    @inits = inits
    @depth = depth
  end

  def reset!
    sentences.clear
    self
  end

  def inspect
    "#<Markov #{object_id} depth:#{depth} size:#{links.size}>"
  end

  def self.empty(depth)
    new({}, [], [], depth)
  end

  SMILEY = /[:@]\S+|D:/
  END_PUNC = /[?!.]/
  PUNC = /[:,=+-]/
  URL = %r(\w+://\S*)
  WORD = /[0-9a-z-]+(?:'\w+)?/i

  def tokenize(string, &b)
    return enum_for :tokenize, string unless b
    string.scan %r(#{SMILEY}|#{END_PUNC}|#{PUNC}|#{URL}|#{WORD})o, &b
  end

  def train!(sentence)
    add_sentence! sentence

    tokens = tokenize(sentence)

    tokens.each_cons(depth+1) do |(*pattern, word)|
      add_link!(pattern, word)
    end

    add_init! tokens.first(depth) unless tokens.to_a.length < depth

    self
  end

  def train_all!(sentences=[])
    sentences.each(&method(:train!))
    self
  end

  def load!
    File.readlines(fname, :encoding => 'UTF-8').each(&method(:load_string))
    @sentences = []
    self
  end

  def load_lines(str)
    str.split("\n").each(&method(:load_string)); nil
  end

  def add_link!(pattern, word)
    (links[pattern.map(&:downcase)] ||= Histogram.new) << word
  end

  def add_init!(pattern)
    inits << pattern.compact
  end

  def add_sentence!(sentence)
    sentences << sentence
  end

  def random_init(seed=[])
    seed = seed.dup
    shifted = []

    loop do
      return inits.sample if seed.empty?

      link = links.keys.select do |p|
        seed.each_with_index.all? do |el, i|
          el.downcase == p[i]
        end
      end.sample

      return shifted.concat(link) if link

      shifted << seed.shift
    end
  end

  def sample(pattern)
    pattern = pattern.map(&:downcase)
    return nil unless links.include? pattern

    links[pattern].sample
  end

  MAX_SENTENCE_WORDS = 50
  def generate_sentence(seed="")
    seed = tokenize(seed).to_a
    out = random_init(seed)

    raise "seed too short" if out.size < depth

    loop do
      break if END_PUNC === out.last
      break if out.size >= MAX_SENTENCE_WORDS
      break unless out.last
      next_word = sample(out[-depth..-1])
      out << next_word
    end

    detokenize(out)
  end

  def detokenize(tokens)
    out = ""
    tokens.each do |tok|
      case tok
      when /^(#{END_PUNC}|#{PUNC})/o
        out << tok
      else
        out << " #{tok}"
      end
    end

    if out[0] == ' '
      out[1..-1]
    else
      out
    end
  end

  def self.load_from(fname)
    db = Marshal.load(File.read(fname))
    new(db)
  end

  def save_to(fname)
    File.open(fname, 'w') { |f| f << Marshal.dump(@db) }
  end
end
