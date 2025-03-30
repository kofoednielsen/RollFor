RollFor = RollFor or {}
local m = RollFor

if m.SoftRes then return end

local M = {}

---@diagnostic disable-next-line: undefined-global
local lib_stub = LibStub

local keys = m.keys
local transform = m.SoftResDataTransformer.transform

--function M:new()
--local o = {}
--setmetatable( o, self )
--self.__index = self

--return o
--end

-- Taragaman the Hungerer all SR by Jogobobek:
-- eyJtZXRhZGF0YSI6eyJpZCI6IjNRUzg1OCIsImluc3RhbmNlIjoxMDEsImluc3RhbmNlcyI6WyJLYXJhemhhbiJdLCJvcmlnaW4iOiJyYWlkcmVzIn0sInNvZnRyZXNlcnZlcyI6W3sibmFtZSI6IkpvZ29ib2JlayIsIml0ZW1zIjpbeyJpZCI6MTQxNDUsInF1YWxpdHkiOjN9LHsiaWQiOjE0MTQ4LCJxdWFsaXR5IjozfSx7ImlkIjoxNDE0OSwicXVhbGl0eSI6M31dfV0sImhhcmRyZXNlcnZlcyI6W119

-- Taragaman the Hungerer mix SR by Jogobobek and Guildhamster:
-- eyJtZXRhZGF0YSI6eyJpZCI6IlhTRUE5USIsImluc3RhbmNlIjo5NiwiaW5zdGFuY2VzIjpbIk5heHhyYW1hcyJdLCJvcmlnaW4iOiJyYWlkcmVzIn0sInNvZnRyZXNlcnZlcyI6W3sibmFtZSI6IkpvZ29ib2JlayIsIml0ZW1zIjpbeyJpZCI6MTQxNDUsInF1YWxpdHkiOjJ9LHsiaWQiOjE0MTQ1LCJxdWFsaXR5IjoyfSx7ImlkIjoxNDE0OCwicXVhbGl0eSI6Mn1dfSx7Im5hbWUiOiJPYnN6Y3p5bXVjaGEiLCJpdGVtcyI6W3siaWQiOjE0MTQ1LCJxdWFsaXR5IjoyfSx7ImlkIjoxNDE0OCwicXVhbGl0eSI6Mn0seyJpZCI6MTQxNDksInF1YWxpdHkiOjJ9XX1dLCJoYXJkcmVzZXJ2ZXMiOltdfQ==

-- Taragaman the Hungerer all SR by Jogobobek and Guildhamster:
-- eyJtZXRhZGF0YSI6eyJpZCI6IlNDRDNQMyIsImluc3RhbmNlIjo5NiwiaW5zdGFuY2VzIjpbIk5heHhyYW1hcyJdLCJvcmlnaW4iOiJyYWlkcmVzIn0sInNvZnRyZXNlcnZlcyI6W3sibmFtZSI6IkpvZ29ib2JlayIsIml0ZW1zIjpbeyJpZCI6MTQxNDUsInF1YWxpdHkiOjJ9LHsiaWQiOjE0MTQ4LCJxdWFsaXR5IjoyfSx7ImlkIjoxNDE0OSwicXVhbGl0eSI6Mn1dfSx7Im5hbWUiOiJPYnN6Y3p5bXVjaGEiLCJpdGVtcyI6W3siaWQiOjE0MTQ1LCJxdWFsaXR5IjoyfSx7ImlkIjoxNDE0OCwicXVhbGl0eSI6Mn0seyJpZCI6MTQxNDksInF1YWxpdHkiOjJ9XX1dLCJoYXJkcmVzZXJ2ZXMiOltdfQ==
function M.new( db )
  ---@type SoftResData
  local softres_data = {}
  local hardres_data = {}

  local function persist( data )
    if data ~= nil then
      db.import_timestamp = m.lua.time()
    else
      db.import_timestamp = nil
    end

    db.data = data
  end

  function M.decode( encoded_softres_data )
    if not encoded_softres_data then return nil end

    local data = m.decode_base64( encoded_softres_data )

    if not data then
      m.pretty_print( "Couldn't decode softres data!", m.colors.red )
      return nil
    end

    if m.bcc then
      data = LibStub( "LibDeflate" ):DecompressZlib( data )

      if not data then
        m.pretty_print( "Couldn't decompress softres data!", m.colors.red )
        return nil
      end
    end

    local json = lib_stub( "Json-0.1.2" )
    local success, result = pcall( function() return json.decode( data ) end )
    return success and result
  end

  local function clear( report )
    if m.count_elements( softres_data ) == 0 then return end
    softres_data = {}
    persist( nil )
    if report then m.pretty_print( "Cleared soft-res data." ) end
  end

  local function get( item_id )
    return softres_data[ item_id ] and m.clone( softres_data[ item_id ].rollers ) or {}
  end

  local function get_all_rollers()
    local roller_name_map = {}

    for _, item in pairs( softres_data ) do
      for _, roller in pairs( item.rollers or {} ) do
        roller_name_map[ roller.name ] = roller
      end
    end

    local result = {}

    for _, roller in pairs( roller_name_map ) do
      table.insert( result, roller )
    end

    return result
  end

  local function find_roller( player_name, data )
    for _, player in ipairs( data ) do
      if player.name == player_name then return player end
    end
  end

  local function is_player_softressing( player_name, item_id )
    if item_id and not softres_data[ item_id ] then return false end

    if item_id then
      local item = softres_data[ item_id ]
      local player = item and find_roller( player_name, item.rollers )
      if player and player.name == player_name then return true end

      return false
    end

    for _, item in pairs( softres_data ) do
      local roller = find_roller( player_name, item.rollers )
      if roller and roller.name == player_name then return true end
    end

    return false
  end

  local function sort_players()
    for _, item in pairs( softres_data ) do
      if item.rollers then
        table.sort( item.rollers, function( left, right ) return left.name < right.name end )
      end
    end
  end

  local function import( data )
    clear()
    if not data then return end

    softres_data, hardres_data = transform( data )
    sort_players()
  end

  local function get_item_ids()
    local result = {}

    for k, _ in pairs( softres_data ) do
      table.insert( result, k )
    end

    return result
  end

  local function get_hr_item_ids()
    return keys( hardres_data )
  end

  local function is_item_hardressed( item_id )
    return hardres_data[ item_id ] and true or false
  end

  local function get_item_quality( item_id )
    return softres_data[ item_id ] and softres_data[ item_id ].quality
  end

  return {
    get = get,
    get_all_rollers = get_all_rollers,
    is_player_softressing = is_player_softressing,
    get_item_ids = get_item_ids,
    get_item_quality = get_item_quality,
    get_hr_item_ids = get_hr_item_ids,
    is_item_hardressed = is_item_hardressed,
    import = import,
    clear = clear,
    persist = persist
  }
end

m.SoftRes = M
return M
