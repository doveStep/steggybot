# -*- coding: utf-8 -*-
require 'cinch'
require 'levenshtein'
require 'json'
class Pokedex
  include Cinch::Plugin
  # match /(all|poke)dex (.+)/
  match /pokedex (.+)/

  def initialize(*args)
    super
    @json_data = get_pokedex_json
    @all_pokemon = get_list_of_pokemon
  end

  def get_pokedex_json
    p Dir.pwd
    pokedex_file = File.new(config[:pokedex], 'r')
    data = JSON.parse(pokedex_file.read)
    pokedex_file.close
    data
  end

  def get_list_of_pokemon
    @json_data.keys
  end

  def execute(m, given_name)
    pokemon = @all_pokemon[@all_pokemon.map{ |this_pokemon| Levenshtein.distance(this_pokemon, given_name)}.each_with_index.min.last]
    pokedex = @json_data[pokemon]
    species = pokedex['species']
    type = pokedex['type']
    height = pokedex['height']
    weight = pokedex['weight']
    description_choice = pokedex['pokedex'].sample

    rv = "#{pokemon}, the #{species} Pokémon. #{type}, #{height}, #{weight} lb. #{description_choice}"

    m.reply(rv, true )
  end
end

