return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    branch = "canary",
    dependencies = {
      { "zbirenbaum/copilot.lua" }, -- or github/copilot.vim
      { "nvim-lua/plenary.nvim" }, -- for curl, log wrapper
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    opts = {
      debug = true, -- Enable debugging
      -- See Configuration section for rest
    },
    -- See Commands section for default commands if you want to lazy load on them
  },
  --   Usage
  -- Commands
  -- :CopilotChat <input>? - Open chat window with optional input
  -- :CopilotChatOpen - Open chat window
  -- :CopilotChatClose - Close chat window
  -- :CopilotChatToggle - Toggle chat window
  -- :CopilotChatStop - Stop current copilot output
  -- :CopilotChatReset - Reset chat window
  -- :CopilotChatSave <name>? - Save chat history to file
  -- :CopilotChatLoad <name>? - Load chat history from file
  -- :CopilotChatDebugInfo - Show debug information
  -- :CopilotChatModels - View and select available models. This is reset when a new instance is made. Please set your model in init.lua for persistence.
  -- :CopilotChatModel - View the currently selected model.
  --
  -- Commands coming from default prompts
  -- :CopilotChatExplain - Write an explanation for the active selection as paragraphs of text
  -- :CopilotChatReview - Review the selected code
  -- :CopilotChatFix - There is a problem in this code. Rewrite the code to show it with the bug fixed
  -- :CopilotChatOptimize - Optimize the selected code to improve performance and readability
  -- :CopilotChatDocs - Please add documentation comment for the selection
  -- :CopilotChatTests - Please generate tests for my code
  -- :CopilotChatFixDiagnostic - Please assist with the following diagnostic issue in file
  -- :CopilotChatCommit - Write commit message for the change with commitizen convention
  -- :CopilotChatCommitStaged - Write commit message for the change with commitizen convention
}
