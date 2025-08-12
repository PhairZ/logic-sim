# Arithmetic Logic Simulator
This is a Logic-gate Simulation made entirely in Godot 4 with GDScript only.

## Controls:
 * Hold `L-CTRL` to Snap to grid.
 * Hold `L-SHIFT` to Align to Axis.
 * Left click on a Connection point to start connecting.
 * Left click while connecting to create a point in the Wire.
 * Right click on a Component to remove it.
 * Right click on a Connection point to disconnect it.
 * Right click while dragging a Component to cancel displacement.
 * Double left click on a custom Component to inspect it.

## Example save file:
  Copy the [`data.res`](data.res) file in the base directory, and paste it in the save file directory.  
  The save file directory is at `user://saves`. `user://` is a custom Godot user data folder by the name of [PhairZ](https://github.com/PhairZ).  
  #### depending on the Operating system you use the directory could be at:
    
  * Windows: `%AppData%\PhairZ\saves`
  * MacOS: `~/Library/Application Support/PhairZ/saves`
  * Linux/BSD: `~/.local/share/Phairz/saves`
  
  [for more info check the Godot documentation for file paths.](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html#accessing-persistent-user-data-user)
  
  Then, paste [`data.res`](data.res) into the save directory **(Make Sure the file is named `data.res`)**.

  This file includes basic gates like **NOT, OR, AND, and XOR**, and more complex gates like a 4-bit number adder.  
  [for more info on how to inspect gates please refer to the Controls section of this README.](#controls)