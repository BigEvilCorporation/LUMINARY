# LUMINARY
A game engine for SEGA Mega Drive and Genesis, in 68000 assembly.

Successor to the TANGLEWOOD engine and framework. Named after the Lunar Module mission software for the Apollo Guidance Computer (AGC) on Apollo 11. Happy 50th anniversary of the moon landing!

LUMINARY features:

- Entity component based game object system, with dynamic spawning and archetype (prefab) support
- Block based dynamic memory allocator
- C++ based object scripting system
- Streaming plane map system with block compression
- Rigid body physics engine with character controller, and Sonic the Hedgehog-like terrain implementation
- Multi-sprite rendering with timeline track animation system
- Fast fixed point 16.16 maths library
- Software drawing canvas with Bresenham line drawing, and primitive 3D point/line transforms
- Support for the Echo sound system by Sik (with a view to switch to Sona when it's ready)

LUMINARY supports scene, sprite, animation, entity, and script data exported by the Beehive toolsuite, see: https://github.com/BigEvilCorporation/Beehive

