require 'yaml'
require 'set'
require 'pry-byebug'
require_relative 'serializable'

##
# Standardize terminal user input functions
class Input
  def self.input(message: 'Input')
    puts "#{message}: "
    gets.chomp
  end

  def self.boolean(message: 'Boolean Input', truthy: 'y', falsey: 'n')
    return if truthy.casecmp? falsey

    map = { truthy => true, falsey => false }
    valid = false
    until valid
      puts "Please submit your case insenstive input in the format [#{truthy}|#{falsey}]"
      input = self.input message: message
      valid = input.casecmp?(truthy) || input.casecmp?(falsey)
      puts "Invalid input; must be #{truthy} or #{falsey}" unless valid
    end
    map[input]
  end

  def self.character(message: 'Character Input', alphabet: false)
    regex = alphabet ? /^[a-zA-Z]{1}$/ : /^\w{1}$/
    valid = false
    until valid
      puts 'Please submit a character'
      input = self.input message: message
      valid = input.match?(regex)
      puts 'Invalid input; string must be of length 1' unless valid
    end
    input
  end
end

##
# This class is the main object that handles the game logic
class Game
  include Serializable

  CONFIG = YAML.load(File.open('config.yaml'))
  DICTIONARY = File.new CONFIG['dictionary']

  def initialize
    default_init unless load_data
    game
  end

  def default_init
    @answer = generate_answer
    @incorrect_guesses = 0
    @guessed_letters = Set[]
    @game_done = false
  end

  def generate_answer
    DICTIONARY.readlines(chomp: true).select do |line|
      word = CONFIG['word']
      (word['minLength']..word['maxLength']).member? line.length
    end.sample
  end

  def load_data
    return unless data_exists?

    should_load_data = Input.boolean message: 'Load data'
    unserialize(File.open("#{CONFIG['savesDirectory']}/save")) if should_load_data
    should_load_data
  end

  def save_data
    should_save_data = Input.boolean message: 'Save data'
    File.open("#{CONFIG['saveDirectory']}/save", 'w') do |save_file|
      save_file.write serialize if should_save_data
    end
  end

  def data_exists?
    !Dir.empty? 'saves'
  end

  def guess
    is_letter = Input.boolean(message: 'Do you wish to guess a [letter] or [word]?', truthy: 'letter', falsey: 'word')
    is_letter ? guess_letter : guess_word
    puts "You have #{@incorrect_guesses} incorrect guesses"
    # TODO: separate winning and losing from gameover
    @game_done |= @incorrect_guesses >= 8
    puts 'Congratz, you won!' if @game_done
  end

  def guess_letter
    valid = false
    until valid
      letter = Input.character alphabet: true
      valid = !@guessed_letters.member?(letter)
      puts 'Letter already guessed' unless valid
    end
    correct = @answer.match?(/[#{letter.downcase}]/)
    @guessed_letters.add letter if correct
    @incorrect_guesses += 1 unless correct
    puts correct ? 'You got it!' : 'Incorrect guess'
    @game_done = @guessed_letters == Set[@answer.chars]
  end

  def guess_word
    word = Input.input message: 'Word Input'
    @game_done = @answer.casecmp word
    @incorrect_guesses += 1 unless @game_done
    @guessed_letters.add @answer.chars if @game_done
    puts 'Incorrect guess' unless @game_done
  end

  def display_guessed_letters
    @answer.chars.each do |char|
      print @guessed_letters.member?(char) ? char : '_'
      print ' '
    end
    puts
  end

  def play_again
    game if Input.boolean message: 'Do you want to play again'
  end

  def game
    until @game_done
      save_data
      guess
      display_guessed_letters
    end
    play_again
  end
end

Game.new
