### Garnish Runtime

The runtime of the garnish engine

### Scene Descriptor File Format
All scene descriptor files must use `scdsk` as there file extension.

The first line of every file must indicate the version the Scene Descriptor format being used, where the first line is all of the characters up to and including the new line character.

#### Versions:
Version Name: `Scene Descriptor V0`
* The most basic version of the scene descriptor file format.
* Only stores the data for one scene.
* Stores entities and there components using JSON.
