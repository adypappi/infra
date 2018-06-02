#!/usr/bin/env lua
local workingDir=os.getenv("PAPI_INFRA_SCRIPTS").."/pkgmgr"
local version="2.4.4"
local testPkg="luasocket"
local luarocksDeps={"unzip", "liblua5.3-dev"}
local luarocksInstallCmd={
  "wget -N https://luarocks.org/releases/luarocks-"..version..".tar.gz"
  ,"tar zxpf luarocks-"..version..".tar.gz"
  ,"cd luarocks-"..version
  ,"sudo ./configure; sudo make bootstrap"}

-- CHeck that luarocks is not installed 
local cmdOutput=os.tmpname()
-- Get where is lua
os.execute("which luarocks >"..cmdOutput)
luarocksInstalled=io.open(cmdOutput):read()
if luarocksInstalled == nil then
  -- Install deps
  os.execute("sudo apt-get install -y "..table.concat(luarocksDeps, " ")) 
  
  -- Configure Build Install Luarocks
  cmdLuable=table.concat(luarocksInstallCmd, ";")
  os.execute(cmdLuable)

-- Install luasocket package and check that it is correctly installed
  os.execute("sudo luarocks install "..testPkg)
  cmdOutput=os.tmpname()
-- Check if the package was been installed 
  os.execute("luarocks list | grep "..testPkg.." >"..cmdOutput)
  local testPkgInstalled=io.open(cmdOutput):read()
  if testPkgInstalled ~= testPkg then
    print("Warning the package "..testPkg.." was not been installed with luarocks")
    goto exit
  end
else
  print("Luarocks is already installed in:"..luarocksInstalled)
end

-- Clean the downlaad and build 
if pcall(os.execute("rm -rf "..workingDir.."/luarocks*")) then
	print("luarocks downloaded archive and build cleaned")
end

::exit::

