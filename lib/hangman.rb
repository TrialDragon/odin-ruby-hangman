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

  attr_accessor :game_over
  alias game_over? game_over

  def initialize
    default_init unless load_data
    game
  end

  def default_init
    @answer = generate_answer
    @incorrect_guesses = 0
    @guessed_letters = Set[]
    @correct_guessed_letters = Set[]
    @game_over = false
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
    unserialize(File.open("#{CONFIG['saveDirectory']}/save")) if should_load_data
    should_load_data
  end

  def save_data
    return unless Input.boolean message: 'Save data'

    File.open("#{CONFIG['saveDirectory']}/save", 'w') do |save_file|
      save_file.write serialize
    end
  end

  def data_exists?
    !Dir.empty? 'saves'
  end

  def guess
    Input.boolean(message: 'What type of guess', truthy: 'letter', falsey: 'word') ? guess_letter : guess_word
  end

  def guess_letter
    valid = false
    until valid
      letter = Input.character alphabet: true
      valid = !@guessed_letters.member?(letter)
      puts 'Already guessed that letter' unless valid
    end
    @guessed_letters.add letter
    @correct_guessed_letters.add letter if @answer.match? letter
    win if @correct_guessed_letters == Set[@answer.chars]
    wrong_guess unless @answer.match? letter
  end

  def guess_word
    word = Input.input(message: 'Word Input')
    matches = word.casecmp? @answer
    wrong_guess unless matches
    win if matches
  end

  def wrong_guess
    @incorrect_guesses += 1
    puts 'Wrong guess'
    puts "Incorrect guesses:#{@incorrect_guesses}"
    lose if @incorrect_guesses >= 8
  end

  def win
    puts 'You won!'
    finish_game
  end

  def lose
    puts 'You lost!'
    finish_game
  end

  def finish_game
    @game_over = true
    @correct_guessed_letters = Set.new @answer.chars
  end

  def display_correct_guessed_letters
    output = ''
    @answer.chars.each do |char|
      output += @correct_guessed_letters.member?(char) ? char : '_'
      output += ' '
    end
    puts output.chomp
  end

  def play_again
    return unless Input.boolean message: 'Play again'

    @game_over = false
    game
  end

  def game
    until game_over?
      save_data
      guess
      display_correct_guessed_letters
    end
    play_again
  end
end

Game.new
