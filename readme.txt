Ad Hoc README (Unprofessional & Useful)

https://docs.godotengine.org/en/4.4/tutorials/scripting/gdscript/gdscript_basics.html
https://docs.godotengine.org/en/4.4/contributing/development/core_and_modules/core_types.html

General Godot Tips

	Interace: https://docs.godotengine.org/en/stable/tutorials/editor/index.html#editor-s-interface
		* On the top ribbon, 2D and script will swap between the 2D visual interface and the GDScript section
		* Selecting a node in the scene tree (left) will show its properties in the inspector (right)
			- Within the "Node" tab at the top of the inspector shows relevant signals associated with the node

	Scenes: https://docs.godotengine.org/en/4.4/getting_started/step_by_step/nodes_and_scenes.html
		* Each component will exist within its own scene
		* Scenes can be manually instantiated with RMB in the scene tree, or through scripts

	Nodes: https://docs.godotengine.org/en/stable/classes/class_node.html
		* Located in the left viewport in the scene tree
		* Each scene has its own collections of nodes
		* Parents have accessibility to their child's functions and 
		* Every node can use the func _process()
		* Each node may have its own script
		
	Input: https://docs.godotengine.org/en/4.5/tutorials/inputs/
		* To view or set new inputs, at the top of the window select Project>Project Settings>Input Map

Project Specific:

	Inputs:
		* Clicking a button will create a transparent version of the relative component that follows the cursor
		* Clicking after selecting a component will place it at the cursor's position
		* While holding a component, Q and E rotate the component left and right, respectively
		* After a component has been placed, it can be dragged by hovering over it and using Shift+LMB
		* Components can be rotated after being placed or while being dragged
		* Wires can be placed by selecting the wire button, then selecting the end points of 2 components
