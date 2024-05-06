import src/nimsrvstat
import std/options

# Create server instance
var server = Server(
    address: "hypixel.net",
    platform: Java
)

# Gets the data for the server (required to use anything)
server.getData

# Check if the icon exists
# If it does write it to a file.
if server.icon().isSome():
    writeFile("icon.png", server.icon().get())