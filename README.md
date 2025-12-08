# Yet Another Circuit Designer

YACD is a circuit simulator and solver built in Godot 4.5, capable of simulating resistors and a voltage source and performing circuit analysis. YACD is geared towards Computer Engineering and Electrical Engineering students learning about circuit theory. 

## Features
- Circuit Analysis
  - Mesh Loop
  - Node Analysis
- Step-by-Step explaination of circuit analysis
- Circuit Simulation
  - Current and resistence calculations

Future development intends to expand on this feature set. 
## Running The Program
### System Requirements

This is a very lightweight program so most modern systems should be able to run it. 

CPU: Any 2 core CPU

Storage: ~120MB

RAM: 2GB

If you choose to build the program yourself, refer the the system requirements of [Godot](https://docs.godotengine.org/en/stable/about/system_requirements.html#godot-editor)

### Release Build
 1. Download latest release
 2. Run executable

### Building from Godot
 1. Download [Godot 4.5](https://godotengine.org/download/archive/4.5.1-stable/) and codebase
 2. Launch Godot executable
 3. Click import project and import the project
 4. Set *gui_main.tscn* as main scene (found under gui_components/)
 5. Run project


## Using YACD
NOTE: Currently there are other three components available: resistors, voltage source, current source

##### To place a component:
1. Select component from component panel using *left-click*
2. Place component on grid using *left-click* (component can be rotated using Q and E)
3. *Right-click* to deselect the component

##### To edit a component value:
1. *Left-click* on component value
2. Enter new value
3. Press *enter*

##### To connect components:
1. Select wire tool from component panel
2. *Left-click* on the source component's connection circle
3. Route the wire as needed by *left-clicking* on the grid
4.  *Left-click* on the destination component's connection circle
5. *Right-click* to deselect the wire tool

##### To clear component grid:
1. Press *CTRL+F*
NOTE: As of v0.7.0 there does not currently exist a way to remove individual components

## Development Team
Caleb Buist, Sam Lilly, Josh Stapera
