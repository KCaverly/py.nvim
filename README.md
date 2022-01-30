# py.nvim
Simple Neovim Plugin for interactive development in Python.

Integrates primarily with Poetry Environments to manage Interactive REPLs, Dependency Management and Testing.

## To Install:

**Via Packer:**  
  `use {"KCaverly/py.nvim",   
        ft = {"python"},  
        config = function() require("py").setup() end}`



## Features:

### Interactive REPL
* Launch a IPython REPL from the poetry environment you are working in.
* Send imports, classes and functions from .py to REPL.
* Send & Replace functions/classes from IPython REPL to .py file with Treesitter.

### Poetry Environment Manager
* Add Dependencies for both Dev & Prod environments.

### Pytest Manager
* Launch pytest from Poetry environment, with notifications provided on test resolution to user.
