#todo style app that keeps track of features we wish to implement for steggybot

require 'cinch'
require 'yaml'

class FeatureRequest
  include Cinch::Plugin

  # Adds your input as a feature request to steggybot.
  # Works best if you give your feature request a <title>:<description>.
  # Example: !add task feature request: a todo style app that lists features
  # and their progress
  match /(add feature|add request) (.+)/i, method: :add_request

  # Replies with a list of already requested features.
  # For a super lengthy list with all of the detail, type !info :
  # If you want to use !info in your app, tell me and I'll change it to
  # something else.
  match /list/i, method: :print_requests

  # Replies with detailed information on each feature whose title or description
  # match your query.
  match /info (.+)/i, method: :print_info

  # Replies with specific information on each feature whose title/descr matches 
  # your query.
  match /(status|progress) (?![=])(.+)/i, method: :search_tasks
  match /(feature|description) (?![=])(.+)/i, method: :search_tasks
  match /(who has claimed) (.+)/i, method: :search_tasks

  # Overwrites specific information on each feature whose title/descr matches 
  # your query.
  # Your query should only match one feature request.
  # Fix typos, update progress, or stake a claim.
  match /(status =|progress =) (.+) for (.+)/i, method: :search_tasks

  match /(complete)( )(.+)/i, method: :search_tasks
  match /(start)( )(.+)/i, method: :search_tasks
  match /(change claim to) (.+) for (.+)/i, method: :search_tasks
  match /(claim)( )(?!(?:to))(.+)/i, method: :search_tasks

  match /(feature =|request =|description =) (.+) for (.+)/i, method: :search_tasks

  # Please only use to remove troll or test feature requests.
  # To remove, you must type the *entire* title+description, aka entire "task".
  # If you complete a feature request, change its progress to "Completed" and
  # it will be moved to the completed_features.yml. 
  match /remove (.+)/i, method: :remove_request


  def initialize(*args)
    super
    @task_list = config[:task_list]
  end

  def add_request(m, unused_message, task)
    new_task = {:task => task, 
                :added_by => m.user.nick, 
                :created_at => Time.now, 
                :progress => "not started", 
                :updated_at => Time.now,
                :claim => "no one"}
    
    old_tasks = get_tasks(@task_list) || []
    combined_tasks = old_tasks << new_task

    store combined_tasks
  
    m.reply "#{m.user.nick}: Request received and rendered ##{new_task}"
  end


  # Replies with a list of already requested features.
  def print_requests(m)
    tasks = get_tasks @task_list || []
    if tasks == []
      m.reply "No one has requested a feature yet."
    else
      m.reply "Listing requested features & their statuses below:"
      tasks.each do |task|
        m.reply "#{task[:task]} -- Progress: #{task[:progress];}"
      end
    end
  end


  # Replies with all information on each feature whose title or description
  # match your query.
  # Works best if you have a name for your feature request.
  def print_info(m, title)
    tasks = get_tasks @task_list
    if tasks
      tasks.each do |task|
        if task[:task].include? title
          m.reply "#{m.user.nick}: Info: #{task}"
        end
      end
    end
  end


  # Please only use to remove mistakes.
  # To mark a task completed, use !complete <task>
  def remove_request(m, task_description)
    tasks = get_tasks @task_list
    if tasks
      nothing_was_deleted = true
      tasks.each do |task|
        if task[:task] == task_description && task[:added_by] == m.user.nick
          tasks.delete task
          nothing_was_deleted = false
          m.reply "#{m.user.nick}: Removed mistaken feature request " <<
            "#{task_description}"
        end
      end
      if nothing_was_deleted
        m.reply "#{m.user.nick}: Cannot remove '#{task_description}' because "<<
          "it is not the full title/description of an added feature request " <<
          "or you are not the one who added the feature request initially." 
      end
    
    end

    store tasks
  end


  #--------------------------------------------------------------------------------
  # Protected
  #--------------------------------------------------------------------------------

  protected

  def store(tasks)
    output = File.new(@task_list, 'w')
    output.puts YAML.dump(tasks)
    output.close

  end

  def get_tasks(file)
    output = File.new(file, 'r')
    tasks = YAML.load(output.read)
    output.close

    tasks
  end


  # Walks through list searching for query matches.
  # Replies with success_message for each query matched.
  # success_message is a string stored in a proc for lazy evaluation.
  # If you change the variable 'task,' you will need to change the strings too.
  # Executes code block for each query matched (e.g. claim a task)
  # If no matches found, replies with no matches found message.
  def search_tasks(m, message, new_data = nil, query)

    tasks = get_tasks @task_list
    if tasks
      nothing_was_found = true      
      tasks.each do |task|
        if task[:task].include? query
          nothing_was_found = false
          if new_data # checking if message is a setter
            task = try_setting(m, message, task, new_data)
          else # message is a getter
            get_data(m, message, task)
          end
        end
      end
      store tasks
      if nothing_was_found
        m.reply "#{m.user.nick}: No requests found that match your query #{query}."
      end
    end
  end


  def try_setting(m, message, task, new_data)
      if claimant(m, task) || (message == "claim" && claim_empty?(m, task))
        task = change_data(m, message, task, new_data)
        m.reply success_message(m, message, task)
      else 
        m.reply failure_message(m, message, task)
      end
      task
  end

  def get_data(m, message, task)
    m.reply success_message(m, message, task)
  end

  def success_message(m, message, task)
    case message
    when /(status =|progress =)/i
      "#{m.user.nick}: Progress successfully changed to #{task[:progress]} " <<
      "for #{task[:task]}."
        
    when /(status|progress)/i
      "#{m.user.nick}: Progress: #{task[:progress]} -- #{task[:task]}"

    when /(feature =|request =|description =)/i
      "#{m.user.nick}: Successfully changed task to #{task[:task]}." 

    when /(feature|description)/i
      "#{m.user.nick}: #{task[:task]}"

    when /(who has claimed)/i
      "#{m.user.nick}: #{task[:claim]} has claimed #{task[:task]}"

    when /(change claim to)/i
      "#{m.user.nick}: You have successfully given your claim to" <<
      " #{task[:claim]} for #{task[:task]}"

    when /(claim)/i
      "#{m.user.nick}: You have successfully claimed #{task[:task]}"

    when /(start)/i
      "#{m.user.nick}: I'm so glad you're starting to work on #{task[:task]}!"

    when /(complete)/i
      "#{m.user.nick}: Congratulations on completing #{task[:task]}!!!"
    end
  end

  def failure_message(m, message, task)
    case message
    when /(claim)/i
      "#{m.user.nick}: #{task[:claim]} has first" << 
          " dibs on #{task[:task]}. Please sort it with them."

    else
      "#{m.user.nick}: Only the claimant #{task[:claim]} may update #{task[:task]}."
    end
  end


  def claimant(m, task)
    task[:claim] == m.user.nick
  end

  def claim_empty?(m, task)
    task[:claim] == "no one" 
  end

  # Check claimant before calling change_data
  def change_data(m, message, task, new_data = nil)
    case message
    when /(status =|progress =)/i
      task[:progress] = new_data
      task[:updated_at] = Time.now
      task

    when /(feature =|request =|description =)/i
      task[:task] = new_data
      task

    when /(change claim to)/i
      task[:claim] = new_data
      task

    when /(claim)/i
      task[:claim] = m.user.nick
      task

    when /(start)/i
      task[:progress] = "begun"
      task[:updated_at] = Time.now
      task

    when /(complete)/i
      task[:progress] = "completed"
      task[:updated_at] = Time.now
      task

    end
  end



end