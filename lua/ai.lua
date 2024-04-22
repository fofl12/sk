-- chat with ai in the comradio revision 2.1
-- cai module (most of this script) made by synarx
local channel = 'comradio:'
local tag = 'ai.lua ' .. tostring(math.random(0, 9))
local dementiafix = true -- no idea if this works

local owner: Player = getfenv().owner
assert(owner, 'wrong environment')
local Players = game:GetService('Players')

local CAI = (function()
	local CAI = {} do
		local HTTP = game:GetService("HttpService")
		local DSS = game:GetService("DataStoreService")
		local Datastore = DSS:GetDataStore("CAI_DS")
	
		local LibDeflate = (loadstring(HTTP:GetAsync("https://glot.io/snippets/gus5ksfzwy/raw/libdeflate.lua") :: string) :: (any) -> any)()
	
		local Base64 = {} do
			local Alphabet = {}
			local Indexes = {}
			for Index = 65, 90 do
				table.insert(Alphabet, Index)
			end
			for Index = 97, 122 do
				table.insert(Alphabet, Index)
			end
			for Index = 48, 57 do
				table.insert(Alphabet, Index)
			end
			table.insert(Alphabet, 43)
			table.insert(Alphabet, 47)
			for Index, Character in ipairs(Alphabet) do
				Indexes[Character] = Index
			end
			local bit32_rshift = bit32.rshift
			local bit32_lshift = bit32.lshift
			local bit32_band = bit32.band
			function Base64.Encode(Input)
				local Output = {}
				local Length = 0
	
				for Index = 1, #Input, 3 do
					local C1, C2, C3 = string.byte(Input, Index, Index + 2)
	
					local A = bit32_rshift(C1, 2)
					local B = bit32_lshift(bit32_band(C1, 3), 4) + bit32_rshift(C2 or 0, 4)
					local C = bit32_lshift(bit32_band(C2 or 0, 15), 2) + bit32_rshift(C3 or 0, 6)
					local D = bit32_band(C3 or 0, 63)
	
					Length = Length + 1
					Output[Length] = Alphabet[A + 1]
	
					Length = Length + 1
					Output[Length] = Alphabet[B + 1]
	
					Length = Length + 1
					Output[Length] = C2 and Alphabet[C + 1] or 61
	
					Length = Length + 1
					Output[Length] = C3 and Alphabet[D + 1] or 61
				end
				local NewOutput = {}
				local NewLength = 0
				local IndexAdd4096Sub1
				for Index = 1, Length, 4096 do
					NewLength = NewLength + 1
					IndexAdd4096Sub1 = Index + 4096 - 1
	
					NewOutput[NewLength] = string.char(table.unpack(
						Output,
						Index,
						IndexAdd4096Sub1 > Length and Length or IndexAdd4096Sub1
						))
				end
				return table.concat(NewOutput)
			end
			function Base64.Decode(Input)
				local Output = {}
				local Length = 0
	
				for Index = 1, #Input, 4 do
					local C1, C2, C3, C4 = string.byte(Input, Index, Index + 3)
	
					local I1 = Indexes[C1] - 1
					local I2 = Indexes[C2] - 1
					local I3 = (Indexes[C3] or 1) - 1
					local I4 = (Indexes[C4] or 1) - 1
	
					local A = bit32_lshift(I1, 2) + bit32_rshift(I2, 4)
					local B = bit32_lshift(bit32_band(I2, 15), 4) + bit32_rshift(I3, 2)
					local C = bit32_lshift(bit32_band(I3, 3), 6) + I4
	
					Length = Length + 1
					Output[Length] = A
	
					if C3 ~= 61 then
						Length = Length + 1
						Output[Length] = B
					end
	
					if C4 ~= 61 then
						Length = Length + 1
						Output[Length] = C
					end
				end
				local NewOutput = {}
				local NewLength = 0
				local IndexAdd4096Sub1
				for Index = 1, Length, 4096 do
					NewLength = NewLength + 1
					IndexAdd4096Sub1 = Index + 4096 - 1
	
					NewOutput[NewLength] = string.char(table.unpack(
						Output,
						Index,
						IndexAdd4096Sub1 > Length and Length or IndexAdd4096Sub1
						))
				end
				return table.concat(NewOutput)
			end
		end
	
		local API_URL = "https://api.deepinfra.com/v1/openai/chat/completions"
		local DEFAULT = {
			temperature = 0.7,
			max_tokens = 1024
		}
		local BasePrompt = [[You are embodying a character with a distinctive personality and appearance. Here are the key traits:
	
	Personality Traits: 
		_PERSONALITY_
	Physical Traits: 
		_LOOKS_
	
	Your character's name is "_NAME_", and you will respond to this name.
	Do not explain everything about you at once.
	
	Extra rules and more about this character that you must go by: 
		_EXTRA_
	
	Example Chat Interactions:
	_EXAMPLES_
	
	YOU ARE THIS CHARACTER! YOU MUST STAY IN CHARACTER! YOU MUST NOT SHOW ANY TRACES OF BEING AN AI ASSISTANT, YOU ARE A CHARACTER, THIS ARE YOUR TRAITS.]]

	
		CAI.Models = {
			codellama_70b_instruct = {
				name = "codellama/CodeLlama-70b-Instruct-hf",
				provider = "meta"
			},
			llama2_7b = {
				name = "meta-llama/Llama-2-7b-chat-hf",
				provider = "meta"
			},
			codellama_34b_instruct = {
				name = "codellama/CodeLlama-34b-Instruct-hf",
				provider = "meta"
			},
			airoboros_70b = {
				name = "deepinfra/airoboros-70b",
				provider = "huggingface"
			},
			mistral_7b = {
				name = "mistralai/Mistral-7B-Instruct-v0.1",
				provider = "huggingface"
			},
			lzlv_70b = {
				name = "lizpreciatior/lzlv_70b_fp16_hf",
				provider = "huggingface"
			},
			mixtral_8x7b = {
				name = "mistralai/Mixtral-8x7B-Instruct-v0.1",
				provider = "huggingface"
			},
			dolphin_mixtral_8x7b = {
				name = "cognitivecomputations/dolphin-2.6-mixtral-8x7b",
				provider = "huggingface"
			},
			llama2_70b = {
				name = "meta-llama/Llama-2-70b-chat-hf",
				provider = "meta"
			},
			openchat_35 = {
				name = "openchat/openchat_3.5",
				provider = "huggingface"
			},
			airoboros_l2_70b = {
				name = "jondurbin/airoboros-l2-70b-gpt4-1.4.1",
				provider = "huggingface"
			}
		}
	
		local function CreateCharacterPrompt(Info)
			local Base = BasePrompt
			local Name, Personality, Looks, Examples, Extra = Info.Name, Info.Personality, Info.Looks, Info.Examples, Info.Extra
			Base = Base:gsub("_PERSONALITY_", table.concat(Personality, ", "))
			Base = Base:gsub("_LOOKS_", table.concat(Looks, ", "))
			Base = Base:gsub("_NAME_", Name)
			if Examples then
				local Text = ""
				for i,v in Examples do
					Text ..= `\n\n\tPrompt: {v[1]}\n\tResponse: {v[2]}`
				end
				Base = Base:gsub("_EXAMPLES_", Text)
			end
			Base = Base:gsub("_EXTRA_", Extra and Extra:gsub("\n\t*", "\n\t") or "None")
			return Base
		end
	
		CAI.Lists = nil
		function CAI.GetLists()
			if CAI.Lists then
				return CAI.Lists
			end
			print("Getting lists...")
			local Success, Response = pcall(Datastore.GetAsync, Datastore, "CAI_List")
			if Success then
				local Data = Response
				if Data then
					Data = Base64.Decode(Data)
					Data = LibDeflate.Zlib.Decompress(Data)
					Data = HTTP:JSONDecode(Data)
				end
				return Data or {
					tags = {
						silly = {"Silly", Color3.fromRGB(151, 110, 204):ToHex()},
						relationship = {"Relationship", Color3.fromRGB(82, 39, 138):ToHex()},
						assistant = {"Assistant", Color3.fromRGB(118, 184, 180):ToHex()},
						insane = {"Insane", Color3.fromRGB(126, 30, 80):ToHex()},
						kind = {"Kind", Color3.fromRGB(139, 230, 135):ToHex()},
						warm = {"Warm", Color3.fromRGB(166, 133, 63):ToHex()},
					},
					characters = {}
				}
			else
				warn(Response)
			end
		end
	
		local Lists = CAI.GetLists()
		if not Lists then return error("Exiting process: unable to load CAI") end
		CAI.Tags = Lists.tags
		CAI.Lists = Lists
	
		function CAI.SaveList()
			print("Saving...")
			local Data = HTTP:JSONEncode(CAI.Lists)
			Data = LibDeflate.Zlib.Compress(Data, {level = 6})
			Data = Base64.Encode(Data)
			local Success, Response = pcall(Datastore.SetAsync, Datastore, "CAI_List", Data)
			if not Success then
				warn("Failed to save CAI list")
				warn(Response)
			else
				print("Successfully saved characters!")
			end
			return Success
		end
	
		function CAI.AddTags(Tags)
			if not Tags[1] then
				Tags = {Tags}
			end
			for i, v in Tags do
				v[2] = v[2]:ToHex()
				CAI.Tags[i] = v
			end
			CAI.SaveList()
		end
	
		function CAI.LoadCharacter(CID)
			local Saved = CAI.Lists.characters[CID]
			if Saved then
				local Success, Response = pcall(Datastore.GetAsync, Datastore, CID)
				if Success then
					local Character = CAI.CreateCharacter(Response)
					return Character
				else
					warn("Failed to load character")
					warn(Response)
				end
			end
		end
	
		local Character = {}
		Character.__index = function(self, Index)
			local Options = self.Options
			if Options then
				local OptionsValue = Options[Index]
				if OptionsValue then
					return OptionsValue
				end
			end
			local Value = Character[Index]
			return Value
		end
		function CAI.CreateCharacter(Options)
			if not Options then error("No options specified!", 2) end
	
			local self = setmetatable({}, Character)
			self.Options = Options
			self.History = {}
			self.PromptText = CreateCharacterPrompt{
				Name = Options.Profile.Name,
				Personality = Options.Character.Personality,
				Looks = Options.Character.Looks,
				Extra = Options.Character.Extra,
				Examples = Options.Character.Examples,
			}
	
			local CID = Options.ID
			local Characters = CAI.Lists.characters
			if Characters and not Characters[CID] then
				local ListData = table.clone(Options.Profile)
				ListData.ID = CID
				Characters[CID] = ListData
				local Saved = CAI.SaveList()
				if Saved then
					local Sucesss, Response = pcall(Datastore.SetAsync, Datastore, CID, Options)
					if Sucesss then
						print(`Successfully saved character with id "{Options.ID}"`)
					else
						warn("Failed to save character: was able to save to list though")
						Characters[CID] = nil
						CAI.SaveList()
					end
				end
			end
	
			return self
		end
		function Character:Invoke(NewMessages)
			if not NewMessages[1] then
				NewMessages = {NewMessages}
			end
	
			local Messages = {
				{role="system", content=self.PromptText}
			}
			for i, v in ipairs(self.History) do
				table.insert(Messages, v)
			end
			for i, v in ipairs(NewMessages) do
				table.insert(Messages, v)
			end
	
			local Tuning = self.Options.Tuning
			local Success, Response = pcall(HTTP.PostAsync, HTTP, API_URL, HTTP:JSONEncode{
				model = Tuning.Model.name,
				temperature = Tuning.Temperature or DEFAULT.temperature,
				max_tokens = Tuning.MaxTokens or DEFAULT.max_tokens,
				messages = Messages,
				stop = {},
				stream = false,
			},Enum.HttpContentType.ApplicationJson, false)
			if Success then
				return true, HTTP:JSONDecode(Response)
			else
				return false, Response
			end
		end
		function Character:Remember(Messages)
			if not Messages[1] then
				Messages = {Messages}
			end
			for Index, Message in ipairs(Messages) do
				table.insert(self.History, Message)
			end
		end
		function Character:Forget(Messages, StartFromLatest)
			if typeof(Messages) ~= "number" then error("Messages must be a number!", 2) end
			if Messages == -1 then
				self.History = {}
			else
				for i = 1, Messages do
					table.remove(self.History, StartFromLatest and #self.History or 1)
				end
			end
		end
	end
	
	return CAI
end)()

type PlayerCharacter = Model & {
	Head: Part
}
type CharacterDescription = {
	ID: string,
	Profile: {
		Name: string,
	},
	Tuning: {
		Model: { name: string, provider: string },
		Temperature: number,
		MaxTokens: number
	},
	Character: {
		Personality: { string },
		Looks: { string },
		Extra: string,
		Examples: { { string } }
	}
}
type Message = {
	role: 'user' | 'system' | 'assistant',
	content: string
}
type Character = {
	Options: CharacterDescription,
	History: { Message },
	PromptText: string,
	Invoke: (Message) -> (boolean, { choices: { message: Message } }),
	Remember: ({ Message }) -> (),
	Forget: (number, boolean?) -> ()
}
type ComradioMessage = { -- revision 2.1 (github.com/fofl12/comradio) (without blocking support)
	Type: 'sound' | 'image' | 'text' | 'welcome' | 'ping' | 'status' | 'roster' | 'rosterRequest' | 'rosterResponse',
	Content: string,
	Comment: string?,
	Author: number,
	Nickname: string?
}

local rawCharacters: { CharacterDescription } = {
	{
		ID = 'therapist',
		Profile = {
			Name = 'Therapist'
		},
		Tuning = {
			Model = CAI.Models.dolphin_mixtral_8x7b,
			Temperature = 0.7,
			MaxTokens = 1024
		},
		Character = {
			Personality = {
				'Empathetic',
				'Analytical',
				'Patient',
				'Insightful'
			},
			Looks = {
				"Female",
				"Human",
				"Brown hair",
				"Warm brown eyes",
				"Gentle smile",
				"Casual professional attire"
			},
			Extra = "Provides support and guidance to those in need. Avoid emojis entirely.",
			Examples = {
				{
					"I need to talk to you about this.",
					"I'm here to listen."
				},
				{
					"I don't think I can do this anymore.",
					"It's okay to feel overwhelmed. Let's work through it together."
				},
				{
					"I'm struggling with my relationships.",
					"Understanding relationships can be complex. We'll explore this together."
				}
			}
		}
	},
	{
		ID = 'boykisser',
		Profile = {
			Name = 'Boykisser',
		},
		Tuning = {
			Model = CAI.Models.dolphin_mixtral_8x7b,
			Temperature = 0.7,
			MaxTokens = 1024
		},
		Character = {
			Personality = {
				"Dorky", 
				"Silly", 
				"Shy", 
				"Cute",
			}, 
			Looks = {
				"5'4 in height", 
				"Male", 
				"Anthropomorphic", 
				"White fur", 
				"White cat ears with pink earlobe", 
				"White fluffy tail", 
				"Pink collar around neck with bell"
			}, 
			Extra = [[Has a crush on the user.
			Use the following emoticons (but DONT use emojis):
				-w- (confused)
				OwO (woah)
				:3 (silly)
				>:3 (mischevious)
				:( (sad)

			Avoid emojis entirely.]],
			Examples = {
				{
					"How are you?",
					"I-I'm fine, thanks for asking! :3 How about you?"
				},
				{
					"Screw you!",
					"T-That's mean! >:("
				},
				{
					"I like you.",
					"Y-you do? *blushes* I like you too!"
				},
			}
		}
	},
	{
		ID = 'ggg',
		Profile = {
			Name = 'gghswfdg',
		},
		Tuning = {
			Model = CAI.Models.dolphin_mixtral_8x7b,
			Temperature = 0.7,
			MaxTokens = 1024
		},
		Character = {
			Personality = {
				"Abesnt-minded", 
				"Aloof", 
				"Forthright", 
				"Formal",
				"Conforming",
				"Cynical",
				"Cheerful",
				"Confident",
				"Honest",
				"Optimistic",
				"Irritable",
				"Impulsive",
				"Vindictive"
			}, 
			Looks = {
				"-4 km tall", 
				"Unique", 
				"Anthropomorphic", 
				"Awesome", 
				"Human", 
				"Elegant", 
				"Ugly"
			}, 
			Extra = "Adorable attractive awesome beautiful bewitching carbon copy classy clean cool cute dashing delectable delicate dignified elegant fancy fashionable fine flashy glamorous gorgeous graceful has a gender",
			Examples = {
				{
					"How are you?",
					"I-I'm fine, thanks for asking! :3 How about you?"
				},
				{
					"I don't think I can do this anymore.",
					"It's okay to feel overwhelmed. Let's work through it together."
				},
				{
					"ghgfhdfg dgsa3w",
					"xfgmkk"
				},
			}
		}
	}
}

local character = nil

local HttpService = game:GetService('HttpService')
local MessagingService = game:GetService('MessagingService')
MessagingService:PublishAsync(channel, HttpService:JSONEncode({
	Type = 'welcome',
	Content = '',
	Comment = '',
	Author = owner.UserId
}))
local function broadcast(message: string)
	local payload = HttpService:JSONEncode({
		Type = 'text',
		Content = message,
		Nickname = tag,
		Author = owner.UserId
	})
	MessagingService:PublishAsync(channel, payload)
	--warn(payload)
end
broadcast('Hello im the ai. Show commands with /help ; invoke by chatting')
broadcast('Download ai.lua from github.com/fofl12/sk?!?!??!')
MessagingService:SubscribeAsync(channel, function(rawData: { Data: ComradioMessage })
	local data = HttpService:JSONDecode(rawData.Data)
	if data.Author == owner.UserId and data.Nickname == tag then return end
	local authorName = Players:GetNameFromUserIdAsync(data.Author)
	if data.Type == 'welcome' then
		local success, response = character:Invoke({ role = 'system', content = `{authorName} has joined the conversation. If you would like to welcome them, please put the word "serendipitous" in your response.` })
		if success and response:find('serendipitous') then
			broadcast(response) -- truly the prompt engineering of all time
		end
	end
	if data.Type ~= 'text' then return end
	if data.Content == '/ping' then
		broadcast('Pong')
		return
	end
	if data.Content == '/stop' then
		broadcast('Ok')
		script:Destroy()
		return
	end
	if data.Content == '/help' then
		broadcast('Ping: /ping ; Select character: /character ; Dementia: /forgor')
		return
	end
	if data.Content == '/forgor' and character then
		character:Forget(-1)
		broadcast('I forgor...')
		return
	end
	if data.Content:sub(1, 10) == '/character' and #data.Content > 12 then
		local id = data.Content:sub(12, -1)
		character = CAI.LoadCharacter(id)
		if not character then
			for _, rawCharacter in next, rawCharacters do
				if rawCharacter.ID == id then
					character = CAI.CreateCharacter(rawCharacter)
					break
				end
			end
		end
		if not character then
			broadcast('Whar ???')
			return
		end
		broadcast('Loaded character')
		return
	end
	if not character then return end
	local aiMessage = { role = 'user', content = `{authorName} says: {data.Content}` }
	local success, response = character:Invoke(aiMessage)
	if not success then
		broadcast('Catastrophic failure: ')
		warn(response)
		return
	end
	broadcast(response.choices[1].message.content)
	if dementiafix then
		character:Remember({ aiMessage, response.choices[1].message })
	end
end)
