require 'spec_helper'
require File.dirname(__FILE__) + "/../pazudora.rb"

describe Pazudora do

  def setup_daily_page_mock
    @daily_mock = mock()
    @pazudora.stub(:open).and_return(mock())
    Nokogiri::HTML::Document.stub(:parse).and_return(@daily_mock)
    @daily_mock.stub(:css).with(".event3").and_return(event_time_nodes)
    @daily_mock.stub(:css).with(".limiteddragon").and_return(event_reward_nodes)
  end
  
  def event_time_nodes
    nodes = []
    15.times do |x|
      nodes << Nokogiri::XML("<td class='event3'>#{x} time</td>").children.first
    end
    nodes
  end
  
  def event_reward_nodes
    nodes = []
    15.times do |x|
      xml = "<td class='limiteddragon'><img src='img/thumbnail/#{x}.png'></td>"
      nodes << Nokogiri::XML(xml).children.first
    end
    nodes
  end
  
  def stub_puzzlemon_info(names=["Puzzlemon Name"])
    @puzzlemon_infos = []
    names.each do |name|
      @puzzlemon_infos << Nokogiri::XML("<td class='name'>#{name}</td>")
    end
    @pazudora.stub(:get_puzzlemon_info).and_return(*@puzzlemon_infos)
  end
  
  def stub_friend_data
    friend_info = {}
    friend_info.default = "123,456,789"
    
    friend_hash = {}
    friend_hash.default = friend_info
    
    @pazudora.stub(:load_data).and_return(friend_hash)
  end
  
  def stub_daily_dungeon_name_and_group_info(msg)
    msg.stub(:reply).with(/Dungeons today/)
    msg.stub(:reply).with(/Group [A|B|C|D|E]/)
  end
  
  context "daily dungeons" do
    before(:each) do
      @pazudora = Pazudora.new(new_test_bot)
      setup_daily_page_mock
      stub_puzzlemon_info
      stub_friend_data
    end
    
    it "should display the group of the requestor if no user is given" do
      @message = mock_message(:nick => "puzzlemonster")
      @message.should_receive(:reply).with(/puzzlemonster is in group/).once
      @pazudora.pazudora_dailies(@message, "")
    end
    
    it "should display the group of the user if one is given" do
      @message = mock_message(:nick => "puzzlemonster")
      @message.should_receive(:reply).with(/other_user is in group/).once
      @message.should_not_receive(:reply).with(/puzzlemonster is in group/)
      @pazudora.pazudora_dailies(@message, "other_user")
    end
    
    it "should reset the timestamp and page if and only if the date is stale" do
      msg = mock_message(:nick => "puzzlemonster")
      @pazudora.instance_variable_set(:@daily_timestamp, "old_timestamp")
      @pazudora.pazudora_dailies(msg, "")
      @pazudora.instance_variable_get(:@daily_timestamp).should == Time.now.strftime("%m-%d-%y")
      @pazudora.instance_variable_get(:@daily_page).should == @daily_mock
      
      msg = mock_message(:nick => "puzzlemonster")
      old_daily_page = @daily_mock
      setup_daily_page_mock
      
      @pazudora.pazudora_dailies(msg, "")
      @pazudora.instance_variable_get(:@daily_page).should_not == @daily_mock
      @pazudora.instance_variable_get(:@daily_page).should == old_daily_page
    end
    
    it "should parse rewards and display their name" do

      @pazudora.stub(:load_data).and_return({})
      
      @message = mock_message(:nick => "puzzlemonster")
      @message.should_receive(:reply).with(/Dungeons today.*Puzzlemon1, Puzzlemon2, Puzzlemon3/)
      
      name1 = Nokogiri::XML("<td class='name'>Puzzlemon1</td>")
      name2 = Nokogiri::XML("<td class='name'>Puzzlemon2</td>")
      name3 = Nokogiri::XML("<td class='name'>Puzzlemon3</td>")
      @pazudora.should_receive(:get_puzzlemon_info).with("0").and_return(name1)
      @pazudora.should_receive(:get_puzzlemon_info).with("5").and_return(name2)
      @pazudora.should_receive(:get_puzzlemon_info).with("10").and_return(name3)
      @pazudora.pazudora_dailies(@message, "")
    end
    
    it "should parse rewards based on the group of the user if one is given" do
      @pazudora.stub(:group_number_from_friend_code).and_return(3)
      
      @message = mock_message(:nick => "puzzlemonster")
      @message.should_receive(:reply).with(/Dungeons today.* /)
      @pazudora.should_receive(:get_puzzlemon_info).with("3")
      @pazudora.should_receive(:get_puzzlemon_info).with("8")
      @pazudora.should_receive(:get_puzzlemon_info).with("13")
      @pazudora.pazudora_dailies(@message, "")
    end
  end
end

