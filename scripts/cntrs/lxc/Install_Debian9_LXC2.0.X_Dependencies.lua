#!/usr/bin/env lua
--[[ Install lxc dependencies ]]
-- Table  containing the list of debian package necessary for lxc

-- import dep

local lxcDeb9Deps={'lxc','cgmanager', 'uidmap', 'cgmanager', 'cgroup-bin', 'libpam-systemd', 'libpam-cgroup','libpam-cgfs', 'bridge-utils', 'libvirt0'}

-- local useful variables  
EMPTY = ""
SPACE = " "
LINE_FEED = "\n"
RETURN = "\r"
RETURN_LINE_FEED = "\r\n"
SUPERIOR_SIGN = ">"
SPACED_SUPERIOR_SIGN = " > "
local CMD_PATH_FINDER={debian="/usr/bin/which"}
currentOS="debian"

-- Generate the correct which command runnable by lua api os.execute to get the absolute path of an os command
local function generateLuaWhichCommand(cmd)
  return CMD_PATH_FINDER[currentOS] .. SPACE .. cmd
end

-- Read the first line of given file from its name
-- @todo unit test
function readFirstLine(inputFileName)
  local input=io.open(inputFileName, "r")
  local data=input:read "*l"
  --print("FILE CONTENT:" .. data) 
  local line = string.gsub(data,RETURN_LINE_FEED, LINE_FEED)
  return line
end

-- Get the full qualified path of a os command
-- @todo uit test
function getCommandFullPath(cmd)
  if type(cmd) == "string" then 
    local cmdOutputTmpFile=os.tmpname()
    local luaWhich=generateLuaWhichCommand(cmd)
    local cmdToExec=luaWhich .. SPACED_SUPERIOR_SIGN .. cmdOutputTmpFile
    os.execute(cmdToExec)
    return readFirstLine(cmdOutputTmpFile) 
  else
    return EMPTY
  end
end

-- Alias for luaunit
local lu = require('luaunit')

-- Unit Test getCommandFullPath Get the path of apt-get, dstat, ip etc, lxc-ls. 
local cmd={
	aptGet={"apt-get","/usr/bin/apt-get"}, 
	dstat={"dstat","/usr/bin/dstat"}, 
	iptools={"ip","/bin/ip"}, 
	lxcls={"lxc-ls","/usr/bin/lxc-ls"}
}

for k,v in pairs(cmd) do 
  lu.assertEquals(v[2], getCommandFullPath(v[1])) 
end

-- Generate apt-get install <string> 
local pkgs=table.concat(lxcDeb9Deps, EMPTY_STRING);
