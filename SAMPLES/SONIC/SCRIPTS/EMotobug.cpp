#include "EMotobug.h"

static const int EMOTOBUG_VEL_X = 1;
static const int EMOTOBUG_IDLE_TIME = 60 * 3;

void EMotobug::OnStart(const Engine& engine, const Scene& scene)
{

}

void EMotobug::OnShutdown(const Engine& engine, const Scene& scene)
{

}

void EMotobug::OnUpdate(const Engine& engine, const Scene& scene)
{
	if (idleTimer > 0)
	{
		if (--idleTimer == 0)
		{
			//Switch direction and start moving again
			velX = -velX;

			//Set sprite flip and restart animation
			ECSprite& sprite = GetComponent<ECSprite>(components.sprite);
			//sprite.SetFlippedX(velX > 0);
			ECSprite& sprite2 = GetComponent<ECSprite>(components.sprite2);
			//sprite2.SetFlippedX(velX > 0);
		}
		else
		{
			return;
		}
	}

	//Move
	positionX.integer += velX;

	//Check floor
	short terrainFlags;
	short floorY = engine.FindFloor(*this, scene, terrainFlags);

	if (terrainFlags & (1 << COLLISION_FLAG_BIT_TERRAIN_W))
	{
		//Snap to floor
		positionY.integer = floorY;

		//Update exhaust pos
	}
	else
	{
		// No terrain, initialise idle timer
		idleTimer = EMOTOBUG_IDLE_TIME;

		//Stop animation

		//Hide exhaust
	}
}

