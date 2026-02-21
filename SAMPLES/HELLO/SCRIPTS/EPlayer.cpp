#include "EPlayer.h"

void EPlayer::OnStart()
{

}

void EPlayer::OnShutdown()
{

}

void EPlayer::OnUpdate()
{
	ECPhysBodyChar& physics = GetComponent<ECPhysBodyChar>(components.physBodyChar);
	physics.groundSpeed = 0x600;
}

