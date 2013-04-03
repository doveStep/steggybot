#todo style app that keeps track of features we wish to implement for steggybot

require 'cinch'
require 'yaml'

class FeatureRequest
	include Cinch::Plugin

	match /add task (.+)/i, method: :add
	match /list tasks/i, method: :list

	def initialize(*args)
		super
		@task_list = config[:task_list]
	end

	def add(m, task)
    	new_task = {"task" => task, "added_by" => m.user.nick, "created_at" => Time.now, "progress" => "not started", "claim" => "no one has claimed"}
		
		old_tasks = get_tasks || []
		combined_tasks = old_tasks << new_task

	    store_tasks = File.new(@task_list, 'w')
	    store_tasks.puts YAML.dump(combined_tasks)
	    store_tasks.close
	
	    m.reply "#{m.user.nick}: Request received and rendered ##{new_task}"
	end

	def list(m)
		tasks = get_tasks || []
		if tasks == []
			m.reply "No one has requested a feature yet."
		else
			m.reply "#{m.user.nick}: Listing requested features & their statuses"
			tasks.each do |task|
				m.reply "#{task["task"]}"
				#m.reply "task: #{task["task"]}, progress: #{task["progress"]}, claim: #{task["claim"]}"
			end


		end
	end

	#--------------------------------------------------------------------------------
	# Protected
	#--------------------------------------------------------------------------------

	protected

	def get_tasks
		output = File.new(@task_list, 'r')
		tasks = YAML.load(output.read)
		output.close

		tasks
	end
  include Cinch::Plugin

  # Adds your input as a feature request to steggybot.
  # Works best if you give your feature request a <title>:<description>.
  # Example: !add task feature request: a todo style app that lists features and their progress
  match /request (.+)/i, method: :add_request
  match /add feature (.+)/i, method: :add_request
  match /add request (.+)/i, method: :add_request


  # Replies with a list of already requested features.
  # For a super lengthy list with all of the detail, type !info :
  # If you want to use !info in your app, tell me and I'll change it to something else.
  match /list/i, method: :print_requests

  # Replies with detailed information on each feature whose title or description match your query.
  match /info (.+)/i, method: :print_info

  # Replies with specific information on each feature whose title/descr matches your query.
  match /status? (.+)/i, method: :get_status
  match /progress? (.+)/i, method: :get_status
  match /task? (.+)/i, method: :get_task
  match /claim? (.+)/i, method: :get_claim

  # Overwrites specific information on each feature whose title/descr matches your query.
  # Your query should only match one feature request.
  # Fix typos, update progress, or stake a claim.
  match /status = (.+) for (.+)/i, method: :update_status
  match /progress = (.+) for (.+)/i, method: :update_status
  match /complete (.+)/i, method: :mark_completed
  match /start (.+)/i, method: :mark_started
  match /task = (.+) for (.+)/i, method: :edit_task
  match /claim (.+)/i, method: :stake_claim

  # Please only use to remove troll or test feature requests.
  # To remove, you must type the *entire* title+description, aka entire "task" field.
  # If you complete a feature request, change its progress to "Completed" and
  # it will be moved to the completed_features.yml. 
  match /remove (.+)/i, method: :remove_request


  def initialize(*args)
    super
    @task_list = config[:task_list]
  end

  def add_request(m, task)
    new_task = {"task" => task, "added_by" => m.user.nick, "created_at" => Time.now, "progress" => "not started", "claim" => "no one has claimed"}
    
    old_tasks = get_tasks @task_list || []
    combined_tasks = old_tasks << new_task

    store combined_tasks
  
    m.reply "#{m.user.nick}: Request received and rendered ##{new_task}"
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

end