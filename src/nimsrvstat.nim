import std/[
  options,
  json,
  httpclient
]

type
  Platform* {.pure.} = enum ## Used to select which platform is used by the server
    Java
    Bedrock
  
  Server* = ref object ## The main server object, this is what you will use most of the time
    address*: string
    platform*: Platform
    online*: bool
    data: ServerData
    debug: DebugData

  DebugData = object
    ping*, query*, srv*, querymismatch*, ipinsrv*, cnameinsrv*, animatedmotd*, cachehit*: bool
    cachetime*, cacheexpire*, apiversion*: int

  NetworkData = object
    ip*, hostname*: string
    port*: int

  Protocol = object
    version*: int
    name*: string

  PlatformData = object
    version*: string
    software*: Option[string]

  BedrockData = object
    gamemode*, serverid*:string

  JavaData = object
    eula_blocked*:bool

  MapData = object
    raw*, clean*, html*: string

  MotdData = object
    raw*, clean*, html*: seq[string]

  Player = object
    name*, uuid*: string

  PlayersData = object
    online*, max*: int
    list: Option[seq[Player]]

  Plugin = object
    name*, version*: string

  PluginsData = object
    plugins*: seq[Plugin]

  Mod = object
    name*, version*: string

  ModsData = object
    mods*: seq[Mod]

  ServerInfo = object
    raw*, clean*, html*: seq[string]

  ServerData = object
    icon*: Option[string]
    network*: NetworkData
    protocol*: Option[Protocol]
    bedrock*: Option[BedrockData]
    java*: Option[JavaData]
    platform*: PlatformData
    map*: Option[MapData]
    motd*: MotdData
    players*: PlayersData
    plugins*: Option[PluginsData]
    mods*: Option[ModsData]
    info*: Option[ServerInfo]

type 
  PlatformError* = object of KeyError ## Raised when the platform is incorrect for the query

#converts a json node into a string sequence
proc getSeq(node: JsonNode):seq[string] = 
  var toreturn = newSeq[string]()

  for n in node:
    toreturn.add($n)

  result = toreturn



# used to get the data from mcsrvstat and convert it into the above types
proc getData*(self: Server) = 
  var client = newHttpClient()

  let endpoint = if self.platform == Platform.Java: "3/" else: "bedrock/3/"

  let data = parseJson(client.getContent("https://api.mcsrvstat.us/" & endpoint & self.address))
  # echo data

  self.online = data["online"].getBool()

  let debug = data["debug"]

  self.debug = DebugData(
    ping: debug["ping"].getBool(),
    query: debug["query"].getBool(),
    srv: debug["srv"].getBool(),
    querymismatch: debug["querymismatch"].getBool(),
    ipinsrv: debug["ipinsrv"].getBool(),
    cnameinsrv: debug["cnameinsrv"].getBool(),
    animatedmotd: debug["animatedmotd"].getBool(),
    cachehit: debug["cachehit"].getBool(),
    cachetime: debug["cachetime"].getInt(),
    cacheexpire: debug["cacheexpire"].getInt(),
    apiversion: debug["apiversion"].getInt()
  )

  if not self.online:
    return
  

  var serverdata = ServerData()


  if data{"icon"} != nil:
    serverdata.icon = some(data["icon"].getStr())
  else:
    serverdata.icon = none(string)

  serverdata.network = NetworkData(
    ip: data["ip"].getStr(),
    hostname: data["hostname"].getStr(),
    port: data["port"].getInt()
  )

  if data{"protocol"} != nil:
    serverdata.protocol = some(Protocol(
      version: data["protocol"]["version"].getInt(),
      name: data["protocol"]["name"].getStr()
    ))
  else:
    serverdata.protocol = none(Protocol)

  var platform = PlatformData(
    version: data["version"].getStr()
  )

  if data{"software"} != nil:
    platform.software = some(data["software"].getStr())
  else:
    platform.software = none(string)

  serverdata.platform = platform

  if data{"map"} != nil:
    serverdata.map = some(MapData(
      raw: data["map"]["raw"].getStr(),
      clean: data["map"]["clean"].getStr(),
      html: data["map"]["html"].getStr()
    ))
  else:
    serverdata.map = none(MapData)

  if self.platform == Platform.Bedrock:
    serverdata.java = none(JavaData)
    serverdata.bedrock = some(BedrockData(
        gamemode: data["gamemode"].getStr(),
        serverid: data["serverid"].getStr() 
    ))
  else:
    serverdata.bedrock = none(BedrockData)
    serverdata.java = some(JavaData(
      eula_blocked: data["eula_blocked"].getBool()
    ))
  

  serverdata.motd = MotdData(
    raw: data["motd"]["raw"].getSeq(),
    clean: data["motd"]["clean"].getSeq(),
    html: data["motd"]["html"].getSeq(),
  )

  var players = PlayersData(
    online: data["players"]["online"].getInt(),
    max: data["players"]["max"].getInt()
  )

  if data["players"]{"list"} != nil:
    var toadd = newSeq[Player]()
    for player in data["players"]["list"]:
      toadd.add(Player(
        name: player["name"].getStr(),
        uuid: player["uuid"].getStr()
      ))
    players.list = some(toadd)
  else:
    players.list = none(seq[Player])

  serverdata.players = players

  if data{"plugins"} != nil:
    var plugins = PluginsData()
    var pluginseq = newSeq[Plugin]()
    for plugin in data["plugins"]:
      pluginseq.add(Plugin(
        name: plugin["name"].getStr(),
        version: plugin["version"].getStr()
      ))
    plugins.plugins = pluginseq
    serverdata.plugins = some(plugins)
  else:
    serverdata.plugins = none(PluginsData)


  if data{"mods"} != nil:
    var mods = ModsData()
    var modseq = newSeq[Mod]()
    for mod2 in data["mods"]:
      modseq.add(Mod(
        name: mod2["name"].getStr(),
        version: mod2["version"].getStr()
      ))
    mods.mods = modseq
    serverdata.mods = some(mods)
  else:
    serverdata.mods = none(ModsData)

  if data{"info"} != nil:
    serverdata.info = some(ServerInfo(
      raw: data["info"]["raw"].getSeq(),
      clean: data["info"]["clean"].getSeq(),
      html: data["info"]["html"].getSeq()
    ))
  else:
    serverdata.info = none(ServerInfo)

  self.data = serverdata
  # echo data

# Gets full types from server

proc getNetwork*(self: Server): NetworkData = 
  ## Gets the network data type of the server
  result = self.data.network

proc getProtocol*(self: Server): Option[Protocol] = 
  ## Gets the protocol data from the server
  result = self.data.protocol

proc getBedrock*(self: Server): Option[BedrockData] = 
  ## Gets the bedrock data from the server (if it exists)
  if self.platform == Platform.Java:
    raise PlatformError.newException("Server is not a bedrock server")
  result = self.data.bedrock

proc getJava*(self: Server): Option[JavaData] = 
  ## Gets the bedrock data from the server (if it exists)
  if self.platform == Platform.Bedrock:
    raise PlatformError.newException("Server is not a java server")
  result = self.data.java

proc getPlatform*(self: Server): PlatformData = 
  ## Gets the platform data from the server
  result = self.data.platform

proc getServerData*(self: Server): ServerData = 
  ## Gets all data from the server
  result = self.data

proc getMapData*(self: Server): Option[MapData] = 
  ## Gets the mapdata data from the server
  result = self.data.map

proc getMotdData*(self: Server): MotdData = 
  ## Gets the motd data from the server
  result = self.data.motd

proc getPlayerData*(self: Server): PlayersData = 
  ## Gets the player data from the server
  result = self.data.players

proc getPluginData*(self: Server): Option[PluginsData] = 
  ## Gets the plugin data from the server
  result = self.data.plugins

proc getModData*(self: Server): Option[ModsData] = 
  ## Gets the mod data from the server
  result = self.data.mods

proc getsServerInfoData*(self: Server): Option[ServerInfo] = 
  ## Gets the server info from the server
  result = self.data.info

proc getDebug*(self: Server): DebugData = 
  ## Gets the debug data from the server
  result = self.debug


# Gets only specific values from server
# More dev friendly 
proc icon*(self: Server): Option[string] = 
  ## Base64 of the server icon (if one exists)
  result = self.data.icon

proc playerCount*(self: Server): int = 
  ## Gets the current player count of the server (as of requesting data)
  result = self.data.players.online

proc maxPlayerCount*(self: Server): int = 
  ## Gets the max player count of the server
  result = self.data.players.max

proc getPlayerByName*(self: Server, name: string): Option[Player] = 
  if not self.data.players.list.isSome():
    return none(Player)
  for p in self.data.players.list.get():
    if p.name == name:
      return some(p)
  return none(Player)

proc getPlayerByUUID*(self: Server, uuid: string): Option[Player] = 
  if not self.data.players.list.isSome():
    return none(Player)
  for p in self.data.players.list.get():
    if p.uuid == uuid:
      return some(p)
  return none(Player)